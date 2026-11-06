// Workers: K01 staff list, K02 staff detail, K03 assign card, K04
// attendance, K05 tasks, K06 wages & advances. Who is in, days worked and
// balances are calculated from attendance and payment records.
import 'dart:async';

import 'package:farm_tap/core/error/failure.dart';
import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/nfc/card_reader.dart';
import 'package:farm_tap/core/nfc/card_tap_listener.dart';
import 'package:farm_tap/core/people/domain/card_registry.dart';
import 'package:farm_tap/core/people/domain/staff_directory.dart';
import 'package:farm_tap/core/people/domain/staff_member.dart';
import 'package:farm_tap/core/people/domain/staff_permissions.dart';
import 'package:farm_tap/core/people/presentation/widgets/card_number_sheet.dart';
import 'package:farm_tap/core/people/presentation/widgets/manager_pin_dialog.dart';
import 'package:farm_tap/core/people/presentation/widgets/staff_form_fields.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/core/utils/formats.dart';
import 'package:farm_tap/sectors/cattle/workers/domain/workers_models.dart';
import 'package:farm_tap/sectors/cattle/workers/domain/workers_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

FarmTapFormat _fmt(BuildContext context) => FarmTapFormat(Localizations.localeOf(context).toLanguageTag());

/// "UGX 180k", "UGX 1.52M" (metric cards).
String _moneyShort(FarmTapFormat f, int ugx) => 'UGX ${ugx >= 1000000 ? f.compact(ugx).toUpperCase() : f.compact(ugx)}';

/// Avatar colours rotate down the staff list (green, gold, blue), as on the
/// mockups; [order] is the farm's staff list.
FarmTapTone _avatarTone(StaffMember s, List<StaffMember> order) =>
    const [FarmTapTone.primary, FarmTapTone.gold, FarmTapTone.info][order.indexWhere((m) => m.id == s.id).abs() % 3];

StatusBadge _cardBadge(AppLocalizations l10n, StaffMember s) => s.hasCard
    ? StatusBadge(label: l10n.cardBadge, tone: FarmTapTone.success, icon: Symbols.contactless_rounded)
    : StatusBadge(label: l10n.noCardBadge, tone: FarmTapTone.gold);

/// "In 6:02" / "Out 5:30" / "Not in" / "Visits".
String _todayText(AppLocalizations l10n, FarmTapFormat f, StaffToday t) {
  if (!t.onShift && t.record == null) return l10n.visitingVet;
  final r = t.record;
  if (r == null) return l10n.notInLabel;
  return r.outAt == null ? l10n.inAt(f.clock24(r.inAt)) : l10n.outAt(f.clock24(r.outAt!));
}

// ---------------------------------------------------------------- K01

enum WorkersTarget { attendance, tasks, wages }

enum _Filter { all, inNow, notIn }

class WorkersPage extends StatefulWidget {
  const new({
    required this.repo,
    required this.onStaff,
    required this.onOpen,
    required this.onAdd,
    super.key,
    this.canManageStaff = true,
    this.onScan,
    this.onPrintAll,
    this.onCards,
  });

  /// Scan station (decision 0016 §4).
  final VoidCallback? onScan;

  /// Print every worker's card on A4.
  final Future<void> Function()? onPrintAll;

  /// The card register (every card and who holds it).
  final VoidCallback? onCards;

  final WorkersRepository repo;

  /// Owner and managers only (ROADMAP 7.4): Add worker.
  final bool canManageStaff;

  /// Pushes the add-worker form; completes when it closes.
  final Future<void> Function() onAdd;
  final ValueChanged<String> onStaff;
  final ValueChanged<WorkersTarget> onOpen;

  @override
  State<WorkersPage> createState() => _WorkersPageState();
}

class _WorkersPageState extends State<WorkersPage> {
  late Future<(List<StaffToday>, Map<String, int>)> _load = _fetch();
  _Filter _filter = _Filter.all;

