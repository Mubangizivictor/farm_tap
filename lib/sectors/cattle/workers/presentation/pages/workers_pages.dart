// Workers: K01 staff list, K02 staff detail, K03 assign card, K04
// attendance, K05 tasks, K06 wages & advances. Who is in, days worked and
// balances are calculated from attendance and payment records.
import 'dart:async';

import 'package:farm_tap/core/error/failure.dart';
import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/nfc/card_tap_listener.dart';
import 'package:farm_tap/core/people/domain/staff_directory.dart';
import 'package:farm_tap/core/people/domain/staff_member.dart';
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

String staffRoleLabel(AppLocalizations l10n, StaffRole r) => switch (r) {
  StaffRole.manager => l10n.roleManager,
  StaffRole.herdsman => l10n.roleHerdsman,
  StaffRole.clerk => l10n.roleMilkClerk,
  StaffRole.worker => l10n.roleWorker,
  StaffRole.vet => l10n.roleVet,
};

String _canDo(AppLocalizations l10n, StaffRole r) => switch (r) {
  StaffRole.manager => l10n.canDoManager,
  StaffRole.herdsman => l10n.canDoHerdsman,
  StaffRole.clerk => l10n.canDoClerk,
  StaffRole.worker => l10n.canDoWorker,
  StaffRole.vet => l10n.canDoVet,
};

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

void _comingSoon(BuildContext context) => FarmTapToast.show(context, message: AppLocalizations.of(context).comingSoon);

