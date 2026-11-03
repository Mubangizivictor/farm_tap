// Scan station (decision 0016 §4): tap, scan the QR or type a card and the
// person's ID shows with their photo and status, then the next card is read
// with no tap needed. Workers: present or not, days this month and pay.
// Milk suppliers: today's litres, this period and money owed.
import 'dart:async';

import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/nfc/card_reader.dart';
import 'package:farm_tap/core/nfc/card_tap_listener.dart';
import 'package:farm_tap/core/people/domain/card_registry.dart';
import 'package:farm_tap/core/people/domain/staff_directory.dart';
import 'package:farm_tap/core/people/domain/staff_member.dart';
import 'package:farm_tap/core/people/presentation/widgets/card_number_sheet.dart';
import 'package:farm_tap/core/people/presentation/widgets/manager_pin_dialog.dart';
import 'package:farm_tap/core/people/presentation/widgets/staff_form_fields.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/core/utils/formats.dart';
import 'package:farm_tap/sectors/cattle/collection_centre/domain/centre_models.dart';
import 'package:farm_tap/sectors/cattle/collection_centre/domain/centre_repository.dart';
import 'package:farm_tap/sectors/cattle/workers/domain/workers_models.dart';
import 'package:farm_tap/sectors/cattle/workers/domain/workers_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// What a scan does to a worker's card.
enum ScanMode {
  /// Clock the worker in or out (K04).
  attendance,

  /// Only show who it is.
  lookUp,
}

/// How the card was read (kept on the attendance record).
enum ScanMethod { card, qr, typed }

// ---------------------------------------------------------------- results

sealed class ScanOutcome {
  const new({required this.at});

  final DateTime at;
}

class StaffScan extends ScanOutcome {
  const new({
    required super.at,
    required this.staff,
    required this.today,
    required this.days,
    this.wage,
    this.lastPayment,
    this.clocked = false,
  });

  final StaffMember staff;
  final StaffToday? today;
  final int days;
  final WageLine? wage;
  final StaffPayment? lastPayment;

  /// This scan clocked them in or out.
  final bool clocked;
}

class FarmerScan extends ScanOutcome {
  const new({required super.at, required this.farmer, required this.deliveries, this.statement});

  final CentreFarmer farmer;
  final List<Delivery> deliveries;
  final FarmerStatement? statement;
}

/// A card that cannot be used: lost, returned, unknown or another farm's.
class ProblemScan extends ScanOutcome {
  const new({required super.at, required this.number, this.card, this.otherFarm = false});

  final String number;
  final IdCardRecord? card;
  final bool otherFarm;
}

// ---------------------------------------------------------------- page

class CardScanPage extends StatefulWidget {
  const new({
    required this.cards,
    required this.directory,
    required this.workers,
    super.key,
    this.centre,
    this.mode = ScanMode.lookUp,
    this.preferFarmers = false,
    this.canManage = false,
    this.onGiveCard,
    this.onOpenPerson,
    this.showSimulate = false,
  });

  final CardRegistry cards;
  final StaffDirectory directory;
  final WorkersRepository workers;

  /// Milk suppliers (null where there are none to look up).
  final CentreRepository? centre;
  final ScanMode mode;

  /// At a collection centre a sample number may be a farmer's and a
  /// worker's (demo data): farmers win there.
  final bool preferFarmers;

  /// Owner or manager: may switch to attendance and give new cards.
  final bool canManage;

  /// A card no one has: give it to someone (opens the people list).
  final VoidCallback? onGiveCard;

  /// Open the person's page (staff id or farmer id).
  final void Function(CardHolderKind kind, String id)? onOpenPerson;
  final bool showSimulate;

  @override
  State<CardScanPage> createState() => _CardScanPageState();
}

class _CardScanPageState extends State<CardScanPage> {
  late ScanMode _mode = widget.mode;
  ScanOutcome? _shown;
  final List<ScanOutcome> _log = [];
  Timer? _clear;
  bool _camera = false;
  bool _busy = false;
  String? _lastQr;

  /// Time since the last QR read (a stopwatch, not the clock).
  final _sinceQr = Stopwatch();

  @override
  void dispose() {
    _clear?.cancel();
    super.dispose();
  }

