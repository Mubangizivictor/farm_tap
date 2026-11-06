// The AI module screens that read the farm's records and show what the
// engine found (decision 0025, phone phase 2). Every figure comes from the
// farm's own records; each card says how it was made.
import 'dart:async';

import 'package:farm_tap/core/ai/ai_core.dart';
import 'package:farm_tap/core/ai/ai_data.dart';
import 'package:farm_tap/core/ai/ai_herd.dart';
import 'package:farm_tap/core/ai/ai_milk.dart';
import 'package:farm_tap/core/ai/ai_money.dart';
import 'package:farm_tap/core/ai/ai_repository.dart';
import 'package:farm_tap/core/ai/ai_risk.dart';
import 'package:farm_tap/core/ai/ai_stock.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/sectors/cattle/ai/presentation/ai_widgets.dart';
import 'package:farm_tap/sectors/cattle/operations/presentation/pages/operations_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

/// A page that shows one module: a few summary cards, then its findings.
class _ModulePage extends StatelessWidget {
  const _ModulePage({required this.ctx, required this.module, required this.summary});

  final AiPageContext ctx;
  final String module;

  /// Cards above the findings.
  final List<Widget> Function(BuildContext context, AiFarm farm, Future<void> Function() reload) summary;

  @override
  Widget build(BuildContext context) => AiBody(
    repo: ctx.repo,
    role: ctx.role,
    title: aiModuleLabel(module),
    builder: (context, farm, reload) {
      final l10n = AppLocalizations.of(context);
      final items = farm.findingsFor(module);
      final cards = summary(context, farm, reload);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...cards,
          if (items.isNotEmpty || cards.isEmpty) ...[
            aiSection(context, l10n.aiFindings),
            FindingList(items: items, onLink: ctx.onLink),
          ],
        ],
      );
    },
  );
}

String _l(double v) => fmtL(v);

// ---------------------------------------------------------------- Milk

class AiMilkPage extends StatelessWidget {
  const AiMilkPage({required this.ctx, super.key});

  final AiPageContext ctx;

  @override
  Widget build(BuildContext context) => _ModulePage(
    ctx: ctx,
    module: 'milk',
    summary: (context, farm, reload) {
      final l10n = AppLocalizations.of(context);
      final s = milkSummary(farm.data);
      final bal = milkBalance(farm.data);
      final drops = cowTrends(farm.data).where((c) => c.changePct <= dropPct).take(10).toList();
      return [
        FarmTapCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AiStat(label: l10n.aiToday, value: s.todayRecorded ? _l(s.today) : l10n.aiNotRecorded),
                  ),
                  Expanded(
                    child: AiStat(label: l10n.aiYesterday, value: _l(s.yesterday)),
                  ),
                  Expanded(
                    child: AiStat(
                      label: l10n.aiAvg7,
                      value: s.avg7 == null ? '-' : _l(s.avg7!),
                      sub: s.weekChangePct == null ? null : '${s.weekChangePct! > 0 ? '+' : ''}${s.weekChangePct}%',
                    ),
                  ),
                ],
              ),
              context.space.gapSm,
              const MethodBadge(Method.calculated),
            ],
          ),
        ),
        context.space.gapLg,
        ListCard(
          title: l10n.aiBalanceTitle,
          children: [
            SummaryRow(label: l10n.aiProduced, value: _l(bal.produced)),
            SummaryRow(label: l10n.aiSold, value: _l(bal.sold)),
            SummaryRow(label: l10n.aiHomeUse, value: _l(bal.homeUse)),
            SummaryRow(label: l10n.aiThrownAway, value: _l(bal.discarded)),
            SummaryRow(
              label: l10n.aiNotAccounted,
              value: bal.unaccounted == null ? l10n.aiNoSalesYet : _l(bal.unaccounted!),
              emphasis: true,
            ),
          ],
        ),
        context.space.gapLg,
        if (drops.isNotEmpty) ...[
          ListCard(
            title: l10n.aiCowsDropping,
            children: [
              for (final c in drops)
                RecordTile(
                  leading: IconBubble(
                    icon: Symbols.trending_down_rounded,
                    tone: FarmTapTone.danger,
                    size: context.sizes.bubbleMd,
                  ),
                  title: c.name,
                  subtitle: '${_l(c.recent)} · ${_l(c.before)}',
                  trailingValue: '${c.changePct}%',
                  onTap: () => ctx.onLink('/herd/?animal=${Uri.encodeComponent(c.animalId)}'),
                ),
            ],
          ),
          context.space.gapLg,
        ],
      ];
    },
  );
}

