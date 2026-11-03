// Collection centre intake: G01 centre home (+ G08 close session), G02 tap
// card (+ G05 saved state with Undo), G03 delivery keypad (+ G04 read-back,
// G12 quality test), G13 reconcile.
import 'dart:async';

import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/nfc/card_tap_listener.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/core/utils/formats.dart';
import 'package:farm_tap/sectors/cattle/collection_centre/domain/centre_models.dart';
import 'package:farm_tap/sectors/cattle/collection_centre/domain/centre_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

FarmTapFormat _fmt(BuildContext context) => FarmTapFormat(Localizations.localeOf(context).toLanguageTag());

String centreSessionName(AppLocalizations l10n, CentreSession s) =>
    s == CentreSession.morning ? l10n.morning : l10n.evening;

CentreSession centreSessionAt(DateTime t) => t.hour < 12 ? CentreSession.morning : CentreSession.evening;

/// Farmer initials circle; tone cycles primary / gold / info like the mockups.
class FarmerAvatar extends StatelessWidget {
  const new({required this.farmer, super.key, this.size, this.ring = false, this.plain = false});

  final CentreFarmer farmer;
  final double? size;
  final bool ring;

  /// Always primary (G01 latest deliveries).
  final bool plain;

  @override
  Widget build(BuildContext context) {
    const tones = [FarmTapTone.primary, FarmTapTone.gold, FarmTapTone.info];
    final i = int.tryParse(farmer.card ?? '') ?? farmer.name.length;
    return PersonAvatar(
      name: farmer.name,
      size: size ?? context.sizes.avatarMd,
      ring: ring,
      tone: plain ? FarmTapTone.primary : tones[i % tones.length],
    );
  }
}

// ---------------------------------------------------------------- G01

enum CentreTool { cardNumber, qualityTest, dispatch, closeSession }

class CentreHomePage extends StatefulWidget {
  const new({
    required this.repo,
    required this.centreName,
    required this.onTapCard,
    required this.onTool,
    required this.onSeeAll,
    super.key,
    this.onRefresh,
  });

  final CentreRepository repo;
  final String centreName;
  final VoidCallback onTapCard;
  final ValueChanged<CentreTool> onTool;
  final VoidCallback onSeeAll;
  final Future<void> Function()? onRefresh;

  @override
  State<CentreHomePage> createState() => _CentreHomePageState();
}

class _CentreHomePageState extends State<CentreHomePage> {
  late Future<(CentreDay?, List<CentreFarmer>)> _load = _fetch();

  Future<(CentreDay?, List<CentreFarmer>)> _fetch() async =>
      ((await widget.repo.today()).data, (await widget.repo.farmers()).data ?? const <CentreFarmer>[]);

  Future<void> _refresh() async {
    await widget.onRefresh?.call();
    setState(() {
      _load = _fetch();
    });
    await _load;
  }