  Future<void> _onScanned(String scanned, ScanMethod method) async {
    if (_busy) return;
    _busy = true;
    try {
      final outcome = await _resolve(scanned, method);
      if (!mounted) return;
      unawaited(HapticFeedback.mediumImpact());
      setState(() {
        _shown = outcome;
        _log.insert(0, outcome);
        if (_log.length > 30) _log.removeLast();
      });
      _scheduleNext();
    } finally {
      _busy = false;
    }
  }

  /// The ID stays up for a few seconds, then the page is ready for the
  /// next card on its own (iPhone: Apple's sheet opens again).
  void _scheduleNext() {
    _clear?.cancel();
    _clear = Timer(context.motion.scanResult, () {
      if (!mounted) return;
      setState(() => _shown = null);
      if (ScanCardButton.needed && !_camera) CardTapListener.scanAgain();
    });
  }

  Future<ScanOutcome> _resolve(String scanned, ScanMethod method) async {
    final now = context.clock.now();
    final found = await widget.cards.lookup(scanned);
    final number = scanned.length <= 4 ? scanned.padLeft(4, '0') : scanned;
    if (found case FailureResult(:final failure) when failure.message == CardIssueError.otherFarm) {
      return ProblemScan(at: now, number: CardQr.decode(scanned)?.$2 ?? number, otherFarm: true);
    }
    final card = found.data;
    // Demo data: a sample farmer's printed number not in the register.
    if (card == null || (widget.preferFarmers && card.holderKind == CardHolderKind.staff)) {
      final farmer = (await widget.centre?.farmerByCard(scanned))?.data;
      if (farmer != null) return await _farmer(farmer, now);
      if (card == null) return ProblemScan(at: now, number: CardQr.decode(scanned)?.$2 ?? number);
    }
    if (!card.active) return ProblemScan(at: now, number: card.number, card: card);
    if (card.holderKind == CardHolderKind.farmer) {
      final farmer = (await widget.centre?.farmer(card.holderId))?.data;
      if (farmer == null) return ProblemScan(at: now, number: card.number, card: card);
      return await _farmer(farmer, now);
    }
    final staff = (await widget.directory.staffById(card.holderId)).data;
    if (staff == null) return ProblemScan(at: now, number: card.number, card: card);
    var clocked = false;
    if (_mode == ScanMode.attendance && staff.role != StaffRole.vet) {
      await widget.workers.clockStaff(staff.id, method: method.name);
      clocked = true;
    }
    return await _staff(staff, now, clocked: clocked);
  }

  Future<StaffScan> _staff(StaffMember s, DateTime now, {required bool clocked}) async {
    final today = ((await widget.workers.today()).data ?? const <StaffToday>[]).where((t) => t.staff.id == s.id);
    final wages = (await widget.workers.wages()).data?.lines.where((l) => l.staff.id == s.id).firstOrNull;
    final payments = (await widget.workers.paymentsOf(s.id)).data ?? const <StaffPayment>[];
    return StaffScan(
      at: now,
      staff: s,
      today: today.firstOrNull,
      days: (await widget.workers.daysThisMonth(s.id)).data ?? 0,
      wage: wages,
      lastPayment: payments.firstOrNull,
      clocked: clocked,
    );
  }

  Future<FarmerScan> _farmer(CentreFarmer f, DateTime now) async {
    final repo = widget.centre!;
    return FarmerScan(
      at: now,
      farmer: f,
      deliveries: (await repo.deliveriesOf(f.id, limit: 3)).data ?? const [],
      statement: (await repo.statement(f.id)).data,
    );
  }

  Future<void> _typed() async {
    final card = await showTypeCardNumber(context);
    if (card == null || !mounted) return;
    // A typed number could be anyone's: clocking in needs a manager PIN
    // (decision 0006); looking up does not.
    if (_mode == ScanMode.attendance) {
      final ok = await showManagerPin(
        context,
        message: AppLocalizations.of(context).typedCardNeedsManager(card),
        verify: (pin) async => (await widget.directory.verifyManagerPin(pin)).data ?? false,
      );
      if (!ok || !mounted) return;
    }
    await _onScanned(card, ScanMethod.typed);
  }

