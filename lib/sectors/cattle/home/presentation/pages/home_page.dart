// D01 owner / manager home, D02 worker home, D05 offline state, D06
// reminders dialog. Pull to refresh syncs.
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/people/domain/staff_member.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/core/utils/formats.dart';
import 'package:farm_tap/sectors/cattle/home/domain/home_models.dart';
import 'package:farm_tap/sectors/cattle/home/domain/home_repository.dart';
import 'package:farm_tap/sectors/cattle/home/presentation/widgets/attention_tile.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Where a home tile or card leads; the router maps it to a route.
enum HomeTarget { milk, recordMilk, herd, health, treatment, workers, tapCard, feeding, breeding, report, alerts, pay }

class HomePage extends StatefulWidget {
  const new({
    required this.repo,
    required this.farmName,
    required this.ownerName,
    required this.onOpen,
    super.key,
    this.staff,
    this.trialDaysLeft,
    this.onLock,
    this.onRefresh,
    this.today,
  });

  final HomeRepository repo;
  final String farmName;

  /// Account owner's full name; the greeting uses the first word.
  final String ownerName;

  /// Worker who unlocked the phone: shows the worker home (D02).
  final StaffMember? staff;
  final int? trialDaysLeft;
  final ValueChanged<HomeTarget> onOpen;
  final VoidCallback? onLock;
  final Future<void> Function()? onRefresh;

  /// Overrides "today" (goldens use the mockups' Sat 7 Nov).
  final DateTime? today;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<(HomeSummary?, List<Attention>)> _owner = _loadOwner();
  late Future<WorkerDay?> _worker = _loadWorker();

  Future<(HomeSummary?, List<Attention>)> _loadOwner() async =>
      ((await widget.repo.summary()).data, (await widget.repo.attention()).data ?? const <Attention>[]);

  Future<WorkerDay?> _loadWorker() async {
    final staff = widget.staff;
    return staff == null ? null : (await widget.repo.workerDay(staff.id)).data;
  }

  bool get _isWorker => widget.staff != null && widget.staff!.role != StaffRole.manager;

  Future<void> _refresh() async {
    await widget.onRefresh?.call();
    setState(() {
      _owner = _loadOwner();
      _worker = _loadWorker();
    });
  }

