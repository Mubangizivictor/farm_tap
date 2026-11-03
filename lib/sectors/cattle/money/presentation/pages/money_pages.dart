// Money & reports: L01 money overview, L02 add expense, L03 reports, L04
// daily WhatsApp report. Every number is read from core/money (expenses),
// the milk records and sales (litres, income) and the other features.
import 'dart:async';

import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/money/domain/money_models.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/core/utils/formats.dart';
import 'package:farm_tap/sectors/cattle/money/domain/farm_money_models.dart';
import 'package:farm_tap/sectors/cattle/money/domain/farm_money_repository.dart';
import 'package:farm_tap/sectors/cattle/owner_reports/domain/daily_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

FarmTapFormat _fmt(BuildContext context) => FarmTapFormat(Localizations.localeOf(context).toLanguageTag());

/// "UGX 1.9M", "UGX 293k", "-UGX 293k".
String _short(FarmTapFormat f, int ugx) {
  final n = ugx.abs();
  final text = 'UGX ${n >= 1000000 ? f.compact(n).toUpperCase() : f.compact(n)}';
  return ugx < 0 ? '-$text' : text;
}

String groupLabel(AppLocalizations l10n, ExpenseGroup g) => switch (g) {
  ExpenseGroup.feed => l10n.groupFeed,
  ExpenseGroup.drugsVet => l10n.groupDrugsVet,
  ExpenseGroup.wages => l10n.groupWages,
  ExpenseGroup.transport => l10n.groupTransport,
  ExpenseGroup.fuel => l10n.groupFuel,
  ExpenseGroup.other => l10n.groupOther,
};

/// Short chart label ("Drugs" under the bar).
String _chartLabel(AppLocalizations l10n, ExpenseGroup g) =>
    g == ExpenseGroup.drugsVet ? l10n.groupDrugsShort : groupLabel(l10n, g);

IconData _groupIcon(ExpenseGroup g) => switch (g) {
  ExpenseGroup.feed => Symbols.grass_rounded,
  ExpenseGroup.drugsVet => Symbols.medication_rounded,
  ExpenseGroup.wages => Symbols.groups_rounded,
  ExpenseGroup.transport => Symbols.local_shipping_rounded,
  ExpenseGroup.fuel => Symbols.bolt_rounded,
  ExpenseGroup.other => Symbols.more_horiz_rounded,
};

FarmTapTone _groupTone(ExpenseGroup g) => switch (g) {
  ExpenseGroup.feed => FarmTapTone.gold,
  ExpenseGroup.drugsVet => FarmTapTone.danger,
  ExpenseGroup.wages => FarmTapTone.primary,
  ExpenseGroup.transport => FarmTapTone.info,
  ExpenseGroup.fuel => FarmTapTone.gold,
  ExpenseGroup.other => FarmTapTone.neutral,
};

void _comingSoon(BuildContext context) => FarmTapToast.show(context, message: AppLocalizations.of(context).comingSoon);

// ---------------------------------------------------------------- L01

class MoneyPage extends StatefulWidget {
  const new({required this.repo, required this.onAddExpense, super.key});

  final FarmMoneyRepository repo;

  /// Pushes L02; completes when it closes.
  final Future<void> Function() onAddExpense;

  @override
  State<MoneyPage> createState() => _MoneyPageState();
}

class _MoneyPageState extends State<MoneyPage> {
  late Future<MonthMoney?> _load = _fetch();