  void _onQr(BarcodeCapture capture) {
    for (final b in capture.barcodes) {
      final v = b.rawValue;
      if (v == null || CardQr.decode(v) == null) continue;
      // The same card held in front of the camera reads many times.
      if (v == _lastQr && _sinceQr.isRunning && _sinceQr.elapsed < context.motion.scanResult) return;
      _lastQr = v;
      _sinceQr
        ..reset()
        ..start();
      unawaited(_onScanned(v, ScanMethod.qr));
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shown = _shown;
    return AdaptiveScaffold(
      title: l10n.scanStationTitle,
      subtitle: _mode == ScanMode.attendance ? l10n.scanModeAttendance : l10n.scanModeLookUp,
      showNavigation: false,
      body: CardTapListener(
        onCard: (c) => unawaited(_onScanned(c, ScanMethod.card)),
        prompt: l10n.tapNextCard,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: context.sizes.keypadMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.canManage) ...[
                  SegmentedButton<ScanMode>(
                    segments: [
                      ButtonSegment(
                        value: ScanMode.attendance,
                        label: Text(l10n.clockInOutShort),
                        icon: const Icon(Symbols.schedule_rounded),
                      ),
                      ButtonSegment(
                        value: ScanMode.lookUp,
                        label: Text(l10n.lookUpShort),
                        icon: const Icon(Symbols.badge_rounded),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (v) => setState(() => _mode = v.first),
                  ),
                  context.space.gapLg,
                ],
                AnimatedSwitcher(
                  duration: context.motion.normal,
                  child: shown == null
                      ? _Waiting(key: const ValueKey('waiting'), camera: _camera, onQr: _onQr)
                      : _ResultPanel(
                          key: ValueKey(shown),
                          outcome: shown,
                          mode: _mode,
                          onOpenPerson: widget.onOpenPerson,
                          onGiveCard: widget.canManage ? widget.onGiveCard : null,
                          onNext: () {
                            _clear?.cancel();
                            setState(() => _shown = null);
                            if (ScanCardButton.needed && !_camera) CardTapListener.scanAgain();
                          },
                        ),
                ),
                context.space.gapLg,
                if (ScanCardButton.needed && !_camera) ...[ScanCardButton(label: l10n.scanCard), context.space.gapSm],
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: context.space.sm,
                  children: [
                    TextAction(
                      label: _camera ? l10n.useNfcInstead : l10n.scanQrInstead,
                      icon: _camera ? Symbols.contactless_rounded : Symbols.qr_code_scanner_rounded,
                      onPressed: () => setState(() => _camera = !_camera),
                    ),
                    TextAction(label: l10n.typeCardNumberLink, icon: Symbols.dialpad_rounded, onPressed: _typed),
                  ],
                ),
                if (widget.showSimulate)
                  Center(
                    child: TextAction(
                      label: l10n.simulateTap,
                      small: true,
                      onPressed: () => unawaited(_onScanned('0142', ScanMethod.card)),
                    ),
                  ),
                if (_log.isNotEmpty) ...[
                  context.space.gapLg,
                  ListCard(
                    title: l10n.scannedTodayTitle(_log.length),
                    children: [for (final o in _log.take(10)) _LogTile(outcome: o, onOpenPerson: widget.onOpenPerson)],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Waiting for a card: the tap animation, or the camera when scanning QR.
class _Waiting extends StatelessWidget {
  const new({required this.camera, required this.onQr, super.key});

  final bool camera;
  final void Function(BarcodeCapture) onQr;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FarmTapCard(
      child: Column(
        children: [
          if (camera)
            ClipRRect(
              borderRadius: context.radii.card,
              child: AspectRatio(aspectRatio: 1, child: MobileScanner(onDetect: onQr)),
            )
          else
            FarmTapAnimationView(
              animation: FarmTapAnimations.tapCard,
              size: context.sizes.animationSm,
              semanticLabel: l10n.tapNextCard,
            ),
          context.space.gapMd,
          Text(
            camera ? l10n.holdQrToCamera : l10n.tapNextCard,
            textAlign: TextAlign.center,
            style: context.text.titleMedium,
          ),
          context.space.gapXs,
          Text(
            l10n.scanStationBody,
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// The person's ID after a scan.
class _ResultPanel extends StatelessWidget {
  const new({
    required this.outcome,
    required this.mode,
    required this.onNext,
    super.key,
    this.onOpenPerson,
    this.onGiveCard,
  });

  final ScanOutcome outcome;
  final ScanMode mode;
  final VoidCallback onNext;
  final void Function(CardHolderKind kind, String id)? onOpenPerson;
  final VoidCallback? onGiveCard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final body = switch (outcome) {
      final StaffScan s => _StaffResult(scan: s),
      final FarmerScan f => _FarmerResult(scan: f),
      final ProblemScan p => _ProblemResult(scan: p, onGiveCard: onGiveCard),
    };
    final open = switch (outcome) {
      StaffScan(:final staff) => () => onOpenPerson?.call(CardHolderKind.staff, staff.id),
      FarmerScan(:final farmer) => () => onOpenPerson?.call(CardHolderKind.farmer, farmer.id),
      ProblemScan() => null,
    };
    return FarmTapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          body,
          context.space.gapMd,
          _Countdown(key: ValueKey(outcome)),
          context.space.gapSm,
          Row(
            children: [
              if (open != null && onOpenPerson != null)
                Expanded(
                  child: FarmTapButton(
                    label: l10n.openDetails,
                    icon: Symbols.person_rounded,
                    kind: ButtonKind.outlined,
                    onPressed: open,
                  ),
                ),
              if (open != null && onOpenPerson != null) context.space.gapSm,
              Expanded(
                child: FarmTapButton(label: l10n.nextCard, icon: Symbols.contactless_rounded, onPressed: onNext),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A bar that runs down while the ID is on screen.
class _Countdown extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 1, end: 0),
    duration: context.motion.scanResult,
    builder: (context, v, _) => LinearProgressIndicator(value: v, minHeight: context.sizes.borderThick * 2),
  );
}

class _Head extends StatelessWidget {
  const new({required this.name, required this.lines, required this.badge, this.photo});

  final String name;
  final String? photo;
  final List<String> lines;
  final Widget badge;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      PersonAvatar(name: name, photo: photo, size: context.sizes.scanPhoto, ring: true),
      context.space.gapLg,
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: context.text.headlineSmall),
            for (final l in lines)
              Text(l, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
            context.space.gapSm,
            badge,
          ],
        ),
      ),
    ],
  );
}

class _StaffResult extends StatelessWidget {
  const new({required this.scan});

  final StaffScan scan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = FarmTapFormat(Localizations.localeOf(context).toLanguageTag());
    final s = scan.staff;
    final r = scan.today?.record;
    final (status, tone, icon) = switch (r) {
      null => (l10n.statusNotInToday, FarmTapTone.gold, Symbols.schedule_rounded),
      AttendanceRecord(outAt: null) => (
        scan.clocked ? l10n.statusClockedIn(f.time(r.inAt)) : l10n.statusPresentSince(f.time(r.inAt)),
        FarmTapTone.success,
        Symbols.login_rounded,
      ),
      AttendanceRecord(:final outAt?) => (
        scan.clocked ? l10n.statusClockedOut(f.time(outAt)) : l10n.statusLeftAt(f.time(outAt)),
        FarmTapTone.info,
        Symbols.logout_rounded,
      ),
    };
    final w = scan.wage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Head(
          name: s.name,
          photo: s.photo,
          lines: [
            [staffTitle(l10n, s), if ((s.department ?? '').isNotEmpty) s.department!].join(' · '),
            l10n.cardNumberBadge(s.cardNumber ?? ''),
          ],
          badge: StatusBadge(label: status, tone: tone, icon: icon),
        ),
        context.space.gapLg,
        MetricStrip(
          children: [
            MetricCard(icon: Symbols.event_available_rounded, label: l10n.daysThisMonth, value: f.count(scan.days)),
            if (w != null)
              MetricCard(
                icon: Symbols.account_balance_wallet_rounded,
                label: l10n.balanceOwed,
                value: f.moneyShort(w.toPay),
                tone: FarmTapTone.gold,
              ),
          ],
        ),
        if (w != null) ...[
          context.space.gapSm,
          Text(
            l10n.payrollLine(f.money(w.wage), f.money(w.advances), f.money(w.paid)),
            style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ],
        if (scan.lastPayment case final p?)
          Text(
            l10n.lastPaidLine(f.money(p.amount), f.day(p.at)),
            style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
          ),
      ],
    );
  }
}

class _FarmerResult extends StatelessWidget {
  const new({required this.scan});

  final FarmerScan scan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = FarmTapFormat(Localizations.localeOf(context).toLanguageTag());
    final x = scan.farmer;
    final st = scan.statement;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Head(
          name: x.name,
          photo: x.photo,
          lines: [
            [l10n.idCardSupplier, x.village].where((s) => s.isNotEmpty).join(' · '),
            [l10n.cardNumberBadge(x.card ?? ''), x.localPhone].join(' · '),
          ],
          badge: x.deliveredToday
              ? StatusBadge(
                  label: l10n.broughtToday(f.litres(x.todayLitres!)),
                  tone: FarmTapTone.success,
                  icon: Symbols.water_drop_rounded,
                )
              : StatusBadge(label: l10n.notDeliveredToday, tone: FarmTapTone.gold, icon: Symbols.schedule_rounded),
        ),
        context.space.gapLg,
        MetricStrip(
          children: [
            MetricCard(
              icon: Symbols.water_drop_rounded,
              label: l10n.thisPeriodLabel,
              value: f.litres(x.periodLitres),
              tone: FarmTapTone.info,
            ),
            MetricCard(
              icon: Symbols.payments_rounded,
              label: l10n.moneyOwedLabel,
              value: f.moneyShort(x.owed),
              tone: FarmTapTone.gold,
            ),
          ],
        ),
        if (st != null) ...[
          context.space.gapSm,
          Text(
            l10n.payDayLine(f.day(st.payDay), f.money(st.pricePerLitre)),
            style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ],
        for (final d in scan.deliveries)
          Text(
            '${f.day(d.at)} ${f.time(d.at)} · ${f.litres(d.litres)}${d.rejected ? ' · ${l10n.rejectedWord}' : ''}',
            style: context.text.bodySmall,
          ),
      ],
    );
  }
}

class _ProblemResult extends StatelessWidget {
  const new({required this.scan, this.onGiveCard});

  final ProblemScan scan;
  final VoidCallback? onGiveCard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = FarmTapFormat(Localizations.localeOf(context).toLanguageTag());
    final c = scan.card;
    final (title, message, tone) = switch (c?.status) {
      _ when scan.otherFarm => (l10n.otherFarmCardTitle, l10n.otherFarmCardBody, FarmTapTone.danger),
      CardStatus.lost => (
        l10n.lostCardTitle(scan.number),
        l10n.lostCardBody(c!.holderName, c.endedAt == null ? '' : f.day(c.endedAt!)),
        FarmTapTone.danger,
      ),
      CardStatus.returned => (
        l10n.returnedCardTitle(scan.number),
        l10n.returnedCardBody(c!.holderName),
        FarmTapTone.gold,
      ),
      _ => (l10n.newCardTitle(scan.number), l10n.unknownCardBody, FarmTapTone.gold),
    };
    final give = onGiveCard;
    return FarmTapBanner(
      tone: tone,
      icon: tone == FarmTapTone.danger ? Symbols.gpp_bad_rounded : Symbols.contactless_rounded,
      title: title,
      message: message,
      actionLabel: give != null && c?.status != CardStatus.lost && !scan.otherFarm ? l10n.giveCardToSomeone : null,
      onAction: give,
    );
  }
}

class _LogTile extends StatelessWidget {
  const new({required this.outcome, this.onOpenPerson});

  final ScanOutcome outcome;
  final void Function(CardHolderKind kind, String id)? onOpenPerson;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = FarmTapFormat(Localizations.localeOf(context).toLanguageTag());
    return switch (outcome) {
      StaffScan(:final staff, :final today, :final clocked) => RecordTile(
        leading: PersonAvatar(name: staff.name, photo: staff.photo),
        title: staff.name,
        subtitle: staffTitle(l10n, staff),
        trailingValue: clocked
            ? (today?.isIn ?? false ? l10n.inLabel : l10n.outLabel)
            : (today?.isIn ?? false ? l10n.presentWord : l10n.absentWord),
        trailingSub: f.time(outcome.at),
        onTap: onOpenPerson == null ? null : () => onOpenPerson!(CardHolderKind.staff, staff.id),
      ),
      FarmerScan(:final farmer) => RecordTile(
        leading: PersonAvatar(name: farmer.name, photo: farmer.photo, tone: FarmTapTone.info),
        title: farmer.name,
        subtitle: farmer.village,
        trailingValue: f.moneyShort(farmer.owed),
        trailingSub: f.time(outcome.at),
        onTap: onOpenPerson == null ? null : () => onOpenPerson!(CardHolderKind.farmer, farmer.id),
      ),
      ProblemScan(:final number) => RecordTile(
        leading: const IconBubble(icon: Symbols.gpp_bad_rounded, tone: FarmTapTone.danger),
        title: l10n.cardNumberBadge(number),
        subtitle: l10n.cardNotUsable,
        trailingSub: f.time(outcome.at),
        showChevron: false,
      ),
    };
  }
}

/// iPhone needs a tap to open Apple's sheet; elsewhere it is already on.
Future<bool> scanStationNfcReady() => CardReader.instance.available();