  @override
  Widget build(BuildContext context) {
    final online = ShellStatus.maybeOf(context)?.online ?? true;
    return AdaptiveScaffold(
      showLogo: true,
      title: AppLocalizations.of(context).home,
      onRefresh: _refresh,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!online) ...[const OfflineBanner(), context.space.gapLg],
          if (_isWorker) _workerBody(context) else _ownerBody(context, online),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- D01 / D05

  Widget _ownerBody(BuildContext context, bool online) {
    final l10n = AppLocalizations.of(context);
    final f = FarmTapFormat(Localizations.localeOf(context).toLanguageTag());
    final now = widget.today ?? context.clock.now();
    final first = widget.ownerName.trim().split(RegExp(r'\s+')).first;
    final greeting = now.hour < 12
        ? l10n.goodMorning(first)
        : now.hour < 17
        ? l10n.goodAfternoon(first)
        : l10n.goodEvening(first);
    return FutureBuilder<(HomeSummary?, List<Attention>)>(
      future: _owner,
      builder: (context, snapshot) {
        final (summary, attention) = snapshot.data ?? (null, const <Attention>[]);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (online && widget.trialDaysLeft != null) ...[
              TrialBanner(daysLeft: widget.trialDaysLeft!, onPay: () => widget.onOpen(HomeTarget.pay)),
              context.space.gapLg,
            ],
            Text(greeting, style: context.text.headlineSmall),
            Text(
              l10n.farmAndDate(widget.farmName, f.longDay(now)),
              style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
            ),
            context.space.gapLg,
            if (summary == null)
              const _SkeletonGrid()
            else
              MetricStrip(
                children: [
                  MetricCard(
                    icon: Symbols.water_drop_rounded,
                    label: l10n.milkToday,
                    value: f.litresValue(summary.milkToday),
                    unit: l10n.litreUnit,
                    trend: '${summary.milkTrendPercent >= 0 ? '+' : ''}${summary.milkTrendPercent}%',
                    trendUp: summary.milkTrendPercent >= 0,
                    onTap: () => widget.onOpen(HomeTarget.milk),
                  ),
                  MetricCard(
                    icon: Symbols.pets_rounded,
                    label: l10n.cows,
                    value: f.count(summary.cows),
                    caption: l10n.milkingDry(summary.milking, summary.dry),
                    tone: FarmTapTone.gold,
                    onTap: () => widget.onOpen(HomeTarget.herd),
                  ),
                  MetricCard(
                    icon: Symbols.medical_services_rounded,
                    label: l10n.underTreatment,
                    value: f.count(summary.underTreatment),
                    caption: l10n.notForSaleCount(summary.notForSale),
                    tone: FarmTapTone.danger,
                    onTap: () => widget.onOpen(HomeTarget.health),
                  ),
                  MetricCard(
                    icon: Symbols.groups_rounded,
                    label: l10n.workersIn,
                    value: f.count(summary.workersIn),
                    unit: '/${summary.workersTotal}',
                    tone: FarmTapTone.info,
                    onTap: () => widget.onOpen(HomeTarget.workers),
                  ),
                ],
              ),
            context.space.gapLg,
            SectionLabel(l10n.quickActions),
            context.space.gapSm,
            ResponsiveGrid(
              minItemWidth: context.sizes.gridQuickAction,
              spacing: context.space.md,
              children: [
                QuickActionTile(
                  icon: Symbols.water_drop_rounded,
                  label: l10n.recordMilk,
                  onTap: () => widget.onOpen(HomeTarget.recordMilk),
                ),
                QuickActionTile(
                  icon: Symbols.contactless_rounded,
                  label: l10n.tapCard,
                  onTap: () => widget.onOpen(HomeTarget.tapCard),
                ),
                QuickActionTile(
                  icon: Symbols.medication_rounded,
                  label: l10n.treatment,
                  tone: FarmTapTone.danger,
                  onTap: () => widget.onOpen(HomeTarget.treatment),
                ),
                QuickActionTile(
                  icon: Symbols.grass_rounded,
                  label: l10n.feeding,
                  tone: FarmTapTone.gold,
                  onTap: () => widget.onOpen(HomeTarget.feeding),
                ),
              ],
            ),
            context.space.gapLg,
            ResponsiveGrid(
              minItemWidth: context.sizes.gridPaired,
              spacing: context.space.md,
              maxColumns: 2,
              children: [
                ListCard(
                  title: l10n.needsAttention,
                  actionLabel: l10n.seeAll,
                  onAction: () => widget.onOpen(HomeTarget.alerts),
                  children: [
                    for (final a in attention.take(3))
                      AttentionTile(item: a, today: widget.today, onTap: () => widget.onOpen(HomeTarget.alerts)),
                  ],
                ),
                if (summary != null)
                  FarmTapCard(
                    onTap: () => widget.onOpen(HomeTarget.milk),
                    children: [
                      CardHeader(
                        title: l10n.milkThisWeek,
                        trailing: StatusBadge(
                          label: '+${summary.milkTrendPercent}%',
                          tone: FarmTapTone.success,
                          icon: Symbols.trending_up_rounded,
                        ),
                      ),
                      MilkLineChart(
                        values: [for (final d in summary.week) d.litres],
                        labels: [for (final d in summary.week) f.weekdayShort(d.day)],
                      ),
                    ],
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------- D02

  Widget _workerBody(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = FarmTapFormat(Localizations.localeOf(context).toLanguageTag());
    final staff = widget.staff!;
    final role = switch (staff.role) {
      StaffRole.manager => l10n.roleManager,
      StaffRole.herdsman => l10n.roleHerdsman,
      StaffRole.clerk => l10n.roleMilkClerk,
      StaffRole.worker => l10n.roleWorker,
      StaffRole.vet => l10n.roleVet,
    };
    return FutureBuilder<WorkerDay?>(
      future: _worker,
      builder: (context, snapshot) {
        final day = snapshot.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: context.colors.primaryContainer,
              borderRadius: context.radii.card,
              child: Padding(
                padding: context.space.card,
                child: Row(
                  children: [
                    PersonAvatar(name: staff.name, size: context.sizes.avatarLg),
                    context.space.gapMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.helloStaff(staff.greetingName),
                            style: context.text.titleLarge?.copyWith(color: context.colors.onPrimaryContainer),
                          ),
                          if (day != null)
                            Text(
                              day.clockedInAt == null ? role : l10n.clockedIn(f.time(day.clockedInAt!), role),
                              style: context.text.bodySmall?.copyWith(color: context.colors.onPrimaryContainer),
                            ),
                        ],
                      ),
                    ),
                    context.space.gapSm,
                    FarmTapButton(
                      label: l10n.lock,
                      icon: Symbols.lock_rounded,
                      kind: ButtonKind.neutral,
                      expand: false,
                      onPressed: widget.onLock,
                    ),
                  ],
                ),
              ),
            ),
            context.space.gapXl,
            SectionLabel(l10n.whatAreYouDoing),
            context.space.gapSm,
            ResponsiveGrid(
              minItemWidth: context.sizes.gridAction,
              spacing: context.space.md,
              children: [
                ActionTile(
                  icon: Symbols.water_drop_rounded,
                  label: l10n.recordMilk,
                  subtitle: day == null || day.morningSession ? l10n.morningSession : l10n.eveningSession,
                  onTap: () => widget.onOpen(HomeTarget.recordMilk),
                ),
                ActionTile(
                  icon: Symbols.grass_rounded,
                  label: l10n.feeding,
                  subtitle: l10n.groupsLeft(day?.feedingGroupsLeft ?? 0),
                  tone: FarmTapTone.gold,
                  onTap: () => widget.onOpen(HomeTarget.feeding),
                ),
                ActionTile(
                  icon: Symbols.medication_rounded,
                  label: l10n.giveTreatment,
                  subtitle: l10n.dueNow(day?.treatmentsDue ?? 0),
                  tone: FarmTapTone.danger,
                  onTap: () => widget.onOpen(HomeTarget.treatment),
                ),
                ActionTile(
                  icon: Symbols.vaccines_rounded,
                  label: l10n.dipping,
                  subtitle: day == null ? null : l10n.dueOn(f.weekday(day.dippingDue)),
                  tone: FarmTapTone.info,
                  onTap: () => widget.onOpen(HomeTarget.health),
                ),
                ActionTile(
                  icon: Symbols.favorite_rounded,
                  label: l10n.heatService,
                  subtitle: l10n.breeding,
                  tone: FarmTapTone.danger,
                  onTap: () => widget.onOpen(HomeTarget.breeding),
                ),
                ActionTile(
                  icon: Symbols.photo_camera_rounded,
                  label: l10n.reportProblem,
                  subtitle: l10n.photoNote,
                  tone: FarmTapTone.neutral,
                  onTap: () => widget.onOpen(HomeTarget.report),
                ),
              ],
            ),
            context.space.gapXl,
            SectionLabel(l10n.myTasksToday),
            context.space.gapSm,
            if (day != null)
              FarmTapCard(
                padding: EdgeInsets.symmetric(horizontal: context.space.lg, vertical: context.space.sm),
                child: Column(
                  children: [
                    for (var i = 0; i < day.tasks.length; i++) ...[
                      if (i > 0) Divider(indent: context.sizes.checkbox + context.space.md),
                      CheckRow(
                        label: day.tasks[i].title,
                        subtitle: day.tasks[i].when,
                        value: day.tasks[i].done,
                        onChanged: (v) async {
                          await widget.repo.setTaskDone(day.tasks[i].id, done: v);
                          setState(() {
                            _worker = _loadWorker();
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Loading state: grey cards where the numbers will be.
class _SkeletonGrid extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return ResponsiveGrid(
      minItemWidth: context.sizes.gridMetric,
      spacing: context.space.md,
      children: [
        for (var i = 0; i < 4; i++)
          Container(
            height: context.sizes.actionTileWithSubtitle,
            decoration: BoxDecoration(color: context.colors.surfaceContainer, borderRadius: context.radii.card),
          ),
      ],
    );
  }
}

/// D06 — ask for notification permission. Shown once, after the first
/// record is saved, never on first launch. Resolves true for "Allow".
Future<bool> showRemindersDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showFarmTapDialog(
    context,
    icon: Symbols.notifications_active_rounded,
    tone: FarmTapTone.primary,
    title: l10n.getReminders,
    message: l10n.getRemindersBody,
    primaryLabel: l10n.allowReminders,
    secondaryLabel: l10n.notNow,
    secondaryKind: ButtonKind.text,
  );
}