// ---------------------------------------------------------------- Predictions

class AiPredictionsPage extends StatelessWidget {
  const AiPredictionsPage({required this.ctx, super.key});

  final AiPageContext ctx;

  @override
  Widget build(BuildContext context) => AiBody(
    repo: ctx.repo,
    role: ctx.role,
    title: aiModuleLabel('predictions'),
    builder: (context, farm, reload) {
      final l10n = AppLocalizations.of(context);
      final f = herdForecast(farm.data);
      if (!f.ok) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EmptyState(title: l10n.aiNoForecast, message: f.reason),
            context.space.gapMd,
            AiNote(l10n.aiForecastNeeds),
          ],
        );
      }
      final cows = <({String name, Forecast f})>[];
      for (final a in alive(farm.data.animals).where(isMilkingCow)) {
        final cf = cowForecast(farm.data, a.id);
        if (cf.ok) cows.add((name: animalName(a), f: cf));
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FarmTapCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AiStat(label: l10n.aiNext7, value: _l(f.total7)),
                    ),
                    Expanded(
                      child: AiStat(label: l10n.aiNext30, value: f.total30 == null ? '-' : _l(f.total30!)),
                    ),
                  ],
                ),
                context.space.gapSm,
                Wrap(
                  spacing: context.space.xs,
                  children: [
                    const MethodBadge(Method.statistical),
                    StatusBadge(
                      label: l10n.aiConfidence(f.confidence),
                      tone: f.confidence == 'high'
                          ? FarmTapTone.success
                          : f.confidence == 'medium'
                          ? FarmTapTone.warning
                          : FarmTapTone.neutral,
                    ),
                  ],
                ),
                context.space.gapSm,
                Text(
                  '${f.method} · ${l10n.aiMadeFromDays(f.daysUsed)}',
                  style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          context.space.gapLg,
          ListCard(
            title: l10n.aiNextDays,
            children: [
              for (final d in f.next7)
                RecordTile(
                  leading: IconBubble(
                    icon: Symbols.water_drop_rounded,
                    tone: FarmTapTone.info,
                    size: context.sizes.bubbleMd,
                  ),
                  title: fmtDay(d.day),
                  subtitle: '${_l(d.low)} - ${_l(d.high)}',
                  trailingValue: _l(d.litres),
                  showChevron: false,
                ),
            ],
          ),
          if (cows.isNotEmpty) ...[
            context.space.gapLg,
            ListCard(
              title: l10n.aiPerCow,
              children: [
                for (final c in cows)
                  RecordTile(
                    leading: IconBubble(
                      icon: Symbols.pets_rounded,
                      tone: FarmTapTone.primary,
                      size: context.sizes.bubbleMd,
                    ),
                    title: c.name,
                    subtitle: l10n.aiConfidence(c.f.confidence),
                    trailingValue: _l(c.f.total7),
                    showChevron: false,
                  ),
              ],
            ),
          ],
          context.space.gapMd,
          AiNote(l10n.aiForecastNote),
        ],
      );
    },
  );
}

// ---------------------------------------------------------------- Feed and inventory

List<Widget> _feedRows(BuildContext context, AppLocalizations l10n, List<FeedView> feeds) => [
  for (final f in feeds)
    RecordTile(
      leading: IconBubble(
        icon: Symbols.grass_rounded,
        tone: f.daysLeft != null && f.daysLeft! <= 2
            ? FarmTapTone.danger
            : f.daysLeft != null && f.daysLeft! <= 7
            ? FarmTapTone.warning
            : FarmTapTone.success,
        size: context.sizes.bubbleMd,
      ),
      title: f.name,
      subtitle: f.daysLeft == null ? l10n.aiNoUseYet : l10n.aiDaysAtRate(f.daysLeft!, jsNum(f.perDay), f.unit),
      trailingValue: '${jsNum(f.left)} ${f.unit}',
      showChevron: false,
    ),
];

