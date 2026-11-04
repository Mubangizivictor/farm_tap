// L03 reports, made on the phone from the farm's records (works offline):
// the monthly farm report, milk records, farmer statements, treatments,
// and "export all" (every list as a spreadsheet).
import 'package:farm_tap/core/export/table_export.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/money/domain/money_models.dart';
import 'package:farm_tap/core/utils/formats.dart';
import 'package:farm_tap/sectors/cattle/collection_centre/domain/centre_models.dart';
import 'package:farm_tap/sectors/cattle/collection_centre/domain/centre_repository.dart';
import 'package:farm_tap/sectors/cattle/health/domain/health_models.dart';
import 'package:farm_tap/sectors/cattle/health/domain/health_repository.dart';
import 'package:farm_tap/sectors/cattle/health/presentation/pages/health_pages.dart';
import 'package:farm_tap/sectors/cattle/milk/domain/milk_models.dart';
import 'package:farm_tap/sectors/cattle/milk/domain/milk_repository.dart';
import 'package:farm_tap/sectors/cattle/money/domain/farm_money_models.dart';
import 'package:farm_tap/sectors/cattle/money/domain/farm_money_repository.dart';
import 'package:farm_tap/sectors/cattle/money/presentation/pages/money_pages.dart';

class FarmReports {
  const new({required this.money, required this.milk, required this.treatments, this.centre});

  final FarmMoneyRepository money;
  final MilkRepository milk;
  final TreatmentRepository treatments;

  /// Collection centres: farmer statements.
  final CentreRepository? centre;

  static DateTime _end(DateTime month) => DateTime(month.year, month.month + 1);

  String _monthName(FarmTapFormat f, DateTime m) => '${f.monthLong(m)} ${m.year}';

  ExportTable expensesTable(AppLocalizations l10n, FarmTapFormat f, MonthMoney m) => ExportTable(
    title: l10n.expensesLabel,
    headers: [l10n.colDate, l10n.categoryLabel, l10n.noteLabel, l10n.colAmount],
    rows: [
      for (final e in m.expenses) [f.day(e.at), groupLabel(l10n, e.category.group), e.note ?? '', f.count(e.amount)],
    ],
    footer: [
      [l10n.total, f.money(m.totalExpenses)],
    ],
  );

  ExportTable incomeTable(AppLocalizations l10n, FarmTapFormat f, MonthMoney m, List<MilkSale> sales) => ExportTable(
    title: l10n.incomeLabel,
    headers: [l10n.colDate, l10n.categoryLabel, l10n.noteLabel, l10n.colAmount],
    rows: [
      for (final x in sales)
        [
          if (x.at == null) '' else f.day(x.at!),
          l10n.milkSales,
          '${x.buyer} · ${f.litres(x.litres)}${x.paid ? '' : ' · ${l10n.unpaid}'}',
          f.count(x.amount),
        ],
      for (final i in m.otherIncome) [f.day(i.at), incomeSourceLabel(l10n, i.source), i.note ?? '', f.count(i.amount)],
    ],
    footer: [
      [l10n.total, f.money(m.income)],
    ],
  );

  /// Milk per day: morning, evening, total.
  Future<ExportTable> milkTable(AppLocalizations l10n, FarmTapFormat f, DateTime month) async {
    final end = _end(month);
    final records = [
      for (final r in (await milk.records(from: month)).data ?? const <MilkRecord>[])
        if (r.at.isBefore(end)) r,
    ];
    final byDay = <DateTime, (double, double)>{};
    for (final r in records) {
      final d = DateTime(r.at.year, r.at.month, r.at.day);
      final (am, pm) = byDay[d] ?? (0.0, 0.0);
      byDay[d] = r.session == MilkSession.morning ? (am + r.litres, pm) : (am, pm + r.litres);
    }
    final days = byDay.keys.toList()..sort();
    final total = records.fold<double>(0, (s, r) => s + r.litres);
    return ExportTable(
      title: l10n.milkRecordsReport,
      subtitle: _monthName(f, month),
      headers: [l10n.colDate, l10n.morning, l10n.evening, l10n.total],
      rows: [
        for (final d in days)
          [
            f.day(d),
            f.litresValue(byDay[d]!.$1),
            f.litresValue(byDay[d]!.$2),
            f.litresValue(byDay[d]!.$1 + byDay[d]!.$2),
          ],
      ],
      footer: [
        [l10n.total, f.litres(total)],
        if (days.isNotEmpty) [l10n.averagePerDayLabel, f.litres(total / days.length)],
      ],
    );
  }