  Future<(List<StaffToday>, Map<String, int>)> _fetch() async {
    final today = (await widget.repo.today()).data ?? const <StaffToday>[];
    return (today, {for (final t in today) t.staff.id: (await widget.repo.daysThisMonth(t.staff.id)).data ?? 0});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    return FutureBuilder<(List<StaffToday>, Map<String, int>)>(
      future: _load,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final all = data?.$1 ?? const <StaffToday>[];
        final inNow = all.where((t) => t.onShift && t.isIn).toList();
        final notIn = all.where((t) => t.onShift && !t.isIn).toList();
        final shown = switch (_filter) {
          _Filter.all => all,
          _Filter.inNow => inNow,
          _Filter.notIn => notIn,
        };
        return AdaptiveScaffold(
          title: l10n.workers,
          subtitle: l10n.peopleCount(all.length),
          actions: [
            if (widget.onScan != null)
              BarAction(icon: Symbols.contactless_rounded, tooltip: l10n.scanStationTitle, onPressed: widget.onScan),
            if (widget.canManageStaff && widget.onPrintAll != null)
              BarAction(
                icon: Symbols.print_rounded,
                tooltip: l10n.printAllCards,
                onPressed: () => unawaited(widget.onPrintAll!()),
              ),
          ],
          floatingActionButton: !widget.canManageStaff
              ? null
              : FarmTapFab(
                  label: l10n.addWorker,
                  icon: Symbols.person_add_rounded,
                  onPressed: () async {
                    await widget.onAdd();
                    if (mounted) {
                      setState(() {
                        _load = _fetch();
                      });
                    }
                  },
                ),
          body: data == null
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilterChips<_Filter>(
                      options: [
                        FilterOption(value: _Filter.all, label: l10n.filterAll, count: all.length),
                        FilterOption(value: _Filter.inNow, label: l10n.filterInNow, count: inNow.length),
                        FilterOption(value: _Filter.notIn, label: l10n.filterNotIn, count: notIn.length),
                      ],
                      selected: _filter,
                      onSelected: (v) => setState(() => _filter = v),
                    ),
                    context.space.gapMd,
                    // Entry to K04-K06 (not in the mockups; see PROGRESS gaps).
                    Wrap(
                      spacing: context.space.sm,
                      runSpacing: context.space.sm,
                      children: [
                        for (final (t, icon, label) in [
                          (WorkersTarget.attendance, Symbols.schedule_rounded, l10n.attendance),
                          (WorkersTarget.tasks, Symbols.checklist_rounded, l10n.tasks),
                          (WorkersTarget.wages, Symbols.payments_rounded, l10n.wagesShort),
                        ])
                          FarmTapChip(label: label, icon: icon, selected: false, onTap: () => widget.onOpen(t)),
                        if (widget.onScan != null)
                          FarmTapChip(
                            label: l10n.scanStationTitle,
                            icon: Symbols.contactless_rounded,
                            selected: false,
                            onTap: widget.onScan,
                          ),
                        if (widget.canManageStaff && widget.onCards != null)
                          FarmTapChip(
                            label: l10n.cardRegisterTitle,
                            icon: Symbols.style_rounded,
                            selected: false,
                            onTap: widget.onCards,
                          ),
                      ],
                    ),
                    context.space.gapLg,
                    RecordCollection<StaffToday>(
                      items: shown,
                      tileBuilder: (context, t) => RecordTile(
                        leading: PersonAvatar(
                          name: t.staff.name,
                          photo: t.staff.photo,
                          tone: _avatarTone(t.staff, [for (final x in all) x.staff]),
                        ),
                        title: t.staff.name,
                        subtitle: staffTitle(l10n, t.staff),
                        badge: _cardBadge(l10n, t.staff),
                        trailingValue: t.record == null ? null : (t.isIn ? l10n.inLabel : l10n.outLabel),
                        trailingSub: t.record == null ? null : f.clock24(t.isIn ? t.record!.inAt : t.record!.outAt!),
                        onTap: () => widget.onStaff(t.staff.id),
                      ),
                      onTap: (t) => widget.onStaff(t.staff.id),
                      columns: [
                        RecordColumn(
                          label: l10n.colName,
                          flex: 3,
                          sortKey: (t) => t.staff.name,
                          cell: (c, t) => Row(
                            children: [
                              PersonAvatar(
                                name: t.staff.name,
                                size: c.sizes.avatarSm,
                                tone: _avatarTone(t.staff, [for (final x in all) x.staff]),
                              ),
                              c.space.gapMd,
                              Flexible(child: Text(t.staff.name, style: c.text.titleSmall)),
                            ],
                          ),
                        ),
                        RecordColumn(label: l10n.colRole, flex: 2, cell: (c, t) => Text(staffTitle(l10n, t.staff))),
                        RecordColumn(
                          label: l10n.colCard,
                          cell: (c, t) =>
                              Align(alignment: AlignmentDirectional.centerStart, child: _cardBadge(l10n, t.staff)),
                        ),
                        RecordColumn(label: l10n.colToday, cell: (c, t) => Text(_todayText(l10n, f, t))),
                        RecordColumn(
                          label: l10n.colThisMonth,
                          sortKey: (t) => data.$2[t.staff.id] ?? 0,
                          cell: (c, t) => Text(l10n.daysCount(data.$2[t.staff.id] ?? 0)),
                        ),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------- K02

/// "Card 0142 belongs to Amos. Revoke it first." and the other refusals
/// (decision 0016 §1).
String cardIssueMessage(AppLocalizations l10n, String card, Failure f) {
  final m = f.message;
  if (m.startsWith(CardIssueError.taken)) return l10n.cardTaken(card, m.split(':').last);
  return switch (m) {
    CardIssueError.lost => l10n.cardLostCannotReuse(card),
    CardIssueError.hasCard => l10n.alreadyHasCard,
    CardIssueError.otherFarm => l10n.otherFarmCardBody,
    _ => l10n.cardNotUsable,
  };
}

/// Lost or returned? Resolves to null when cancelled.
Future<CardStatus?> askRevokeCard(BuildContext context, String card, String name) {
  final l10n = AppLocalizations.of(context);
  return showAdaptiveSheet<CardStatus>(
    context,
    builder: (sheet) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(l10n.revokeCardTitle(card), subtitle: l10n.revokeCardBody(name)),
        sheet.space.gapLg,
        FarmTapButton(
          label: l10n.revokeLost,
          icon: Symbols.gpp_bad_rounded,
          kind: ButtonKind.danger,
          onPressed: () => Navigator.of(sheet).pop(CardStatus.lost),
        ),
        sheet.space.gapSm,
        FarmTapButton(
          label: l10n.revokeReturned,
          icon: Symbols.assignment_return_rounded,
          kind: ButtonKind.outlined,
          onPressed: () => Navigator.of(sheet).pop(CardStatus.returned),
        ),
      ],
    ),
  );
}

class StaffDetailPage extends StatefulWidget {
  const new({
    required this.repo,
    required this.directory,
    required this.staffId,
    required this.onAssignCard,
    required this.onEdit,
    super.key,
    this.canManageStaff = true,
    this.onIdCard,
    this.onPhoto,
    this.onResetLogin,
    this.onSetUpLogin,
  });

  /// Owner and managers only (ROADMAP 7.4): edit, reset PIN, cards.
  final bool canManageStaff;

  final WorkersRepository repo;
  final StaffDirectory directory;
  final String staffId;

  /// Pushes the edit form; completes when it closes.
  final Future<void> Function() onEdit;

  /// Opens K03; completes when it closes.
  final Future<void> Function() onAssignCard;

  /// Opens the ID card (print / download).
  final Future<void> Function()? onIdCard;

  /// Take or change the worker's photo; completes when saved.
  final Future<void> Function(StaffMember staff)? onPhoto;

  /// After a PIN reset: renew the phone sign-in with the temporary PIN.
  final Future<void> Function(StaffMember staff, String pin)? onResetLogin;

  /// Phone sign-in was not made (offline when added): make it now.
  final Future<void> Function(StaffMember staff)? onSetUpLogin;

  @override
  State<StaffDetailPage> createState() => _StaffDetailPageState();
}

class _StaffDetail {
  const new({
    required this.staff,
    required this.days,
    required this.wage,
    required this.milk,
    required this.cards,
    required this.attendance,
  });

  final StaffMember? staff;
  final int days;
  final WageLine? wage;
  final int milk;
  final List<IdCardRecord> cards;
  final List<AttendanceRecord> attendance;
}

class _StaffDetailPageState extends State<StaffDetailPage> {
  late Future<_StaffDetail> _load = _fetch();

  Future<_StaffDetail> _fetch() async {
    final id = widget.staffId;
    return _StaffDetail(
      staff: (await widget.directory.staffById(id)).data,
      days: (await widget.repo.daysThisMonth(id)).data ?? 0,
      wage: (await widget.repo.wages()).data?.lines.where((l) => l.staff.id == id).firstOrNull,
      milk: (await widget.repo.milkRecordsThisMonth(id)).data ?? 0,
      cards: (await widget.directory.cardHistory(id)).data ?? const [],
      attendance: (await widget.repo.attendanceThisMonth(id)).data ?? const [],
    );
  }

  Future<void> _resetPin(StaffMember s) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showFarmTapDialog(
      context,
      icon: Symbols.pin_rounded,
      title: l10n.resetPinTitle(s.greetingName),
      message: l10n.resetPinBodyTemp(s.greetingName),
      primaryLabel: l10n.choosePin,
      secondaryLabel: l10n.cancel,
    );
    if (!ok || !mounted) return;
    final temp = await showAdaptiveSheet<String>(
      context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetTitle(l10n.temporaryPinTitle, subtitle: l10n.temporaryPinBody(s.greetingName), center: true),
          sheet.space.gapXl,
          PinPad(
            onCompleted: (p) async {
              Navigator.of(sheet).pop(p);
              return true;
            },
          ),
        ],
      ),
    );
    if (temp == null || !mounted) return;
    await widget.directory.resetPin(s.id, temp);
    await widget.onResetLogin?.call(s, temp);
    if (mounted) FarmTapToast.show(context, message: l10n.resetPinDoneTemp(s.greetingName));
    _reload();
  }

  Future<void> _revoke(StaffMember s) async {
    final l10n = AppLocalizations.of(context);
    final why = await askRevokeCard(context, s.cardNumber!, s.greetingName);
    if (why == null || !mounted) return;
    await widget.directory.revokeCard(s.id, why);
    if (mounted) FarmTapToast.show(context, message: l10n.cardRevokedToast(s.cardNumber!));
    _reload();
  }

  void _showAccess(StaffMember s) {
    final l10n = AppLocalizations.of(context);
    final sections = StaffPermissions.sections(s.role).map((x) => sectionName(l10n, x)).join(', ');
    unawaited(
      showFarmTapDialog(
        context,
        icon: Symbols.lock_open_rounded,
        title: l10n.whatCanDo(s.greetingName),
        message: '${staffCanDo(l10n, s.role)}\n\n${l10n.opensSections(sections)}',
        primaryLabel: l10n.close,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    return AdaptiveScaffold(
      title: l10n.workerTitle,
      actions: [
        if (widget.canManageStaff)
          BarAction(
            icon: Symbols.edit_rounded,
            tooltip: l10n.editWorker,
            onPressed: () async {
              await widget.onEdit();
              if (mounted) _reload();
            },
          ),
      ],
      body: FutureBuilder<_StaffDetail>(
        future: _load,
        builder: (context, snapshot) {
          final d = snapshot.data;
          final s = d?.staff;
          if (d == null || s == null) return const FarmTapPageLoader();
          final wage = d.wage;
          final photo = widget.onPhoto;
          final idCard = widget.onIdCard;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FarmTapCard(
                child: Row(
                  children: [
                    PersonAvatar(
                      name: s.name,
                      photo: s.photo,
                      size: context.sizes.avatarHero,
                      onTap: photo == null || !widget.canManageStaff
                          ? null
                          : () async {
                              await photo(s);
                              if (mounted) _reload();
                            },
                    ),
                    context.space.gapLg,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name, style: context.text.headlineSmall),
                          context.space.gapXs,
                          Text(
                            s.since == null
                                ? staffTitle(l10n, s)
                                : l10n.roleSince(staffTitle(l10n, s), '${f.monthShort(s.since!)} ${s.since!.year}'),
                            style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                          ),
                          if ((s.department ?? '').isNotEmpty)
                            Text(
                              s.department!,
                              style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                            ),
                          context.space.gapSm,
                          Wrap(
                            spacing: context.space.xs,
                            runSpacing: context.space.xs,
                            children: [
                              if (s.hasCard)
                                StatusBadge(
                                  label: l10n.cardNumberBadge(s.cardNumber!),
                                  tone: FarmTapTone.success,
                                  icon: Symbols.contactless_rounded,
                                )
                              else
                                StatusBadge(label: l10n.noCardBadge, tone: FarmTapTone.gold),
                              if (s.login == StaffLoginStatus.active || s.login == StaffLoginStatus.mustChangePin)
                                StatusBadge(
                                  label: l10n.phoneSignInBadge,
                                  tone: FarmTapTone.info,
                                  icon: Symbols.smartphone_rounded,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (photo != null && widget.canManageStaff && !s.hasPhoto) ...[
                context.space.gapSm,
                Center(
                  child: TextAction(
                    label: l10n.addPhoto,
                    icon: Symbols.photo_camera_rounded,
                    onPressed: () async {
                      await photo(s);
                      if (mounted) _reload();
                    },
                  ),
                ),
              ],
              context.space.gapLg,
              MetricStrip(
                children: [
                  MetricCard(icon: Symbols.schedule_rounded, label: l10n.daysThisMonth, value: f.count(d.days)),
                  MetricCard(
                    icon: Symbols.water_drop_rounded,
                    label: l10n.milkRecords,
                    value: f.count(d.milk),
                    tone: FarmTapTone.info,
                  ),
                  if (wage != null)
                    MetricCard(
                      icon: Symbols.account_balance_wallet_rounded,
                      label: l10n.balanceOwed,
                      value: _moneyShort(f, wage.toPay),
                      tone: FarmTapTone.gold,
                    ),
                ],
              ),
              context.space.gapLg,
              ListCard(
                children: [
                  if (idCard != null)
                    RecordTile(
                      leading: IconBubble(icon: Symbols.badge_rounded, size: context.sizes.bubbleMd),
                      title: l10n.idCardTitle,
                      subtitle: l10n.idCardRowBody,
                      onTap: () async {
                        await idCard();
                        if (mounted) _reload();
                      },
                    ),
                  if (widget.canManageStaff) ...[
                    RecordTile(
                      leading: IconBubble(
                        icon: Symbols.contactless_rounded,
                        tone: FarmTapTone.gold,
                        size: context.sizes.bubbleMd,
                      ),
                      title: s.hasCard ? l10n.replaceLostCard : l10n.assignCardRow,
                      onTap: () async {
                        await widget.onAssignCard();
                        if (mounted) _reload();
                      },
                    ),
                    if (s.hasCard)
                      RecordTile(
                        leading: IconBubble(
                          icon: Symbols.credit_card_off_rounded,
                          tone: FarmTapTone.danger,
                          size: context.sizes.bubbleMd,
                        ),
                        title: l10n.revokeCardRow,
                        subtitle: l10n.revokeCardRowBody,
                        onTap: () => unawaited(_revoke(s)),
                      ),
                    RecordTile(
                      leading: IconBubble(
                        icon: Symbols.pin_rounded,
                        tone: FarmTapTone.neutral,
                        size: context.sizes.bubbleMd,
                      ),
                      title: l10n.resetPin,
                      subtitle: l10n.pinWhatFor,
                      onTap: () => unawaited(_resetPin(s)),
                    ),
                    if (s.login == StaffLoginStatus.failed && widget.onSetUpLogin != null)
                      RecordTile(
                        leading: IconBubble(
                          icon: Symbols.smartphone_rounded,
                          tone: FarmTapTone.warning,
                          size: context.sizes.bubbleMd,
                        ),
                        title: l10n.setUpPhoneSignIn,
                        subtitle: l10n.setUpPhoneSignInBody,
                        onTap: () async {
                          await widget.onSetUpLogin!(s);
                          if (mounted) _reload();
                        },
                      ),
                  ],
                  RecordTile(
                    leading: IconBubble(
                      icon: Symbols.lock_rounded,
                      tone: FarmTapTone.info,
                      size: context.sizes.bubbleMd,
                    ),
                    title: l10n.whatCanDo(s.greetingName),
                    subtitle: staffCanDo(l10n, s.role),
                    onTap: () => _showAccess(s),
                  ),
                ],
              ),
              context.space.gapLg,
              ListCard(
                title: l10n.activityLog,
                children: [
                  if (d.attendance.isEmpty) RecordTile(title: l10n.statusNotInToday, showChevron: false),
                  for (final a in d.attendance.take(8))
                    RecordTile(
                      leading: IconBubble(icon: Symbols.schedule_rounded, size: context.sizes.bubbleMd),
                      title: f.day(a.inAt),
                      trailingValue: '${f.clock24(a.inAt)} – ${a.outAt == null ? '…' : f.clock24(a.outAt!)}',
                      showChevron: false,
                    ),
                ],
              ),
              if (d.cards.isNotEmpty) ...[
                context.space.gapLg,
                ListCard(
                  title: l10n.cardHistoryTitle,
                  children: [for (final c in d.cards) CardHistoryTile(card: c)],
                ),
              ],
              if ((s.phone ?? '').isNotEmpty ||
                  (s.emergencyPhone ?? '').isNotEmpty ||
                  (s.nationalId ?? '').isNotEmpty ||
                  (s.village ?? '').isNotEmpty) ...[
                context.space.gapLg,
                ListCard(
                  title: l10n.detailsTitle,
                  children: [
                    if ((s.phone ?? '').isNotEmpty)
                      RecordTile(title: l10n.phoneLabel, trailingValue: '0${s.phone}', showChevron: false),
                    if ((s.emergencyPhone ?? '').isNotEmpty || (s.emergencyName ?? '').isNotEmpty)
                      RecordTile(
                        title: l10n.emergencyLabel,
                        subtitle: s.emergencyName,
                        trailingValue: s.emergencyPhone == null ? null : '0${s.emergencyPhone}',
                        showChevron: false,
                      ),
                    if ((s.village ?? '').isNotEmpty)
                      RecordTile(title: l10n.villageLabel, trailingValue: s.village, showChevron: false),
                    if ((s.nationalId ?? '').isNotEmpty)
                      RecordTile(title: l10n.ninLabel, trailingValue: s.nationalId, showChevron: false),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _reload() => setState(() {
    _load = _fetch();
  });
}

/// One card in a person's card history (active, returned, lost).
class CardHistoryTile extends StatelessWidget {
  const new({required this.card, super.key});

  final IdCardRecord card;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    final (label, tone) = switch (card.status) {
      CardStatus.active => (l10n.cardActive, FarmTapTone.success),
      CardStatus.returned => (l10n.cardReturned, FarmTapTone.neutral),
      CardStatus.lost => (l10n.cardLost, FarmTapTone.danger),
    };
    return RecordTile(
      leading: IconBubble(icon: Symbols.contactless_rounded, tone: tone, size: context.sizes.bubbleMd),
      title: l10n.cardNumberBadge(card.number),
      subtitle: [
        if (card.issuedAt != null) l10n.issuedOn(f.day(card.issuedAt!)),
        if (card.endedAt != null) l10n.endedOn(f.day(card.endedAt!)),
      ].join(' · '),
      badge: StatusBadge(label: label, tone: tone),
      showChevron: false,
    );
  }
}

/// A section's name as the navigation shows it.
String sectionName(AppLocalizations l10n, AppSection s) => switch (s) {
  AppSection.home => l10n.home,
  AppSection.herd => l10n.herd,
  AppSection.milk => l10n.milk,
  AppSection.health => l10n.health,
  AppSection.feeding => l10n.feeding,
  AppSection.breeding => l10n.breeding,
  AppSection.collect => l10n.collect,
  AppSection.farmers => l10n.farmers,
  AppSection.pay => l10n.pay,
  AppSection.workers => l10n.workers,
  AppSection.money => l10n.money,
  AppSection.reports => l10n.reports,
  AppSection.settings => l10n.settings,
  AppSection.me => l10n.myPageTitle,
};

// ---------------------------------------------------------------- K03

class AssignCardPage extends StatefulWidget {
  const new({
    required this.directory,
    required this.staffId,
    required this.farmName,
    required this.onDone,
    super.key,
    this.nfcAvailable,
    this.showSimulate = false,
  });

  final StaffDirectory directory;
  final String staffId;
  final String farmName;
  final VoidCallback onDone;

  /// Whether the phone reads NFC; the simulator has none.
  final Future<bool> Function()? nfcAvailable;
  final bool showSimulate;

  @override
  State<AssignCardPage> createState() => _AssignCardPageState();
}

class _AssignCardPageState extends State<AssignCardPage> {
  late final Future<(StaffMember?, String?)> _load = _fetch();
  bool _busy = false;

  Future<(StaffMember?, String?)> _fetch() async {
    final s = (await widget.directory.staffById(widget.staffId)).data;
    return (s, (await widget.directory.nextBlankCard()).data);
  }

  /// [card] null: a printed QR card with a new number (no NFC chip).
  Future<void> _assign(StaffMember s, String? card) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    // A worker who has a card is here to replace a lost one.
    if (s.hasCard) {
      final ok = await showFarmTapDialog(
        context,
        icon: Symbols.contactless_rounded,
        tone: FarmTapTone.gold,
        title: l10n.replaceCardTitle(s.cardNumber!),
        message: l10n.replaceCardBody(s.greetingName, s.cardNumber!),
        primaryLabel: l10n.replaceLostCard,
        secondaryLabel: l10n.cancel,
      );
      if (!ok || !mounted) return;
    }
    _busy = true;
    final result = await widget.directory.assignCard(s.id, card, replace: s.hasCard);
    _busy = false;
    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        unawaited(HapticFeedback.mediumImpact());
        FarmTapToast.show(context, message: l10n.cardAssigned(data.cardNumber ?? '', s.greetingName));
        widget.onDone();
      case FailureResult(failure: final Failure f):
        // A dialog, not a toast: it is still there after Apple's sheet closes.
        await showFarmTapDialog(
          context,
          icon: Symbols.gpp_bad_rounded,
          tone: FarmTapTone.danger,
          title: l10n.cardNotGivenTitle,
          message: cardIssueMessage(l10n, card ?? '', f),
          primaryLabel: l10n.close,
        );
    }
  }

  Future<void> _type(StaffMember s) async {
    final card = await showTypeCardNumber(context);
    if (card != null && mounted) await _assign(s, card);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AdaptiveScaffold(
      title: l10n.assignCard,
      showNavigation: false,
      body: FutureBuilder<(StaffMember?, String?)>(
        future: _load,
        builder: (context, snapshot) {
          final (s, blank) = snapshot.data ?? (null, null);
          if (s == null) return const FarmTapPageLoader();
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.sizes.keypadMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CardTapListener(
                    onCard: (card) => _assign(s, card),
                    prompt: l10n.tapNewCardNow,
                    child: const SizedBox.shrink(),
                  ),
                  PrintedCardPreview(
                    name: s.name,
                    cardNumber: blank == null ? '' : l10n.cardNumberBadge(blank),
                    subtitle: '${staffTitle(l10n, s)} · ${widget.farmName}',
                  ),
                  context.space.gapXxl,
                  FarmTapAnimationView(
                    animation: FarmTapAnimations.tapCard,
                    size: context.sizes.animationSm,
                    semanticLabel: l10n.tapNewCardNow,
                  ),
                  context.space.gapXl,
                  Text(l10n.tapNewCardNow, textAlign: TextAlign.center, style: context.text.titleLarge),
                  context.space.gapXs,
                  Text(
                    l10n.holdBlankCard(s.greetingName),
                    textAlign: TextAlign.center,
                    style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                  context.space.gapLg,
                  if (ScanCardButton.needed) ...[ScanCardButton(label: l10n.scanCard), context.space.gapMd],
                  Center(
                    child: TextAction(
                      label: l10n.typeCardNumber,
                      icon: Symbols.dialpad_rounded,
                      onPressed: () => _type(s),
                    ),
                  ),
                  Center(
                    child: TextAction(
                      label: l10n.printedCardNoChip,
                      icon: Symbols.qr_code_2_rounded,
                      onPressed: () => _assign(s, null),
                    ),
                  ),
                  if (widget.showSimulate && blank != null)
                    Center(
                      child: TextAction(label: l10n.simulateTap, small: true, onPressed: () => _assign(s, blank)),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------- K04

class AttendancePage extends StatefulWidget {
  const new({
    required this.repo,
    required this.directory,
    super.key,
    this.now,
    this.showSimulate = false,
    this.farmerByCard,
    this.onGiveCard,
    this.onScanStation,
  });

  /// Opens the scan station in clock-in mode: each card shows the person
  /// with their photo and the next card is read by itself (decision 0016).
  final VoidCallback? onScanStation;

  final WorkersRepository repo;

  /// Checks the manager PIN for typed card numbers (DAIRY-WRK-01).
  final StaffDirectory directory;

  /// The farmer whose card this is, if any (a farmer card tapped here).
  final Future<String?> Function(String card)? farmerByCard;

  /// A new card: go and give it to a worker (Workers list).
  final VoidCallback? onGiveCard;
  final DateTime? now;
  final bool showSimulate;

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  late Future<List<StaffToday>> _load = _fetch();

  Future<List<StaffToday>> _fetch() async => (await widget.repo.today()).data ?? const [];

  Future<void> _clock(String card) async {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    final t = (await widget.repo.clockByCard(card)).data;
    if (!mounted) return;
    if (t == null) {
      // A dialog, not a toast: it is still there after the phone's scan
      // sheet closes.
      final farmer = await widget.farmerByCard?.call(card);
      if (!mounted) return;
      final give = widget.onGiveCard;
      final ok = await showFarmTapDialog(
        context,
        icon: Symbols.contactless_rounded,
        tone: FarmTapTone.gold,
        title: farmer == null ? l10n.newCardTitle(card) : l10n.noOneHasCard(card),
        message: farmer == null ? l10n.newCardOnAttendance : l10n.farmerCardOnAttendance(farmer),
        primaryLabel: farmer == null && give != null ? l10n.giveCardToWorker : l10n.close,
        secondaryLabel: farmer == null && give != null ? l10n.cancel : null,
      );
      if (ok && farmer == null) give?.call();
      return;
    }
    unawaited(HapticFeedback.mediumImpact());
    final r = t.record!;
    FarmTapToast.show(
      context,
      message: t.isIn
          ? l10n.clockedInToast(t.staff.greetingName, f.time(r.inAt))
          : l10n.clockedOutToast(t.staff.greetingName, f.time(r.outAt!)),
    );
    setState(() {
      _load = _fetch();
    });
  }

  /// No NFC on this phone (simulator): type the number printed on the card.
  /// A typed number could be anyone's, so a manager confirms it (P04);
  /// a card tap needs no PIN.
  Future<void> _tapCard() async {
    final card = await showTypeCardNumber(context);
    if (card == null || !mounted) return;
    final ok = await showManagerPin(
      context,
      message: AppLocalizations.of(context).typedCardNeedsManager(card),
      verify: (pin) async => (await widget.directory.verifyManagerPin(pin)).data ?? false,
    );
    if (ok && mounted) await _clock(card);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    final now = widget.now ?? context.clock.now();
    return AdaptiveScaffold(
      title: l10n.attendance,
      subtitle: f.longDay(now),
      body: FutureBuilder<List<StaffToday>>(
        future: _load,
        builder: (context, snapshot) {
          final all = snapshot.data;
          if (all == null) return const FarmTapPageLoader();
          final shift = all.where((t) => t.onShift).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // A real card tap needs no manager PIN.
              CardTapListener(onCard: _clock, prompt: l10n.tapToClock, child: const SizedBox.shrink()),
              HeroCard(
                label: '',
                value: l10n.ofInCount(shift.where((t) => t.isIn).length, shift.length),
                sub: l10n.tapToClock,
                animation: FarmTapAnimations.attendance,
                animationLeading: true,
              ),
              context.space.gapLg,
              // iPhone: open the scan sheet; phones without NFC: type the
              // number (with a manager PIN).
              FarmTapButton(
                label: l10n.clockInOut,
                icon: Symbols.contactless_rounded,
                large: true,
                onPressed: () async {
                  if (widget.onScanStation case final open?) {
                    open();
                    return;
                  }
                  if (ScanCardButton.needed && await CardReader.instance.available()) {
                    CardTapListener.scanAgain();
                  } else {
                    await _tapCard();
                  }
                },
              ),
              if (ScanCardButton.needed)
                Center(
                  child: TextAction(label: l10n.typeCardNumberLink, icon: Symbols.dialpad_rounded, onPressed: _tapCard),
                ),
              if (widget.showSimulate)
                Center(
                  child: TextAction(label: l10n.simulateTap, small: true, onPressed: () => _clock('0168')),
                ),
              context.space.gapLg,
              ListCard(
                children: [
                  for (final t in shift)
                    RecordTile(
                      leading: PersonAvatar(
                        name: t.staff.name,
                        photo: t.staff.photo,
                        tone: _avatarTone(t.staff, [for (final x in all) x.staff]),
                      ),
                      title: t.staff.name,
                      subtitle: staffTitle(l10n, t.staff),
                      trailingValue: _todayText(l10n, f, t),
                      showChevron: false,
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

// ---------------------------------------------------------------- K05

enum _TaskTab { today, week, done }

class TasksPage extends StatefulWidget {
  const new({required this.repo, required this.directory, super.key, this.now});

  final WorkersRepository repo;
  final StaffDirectory directory;
  final DateTime? now;

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  late Future<(List<FarmTask>, List<StaffMember>)> _load = _fetch();
  _TaskTab _tab = _TaskTab.today;

  Future<(List<FarmTask>, List<StaffMember>)> _fetch() async => (
    (await widget.repo.tasks()).data ?? const <FarmTask>[],
    (await widget.directory.staff()).data ?? const <StaffMember>[],
  );

  void _reload() => setState(() {
    _load = _fetch();
  });

  Future<void> _toggle(FarmTask t) async {
    unawaited(HapticFeedback.selectionClick());
    await widget.repo.setTaskDone(t.id, done: !t.done);
    if (mounted) _reload();
  }

  Future<void> _add(List<StaffMember> staff) async {
    final saved = await showAdaptiveSheet<FarmTask>(
      context,
      builder: (_) => _NewTaskSheet(repo: widget.repo, staff: staff, now: widget.now ?? context.clock.now()),
    );
    if (saved == null || !mounted) return;
    FarmTapToast.show(context, message: AppLocalizations.of(context).taskSaved);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    final now = widget.now ?? context.clock.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final weekEnd = today.add(const Duration(days: 7));
    return FutureBuilder<(List<FarmTask>, List<StaffMember>)>(
      future: _load,
      builder: (context, snapshot) {
        final (tasks, staff) = snapshot.data ?? (const <FarmTask>[], const <StaffMember>[]);
        String who(String id) => staff.where((s) => s.id == id).firstOrNull?.name ?? '';
        final shown = switch (_tab) {
          // Today: due today, or done today (stays ticked until tomorrow).
          _TaskTab.today => tasks.where((t) => t.due.isBefore(tomorrow) && (!t.done || !t.doneAt!.isBefore(today))),
          _TaskTab.week => tasks.where((t) => !t.done && !t.due.isBefore(tomorrow) && t.due.isBefore(weekEnd)),
          _TaskTab.done => tasks.where((t) => t.done),
        }.toList();
        return AdaptiveScaffold(
          title: l10n.tasks,
          floatingActionButton: FarmTapFab(
            label: l10n.newTask,
            icon: Symbols.add_rounded,
            onPressed: () => _add(staff),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedTabs<_TaskTab>(
                options: [
                  TabOption(value: _TaskTab.today, label: l10n.tabToday),
                  TabOption(value: _TaskTab.week, label: l10n.tabThisWeek),
                  TabOption(value: _TaskTab.done, label: l10n.tabDone),
                ],
                selected: _tab,
                onChanged: (t) => setState(() => _tab = t),
              ),
              context.space.gapLg,
              if (shown.isEmpty)
                EmptyState(title: l10n.noTasks, animation: FarmTapAnimations.cowGrazing)
              else
                ListCard(
                  children: [
                    for (final t in shown)
                      RecordTile(
                        leading: Checkbox(value: t.done, onChanged: (_) => _toggle(t)),
                        title: t.title,
                        subtitle: '${who(t.staffId)} · ${t.when}',
                        badge: t.done
                            ? StatusBadge(label: l10n.doneAt(f.clock24(t.doneAt!)), tone: FarmTapTone.success)
                            : t.overdue(now)
                            ? StatusBadge(label: l10n.overdueBadge, tone: FarmTapTone.danger)
                            : t.photoNeeded
                            ? StatusBadge(
                                label: l10n.photoNeeded,
                                tone: FarmTapTone.info,
                                icon: Symbols.photo_camera_rounded,
                              )
                            : null,
                        showChevron: false,
                        onTap: () => _toggle(t),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _NewTaskSheet extends StatefulWidget {
  const new({required this.repo, required this.staff, required this.now});

  final WorkersRepository repo;
  final List<StaffMember> staff;
  final DateTime now;

  @override
  State<_NewTaskSheet> createState() => _NewTaskSheetState();
}

class _NewTaskSheetState extends State<_NewTaskSheet> {
  final _title = TextEditingController();
  final _when = TextEditingController();
  StaffMember? _who;

  @override
  void dispose() {
    _title.dispose();
    _when.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final today = DateTime(widget.now.year, widget.now.month, widget.now.day);
    final t = (await widget.repo.addTask(
      title: _title.text.trim(),
      staffId: _who!.id,
      due: today.add(const Duration(hours: 18)),
      when: _when.text.trim(),
    )).data;
    if (t != null && mounted) Navigator.of(context).pop(t);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DiscardGuard(
      dirty: _title.text.trim().isNotEmpty || _who != null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetTitle(l10n.newTask),
          context.space.gapLg,
          FarmTapTextField(
            label: l10n.taskTitle,
            icon: Symbols.checklist_rounded,
            controller: _title,
            onChanged: (_) => setState(() {}),
          ),
          context.space.gapLg,
          FarmTapSelectField<StaffMember>(
            label: l10n.whoDoesIt,
            icon: Symbols.person_rounded,
            options: widget.staff,
            value: _who,
            labelOf: (s) => s.name,
            onChanged: (s) => setState(() => _who = s),
          ),
          context.space.gapLg,
          FarmTapTextField(label: l10n.whenLabel, icon: Symbols.schedule_rounded, controller: _when),
          context.space.gapXl,
          FarmTapButton(
            label: l10n.saveTask,
            icon: Symbols.check_rounded,
            onPressed: _title.text.trim().isEmpty || _who == null ? null : _save,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- K06

class WagesPage extends StatefulWidget {
  const new({required this.repo, super.key});

  final WorkersRepository repo;

  @override
  State<WagesPage> createState() => _WagesPageState();
}

class _WagesPageState extends State<WagesPage> {
  late Future<WagesSummary?> _load = _fetch();

  Future<WagesSummary?> _fetch() async => (await widget.repo.wages()).data;

  void _reload() => setState(() {
    _load = _fetch();
  });

  /// Money: read back, then record the payment (a wage expense).
  Future<void> _pay(StaffMember s, PayKind kind, int amount) async {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    final ok = await showReadBack(
      context,
      leading: PersonAvatar(name: s.name),
      subject: '${s.name} · ${kind == PayKind.advance ? l10n.advanceKind : l10n.wageKind}',
      valueText: f.money(amount),
    );
    if (!ok || !mounted) return;
    await widget.repo.pay(s.id, kind: kind, amount: amount);
    if (!mounted) return;
    FarmTapToast.show(
      context,
      message: kind == PayKind.advance
          ? l10n.advanceSaved(f.money(amount), s.greetingName)
          : l10n.wagePaid(s.greetingName, f.money(amount)),
    );
    _reload();
  }

  Future<void> _advance(List<WageLine> lines) async {
    final picked = await showAdaptiveSheet<(StaffMember, int)>(context, builder: (_) => _AdvanceSheet(lines: lines));
    if (picked != null && mounted) await _pay(picked.$1, PayKind.advance, picked.$2);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    return FutureBuilder<WagesSummary?>(
      future: _load,
      builder: (context, snapshot) {
        final w = snapshot.data;
        return AdaptiveScaffold(
          title: l10n.wagesAdvances,
          subtitle: w == null ? null : f.monthLong(w.month),
          body: w == null
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MetricStrip(
                      children: [
                        MetricCard(
                          icon: Symbols.payments_rounded,
                          label: l10n.wagesThisMonth,
                          value: _moneyShort(f, w.wages),
                        ),
                        MetricCard(
                          icon: Symbols.savings_rounded,
                          label: l10n.advancesGiven,
                          value: _moneyShort(f, w.advances),
                          tone: FarmTapTone.gold,
                        ),
                      ],
                    ),
                    context.space.gapLg,
                    ListCard(
                      children: [
                        for (final line in w.lines)
                          RecordTile(
                            leading: PersonAvatar(
                              name: line.staff.name,
                              tone: _avatarTone(line.staff, [for (final l in w.lines) l.staff]),
                            ),
                            title: line.staff.name,
                            subtitle: l10n.wageLine(f.money(line.wage), f.count(line.advances)),
                            badge: line.toPay <= 0
                                ? StatusBadge(label: l10n.paidBadge, tone: FarmTapTone.success)
                                : null,
                            trailingValue: line.toPay > 0 ? f.count(line.toPay) : null,
                            trailingSub: line.toPay > 0 ? l10n.toPayLabel : null,
                            onTap: line.toPay > 0 ? () => _pay(line.staff, PayKind.wage, line.toPay) : null,
                          ),
                      ],
                    ),
                    context.space.gapLg,
                    FarmTapButton(
                      label: l10n.recordAdvance,
                      icon: Symbols.add_rounded,
                      kind: ButtonKind.outlined,
                      onPressed: () => _advance(w.lines),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _AdvanceSheet extends StatefulWidget {
  const new({required this.lines});

  final List<WageLine> lines;

  @override
  State<_AdvanceSheet> createState() => _AdvanceSheetState();
}

class _AdvanceSheetState extends State<_AdvanceSheet> {
  StaffMember? _who;
  final _amount = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  int get _value => int.tryParse(_amount.text.replaceAll(',', '')) ?? 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DiscardGuard(
      dirty: _who != null || _amount.text.isNotEmpty,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetTitle(l10n.recordAdvance),
          context.space.gapLg,
          FarmTapSelectField<StaffMember>(
            label: l10n.whoDoesIt,
            icon: Symbols.person_rounded,
            options: [for (final l in widget.lines) l.staff],
            value: _who,
            labelOf: (s) => s.name,
            onChanged: (s) => setState(() => _who = s),
          ),
          context.space.gapLg,
          FarmTapTextField(
            label: l10n.amountLabel,
            prefixText: 'UGX ',
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9,]'))],
            onChanged: (_) => setState(() {}),
          ),
          context.space.gapXl,
          FarmTapButton(
            label: l10n.recordAdvance,
            icon: Symbols.check_rounded,
            onPressed: _who == null || _value <= 0 ? null : () => Navigator.of(context).pop((_who!, _value)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Add / edit worker

/// K01 "Add worker" and K02 edit: the B09 first-worker form (no Skip). A new
/// worker gets a PIN now and a card later (K03).
class StaffFormPage extends StatefulWidget {
  const new({required this.directory, required this.onSaved, super.key, this.staffId, this.onCreatedWithPhone});

  final StaffDirectory directory;

  /// Makes the worker's phone + PIN sign-in after they are added.
  final Future<void> Function(StaffMember staff, String pin)? onCreatedWithPhone;

  /// Null adds a worker; otherwise edits this one.
  final String? staffId;
  final ValueChanged<StaffMember> onSaved;

  @override
  State<StaffFormPage> createState() => _StaffFormPageState();
}

class _StaffFormPageState extends State<StaffFormPage> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _wage = TextEditingController();
  final _nin = TextEditingController();
  final _village = TextEditingController();
  final _emergencyName = TextEditingController();
  final _emergencyPhone = TextEditingController();
  String _department = '';
  StaffRole _role = StaffRole.herdsman;
  String _job = '';
  String _pin = '';
  String? _nameError;
  String? _pinError;
  StaffMember? _editing;
  bool _edited = false;

  bool get _isEdit => widget.staffId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) unawaited(_loadExisting());
  }

  Future<void> _loadExisting() async {
    final s = ((await widget.directory.staff()).data ?? const <StaffMember>[])
        .where((m) => m.id == widget.staffId)
        .firstOrNull;
    if (s == null || !mounted) return;
    setState(() {
      _editing = s;
      _name.text = s.name;
      _role = s.role;
      _job = s.title ?? '';
      _phone.text = s.phone ?? '';
      _wage.text = s.monthlyWage?.toString() ?? '';
      _department = s.department ?? '';
      _nin.text = s.nationalId ?? '';
      _village.text = s.village ?? '';
      _emergencyName.text = s.emergencyName ?? '';
      _emergencyPhone.text = s.emergencyPhone ?? '';
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _wage.dispose();
    _nin.dispose();
    _village.dispose();
    _emergencyName.dispose();
    _emergencyPhone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _nameError = _name.text.trim().isEmpty ? l10n.nameRequired : null;
      _pinError = _isEdit || _pin.length == 4 ? null : l10n.pinRequired;
    });
    if (_nameError != null || _pinError != null) return;
    final title = _job.trim().isEmpty ? null : _job.trim();
    final phone = _phone.text.trim().isEmpty ? null : _phone.text.trim();
    final wage = int.tryParse(_wage.text);
    String? opt(String v) => v.trim().isEmpty ? null : v.trim();
    final saved = _isEdit
        ? (await widget.directory.updateStaff(
            widget.staffId!,
            name: _name.text.trim(),
            role: _role,
            title: title,
            phone: phone,
            monthlyWage: wage,
            department: opt(_department),
            nationalId: opt(_nin.text),
            village: opt(_village.text),
            emergencyName: opt(_emergencyName.text),
            emergencyPhone: opt(_emergencyPhone.text),
          )).data
        : (await widget.directory.addStaff(
            name: _name.text.trim(),
            role: _role,
            pin: _pin,
            title: title,
            phone: phone,
            monthlyWage: wage,
            department: opt(_department),
            nationalId: opt(_nin.text),
            village: opt(_village.text),
            emergencyName: opt(_emergencyName.text),
            emergencyPhone: opt(_emergencyPhone.text),
          )).data;
    if (saved == null || !mounted) return;
    setState(() => _edited = false);
    // A new worker with a phone can sign in on their own phone (decision 0016).
    if (!_isEdit && phone != null) await widget.onCreatedWithPhone?.call(saved, _pin);
    if (!mounted) return;
    FarmTapToast.show(context, message: l10n.workerSaved(saved.name));
    widget.onSaved(saved);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_isEdit && _editing == null) return AdaptiveScaffold(title: l10n.editWorker, body: const SizedBox.shrink());
    return DiscardGuard(
      dirty: _edited,
      child: AdaptiveScaffold(
        title: _isEdit ? l10n.editWorker : l10n.addWorker,
        showNavigation: false,
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: context.sizes.keypadMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StaffFormFields(
                  name: _name,
                  job: _job,
                  onJob: (j) => setState(() {
                    _job = j;
                    _edited = true;
                  }),
                  access: _role,
                  onAccess: (r) => setState(() {
                    _role = r;
                    _edited = true;
                  }),
                  phone: _phone,
                  wage: _wage,
                  onChanged: () => setState(() => _edited = true),
                  pin: _isEdit ? null : _pin,
                  onPin: (p) => setState(() {
                    _pin = p;
                    _edited = true;
                  }),
                  nameError: _nameError,
                  pinError: _pinError,
                  showCardNote: !_isEdit,
                  department: _department,
                  onDepartment: (d) => setState(() {
                    _department = d;
                    _edited = true;
                  }),
                  nationalId: _nin,
                  village: _village,
                  emergencyName: _emergencyName,
                  emergencyPhone: _emergencyPhone,
                ),
                context.space.gapXl,
                FarmTapButton(
                  label: _isEdit ? l10n.saveChanges : l10n.saveWorker,
                  icon: _isEdit ? Symbols.check_rounded : Symbols.person_add_rounded,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