class AiFeedPage extends StatelessWidget {
  const AiFeedPage({required this.ctx, super.key});

  final AiPageContext ctx;

  @override
  Widget build(BuildContext context) => _ModulePage(
    ctx: ctx,
    module: 'feed',
    summary: (context, farm, reload) {
      final l10n = AppLocalizations.of(context);
      final feeds = feedViews(farm.data);
      final e = feedEconomics(farm.data);
      return [
        if (feeds.isEmpty)
          EmptyState(title: l10n.aiNoFeed, message: l10n.aiNoFeedBody)
        else
          ListCard(title: l10n.aiFeedInStore, children: _feedRows(context, l10n, feeds)),
        context.space.gapLg,
        if (farm.seesMoneyNow && e.costPerLitre != null) ...[
          FarmTapCard(
            child: Row(
              children: [
                Expanded(
                  child: AiStat(label: l10n.aiCostPerLitre, value: fmtUgx(e.costPerLitre!)),
                ),
                if (e.litresPer1000 != null)
                  Expanded(
                    child: AiStat(label: l10n.aiLitresPer1000, value: jsNum(e.litresPer1000!)),
                  ),
              ],
            ),
          ),
          context.space.gapLg,
        ],
      ];
    },
  );
}

class AiInventoryPage extends StatelessWidget {
  const AiInventoryPage({required this.ctx, super.key});

  final AiPageContext ctx;

  @override
  Widget build(BuildContext context) => _ModulePage(
    ctx: ctx,
    module: 'inventory',
    summary: (context, farm, reload) {
      final l10n = AppLocalizations.of(context);
      final feeds = feedViews(farm.data);
      final drugs = drugViews(farm.data);
      return [
        if (feeds.isNotEmpty) ...[
          ListCard(title: l10n.aiFeedInStore, children: _feedRows(context, l10n, feeds)),
          context.space.gapLg,
        ],
        if (drugs.isNotEmpty) ...[
          ListCard(
            title: l10n.aiDrugStock,
            children: [
              for (final x in drugs)
                RecordTile(
                  leading: IconBubble(
                    icon: Symbols.medication_rounded,
                    tone: x.stock != null && x.reorderAt != null && x.stock! <= x.reorderAt!
                        ? FarmTapTone.danger
                        : FarmTapTone.success,
                    size: context.sizes.bubbleMd,
                  ),
                  title: x.name,
                  subtitle: x.reorderAt == null ? null : l10n.aiReorderAt('${jsNum(x.reorderAt!)} ${x.unit}'.trim()),
                  trailingValue: x.stock == null ? l10n.aiNotCounted : '${jsNum(x.stock!)} ${x.unit}'.trim(),
                  showChevron: false,
                ),
            ],
          ),
          context.space.gapLg,
        ],
      ];
    },
  );
}

// ---------------------------------------------------------------- Breeding

class AiBreedingPage extends StatelessWidget {
  const AiBreedingPage({required this.ctx, super.key});

  final AiPageContext ctx;

