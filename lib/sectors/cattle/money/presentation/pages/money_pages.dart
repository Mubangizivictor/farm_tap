// Money & reports: L01 money overview, L02 add expense, L03 reports, L04
// daily WhatsApp report. Every number is read from core/money (expenses),
// the milk records and sales (litres, income) and the other features.
import 'dart:async';

import 'package:farm_tap/core/export/table_export.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/money/domain/money_models.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/core/utils/formats.dart';
import 'package:farm_tap/sectors/cattle/money/domain/farm_money_models.dart';
import 'package:farm_tap/sectors/cattle/money/domain/farm_money_repository.dart';
import 'package:farm_tap/sectors/cattle/owner_reports/domain/daily_report.dart';
import 'package:farm_tap/sectors/cattle/owner_reports/presentation/farm_reports.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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

// ---------------------------------------------------------------- L01

class MoneyPage extends StatefulWidget {
  const new({required this.repo, required this.onAddExpense, super.key, this.reports, this.farmName = ''});

  final FarmMoneyRepository repo;

  /// Pushes L02; completes when it closes.
  final Future<void> Function() onAddExpense;

  /// Export: the month's income and expenses.
  final FarmReports? reports;
  final String farmName;

  @override
  State<MoneyPage> createState() => _MoneyPageState();
}

class _MoneyPageState extends State<MoneyPage> {
  /// The month shown (null = this month).
  DateTime? _month;
  late Future<MonthMoney?> _load = _fetch();

  Future<MonthMoney?> _fetch() async => (await widget.repo.month(month: _month)).data;

  void _reload() => setState(() => _load = _fetch());

  void _shift(MonthMoney m, int by) {
    final now = context.clock.now();
    final next = DateTime(m.month.year, m.month.month + by);
    _month = next.year == now.year && next.month == now.month ? null : next;
    _reload();
  }

  Future<void> _export(MonthMoney m) async {
    final reports = widget.reports;
    if (reports == null) return;
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    final r = await reports.monthly(l10n, f, month: m.month);
    if (!mounted) return;
    await exportReport(context, r, farmName: widget.farmName);
  }

  Future<void> _addIncome() async {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    final saved = await showAdaptiveSheet<Income>(context, builder: (_) => _AddIncomeSheet(repo: widget.repo));
    if (saved == null || !mounted) return;
    FarmTapToast.show(context, message: l10n.incomeSaved(f.money(saved.amount)));
    _reload();
  }