  Future<MonthMoney?> _fetch() async => (await widget.repo.month()).data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    return FutureBuilder<MonthMoney?>(
      future: _load,
      builder: (context, snapshot) {
        final m = snapshot.data;
        return AdaptiveScaffold(
          title: l10n.money,
          subtitle: m == null ? null : f.monthLong(m.month),
          actions: [
            BarAction(icon: Symbols.download_rounded, tooltip: l10n.exportLabel, onPressed: () => _comingSoon(context)),
          ],
          floatingActionButton: FarmTapFab(
            label: l10n.addExpense,
            icon: Symbols.add_rounded,
            onPressed: () async {
              await widget.onAddExpense();
              if (mounted) {
                setState(() {
                  _load = _fetch();
                });
              }
            },
          ),
          body: m == null ? const SizedBox.shrink() : _overview(context, l10n, f, m),
        );
      },
    );
  }

  Widget _overview(BuildContext context, AppLocalizations l10n, FarmTapFormat f, MonthMoney m) {
    // Chart order as on the mockup: biggest usual costs first.
    const order = [
      ExpenseGroup.feed,
      ExpenseGroup.wages,
      ExpenseGroup.drugsVet,
      ExpenseGroup.fuel,
      ExpenseGroup.transport,
      ExpenseGroup.other,
    ];
    final groups = [
      for (final g in order)
        if ((m.byGroup[g] ?? 0) > 0) g,
    ];
    final top = [...groups]..sort((a, b) => m.byGroup[b]!.compareTo(m.byGroup[a]!));
    int pct(ExpenseGroup g) => m.totalExpenses == 0 ? 0 : (m.byGroup[g]! * 100 / m.totalExpenses).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MetricStrip(
          children: [
            MetricCard(
              icon: Symbols.trending_up_rounded,
              label: l10n.incomeLabel,
              value: _short(f, m.income),
              caption: l10n.milkIncomeCaption(_short(f, m.milkIncome)),
              tone: FarmTapTone.success,
            ),
            MetricCard(
              icon: Symbols.trending_down_rounded,
              label: l10n.expensesLabel,
              value: _short(f, m.totalExpenses),
              caption: [for (final g in top.take(2)) l10n.expenseShare(groupLabel(l10n, g), pct(g))].join(' · '),
              tone: FarmTapTone.danger,
            ),
            MetricCard(
              icon: Symbols.account_balance_wallet_rounded,
              label: m.profit < 0 ? l10n.lossLabel : l10n.profitLabel,
              value: _short(f, m.profit),
              tone: m.profit < 0 ? FarmTapTone.danger : FarmTapTone.primary,
            ),
            MetricCard(
              icon: Symbols.water_drop_rounded,
              label: l10n.costPerLitre,
              value: m.costPerLitre == null ? '—' : f.money(m.costPerLitre!),
              tone: FarmTapTone.gold,
            ),
          ],
        ),
        context.space.gapLg,
        FarmTapCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CardHeader(title: l10n.expensesByCategory),
              context.space.gapMd,
              FarmTapBarChart(
                values: [for (final g in groups) m.byGroup[g]!.toDouble()],
                labels: [for (final g in groups) _chartLabel(l10n, g)],
                tones: [for (final g in groups) _groupTone(g)],
                showAxis: false,
                barWidth: context.sizes.touchTarget,
              ),
            ],
          ),
        ),
        context.space.gapLg,
        ListCard(
          title: l10n.latestLabel,
          children: [
            for (final e in m.expenses.take(5))
              RecordTile(
                leading: IconBubble(
                  icon: _groupIcon(e.category.group),
                  tone: _groupTone(e.category.group),
                  size: context.sizes.bubbleMd,
                ),
                title: e.note ?? groupLabel(l10n, e.category.group),
                subtitle: '${groupLabel(l10n, e.category.group)} · ${f.day(e.at)}',
                trailingValue: f.money(e.amount),
                showChevron: false,
              ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- L02

class AddExpensePage extends StatefulWidget {
  const new({
    required this.repo,
    required this.onSaved,
    super.key,
    this.initialGroup,
    this.initialAmount,
    this.initialNote,
  });

  final FarmMoneyRepository repo;
  final ValueChanged<Expense> onSaved;

  /// Goldens: the mockup's filled form.
  final ExpenseGroup? initialGroup;
  final String? initialAmount;
  final String? initialNote;

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  late ExpenseGroup? _group = widget.initialGroup;
  late final _amount = TextEditingController(text: widget.initialAmount);
  late final _note = TextEditingController(text: widget.initialNote);
  bool _edited = false;

  int get _value => int.tryParse(_amount.text.replaceAll(',', '')) ?? 0;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    final group = _group;
    if (group == null) {
      FarmTapToast.show(context, message: l10n.chooseCategory);
      return;
    }
    // Money: read back before saving.
    final ok = await showReadBack(
      context,
      leading: IconBubble(icon: _groupIcon(group), tone: _groupTone(group), size: context.sizes.bubbleXl),
      subject: groupLabel(l10n, group),
      valueText: f.money(_value),
      detail: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
    if (!ok || !mounted) return;
    final e = (await widget.repo.addExpense(
      group: group,
      amount: _value,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    )).data;
    if (e == null || !mounted) return;
    setState(() => _edited = false);
    FarmTapToast.show(context, message: l10n.expenseSaved(f.money(e.amount)));
    widget.onSaved(e);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DiscardGuard(
      dirty: _edited,
      child: AdaptiveScaffold(
        title: l10n.addExpense,
        showNavigation: false,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.categoryLabel, style: context.text.titleSmall),
            context.space.gapMd,
            ResponsiveGrid(
              minItemWidth: context.sizes.gridMetric,
              maxColumns: 3,
              spacing: context.space.md,
              children: [
                for (final g in const [
                  ExpenseGroup.feed,
                  ExpenseGroup.drugsVet,
                  ExpenseGroup.wages,
                  ExpenseGroup.transport,
                  ExpenseGroup.fuel,
                  ExpenseGroup.other,
                ])
                  ActionTile(
                    icon: _groupIcon(g),
                    label: groupLabel(l10n, g),
                    tone: _groupTone(g),
                    selected: _group == g,
                    onTap: () => setState(() {
                      _group = g;
                      _edited = true;
                    }),
                  ),
              ],
            ),
            context.space.gapLg,
            FarmTapTextField(
              label: l10n.amountLabel,
              prefixText: 'UGX ',
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9,]'))],
              onChanged: (_) => setState(() => _edited = true),
            ),
            context.space.gapLg,
            FarmTapTextField(
              label: l10n.noteLabel,
              icon: Symbols.edit_rounded,
              controller: _note,
              onChanged: (_) => setState(() => _edited = true),
            ),
            context.space.gapLg,
            ButtonPair(
              forceRow: true,
              first: FarmTapButton(
                label: l10n.receiptPhoto,
                icon: Symbols.photo_camera_rounded,
                kind: ButtonKind.outlined,
                onPressed: () => _comingSoon(context),
              ),
              second: FarmTapButton(
                label: l10n.save,
                icon: Symbols.check_rounded,
                onPressed: _value > 0 ? _save : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- L03

class ReportsPage extends StatefulWidget {
  const new({required this.money, required this.farmName, required this.onDaily, super.key, this.dailySendMinutes});

  final FarmMoneyRepository money;
  final String farmName;
  final VoidCallback onDaily;
  final int? dailySendMinutes;

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  late final Future<MonthMoney?> _load = _fetch();

  Future<MonthMoney?> _fetch() async => (await widget.money.month()).data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    RecordTile row(IconData icon, FarmTapTone tone, String title, String subtitle, VoidCallback onTap) => RecordTile(
      leading: IconBubble(icon: icon, tone: tone, size: context.sizes.bubbleMd),
      title: title,
      subtitle: subtitle,
      onTap: onTap,
    );
    final minutes = widget.dailySendMinutes ?? 19 * 60;
    final sendAt = DateTime(2000, 1, 1, minutes ~/ 60, minutes % 60);
    return AdaptiveScaffold(
      title: l10n.reports,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListCard(
            children: [
              row(
                Symbols.picture_as_pdf_rounded,
                FarmTapTone.danger,
                l10n.monthlyFarmReport,
                l10n.monthlyFarmReportSub,
                () => _comingSoon(context),
              ),
              row(
                Symbols.description_rounded,
                FarmTapTone.primary,
                l10n.milkRecordsReport,
                l10n.milkRecordsReportSub,
                () => _comingSoon(context),
              ),
              row(
                Symbols.receipt_long_rounded,
                FarmTapTone.gold,
                l10n.farmerStatements,
                l10n.farmerStatementsSub,
                () => _comingSoon(context),
              ),
              row(
                Symbols.medication_rounded,
                FarmTapTone.danger,
                l10n.treatmentsReport,
                l10n.treatmentsReportSub,
                () => _comingSoon(context),
              ),
              row(
                Symbols.download_rounded,
                FarmTapTone.neutral,
                l10n.exportAll,
                l10n.exportAllSub,
                () => _comingSoon(context),
              ),
              // Entry to L04 (not in the mockup; see PROGRESS gaps).
              row(
                Symbols.chat_rounded,
                FarmTapTone.success,
                l10n.dailyWhatsapp,
                l10n.dailyWhatsappSub(f.time(sendAt)),
                widget.onDaily,
              ),
            ],
          ),
          context.space.gapLg,
          FutureBuilder<MonthMoney?>(
            future: _load,
            builder: (context, snapshot) {
              final m = snapshot.data;
              if (m == null) return const FarmTapPageLoader();
              final month = '${f.monthLong(m.month)} ${m.month.year}';
              return FarmTapCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CardHeader(
                      title: l10n.previewReport(f.monthLong(m.month)),
                      trailing: FarmTapButton(
                        label: l10n.shareLabel,
                        icon: Symbols.share_rounded,
                        kind: ButtonKind.tonal,
                        expand: false,
                        onPressed: () => _comingSoon(context),
                      ),
                    ),
                    context.space.gapMd,
                    ReportPreviewCard(
                      title: l10n.reportTitle(widget.farmName, month),
                      rows: [
                        (l10n.milkProduced, '${f.count(m.litresProduced.round())} L'),
                        (l10n.milkSold, '${f.count(m.litresSold.round())} L'),
                        (l10n.incomeLabel, _short(f, m.income)),
                        (l10n.expensesLabel, _short(f, m.totalExpenses)),
                        (m.profit < 0 ? l10n.lossLabel : l10n.profitLabel, _short(f, m.profit)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- L04

class DailyReportPage extends StatefulWidget {
  const new({required this.repo, super.key});

  final DailyReportRepository repo;

  @override
  State<DailyReportPage> createState() => _DailyReportPageState();
}

class _DailyReportPageState extends State<DailyReportPage> {
  DailyReport? _report;
  DailyReportSettings? _settings;

  @override
  void initState() {
    super.initState();
    unawaited(_fetch());
  }

  Future<void> _fetch() async {
    final r = (await widget.repo.today()).data;
    final s = (await widget.repo.settings()).data;
    if (mounted) {
      setState(() {
        _report = r;
        _settings = s;
      });
    }
  }

  Future<void> _update(DailyReportSettings s) async {
    setState(() => _settings = s);
    await widget.repo.saveSettings(s);
  }

  Future<void> _pickTime(DailyReportSettings s) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: s.sendMinutes ~/ 60, minute: s.sendMinutes % 60),
    );
    if (picked != null) await _update(s.copyWith(sendMinutes: picked.hour * 60 + picked.minute));
  }

  String _message(AppLocalizations l10n, FarmTapFormat f, DailyReport r, DailyReportSettings s) => [
    '${r.farmName} — ${f.day(r.day)}',
    l10n.rpMilk(f.litresValue(r.milkLitres), '${r.milkTrendPercent >= 0 ? '+' : ''}${r.milkTrendPercent}%'),
    if (r.notForSaleLitres > 0) l10n.rpNotForSale(f.litresValue(r.notForSaleLitres), r.notForSaleAnimals),
    l10n.rpTreatmentsFeed(r.treatmentsToday, f.litresValue(r.dairyMealUsed)),
    l10n.rpWorkers(r.workersIn, r.workersTotal),
    for (final (item, n) in r.alerts) l10n.rpAlert(item, n),
    if (s.includeMoney) l10n.rpMoney(_short(f, r.moneyIn), _short(f, r.moneyOut)),
  ].join('\n');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    final r = _report;
    final s = _settings;
    final sendAt = s == null ? null : DateTime(2000, 1, 1, s.sendMinutes ~/ 60, s.sendMinutes % 60);
    return AdaptiveScaffold(
      title: l10n.dailyWhatsapp,
      body: r == null || s == null
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.sentToEveryDay(s.phone, f.time(sendAt!)),
                  style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                ),
                context.space.gapLg,
                FarmTapCard(
                  child: SmsPreviewBubble(
                    message: _message(l10n, f, r, s),
                    time: f.time(sendAt),
                    tone: FarmTapTone.success,
                  ),
                ),
                context.space.gapLg,
                ListCard(
                  children: [
                    RecordTile(
                      leading: IconBubble(icon: Symbols.schedule_rounded, size: context.sizes.bubbleMd),
                      title: l10n.sendTime,
                      subtitle: f.time(sendAt),
                      onTap: () => _pickTime(s),
                    ),
                    RecordTile(
                      leading: IconBubble(
                        icon: Symbols.payments_rounded,
                        tone: FarmTapTone.gold,
                        size: context.sizes.bubbleMd,
                      ),
                      title: l10n.includeMoney,
                      subtitle: l10n.includeMoneySub,
                      showChevron: false,
                      trailing: Switch(
                        value: s.includeMoney,
                        onChanged: (v) => _update(s.copyWith(includeMoney: v)),
                      ),
                      onTap: () => _update(s.copyWith(includeMoney: !s.includeMoney)),
                    ),
                    RecordTile(
                      leading: IconBubble(
                        icon: Symbols.sms_rounded,
                        tone: FarmTapTone.info,
                        size: context.sizes.bubbleMd,
                      ),
                      title: l10n.smsIfWhatsappFails,
                      showChevron: false,
                      trailing: Switch(
                        value: s.smsFallback,
                        onChanged: (v) => _update(s.copyWith(smsFallback: v)),
                      ),
                      onTap: () => _update(s.copyWith(smsFallback: !s.smsFallback)),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