  @override
  Widget build(BuildContext context) => _ModulePage(
    ctx: ctx,
    module: 'breeding',
    summary: (context, farm, reload) {
      final l10n = AppLocalizations.of(context);
      final day = today(farm.data);
      final cows = farm.data.animals
          .where(
            (a) =>
                !a.isDeleted &&
                isActive(a) &&
                a.str('sex') != 'male' &&
                !const ['calf', 'bull'].contains(a.str('dairyStatus') ?? ''),
          )
          .toList();
      final states = [for (final a in cows) (a: a, b: breedingState(a.id, farm.data.breeding, day))];
      final pregnant = states.where((x) => x.b.pregnant).toList()
        ..sort((x, y) => (x.b.due ?? '').compareTo(y.b.due ?? ''));
      final open = states.where((x) => !x.b.pregnant).toList();
      final ci = calvingInterval(farm.data);
      return [
        FarmTapCard(
          child: Row(
            children: [
              Expanded(
                child: AiStat(label: l10n.aiInCalf, value: '${pregnant.length}'),
              ),
              Expanded(
                child: AiStat(label: l10n.aiOpenCows, value: '${open.length}'),
              ),
              Expanded(
                child: AiStat(
                  label: l10n.aiCalvingInterval,
                  value: ci.avgDays == null ? '-' : l10n.aiDaysShort(ci.avgDays!),
                ),
              ),
            ],
          ),
        ),
        context.space.gapLg,
        if (pregnant.isNotEmpty) ...[
          ListCard(
            title: l10n.aiServedOrInCalf,
            children: [
              for (final x in pregnant)
                RecordTile(
                  leading: IconBubble(
                    icon: Symbols.favorite_rounded,
                    tone: FarmTapTone.danger,
                    size: context.sizes.bubbleMd,
                  ),
                  title: animalName(x.a),
                  subtitle:
                      '${l10n.aiDueAbout(fmtDay(x.b.due!))} · ${x.b.confirmed ? l10n.aiConfirmed : l10n.aiNotConfirmed}',
                  onTap: () => ctx.onLink('/herd/?animal=${Uri.encodeComponent(x.a.id)}'),
                ),
            ],
          ),
          context.space.gapLg,
        ],
        if (open.isNotEmpty) ...[
          ListCard(
            title: l10n.aiOpenCows,
            children: [
              for (final x in open)
                RecordTile(
                  leading: IconBubble(
                    icon: Symbols.favorite_rounded,
                    tone: FarmTapTone.neutral,
                    size: context.sizes.bubbleMd,
                  ),
                  title: animalName(x.a),
                  subtitle: x.b.nextHeat == null ? l10n.aiNoHeatRecorded : l10n.aiNextHeatAbout(fmtDay(x.b.nextHeat!)),
                  trailingValue: x.b.daysInMilk == null ? null : l10n.aiDaysShort(x.b.daysInMilk!),
                  onTap: () => ctx.onLink('/herd/?animal=${Uri.encodeComponent(x.a.id)}'),
                ),
            ],
          ),
          context.space.gapLg,
        ],
        AiNote(l10n.aiBreedingNote),
        context.space.gapLg,
      ];
    },
  );
}

// ---------------------------------------------------------------- Health

class AiHealthPage extends StatelessWidget {
  const AiHealthPage({required this.ctx, super.key});

  final AiPageContext ctx;

  @override
  Widget build(BuildContext context) => _ModulePage(
    ctx: ctx,
    module: 'health',
    summary: (context, farm, reload) {
      final l10n = AppLocalizations.of(context);
      final active = farm.data.animals.where((a) => !a.isDeleted && isActive(a)).toList();
      final health = [for (final a in active) animalHealth(farm.data, a.id)];
      final attention = health.where((h) => h.attention.isNotEmpty).toList();
      final withdrawal = health.where((h) => h.inWithdrawal).toList();
      final vaccines = vaccinesDue(farm.data);
      return [
        if (attention.isNotEmpty) ...[
          ListCard(
            title: l10n.aiNeedAttention,
            children: [
              for (final h in attention.take(12))
                RecordTile(
                  leading: IconBubble(
                    icon: Symbols.health_and_safety_rounded,
                    tone: FarmTapTone.warning,
                    size: context.sizes.bubbleMd,
                  ),
                  title: h.name,
                  subtitle: h.attention.join('; '),
                  onTap: () => ctx.onLink('/herd/?animal=${Uri.encodeComponent(h.animalId)}'),
                ),
            ],
          ),
          context.space.gapLg,
        ],
        if (withdrawal.isNotEmpty) ...[
          ListCard(
            title: l10n.aiInWithdrawal,
            children: [
              for (final h in withdrawal)
                RecordTile(
                  leading: IconBubble(
                    icon: Symbols.block_rounded,
                    tone: FarmTapTone.danger,
                    size: context.sizes.bubbleMd,
                  ),
                  title: h.name,
                  subtitle: l10n.aiSafeFrom(fmtDay(h.safeFrom!)),
                  showChevron: false,
                ),
            ],
          ),
          context.space.gapLg,
        ],
        if (vaccines.isNotEmpty) ...[
          ListCard(
            title: l10n.aiVaccinesDue,
            children: [
              for (final v in vaccines)
                RecordTile(
                  leading: IconBubble(
                    icon: Symbols.vaccines_rounded,
                    tone: v.overdueDays > 0 ? FarmTapTone.danger : FarmTapTone.info,
                    size: context.sizes.bubbleMd,
                  ),
                  title: v.vaccine,
                  subtitle: v.overdueDays > 0 ? l10n.aiOverdueDays(v.overdueDays) : l10n.aiDueOn(fmtDay(v.due)),
                  showChevron: false,
                ),
            ],
          ),
          context.space.gapLg,
        ],
      ];
    },
  );
}