  Future<ExportTable> treatmentsTable(AppLocalizations l10n, FarmTapFormat f, DateTime month) async {
    final end = _end(month);
    final list = [
      for (final t in (await treatments.treatments()).data ?? const <TreatmentRecord>[])
        if (!t.given.isBefore(month) && t.given.isBefore(end)) t,
    ]..sort((a, b) => a.given.compareTo(b.given));
    return ExportTable(
      title: l10n.treatmentsReport,
      subtitle: _monthName(f, month),
      headers: [
        l10n.colDate,
        l10n.animalTitle,
        l10n.conditionLabel,
        l10n.drugLabel,
        l10n.givenByLabel,
        l10n.milkSafeFrom,
      ],
      rows: [
        for (final t in list)
          [
            f.day(t.given),
            '${t.animalName} (${t.tag})',
            conditionLabel(l10n, t.condition),
            [t.drug.name, if ((t.dose ?? '').isNotEmpty) t.dose!].join(' · '),
            t.givenBy ?? '',
            f.day(t.safeFrom),
          ],
      ],
    );
  }

  /// One row per supplying farmer for the pay period.
  Future<ExportTable> statementsTable(AppLocalizations l10n, FarmTapFormat f) async {
    final period = (await centre?.payments())?.data;
    return ExportTable(
      title: l10n.farmerStatements,
      subtitle: period == null ? null : f.period(period.start, period.end),
      headers: [
        l10n.name,
        l10n.cardLabel,
        l10n.phone,
        l10n.colLitres,
        l10n.grossLabel,
        l10n.deductionsLabel,
        l10n.netLabel,
      ],
      rows: [
        for (final line in period?.lines ?? const <PaymentLine>[])
          [
            line.farmer.name,
            line.farmer.card ?? '',
            line.farmer.phone,
            f.litresValue(line.litres),
            f.count(line.gross.round()),
            f.count(line.deductions.round()),
            f.count(line.net.round()),
          ],
      ],
      footer: [
        if (period != null) [l10n.total, f.money(period.amount.round())],
      ],
    );
  }

  /// G06: every supplier with this period's litres and what is owed.
  Future<ExportTable> farmersTable(AppLocalizations l10n, FarmTapFormat f) async {
    final farmers = (await centre?.farmers())?.data ?? const <CentreFarmer>[];
    return ExportTable(
      title: l10n.farmers,
      headers: [l10n.name, l10n.cardLabel, l10n.phone, l10n.villageLabel, l10n.colThisPeriod, l10n.colOwed],
      rows: [
        for (final x in farmers)
          [x.name, x.card ?? '', x.phone, x.village, f.litresValue(x.periodLitres), f.count(x.owed.round())],
      ],
    );
  }

  /// The monthly farm report: summary, income, expenses, milk, treatments.
  Future<ExportReport> monthly(AppLocalizations l10n, FarmTapFormat f, {DateTime? month}) async {
    final m = (await money.month(month: month)).data!;
    final end = _end(m.month);
    final sales = [
      for (final x in (await milk.salesSince(m.month)).data ?? const <MilkSale>[])
        if (x.at == null || x.at!.isBefore(end)) x,
    ];
    return ExportReport(
      title: '${l10n.monthlyFarmReport} · ${_monthName(f, m.month)}',
      summary: [
        (l10n.milkProduced, f.litres(m.litresProduced)),
        (l10n.milkSold, f.litres(m.litresSold)),
        (l10n.incomeLabel, f.money(m.income)),
        (l10n.expensesLabel, f.money(m.totalExpenses)),
        (m.profit < 0 ? l10n.lossLabel : l10n.profitLabel, f.money(m.profit)),
        if (m.costPerLitre != null) (l10n.costPerLitre, f.money(m.costPerLitre!)),
      ],
      tables: [
        incomeTable(l10n, f, m, sales),
        expensesTable(l10n, f, m),
        await milkTable(l10n, f, m.month),
        await treatmentsTable(l10n, f, m.month),
      ],
    );
  }

  /// Every list of the month, for a spreadsheet.
  Future<ExportReport> all(AppLocalizations l10n, FarmTapFormat f, {DateTime? month}) async {
    final r = await monthly(l10n, f, month: month);
    return ExportReport(
      title: l10n.exportAll,
      summary: r.summary,
      tables: [...r.tables, if (centre != null) await statementsTable(l10n, f)],
    );
  }
}

String incomeSourceLabel(AppLocalizations l10n, IncomeSource s) => switch (s) {
  IncomeSource.animalSale => l10n.incomeAnimalSale,
  IncomeSource.calfSale => l10n.incomeCalfSale,
  IncomeSource.manure => l10n.incomeManure,
  IncomeSource.hire => l10n.incomeHire,
  IncomeSource.other => l10n.groupOther,
};