  Future<void> _openExpense(Expense e) async {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    final remove = await showAdaptiveSheet<bool>(
      context,
      builder: (sheet) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetTitle(e.note ?? groupLabel(l10n, e.category.group), subtitle: f.day(e.at)),
          sheet.space.gapMd,
          SummaryRow(label: l10n.categoryLabel, value: groupLabel(l10n, e.category.group)),
          SummaryRow(label: l10n.amountLabel, value: f.money(e.amount), emphasis: true),
          if (e.photo != null) ...[
            sheet.space.gapMd,
            ClipRRect(
              borderRadius: sheet.radii.card,
              child: SizedBox(
                height: sheet.sizes.photoPreview,
                child: StoredPhoto(
                  photoKey: e.photo!,
                  placeholder: const IconBubble(icon: Symbols.receipt_long_rounded),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
          sheet.space.gapLg,
          if (e.sourceId == null)
            FarmTapButton(
              label: l10n.deleteExpense,
              icon: Symbols.delete_rounded,
              kind: ButtonKind.danger,
              onPressed: () => Navigator.of(sheet).pop(true),
            )
          else
            Text(l10n.fromFeedPurchase, style: sheet.text.bodySmall),
        ],
      ),
    );
    if (remove != true || !mounted) return;
    final sure = await showFarmTapDialog(
      context,
      icon: Symbols.delete_rounded,
      title: l10n.deleteExpense,
      message: l10n.deleteExpenseBody,
      primaryLabel: l10n.deleteExpense,
      primaryKind: ButtonKind.danger,
      secondaryLabel: l10n.cancel,
    );
    if (!sure || !mounted) return;
    await widget.repo.deleteExpense(e.id);
    if (!mounted) return;
    FarmTapToast.show(context, message: l10n.expenseDeleted);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    return FutureBuilder<MonthMoney?>(
      future: _load,
      builder: (context, snapshot) {
        final m = snapshot.data;
        final thisMonth = _month == null;
        return AdaptiveScaffold(
          title: l10n.money,
          subtitle: m == null ? null : '${f.monthLong(m.month)} ${m.month.year}',
          actions: [
            BarAction(
              icon: Symbols.chevron_left_rounded,
              tooltip: l10n.previousMonth,
              onPressed: m == null ? null : () => _shift(m, -1),
            ),
            if (!thisMonth)
              BarAction(
                icon: Symbols.chevron_right_rounded,
                tooltip: l10n.nextMonth,
                onPressed: m == null ? null : () => _shift(m, 1),
              ),
            BarAction(icon: Symbols.add_card_rounded, tooltip: l10n.addIncome, onPressed: _addIncome),
            BarAction(
              icon: Symbols.download_rounded,
              tooltip: l10n.exportLabel,
              onPressed: m == null || widget.reports == null ? null : () => _export(m),
            ),
          ],
          floatingActionButton: FarmTapFab(
            label: l10n.addExpense,
            icon: Symbols.add_rounded,
            onPressed: () async {
              await widget.onAddExpense();
              if (mounted) _reload();
            },
          ),
          body: m == null ? const FarmTapPageLoader() : _overview(context, l10n, f, m),
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
              caption: m.otherIncome.isEmpty
                  ? l10n.milkIncomeCaption(_short(f, m.milkIncome))
                  : '${l10n.milkIncomeCaption(_short(f, m.milkIncome))} · '
                        '${l10n.otherIncomeCaption(_short(f, m.otherIncomeTotal))}',
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
        if (m.expenses.isEmpty && m.income == 0) ...[
          context.space.gapLg,
          EmptyState(title: l10n.noExpensesYet, message: l10n.noExpensesYetBody),
        ],
        if (groups.isNotEmpty) ...[
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
        ],
        if (m.otherIncome.isNotEmpty) ...[
          context.space.gapLg,
          ListCard(
            title: l10n.incomeLabel,
            children: [
              for (final i in m.otherIncome)
                RecordTile(
                  leading: IconBubble(
                    icon: Symbols.add_card_rounded,
                    tone: FarmTapTone.success,
                    size: context.sizes.bubbleMd,
                  ),
                  title: i.note == null || i.note!.isEmpty ? incomeSourceLabel(l10n, i.source) : i.note!,
                  subtitle: '${incomeSourceLabel(l10n, i.source)} · ${f.day(i.at)}',
                  trailingValue: f.money(i.amount),
                  showChevron: false,
                ),
            ],
          ),
        ],
        if (m.expenses.isNotEmpty) ...[
          context.space.gapLg,
          ListCard(
            title: l10n.expensesLabel,
            children: [
              for (final e in m.expenses)
                RecordTile(
                  leading: IconBubble(
                    icon: e.photo == null ? _groupIcon(e.category.group) : Symbols.receipt_long_rounded,
                    tone: _groupTone(e.category.group),
                    size: context.sizes.bubbleMd,
                  ),
                  title: e.note ?? groupLabel(l10n, e.category.group),
                  subtitle: '${groupLabel(l10n, e.category.group)} · ${f.day(e.at)}',
                  trailingValue: f.money(e.amount),
                  onTap: () => _openExpense(e),
                ),
            ],
          ),
        ],
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
  String? _photo;

  /// A past day (null = now): expenses are often written down later.
  DateTime? _day;

  Future<void> _pickDay() async {
    final now = context.clock.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _day ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (picked != null) setState(() => _day = picked);
  }

  Future<void> _takePhoto() async {
    final key = await pickPhoto(context, canRemove: _photo != null);
    if (key == null || !mounted) return;
    setState(() {
      _photo = key.isEmpty ? null : key;
      _edited = true;
    });
  }

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
    final day = _day;
    final now = context.clock.now();
    final e = (await widget.repo.addExpense(
      group: group,
      amount: _value,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      at: day == null ? null : DateTime(day.year, day.month, day.day, now.hour, now.minute),
      photo: _photo,
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
            RecordTile(
              leading: IconBubble(icon: Symbols.calendar_month_rounded, size: context.sizes.bubbleMd),
              title: l10n.dateLabel,
              subtitle: _day == null ? l10n.today : _fmt(context).day(_day!),
              onTap: _pickDay,
            ),
            if (_photo != null) ...[
              context.space.gapMd,
              ClipRRect(
                borderRadius: context.radii.card,
                child: SizedBox(
                  height: context.sizes.photoPreview,
                  child: StoredPhoto(
                    photoKey: _photo!,
                    placeholder: const IconBubble(icon: Symbols.receipt_long_rounded),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
            context.space.gapLg,
            ButtonPair(
              forceRow: true,
              first: FarmTapButton(
                label: _photo == null ? l10n.receiptPhoto : l10n.changePhoto,
                icon: Symbols.photo_camera_rounded,
                kind: ButtonKind.outlined,
                onPressed: _takePhoto,
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

/// "Add income": money in that is not a milk sale (an animal, manure).
class _AddIncomeSheet extends StatefulWidget {
  const new({required this.repo});

  final FarmMoneyRepository repo;

  @override
  State<_AddIncomeSheet> createState() => _AddIncomeSheetState();
}

class _AddIncomeSheetState extends State<_AddIncomeSheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  IncomeSource _source = IncomeSource.calfSale;
  bool _tried = false;
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  int get _value => int.tryParse(_amount.text.replaceAll(RegExp('[^0-9]'), '')) ?? 0;

  Future<void> _save() async {
    setState(() => _tried = true);
    if (_value <= 0 || _saving) return;
    setState(() => _saving = true);
    final note = _note.text.trim();
    final r = await widget.repo.addIncome(source: _source, amount: _value, note: note.isEmpty ? null : note);
    if (mounted) Navigator.of(context).pop(r.data);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetTitle(l10n.addIncome),
        context.space.gapMd,
        FarmTapSelectField<IncomeSource>(
          label: l10n.sourceLabel,
          icon: Symbols.add_card_rounded,
          options: IncomeSource.values,
          labelOf: (s) => incomeSourceLabel(l10n, s),
          value: _source,
          onChanged: (s) => setState(() => _source = s),
        ),
        context.space.gapMd,
        FarmTapTextField(
          label: l10n.amountLabel,
          prefixText: 'UGX ',
          controller: _amount,
          keyboardType: TextInputType.number,
          error: _tried && _value <= 0 ? l10n.enterPrice : null,
          onChanged: (_) => setState(() {}),
        ),
        context.space.gapMd,
        FarmTapTextField(label: l10n.noteLabel, icon: Symbols.edit_rounded, controller: _note),
        context.space.gapLg,
        FarmTapButton(label: l10n.save, icon: Symbols.check_rounded, loading: _saving, onPressed: _save),
      ],
    );
  }
}

// ---------------------------------------------------------------- L03

class ReportsPage extends StatefulWidget {
  const new({
    required this.money,
    required this.farmName,
    required this.onDaily,
    super.key,
    this.dailySendMinutes,
    this.reports,
  });

  final FarmMoneyRepository money;
  final String farmName;
  final VoidCallback onDaily;
  final int? dailySendMinutes;

  /// Builds the PDFs and spreadsheets (null in goldens).
  final FarmReports? reports;

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  late final Future<MonthMoney?> _load = _fetch();

  Future<MonthMoney?> _fetch() async => (await widget.money.month()).data;

  bool _busy = false;

  /// Builds one report and opens the share sheet.
  Future<void> _make(Future<ExportReport> Function(FarmReports r) build, {bool pdfOnly = false}) async {
    final reports = widget.reports;
    if (reports == null || _busy) return;
    setState(() => _busy = true);
    FarmTapToast.show(context, message: AppLocalizations.of(context).makingReport, playSound: false);
    try {
      final report = await build(reports);
      if (!mounted) return;
      await exportReport(context, report, farmName: widget.farmName, pdfOnly: pdfOnly);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  ExportReport _one(ExportTable t) => ExportReport(title: t.title, subtitle: t.subtitle, tables: [t], single: true);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    final now = context.clock.now();
    final month = DateTime(now.year, now.month);
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
                () => _make((r) => r.monthly(l10n, f), pdfOnly: true),
              ),
              row(
                Symbols.description_rounded,
                FarmTapTone.primary,
                l10n.milkRecordsReport,
                l10n.milkRecordsReportSub,
                () => _make((r) async => _one(await r.milkTable(l10n, f, month))),
              ),
              row(
                Symbols.receipt_long_rounded,
                FarmTapTone.gold,
                l10n.farmerStatements,
                l10n.farmerStatementsSub,
                () => _make((r) async => _one(await r.statementsTable(l10n, f))),
              ),
              row(
                Symbols.medication_rounded,
                FarmTapTone.danger,
                l10n.treatmentsReport,
                l10n.treatmentsReportSub,
                () => _make((r) async => _one(await r.treatmentsTable(l10n, f, month))),
              ),
              row(
                Symbols.download_rounded,
                FarmTapTone.neutral,
                l10n.exportAll,
                l10n.exportAllSub,
                () => _make((r) => r.all(l10n, f)),
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
                        onPressed: () => _make((r) => r.monthly(l10n, f), pdfOnly: true),
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

  Future<void> _editPhone(DailyReportSettings s) async {
    final l10n = AppLocalizations.of(context);
    final phone = await showAdaptiveSheet<String>(context, builder: (_) => _PhoneSheet(initial: s.phone));
    if (phone == null || !mounted) return;
    await _update(s.copyWith(phone: phone));
    if (mounted) FarmTapToast.show(context, message: l10n.saved);
  }

  /// Opens WhatsApp with today's report typed in; the owner taps Send.
  /// Free: no SMS or WhatsApp provider is needed for this.
  Future<void> _sendNow(String message, DailyReportSettings s) async {
    final digits = s.phone.replaceAll(RegExp('[^0-9]'), '');
    final to = digits.startsWith('0') ? '256${digits.substring(1)}' : digits;
    final uri = Uri.parse('https://wa.me/$to?text=${Uri.encodeComponent(message)}');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      await SharePlus.instance.share(ShareParams(text: message));
    }
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
                  s.phone.isEmpty ? l10n.setWhatsappNumber : l10n.sentToEveryDay(s.phone, f.time(sendAt!)),
                  style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                ),
                context.space.gapLg,
                FarmTapCard(
                  child: SmsPreviewBubble(
                    message: _message(l10n, f, r, s),
                    time: f.time(sendAt!),
                    tone: FarmTapTone.success,
                  ),
                ),
                context.space.gapMd,
                FarmTapButton(
                  label: l10n.sendNowWhatsapp,
                  icon: Symbols.send_rounded,
                  onPressed: () => _sendNow(_message(l10n, f, r, s), s),
                ),
                context.space.gapLg,
                ListCard(
                  children: [
                    RecordTile(
                      leading: IconBubble(
                        icon: Symbols.chat_rounded,
                        tone: FarmTapTone.success,
                        size: context.sizes.bubbleMd,
                      ),
                      title: l10n.whatsappNumber,
                      subtitle: s.phone.isEmpty ? l10n.notSetYet : s.phone,
                      onTap: () => _editPhone(s),
                    ),
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

class _PhoneSheet extends StatefulWidget {
  const new({required this.initial});

  final String initial;

  @override
  State<_PhoneSheet> createState() => _PhoneSheetState();
}

class _PhoneSheetState extends State<_PhoneSheet> {
  late final _phone = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetTitle(l10n.whatsappNumber),
        context.space.gapLg,
        FarmTapTextField(
          label: l10n.phone,
          icon: Symbols.chat_rounded,
          controller: _phone,
          keyboardType: TextInputType.phone,
          autofocus: true,
        ),
        context.space.gapLg,
        FarmTapButton(
          label: l10n.save,
          icon: Symbols.check_rounded,
          onPressed: () => Navigator.of(context).pop(_phone.text.trim()),
        ),
      ],
    );
  }
}