  Future<void> _tool(CentreDay day, CentreTool tool) async {
    if (tool != CentreTool.closeSession) return widget.onTool(tool);
    final closed = await showCloseSessionDialog(context, repo: widget.repo, day: day);
    if (!closed || !mounted) return;
    FarmTapToast.show(context, message: AppLocalizations.of(context).sessionClosed, icon: Symbols.lock_rounded);
    setState(() {
      _load = _fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    final online = ShellStatus.maybeOf(context)?.online ?? true;
    return AdaptiveScaffold(
      showLogo: true,
      title: l10n.home,
      onRefresh: _refresh,
      body: FutureBuilder<(CentreDay?, List<CentreFarmer>)>(
        future: _load,
        builder: (context, snapshot) {
          final (day, farmers) = snapshot.data ?? (null, const <CentreFarmer>[]);
          if (day == null) return const FarmTapPageLoader();
          final session = centreSessionName(l10n, day.session);
          final byId = {for (final x in farmers) x.id: x};
          final tiles = [
            ActionTile(
              icon: Symbols.dialpad_rounded,
              label: l10n.cardNumber,
              onTap: () => _tool(day, CentreTool.cardNumber),
            ),
            ActionTile(
              icon: Symbols.science_rounded,
              label: l10n.qualityTest,
              tone: FarmTapTone.info,
              onTap: () => _tool(day, CentreTool.qualityTest),
            ),
            ActionTile(
              icon: Symbols.local_shipping_rounded,
              label: l10n.dispatch,
              tone: FarmTapTone.gold,
              onTap: () => _tool(day, CentreTool.dispatch),
            ),
            ActionTile(
              icon: Symbols.lock_rounded,
              label: l10n.closeSession,
              tone: FarmTapTone.danger,
              onTap: day.closed ? null : () => _tool(day, CentreTool.closeSession),
            ),
          ];
          final latest = ListCard(
            title: l10n.latestDeliveries,
            actionLabel: l10n.seeAll,
            onAction: widget.onSeeAll,
            children: [
              for (final d in day.latest.take(3))
                RecordTile(
                  leading: byId[d.farmerId] == null
                      ? PersonAvatar(name: d.farmerName, size: context.sizes.avatarMd)
                      : FarmerAvatar(farmer: byId[d.farmerId]!, plain: true),
                  title: d.farmerName,
                  subtitle: l10n.timeAndCard(f.clock24(d.at), d.card),
                  badge: d.rejected
                      ? StatusBadge(label: l10n.rejected, tone: FarmTapTone.danger, icon: Symbols.block_rounded)
                      : null,
                  trailingValue: f.litres(d.litres),
                  showChevron: false,
                ),
            ],
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!online) ...[const OfflineBanner(), context.space.gapLg],
              Text(widget.centreName, style: context.text.headlineSmall),
              Text(
                l10n.sessionOpenSince(session, f.clock24(day.openSince)),
                style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
              ),
              context.space.gapLg,
              HeroCard(
                label: l10n.collectedThisSession(session.toLowerCase()),
                value: f.count(day.litres),
                unit: l10n.litreUnit,
                sub: l10n.fromFarmersRejected(day.farmers, day.rejected),
                animation: FarmTapAnimations.milking,
              ),
              context.space.gapLg,
              FarmTapButton(
                label: l10n.tapFarmerCard,
                icon: Symbols.contactless_rounded,
                large: true,
                onPressed: day.closed ? null : widget.onTapCard,
              ),
              context.space.gapLg,
              ResponsiveGrid(minItemWidth: context.sizes.gridAction, spacing: context.space.md, children: tiles),
              context.space.gapLg,
              if (context.isCompact)
                latest
              else
                ResponsiveGrid(
                  minItemWidth: context.sizes.gridPaired,
                  maxColumns: 2,
                  spacing: context.space.md,
                  children: [
                    latest,
                    FarmTapCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CardHeader(title: l10n.litresByHour),
                          context.space.gapLg,
                          FarmTapBarChart(values: day.litresByHour, labels: day.hourLabels),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------- G08

/// "Close the morning session?" with the manager PIN. True once closed.
Future<bool> showCloseSessionDialog(
  BuildContext context, {
  required CentreRepository repo,
  required CentreDay day,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => DialogFrame(
      child: CloseSessionDialog(repo: repo, day: day),
    ),
  );
  return result ?? false;
}

class CloseSessionDialog extends StatefulWidget {
  const new({required this.repo, required this.day, super.key, this.initialPin = ''});

  final CentreRepository repo;
  final CentreDay day;

  /// Goldens show one digit typed.
  final String initialPin;

  @override
  State<CloseSessionDialog> createState() => _CloseSessionDialogState();
}

class _CloseSessionDialogState extends State<CloseSessionDialog> {
  late final _pin = TextEditingController(text: widget.initialPin);
  final _focus = FocusNode();
  int _errorTick = 0;
  bool _wrong = false;

  @override
  void dispose() {
    _pin.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (_pin.text.length < 4) return _focus.requestFocus();
    final ok = (await widget.repo.closeSession(_pin.text)).data ?? false;
    if (!mounted) return;
    if (ok) {
      unawaited(HapticFeedback.mediumImpact());
      Navigator.of(context).pop(true);
      return;
    }
    unawaited(HapticFeedback.heavyImpact());
    setState(() {
      _wrong = true;
      _errorTick++;
      _pin.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    final session = centreSessionName(l10n, widget.day.session).toLowerCase();
    return FarmTapDialog(
      icon: Symbols.lock_rounded,
      title: l10n.closeSessionTitle(session),
      message: l10n.closeSessionBody(f.count(widget.day.litres), widget.day.farmers),
      primaryLabel: l10n.closeSession,
      primaryIcon: Symbols.lock_rounded,
      secondaryLabel: l10n.keepOpen,
      secondaryKind: ButtonKind.text,
      onPrimary: _close,
      child: Column(
        children: [
          Semantics(
            label: l10n.managerPin,
            textField: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _focus.requestFocus,
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _pin,
                builder: (context, value, _) =>
                    PinDots(filled: value.text.length, error: _wrong, errorTick: _errorTick),
              ),
            ),
          ),
          if (_wrong) ...[
            context.space.gapSm,
            Text(l10n.wrongManagerPin, style: context.text.bodySmall?.copyWith(color: context.status.danger)),
          ],
          // Collects the digits; the dots above show them.
          SizedBox.shrink(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: _pin,
                focusNode: _focus,
                autofocus: widget.initialPin.isEmpty,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (v) {
                  if (_wrong) setState(() => _wrong = false);
                  if (v.length == 4) unawaited(_close());
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- G02 / G05

class ReceiveMilkPage extends StatefulWidget {
  const new({
    required this.repo,
    required this.onFarmer,
    super.key,
    this.savedDeliveryId,
    this.showSimulate = false,
    this.now,
    this.showToast = true,
  });

  final CentreRepository repo;

  /// A card was read (or the farmer was found by number / name).
  final ValueChanged<CentreFarmer> onFarmer;

  /// G05: the delivery just saved (shows "Last saved" and the Undo toast).
  final String? savedDeliveryId;
  final bool showSimulate;
  final DateTime? now;
  final bool showToast;

  @override
  State<ReceiveMilkPage> createState() => _ReceiveMilkPageState();
}

class _ReceiveMilkPageState extends State<ReceiveMilkPage> {
  Delivery? _saved;

  /// The farmer of [_saved] gets an SMS receipt.
  bool _savedSms = false;

  @override
  void initState() {
    super.initState();
    if (widget.savedDeliveryId != null) unawaited(_loadSaved());
  }

  @override
  void didUpdateWidget(ReceiveMilkPage old) {
    super.didUpdateWidget(old);
    if (old.savedDeliveryId != widget.savedDeliveryId) {
      if (widget.savedDeliveryId == null) {
        setState(() => _saved = null);
      } else {
        unawaited(_loadSaved());
      }
    }
  }

  Future<void> _loadSaved() async {
    final day = (await widget.repo.today()).data;
    final saved = day?.latest.where((d) => d.id == widget.savedDeliveryId).firstOrNull;
    if (!mounted || saved == null) return;
    final farmer = (await widget.repo.farmer(saved.farmerId)).data;
    if (!mounted) return;
    setState(() {
      _saved = saved;
      _savedSms = (farmer?.smsReceipts ?? false) && (farmer?.phone.isNotEmpty ?? false);
    });
    if (!widget.showToast) return;
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    FarmTapToast.show(
      context,
      message: l10n.savedForFarmer(f.litresValue(saved.litres, trim: false), saved.farmerName),
      singleLine: true,
      actionLabel: l10n.undo,
      duration: context.motion.undoWindow,
      onAction: () async {
        await widget.repo.undoDelivery(saved.id);
        if (!mounted) return;
        setState(() => _saved = null);
        FarmTapToast.show(context, message: l10n.deliveryUndone, icon: Symbols.undo_rounded, playSound: false);
      },
    );
  }

  Future<void> _byCard(String card) async {
    final farmer = (await widget.repo.farmerByCard(card)).data;
    if (!mounted) return;
    if (farmer == null) {
      FarmTapToast.show(
        context,
        message: AppLocalizations.of(context).farmerCardNotFound,
        icon: Symbols.error_rounded,
        tone: FarmTapTone.danger,
      );
      return;
    }
    widget.onFarmer(farmer);
  }

  Future<void> _enterNumber() async {
    final card = await showCardNumberSheet(context);
    if (card != null) await _byCard(card);
  }

  Future<void> _search() async {
    final farmers = (await widget.repo.farmers()).data ?? const <CentreFarmer>[];
    if (!mounted) return;
    final farmer = await showFindFarmerSheet(context, farmers);
    if (farmer != null) widget.onFarmer(farmer);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    final saved = _saved;
    final session = centreSessionAt(widget.now ?? context.clock.now());
    return AdaptiveScaffold(
      title: l10n.receiveMilk,
      subtitle: l10n.sessionLabel(centreSessionName(l10n, session)),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: context.sizes.centeredMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CardTapListener(onCard: _byCard, prompt: l10n.tapFarmersCard, child: const SizedBox.shrink()),
              context.space.gapXxxl,
              Center(
                child: FarmTapAnimationView(
                  animation: FarmTapAnimations.tapCard,
                  size: context.sizes.animationMd,
                  semanticLabel: l10n.tapFarmersCard,
                ),
              ),
              context.space.gapXxxl,
              Text(
                saved == null ? l10n.tapFarmersCard : l10n.tapNextCard,
                textAlign: TextAlign.center,
                style: context.text.titleLarge,
              ),
              context.space.gapXs,
              Text(
                saved == null ? l10n.holdCardBack : l10n.readyNextFarmer,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
              ),
              context.space.gapLg,
              if (saved != null)
                FarmTapCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l10n.lastSaved, style: context.textStyles.metricLabel),
                      context.space.gapMd,
                      Row(
                        children: [
                          Expanded(child: Text(saved.farmerName, style: context.text.titleSmall)),
                          Text(f.litres(saved.litres), style: context.text.titleSmall),
                        ],
                      ),
                      if (_savedSms) ...[
                        context.space.gapMd,
                        Text(
                          l10n.smsQueuedPrintSlip,
                          style: context.text.bodyMedium?.copyWith(color: context.colors.primary),
                        ),
                      ],
                    ],
                  ),
                )
              else ...[
                FarmTapButton(
                  label: l10n.enterCardNumber,
                  icon: Symbols.dialpad_rounded,
                  kind: ButtonKind.outlined,
                  onPressed: _enterNumber,
                ),
                context.space.gapMd,
                TextAction(label: l10n.searchFarmerByName, icon: Symbols.search_rounded, onPressed: _search),
              ],
              if (widget.showSimulate)
                TextAction(label: l10n.simulateTap, small: true, onPressed: () => unawaited(_byCard('0142'))),
            ],
          ),
        ),
      ),
    );
  }
}

/// Four-digit card number keypad. Resolves to the number typed.
Future<String?> showCardNumberSheet(BuildContext context) =>
    showAdaptiveSheet<String>(context, builder: (_) => const _CardNumberSheet());

class _CardNumberSheet extends StatefulWidget {
  const new();

  @override
  State<_CardNumberSheet> createState() => _CardNumberSheetState();
}

class _CardNumberSheetState extends State<_CardNumberSheet> {
  String _digits = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(l10n.cardNumber),
        context.space.gapMd,
        KeypadDisplay(text: _digits, placeholder: '0000'),
        context.space.gapMd,
        BigNumberKeypad(
          onDigit: (d) => setState(() => _digits = _digits.length < 4 ? _digits + d : _digits),
          onBackspace: () => setState(() => _digits = _digits.isEmpty ? '' : _digits.substring(0, _digits.length - 1)),
        ),
        context.space.gapSm,
        FarmTapButton(
          label: l10n.findFarmer,
          icon: Symbols.search_rounded,
          onPressed: _digits.isEmpty ? null : () => Navigator.of(context).pop(_digits),
        ),
      ],
    );
  }
}

/// Search the centre's farmers by name or card.
Future<CentreFarmer?> showFindFarmerSheet(BuildContext context, List<CentreFarmer> farmers) =>
    showAdaptiveSheet<CentreFarmer>(context, builder: (_) => _FindFarmerSheet(farmers: farmers));

class _FindFarmerSheet extends StatefulWidget {
  const new({required this.farmers});

  final List<CentreFarmer> farmers;

  @override
  State<_FindFarmerSheet> createState() => _FindFarmerSheetState();
}

class _FindFarmerSheetState extends State<_FindFarmerSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final q = _q.trim().toLowerCase();
    final shown = widget.farmers
        .where((x) => q.isEmpty || x.name.toLowerCase().contains(q) || (x.card ?? '').contains(q))
        .take(5);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(l10n.findFarmer),
        context.space.gapMd,
        SearchField(hint: l10n.searchFarmers, onChanged: (v) => setState(() => _q = v)),
        context.space.gapSm,
        for (final x in shown)
          RecordTile(
            leading: FarmerAvatar(farmer: x),
            title: x.name,
            subtitle: x.card == null ? x.village : l10n.cardAndVillage(x.card!, x.village),
            onTap: () => Navigator.of(context).pop(x),
          ),
        if (shown.isEmpty)
          Padding(
            padding: EdgeInsets.all(context.space.lg),
            child: Text(l10n.noMatches, textAlign: TextAlign.center, style: context.text.bodyMedium),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------- G03 / G04 / G12

class DeliveryKeypadPage extends StatefulWidget {
  const new({
    required this.repo,
    required this.farmerId,
    required this.onSaved,
    required this.onRejected,
    super.key,
    this.now,
    this.initialLitres = '',
  });

  final CentreRepository repo;
  final String farmerId;
  final ValueChanged<Delivery> onSaved;
  final VoidCallback onRejected;
  final DateTime? now;

  /// Goldens start with a number typed ("42.5").
  final String initialLitres;

  @override
  State<DeliveryKeypadPage> createState() => _DeliveryKeypadPageState();
}

class _DeliveryKeypadPageState extends State<DeliveryKeypadPage> {
  late final Future<CentreFarmer?> _farmer = widget.repo.farmer(widget.farmerId).then((r) => r.data);
  late DecimalEntry _entry = DecimalEntry(text: widget.initialLitres);
  QualityTest _test = QualityTest.notDone;

  CentreSession get _session => centreSessionAt(widget.now ?? context.clock.now());

  Future<void> _quality(CentreFarmer farmer) async {
    if (_entry.value <= 0) return;
    final result = await showQualityTestSheet(context, farmer: farmer, litres: _entry.value);
    if (result == null || !mounted) return;
    if (result.passed) {
      setState(() => _test = QualityTest.passed);
      return;
    }
    await widget.repo.rejectDelivery(farmer.id, _entry.value, result.reason!, note: result.note);
    if (!mounted) return;
    unawaited(HapticFeedback.heavyImpact());
    final l10n = AppLocalizations.of(context);
    FarmTapToast.show(
      context,
      message: l10n.willBeRejected(_fmt(context).litresValue(_entry.value, trim: false)),
      icon: Symbols.block_rounded,
      tone: FarmTapTone.danger,
    );
    widget.onRejected();
  }

  Future<void> _next(CentreFarmer farmer) async {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    final litres = _entry.value;
    if (litres <= 0) return;
    final ok = await showReadBack(
      context,
      leading: FarmerAvatar(farmer: farmer, size: context.sizes.avatarReadBack, ring: true),
      subject: farmer.name,
      valueText: l10n.litresValue(f.litresValue(litres, trim: false)),
      detail: l10n.deliveryDetail(
        centreSessionName(l10n, _session),
        farmer.card ?? '—',
        _test == QualityTest.passed ? l10n.testPassed : l10n.testNotDone,
      ),
    );
    if (!ok || !mounted) return;
    final saved = (await widget.repo.recordDelivery(
      farmer.id,
      litres,
      test: _test == QualityTest.notDone ? QualityTest.passed : _test,
    )).data;
    if (saved == null || !mounted) return;
    unawaited(HapticFeedback.mediumImpact());
    widget.onSaved(saved);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<CentreFarmer?>(
      future: _farmer,
      builder: (context, snapshot) {
        final farmer = snapshot.data;
        return AdaptiveScaffold(
          title: l10n.receiveMilk,
          subtitle: l10n.sessionLabel(centreSessionName(l10n, _session)),
          showNavigation: false,
          actions: [
            if (farmer != null)
              BarAction(icon: Symbols.science_rounded, tooltip: l10n.qualityTest, onPressed: () => _quality(farmer)),
          ],
          body: farmer == null
              ? const SizedBox.shrink()
              : Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: context.sizes.keypadMaxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FarmTapCard(
                          child: Row(
                            children: [
                              FarmerAvatar(farmer: farmer, size: context.sizes.avatarLg, plain: true),
                              context.space.gapLg,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(farmer.name, style: context.text.titleMedium),
                                    Text(
                                      farmer.card == null
                                          ? farmer.village
                                          : l10n.cardAndVillage(farmer.card!, farmer.village),
                                      style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              context.space.gapSm,
                              if (farmer.card != null)
                                StatusBadge(
                                  label: _test == QualityTest.passed ? l10n.testPassed : l10n.cardOk,
                                  tone: FarmTapTone.success,
                                  icon: Symbols.check_circle_rounded,
                                ),
                            ],
                          ),
                        ),
                        context.space.gapLg,
                        KeypadDisplay(
                          text: _entry.text,
                          unit: l10n.litreUnit,
                          caption: l10n.usuallyBrings(farmer.usualLow, farmer.usualHigh),
                        ),
                        context.space.gapMd,
                        BigNumberKeypad(
                          showDecimal: true,
                          onDigit: (d) => setState(() => _entry = _entry.press(d)),
                          onBackspace: () => setState(() => _entry = _entry.backspace()),
                        ),
                        context.space.gapSm,
                        FarmTapButton(
                          label: l10n.next,
                          icon: Symbols.check_rounded,
                          large: true,
                          onPressed: _entry.value > 0 ? () => _next(farmer) : null,
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class QualityResult {
  const new({required this.passed, this.reason, this.note});

  final bool passed;
  final RejectReason? reason;
  final String? note;
}

/// G12 — alcohol test; a failed test rejects the milk (not paid).
Future<QualityResult?> showQualityTestSheet(
  BuildContext context, {
  required CentreFarmer farmer,
  required double litres,
}) => showAdaptiveSheet<QualityResult>(
  context,
  builder: (_) => QualityTestSheet(farmer: farmer, litres: litres),
);

class QualityTestSheet extends StatefulWidget {
  const new({
    required this.farmer,
    required this.litres,
    super.key,
    this.initialPassed = true,
    this.initialReason,
    this.initialNote = '',
  });

  final CentreFarmer farmer;
  final double litres;
  final bool initialPassed;
  final RejectReason? initialReason;
  final String initialNote;

  @override
  State<QualityTestSheet> createState() => _QualityTestSheetState();
}

class _QualityTestSheetState extends State<QualityTestSheet> {
  late bool _passed = widget.initialPassed;
  late RejectReason? _reason = widget.initialReason;
  late final _note = TextEditingController(text: widget.initialNote);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  String _reasonLabel(AppLocalizations l10n, RejectReason r) => switch (r) {
    RejectReason.sour => l10n.reasonSour,
    RejectReason.addedWater => l10n.reasonWater,
    RejectReason.dirty => l10n.reasonDirty,
    RejectReason.treatedCow => l10n.reasonTreated,
    RejectReason.other => l10n.reasonOther,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    final litres = f.litresValue(widget.litres, trim: false);
    Widget label(String text) => Padding(
      padding: EdgeInsets.only(top: context.space.lg, bottom: context.space.sm),
      child: Text(text, style: context.text.titleSmall),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(l10n.qualityTest, subtitle: l10n.farmerAndLitres(widget.farmer.name, litres)),
        label(l10n.alcoholTest),
        SegmentedTabs<bool>(
          options: [
            TabOption(value: true, label: l10n.passed),
            TabOption(value: false, label: l10n.failed),
          ],
          selected: _passed,
          onChanged: (v) => setState(() => _passed = v),
        ),
        if (!_passed) ...[
          label(l10n.reason),
          Wrap(
            spacing: context.space.chipRun,
            children: [
              for (final r in RejectReason.values)
                FarmTapChip(
                  label: _reasonLabel(l10n, r),
                  selected: _reason == r,
                  onTap: () => setState(() => _reason = r),
                ),
            ],
          ),
          context.space.gapMd,
          FarmTapTextField(label: l10n.noteOptional, icon: Symbols.experiment_rounded, controller: _note),
          context.space.gapLg,
          FarmTapBanner(
            tone: FarmTapTone.danger,
            icon: Symbols.error_rounded,
            title: l10n.willBeRejected(litres),
            message: l10n.rejectedBody,
          ),
          context.space.gapLg,
          FarmTapButton(
            label: l10n.rejectMilk,
            icon: Symbols.do_not_disturb_on_rounded,
            kind: ButtonKind.danger,
            onPressed: _reason == null
                ? null
                : () => Navigator.of(context).pop(
                    QualityResult(
                      passed: false,
                      reason: _reason,
                      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
                    ),
                  ),
          ),
        ] else ...[
          context.space.gapXl,
          FarmTapButton(
            label: l10n.acceptMilk,
            icon: Symbols.check_rounded,
            onPressed: () => Navigator.of(context).pop(const QualityResult(passed: true)),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------- G13

class ReconcilePage extends StatefulWidget {
  const new({required this.repo, required this.onSaved, super.key});

  final CentreRepository repo;
  final VoidCallback onSaved;

  @override
  State<ReconcilePage> createState() => _ReconcilePageState();
}

class _ReconcilePageState extends State<ReconcilePage> {
  late final Future<Reconciliation?> _load = widget.repo.reconciliation().then((r) => r.data);
  final _why = TextEditingController();

  @override
  void dispose() {
    _why.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await widget.repo.saveReconciliation(_why.text.trim());
    if (!mounted) return;
    FarmTapToast.show(context, message: AppLocalizations.of(context).reconciliationSaved);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    return FutureBuilder<Reconciliation?>(
      future: _load,
      builder: (context, snapshot) {
        final r = snapshot.data;
        return DiscardGuard(
          dirty: _why.text.isNotEmpty,
          child: AdaptiveScaffold(
            title: l10n.reconcile,
            subtitle: r == null ? null : l10n.sessionLabel(centreSessionName(l10n, r.session)),
            body: r == null
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MetricStrip(
                        children: [
                          MetricCard(
                            icon: Symbols.download_rounded,
                            label: l10n.receivedFromFarmers,
                            value: f.count(r.received),
                            unit: l10n.litreUnit,
                          ),
                          MetricCard(
                            icon: Symbols.local_shipping_rounded,
                            label: l10n.dispatchedToDairy,
                            value: f.count(r.dispatched),
                            unit: l10n.litreUnit,
                            tone: FarmTapTone.gold,
                          ),
                          MetricCard(
                            icon: r.aboveLimit ? Symbols.warning_rounded : Symbols.check_circle_rounded,
                            label: l10n.difference,
                            value: '${r.difference < 0 ? '−' : '+'}${f.count(r.difference.abs())}',
                            unit: l10n.litreUnit,
                            caption: r.aboveLimit
                                ? l10n.diffPercent(r.percent.toStringAsFixed(1), r.limitPercent)
                                : l10n.diffPercentOk(r.percent.toStringAsFixed(1), r.limitPercent),
                            tone: r.aboveLimit ? FarmTapTone.warning : FarmTapTone.success,
                          ),
                        ],
                      ),
                      if (r.aboveLimit) ...[
                        context.space.gapLg,
                        FarmTapBanner(
                          tone: FarmTapTone.warning,
                          icon: Symbols.warning_rounded,
                          title: l10n.diffAboveLimit(r.limitPercent),
                          message: l10n.diffAboveBody,
                        ),
                      ],
                      context.space.gapLg,
                      FarmTapCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CardHeader(title: l10n.dispatchTitle),
                            context.space.gapSm,
                            SummaryRow(label: l10n.truck, value: '${r.truck} · ${r.buyer}'),
                            SummaryRow(label: l10n.driver, value: r.driver),
                            SummaryRow(label: l10n.leftAt, value: f.time(r.leftAt)),
                            SummaryRow(label: l10n.temperature, value: '${r.temperature.toStringAsFixed(1)} °C'),
                          ],
                        ),
                      ),
                      context.space.gapLg,
                      FarmTapTextField(
                        label: l10n.explainDifference,
                        icon: Symbols.edit_note_rounded,
                        controller: _why,
                        onChanged: (_) => setState(() {}),
                      ),
                      context.space.gapLg,
                      FarmTapButton(
                        label: l10n.saveReconciliation,
                        icon: Symbols.check_rounded,
                        onPressed: r.aboveLimit && _why.text.trim().isEmpty ? null : _save,
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