/// Card reading for K03 and K04: NFC where the phone has it, "Simulate tap"
/// in debug builds, and always "Type card number" (decision 0006).
Future<String?> showTypeCardNumber(BuildContext context, {String? initial}) {
  final l10n = AppLocalizations.of(context);
  var digits = initial ?? '';
  return showAdaptiveSheet<String>(
    context,
    builder: (sheet) => StatefulBuilder(
      builder: (sheet, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetTitle(l10n.typeCardNumber, subtitle: l10n.typeTheCardNumber),
          sheet.space.gapLg,
          KeypadDisplay(text: digits, placeholder: '0000'),
          sheet.space.gapLg,
          BigNumberKeypad(
            onDigit: (d) => setState(() => digits = digits.length < 4 ? '$digits$d' : digits),
            onBackspace: () =>
                setState(() => digits = digits.isEmpty ? digits : digits.substring(0, digits.length - 1)),
          ),
          sheet.space.gapLg,
          FarmTapButton(
            label: l10n.useCard,
            icon: Symbols.check_rounded,
            onPressed: digits.isEmpty ? null : () => Navigator.of(sheet).pop(digits.padLeft(4, '0')),
          ),
        ],
      ),
    ),
  );
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
  });

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
                      ],
                    ),
                    context.space.gapLg,
                    RecordCollection<StaffToday>(
                      items: shown,
                      tileBuilder: (context, t) => RecordTile(
                        leading: PersonAvatar(
                          name: t.staff.name,
                          tone: _avatarTone(t.staff, [for (final x in all) x.staff]),
                        ),
                        title: t.staff.name,
                        subtitle: staffRoleLabel(l10n, t.staff.role),
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
                        RecordColumn(
                          label: l10n.colRole,
                          flex: 2,
                          cell: (c, t) => Text(staffRoleLabel(l10n, t.staff.role)),
                        ),
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

class StaffDetailPage extends StatefulWidget {
  const new({
    required this.repo,
    required this.directory,
    required this.staffId,
    required this.onAssignCard,
    required this.onEdit,
    super.key,
    this.canManageStaff = true,
  });

  /// Owner and managers only (ROADMAP 7.4): edit, reset PIN.
  final bool canManageStaff;

  final WorkersRepository repo;
  final StaffDirectory directory;
  final String staffId;

  /// Pushes the edit form; completes when it closes.
  final Future<void> Function() onEdit;

  /// Opens K03; completes when it closes.
  final Future<void> Function() onAssignCard;

  @override
  State<StaffDetailPage> createState() => _StaffDetailPageState();
}

class _StaffDetailPageState extends State<StaffDetailPage> {
  late Future<(StaffMember?, int, WageLine?, int)> _load = _fetch();

  Future<(StaffMember?, int, WageLine?, int)> _fetch() async {
    final staff = ((await widget.directory.staff()).data ?? const <StaffMember>[])
        .where((s) => s.id == widget.staffId)
        .firstOrNull;
    final days = (await widget.repo.daysThisMonth(widget.staffId)).data ?? 0;
    final wage = (await widget.repo.wages()).data?.lines.where((l) => l.staff.id == widget.staffId).firstOrNull;
    final milk = (await widget.repo.milkRecordsThisMonth(widget.staffId)).data ?? 0;
    return (staff, days, wage, milk);
  }

  Future<void> _resetPin(StaffMember s) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showFarmTapDialog(
      context,
      icon: Symbols.pin_rounded,
      title: l10n.resetPinTitle(s.greetingName),
      message: l10n.resetPinBody,
      primaryLabel: l10n.resetPin,
      secondaryLabel: l10n.cancel,
    );
    if (!ok || !mounted) return;
    await widget.directory.resetPin(s.id);
    if (mounted) FarmTapToast.show(context, message: l10n.resetPinDone(s.greetingName));
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
      body: FutureBuilder<(StaffMember?, int, WageLine?, int)>(
        future: _load,
        builder: (context, snapshot) {
          final (s, days, wage, milkRecords) = snapshot.data ?? (null, 0, null, 0);
          if (s == null) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FarmTapCard(
                child: Row(
                  children: [
                    PersonAvatar(name: s.name, size: context.sizes.avatarHero),
                    context.space.gapLg,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name, style: context.text.headlineSmall),
                          context.space.gapXs,
                          Text(
                            s.since == null
                                ? staffRoleLabel(l10n, s.role)
                                : l10n.roleSince(
                                    staffRoleLabel(l10n, s.role),
                                    '${f.monthShort(s.since!)} ${s.since!.year}',
                                  ),
                            style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                          ),
                          context.space.gapSm,
                          if (s.hasCard)
                            StatusBadge(
                              label: l10n.cardNumberBadge(s.cardNumber!),
                              tone: FarmTapTone.success,
                              icon: Symbols.contactless_rounded,
                            )
                          else
                            StatusBadge(label: l10n.noCardBadge, tone: FarmTapTone.gold),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              context.space.gapLg,
              MetricStrip(
                children: [
                  MetricCard(icon: Symbols.schedule_rounded, label: l10n.daysThisMonth, value: f.count(days)),
                  MetricCard(
                    icon: Symbols.water_drop_rounded,
                    label: l10n.milkRecords,
                    value: f.count(milkRecords),
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
                  if (widget.canManageStaff)
                    RecordTile(
                      leading: IconBubble(
                        icon: Symbols.pin_rounded,
                        tone: FarmTapTone.neutral,
                        size: context.sizes.bubbleMd,
                      ),
                      title: l10n.resetPin,
                      onTap: () => _resetPin(s),
                    ),
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
                  RecordTile(
                    leading: IconBubble(
                      icon: Symbols.lock_rounded,
                      tone: FarmTapTone.info,
                      size: context.sizes.bubbleMd,
                    ),
                    title: l10n.whatCanDo(s.greetingName),
                    subtitle: _canDo(l10n, s.role),
                    onTap: () => _comingSoon(context),
                  ),
                  RecordTile(
                    leading: IconBubble(icon: Symbols.history_rounded, size: context.sizes.bubbleMd),
                    title: l10n.activityLog,
                    onTap: () => _comingSoon(context),
                  ),
                ],
              ),
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

  Future<(StaffMember?, String?)> _fetch() async {
    final s = ((await widget.directory.staff()).data ?? const <StaffMember>[])
        .where((m) => m.id == widget.staffId)
        .firstOrNull;
    return (s, (await widget.directory.nextBlankCard()).data);
  }

  Future<void> _assign(StaffMember s, String card) async {
    final l10n = AppLocalizations.of(context);
    final result = await widget.directory.assignCard(s.id, card);
    if (!mounted) return;
    switch (result) {
      case Success():
        unawaited(HapticFeedback.mediumImpact());
        FarmTapToast.show(context, message: l10n.cardAssigned(card, s.greetingName));
        widget.onDone();
      case FailureResult(failure: final Failure f):
        FarmTapToast.show(context, message: l10n.cardTaken(card, f.message.split(':').last));
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
          if (s == null) return const SizedBox.shrink();
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
                    subtitle: '${staffRoleLabel(l10n, s.role)} · ${widget.farmName}',
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
                  Center(
                    child: TextAction(
                      label: l10n.typeCardNumber,
                      icon: Symbols.dialpad_rounded,
                      onPressed: () => _type(s),
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
  const new({required this.repo, required this.directory, super.key, this.now, this.showSimulate = false});

  final WorkersRepository repo;

  /// Checks the manager PIN for typed card numbers (DAIRY-WRK-01).
  final StaffDirectory directory;
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
      FarmTapToast.show(context, message: l10n.noOneHasCard(card));
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
          if (all == null) return const SizedBox.shrink();
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
              FarmTapButton(
                label: l10n.clockInOut,
                icon: Symbols.contactless_rounded,
                large: true,
                onPressed: _tapCard,
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
                        tone: _avatarTone(t.staff, [for (final x in all) x.staff]),
                      ),
                      title: t.staff.name,
                      subtitle: staffRoleLabel(l10n, t.staff.role),
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
  const new({required this.directory, required this.onSaved, super.key, this.staffId});

  final StaffDirectory directory;

  /// Null adds a worker; otherwise edits this one.
  final String? staffId;
  final ValueChanged<StaffMember> onSaved;

  @override
  State<StaffFormPage> createState() => _StaffFormPageState();
}

class _StaffFormPageState extends State<StaffFormPage> {
  static const List<StaffRole> _roles = [
    StaffRole.herdsman,
    StaffRole.clerk,
    StaffRole.worker,
    StaffRole.manager,
    StaffRole.vet,
  ];

  final _name = TextEditingController();
  StaffRole _role = StaffRole.herdsman;
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
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _nameError = _name.text.trim().isEmpty ? l10n.nameRequired : null;
      _pinError = _isEdit || _pin.length == 4 ? null : l10n.pinRequired;
    });
    if (_nameError != null || _pinError != null) return;
    final saved = _isEdit
        ? (await widget.directory.updateStaff(widget.staffId!, name: _name.text.trim(), role: _role)).data
        : (await widget.directory.addStaff(name: _name.text.trim(), role: _role, pin: _pin)).data;
    if (saved == null || !mounted) return;
    setState(() => _edited = false);
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
                StaffFormFields<StaffRole>(
                  name: _name,
                  roles: _roles,
                  role: _role,
                  roleLabel: (r) => staffRoleLabel(l10n, r),
                  onRole: (r) => setState(() {
                    _role = r;
                    _edited = true;
                  }),
                  onChanged: () => setState(() => _edited = true),
                  pin: _isEdit ? null : _pin,
                  onPin: (p) => setState(() {
                    _pin = p;
                    _edited = true;
                  }),
                  nameError: _nameError,
                  pinError: _pinError,
                  showCardNote: !_isEdit,
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