// ---------------------------------------------------------------- Finance

class AiFinancePage extends StatelessWidget {
  const AiFinancePage({required this.ctx, super.key});

  final AiPageContext ctx;

  @override
  Widget build(BuildContext context) => _ModulePage(
    ctx: ctx,
    module: 'finance',
    summary: (context, farm, reload) {
      final l10n = AppLocalizations.of(context);
      final months = monthsBack(farm.data, 3);
      final cash = cashForecast(farm.data);
      final unusual = unusualExpenses(farm.data);
      return [
        ListCard(
          title: l10n.aiLastMonths,
          children: [
            for (final m in months)
              RecordTile(
                leading: IconBubble(
                  icon: Symbols.account_balance_wallet_rounded,
                  tone: m.net < 0 ? FarmTapTone.danger : FarmTapTone.success,
                  size: context.sizes.bubbleMd,
                ),
                title: fmtMonth(m.month),
                subtitle: '${l10n.aiIncomeShort} ${fmtUgx(m.income)} · ${l10n.aiSpentShort} ${fmtUgx(m.spent)}',
                trailingValue: fmtUgx(m.net),
                trailingSub: m.costPerLitre == null ? null : '${fmtUgx(m.costPerLitre!)} / L',
                showChevron: false,
              ),
          ],
        ),
        context.space.gapLg,
        FarmTapCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.aiNextMonth(fmtMonth(cash.month)), style: context.text.titleSmall),
              context.space.gapXs,
              if (cash.ok) ...[
                SummaryRow(label: l10n.aiIncomeShort, value: fmtUgx(cash.income)),
                SummaryRow(label: l10n.aiSpentShort, value: fmtUgx(cash.spent)),
                SummaryRow(label: l10n.aiNet, value: fmtUgx(cash.net), emphasis: true),
                context.space.gapXs,
                Text(cash.method, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
              ] else
                Text(cash.reason ?? '', style: context.text.bodyMedium),
              context.space.gapSm,
              const MethodBadge(Method.statistical),
            ],
          ),
        ),
        context.space.gapLg,
        if (unusual.isNotEmpty) ...[
          ListCard(
            title: l10n.aiLargeExpenses,
            children: [
              for (final u in unusual.take(5))
                RecordTile(
                  leading: IconBubble(
                    icon: Symbols.warning_rounded,
                    tone: FarmTapTone.warning,
                    size: context.sizes.bubbleMd,
                  ),
                  title: catLabel(u.category),
                  subtitle: '${u.at} · ${l10n.aiUsually(fmtUgx(u.usual))}',
                  trailingValue: fmtUgx(u.amount),
                  showChevron: false,
                ),
            ],
          ),
          context.space.gapLg,
        ],
      ];
    },
  );
}

// ---------------------------------------------------------------- Risks, recommendations, alerts

class AiRisksPage extends StatelessWidget {
  const AiRisksPage({required this.ctx, super.key});

  final AiPageContext ctx;

  @override
  Widget build(BuildContext context) => AiBody(
    repo: ctx.repo,
    role: ctx.role,
    title: aiModuleLabel('risks'),
    builder: (context, farm, reload) {
      final l10n = AppLocalizations.of(context);
      final all = farm.findings();
      final counts = countBySeverity([for (final f in all) f.finding]);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FarmTapCard(
            child: Row(
              children: [
                for (final s in Severity.values)
                  Expanded(
                    child: AiStat(label: severityLabel[s]!, value: '${counts[s]}'),
                  ),
              ],
            ),
          ),
          context.space.gapLg,
          FindingList(items: all, onLink: ctx.onLink, emptyTitle: l10n.aiNoRisks),
        ],
      );
    },
  );
}

class AiRecommendationsPage extends StatelessWidget {
  const AiRecommendationsPage({required this.ctx, super.key});

  final AiPageContext ctx;

  @override
  Widget build(BuildContext context) => AiBody(
    repo: ctx.repo,
    role: ctx.role,
    title: aiModuleLabel('recommendations'),
    builder: (context, farm, reload) =>
        FindingList(items: todaysInsights(farm.findings(), farm.config.insightsCount), onLink: ctx.onLink),
  );
}

class AiAlertsPage extends StatefulWidget {
  const AiAlertsPage({required this.ctx, super.key});

  final AiPageContext ctx;

  @override
  State<AiAlertsPage> createState() => _AiAlertsPageState();
}

class _AiAlertsPageState extends State<AiAlertsPage> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ctx = widget.ctx;
    return AiBody(
      repo: ctx.repo,
      role: ctx.role,
      title: aiModuleLabel('alerts'),
      builder: (context, farm, reload) {
        final all = farm.findings();
        final shown = switch (_filter) {
          'new' => all.where((f) => f.state == 'new').toList(),
          'seen' => all.where((f) => f.state != 'new').toList(),
          _ => all,
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilterChips<String>(
              options: [
                FilterOption(value: 'all', label: l10n.aiFilterAll, count: all.length),
                FilterOption(value: 'new', label: l10n.aiFilterNew, count: all.where((f) => f.state == 'new').length),
                FilterOption(value: 'seen', label: l10n.aiSeen, count: all.where((f) => f.state != 'new').length),
              ],
              selected: _filter,
              onSelected: (v) => setState(() => _filter = v),
            ),
            context.space.gapLg,
            FindingList(items: shown, onLink: ctx.onLink, repo: ctx.repo, byName: ctx.byName, onChanged: reload),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------- Milk quality and expiry

class AiQualityPage extends StatelessWidget {
  const AiQualityPage({required this.ctx, super.key});

  final AiPageContext ctx;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AiBody(
      repo: ctx.repo,
      role: ctx.role,
      title: aiModuleLabel('quality'),
      builder: (context, farm, reload) {
        final batches = batchViews(farm.data);
        final open = batches.where((b) => b.state != 'closed').toList()
          ..sort((a, b) => a.hoursLeft.compareTo(b.hoursLeft));
        final closed = batches.where((b) => b.state == 'closed').toList().reversed.take(10).toList();
        final rule = shelfRule(farm.data);
        final items = farm.findingsFor('quality');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FarmTapCard(
              onTap: ctx.manages ? () => _editRule(context, farm, reload) : null,
              child: Row(
                children: [
                  IconBubble(icon: Symbols.ac_unit_rounded, tone: FarmTapTone.info, size: context.sizes.bubbleMd),
                  context.space.gapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rule.label, style: context.text.titleSmall),
                        Text(
                          l10n.aiShelfRule(jsNum(rule.cooledHours), jsNum(rule.maxTempC), jsNum(rule.warmHours)),
                          style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (ctx.manages) Icon(Symbols.edit_rounded, color: context.colors.onSurfaceVariant),
                ],
              ),
            ),
            context.space.gapSm,
            AiNote(l10n.aiUseByNote, icon: Symbols.shield_rounded),
            context.space.gapLg,
            FarmTapButton(
              label: l10n.aiAddBatch,
              icon: Symbols.add_rounded,
              onPressed: () => unawaited(_addBatch(context, reload)),
            ),
            context.space.gapLg,
            if (open.isEmpty)
              EmptyState(title: l10n.aiNoBatches, message: l10n.aiNoBatchesBody)
            else
              ListCard(title: l10n.aiInStorage, children: [for (final b in open) _batchTile(context, l10n, b, reload)]),
            if (closed.isNotEmpty) ...[
              context.space.gapLg,
              ListCard(
                title: l10n.aiClosedBatches,
                children: [for (final b in closed) _batchTile(context, l10n, b, reload)],
              ),
            ],
            if (items.isNotEmpty) ...[
              context.space.gapLg,
              aiSection(context, l10n.aiFindings),
              FindingList(items: items, onLink: ctx.onLink),
            ],
          ],
        );
      },
    );
  }

  Widget _batchTile(BuildContext context, AppLocalizations l10n, BatchView b, Future<void> Function() reload) {
    final tone = switch (b.state) {
      'expired' => FarmTapTone.danger,
      'useSoon' => FarmTapTone.warning,
      'closed' => FarmTapTone.neutral,
      _ => FarmTapTone.success,
    };
    final label = switch (b.state) {
      'expired' => l10n.aiExpired,
      'useSoon' => l10n.aiUseSoon,
      'closed' => b.status,
      _ => l10n.aiFresh,
    };
    return RecordTile(
      leading: IconBubble(icon: Symbols.water_drop_rounded, tone: tone, size: context.sizes.bubbleMd),
      title: '${fmtL(b.litres)} · ${b.place}',
      subtitle: b.state == 'closed'
          ? b.collectedAt.replaceFirst('T', ' ')
          : '${l10n.aiUseBy(b.useBy.replaceFirst('T', ' '))}${b.unverified ? ' · ${l10n.aiNoReading}' : ''}',
      badge: StatusBadge(label: label, tone: tone),
      onTap: b.state == 'closed' ? null : () => unawaited(_batchActions(context, b, reload)),
    );
  }

  Future<void> _batchActions(BuildContext context, BatchView b, Future<void> Function() reload) async {
    final l10n = AppLocalizations.of(context);
    await showAdaptiveSheet<void>(
      context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetTitle('${fmtL(b.litres)} · ${b.place}'),
          sheet.space.gapMd,
          FarmTapButton(
            label: l10n.aiRecordTemp,
            icon: Symbols.ac_unit_rounded,
            kind: ButtonKind.tonal,
            onPressed: () async {
              Navigator.of(sheet).pop();
              await _addReading(context, b, reload);
            },
          ),
          sheet.space.gapSm,
          for (final (status, label) in [
            ('sold', l10n.aiMarkSold),
            ('used', l10n.aiMarkUsed),
            ('discarded', l10n.aiMarkDiscarded),
          ]) ...[
            FarmTapButton(
              label: label,
              kind: ButtonKind.outlined,
              onPressed: () async {
                Navigator.of(sheet).pop();
                await ctx.repo.closeBatch(b.id, status);
                await reload();
              },
            ),
            sheet.space.gapSm,
          ],
        ],
      ),
    );
  }

  Future<void> _addBatch(BuildContext context, Future<void> Function() reload) async {
    final clock = context.clock;
    await showAdaptiveSheet<void>(
      context,
      builder: (_) => _BatchForm(repo: ctx.repo, now: clock.now(), onSaved: reload),
    );
  }

  Future<void> _addReading(BuildContext context, BatchView b, Future<void> Function() reload) async {
    await showAdaptiveSheet<void>(
      context,
      builder: (_) => _ReadingForm(repo: ctx.repo, batch: b, onSaved: reload),
    );
  }

  Future<void> _editRule(BuildContext context, AiFarm farm, Future<void> Function() reload) async {
    await showAdaptiveSheet<void>(
      context,
      builder: (_) => _RuleForm(repo: ctx.repo, rules: farm.shelfRules, onSaved: reload),
    );
  }
}

double? _num(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

final _decimal = <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\-]'))];

class _BatchForm extends StatefulWidget {
  const _BatchForm({required this.repo, required this.now, required this.onSaved});

  final AiRepository repo;
  final DateTime now;
  final Future<void> Function() onSaved;

  @override
  State<_BatchForm> createState() => _BatchFormState();
}

class _BatchFormState extends State<_BatchForm> {
  final _litres = TextEditingController();
  final _place = TextEditingController();
  bool _cooled = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _litres.dispose();
    _place.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FormSheet(
      title: l10n.aiAddBatch,
      saving: _saving,
      onSave: () async {
        final litres = _num(_litres.text);
        if (litres == null || litres <= 0) {
          setState(() => _error = l10n.aiLitresNeeded);
          return;
        }
        setState(() => _saving = true);
        await widget.repo.addBatch(litres: litres, collectedAt: widget.now, cooled: _cooled, place: _place.text);
        await widget.onSaved();
        if (context.mounted) Navigator.of(context).pop();
      },
      children: [
        FarmTapTextField(
          label: l10n.aiLitres,
          controller: _litres,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: _decimal,
          error: _error,
        ),
        FarmTapTextField(label: l10n.aiPlaceOptional, controller: _place, hint: l10n.aiPlaceHint),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.aiCooledQuestion),
          value: _cooled,
          onChanged: (v) => setState(() => _cooled = v),
        ),
      ],
    );
  }
}

class _ReadingForm extends StatefulWidget {
  const _ReadingForm({required this.repo, required this.batch, required this.onSaved});

  final AiRepository repo;
  final BatchView batch;
  final Future<void> Function() onSaved;

  @override
  State<_ReadingForm> createState() => _ReadingFormState();
}

class _ReadingFormState extends State<_ReadingForm> {
  final _temp = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _temp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FormSheet(
      title: l10n.aiRecordTemp,
      saving: _saving,
      onSave: () async {
        final t = _num(_temp.text);
        if (t == null || t < -20 || t > 60) {
          setState(() => _error = l10n.aiTempNeeded);
          return;
        }
        setState(() => _saving = true);
        await widget.repo.addReading(
          tempC: t,
          batchId: widget.batch.id,
          place: widget.batch.place == 'Not named' ? null : widget.batch.place,
        );
        await widget.onSaved();
        if (context.mounted) Navigator.of(context).pop();
      },
      children: [
        Text('${fmtL(widget.batch.litres)} · ${widget.batch.place}', style: context.text.bodyMedium),
        FarmTapTextField(
          label: l10n.aiTempC,
          controller: _temp,
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          inputFormatters: _decimal,
          error: _error,
        ),
      ],
    );
  }
}

class _RuleForm extends StatefulWidget {
  const _RuleForm({required this.repo, required this.rules, required this.onSaved});

  final AiRepository repo;
  final List<ShelfRule> rules;
  final Future<void> Function() onSaved;

  @override
  State<_RuleForm> createState() => _RuleFormState();
}

class _RuleFormState extends State<_RuleForm> {
  late final ShelfRule _rule = widget.rules.first;
  late final _cooled = TextEditingController(text: jsNum(_rule.cooledHours));
  late final _warm = TextEditingController(text: jsNum(_rule.warmHours));
  late final _max = TextEditingController(text: jsNum(_rule.maxTempC));
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _cooled.dispose();
    _warm.dispose();
    _max.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FormSheet(
      title: _rule.label,
      saving: _saving,
      onSave: () async {
        final c = _num(_cooled.text);
        final w = _num(_warm.text);
        final m = _num(_max.text);
        if (c == null || w == null || m == null || c < 1 || c > 336 || w < 0.5 || w > 48 || m < -5 || m > 15) {
          setState(() => _error = l10n.aiRuleInvalid);
          return;
        }
        setState(() => _saving = true);
        final next = [
          for (final r in widget.rules)
            if (r.product == _rule.product)
              ShelfRule(product: r.product, label: r.label, cooledHours: c, warmHours: w, maxTempC: m)
            else
              r,
        ];
        await widget.repo.saveShelfRules(next);
        await widget.onSaved();
        if (context.mounted) Navigator.of(context).pop();
      },
      children: [
        AiNote(l10n.aiRuleNote),
        FarmTapTextField(
          label: l10n.aiCooledHours,
          controller: _cooled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: _decimal,
        ),
        FarmTapTextField(
          label: l10n.aiWarmHours,
          controller: _warm,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: _decimal,
        ),
        FarmTapTextField(
          label: l10n.aiMaxTemp,
          controller: _max,
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          inputFormatters: _decimal,
          error: _error,
        ),
      ],
    );
  }
}
