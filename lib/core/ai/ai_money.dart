// FarmTap AI engine: money (decision 0025). Every figure is a sum of the
// farm's own expenses, income and milk sales. Hand port of shared/aiMoney.ts.
import 'ai_core.dart';
import 'ai_data.dart';

const categoryName = <String, String>{
  'feed': 'Feed',
  'vet': 'Health and vet',
  'breeding': 'Breeding',
  'wages': 'Worker pay',
  'transport': 'Transport',
  'fuel': 'Fuel',
  'equipment': 'Equipment and repairs',
  'other': 'Other',
};

String catLabel(String c) =>
    categoryName[c] ??
    (c.isNotEmpty
        ? c[0].toUpperCase() + c.substring(1).replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[1]}').toLowerCase()
        : 'Other');

class CategoryAmount {
  const CategoryAmount(this.category, this.amount);
  final String category;
  final double amount;
}

class MonthMoney {
  const MonthMoney({
    required this.month,
    required this.spent,
    required this.milkSales,
    required this.otherIncome,
    required this.income,
    required this.net,
    required this.litres,
    required this.costPerLitre,
    required this.byCategory,
  });
  final String month;
  final double spent;
  final double milkSales;
  final double otherIncome;
  final double income;
  final double net;
  final double litres;
  final double? costPerLitre;
  final List<CategoryAmount> byCategory;
}

bool _inMonth(String? day, String month) => day != null && day.startsWith(month);

MonthMoney monthMoney(FarmData d, String month) {
  final exp = alive(d.expenses).where((e) => _inMonth(recDay(e, 'at'), month)).toList();
  final inc = alive(d.income).where((e) => _inMonth(recDay(e, 'at'), month)).toList();
  final sales = alive(d.milkSales).where((s) => _inMonth(recDay(s), month)).toList();
  final litres = sum(alive(d.milk).where((m) => _inMonth(recDay(m), month)).map((m) => num0(m.body['litres'])));
  final by = <String, double>{};
  for (final e in exp) {
    final c = (e.str('category')?.isNotEmpty ?? false) ? e.str('category')! : 'other';
    by[c] = (by[c] ?? 0) + num0(e.body['amount']);
  }
  final spent = sum(exp.map((e) => num0(e.body['amount'])));
  final milkSales = sum(sales.map((s) => num0(s.body['litres']) * num0(s.body['pricePerLitre'])));
  final otherIncome = sum(inc.map((e) => num0(e.body['amount'])));
  return MonthMoney(
    month: month,
    spent: jsRound(spent),
    milkSales: jsRound(milkSales),
    otherIncome: jsRound(otherIncome),
    income: jsRound(milkSales + otherIncome),
    net: jsRound(milkSales + otherIncome - spent),
    litres: jsRound(litres * 10) / 10,
    costPerLitre: litres > 0 && spent > 0 ? jsRound(spent / litres) : null,
    byCategory: stableSort([
      for (final e in by.entries) CategoryAmount(e.key, jsRound(e.value)),
    ], (a, b) => b.amount.compareTo(a.amount)),
  );
}

/// This month and the [n]-1 before it, newest first.
List<MonthMoney> monthsBack(FarmData d, int n) {
  final m = today(d).substring(0, 7);
  return List.generate(n, (i) => monthMoney(d, addMonths(m, -i)));
}

bool hasRecords(MonthMoney m) => m.spent > 0 || m.income > 0;

class CashForecast {
  const CashForecast({
    required this.ok,
    this.reason,
    required this.month,
    required this.income,
    required this.spent,
    required this.net,
    required this.monthsUsed,
    required this.method,
  });
  final bool ok;
  final String? reason;
  final String month;
  final double income;
  final double spent;
  final double net;
  final int monthsUsed;
  final String method;
}

String _fmtList(List<String> xs) =>
    xs.length <= 1 ? xs.join() : '${xs.sublist(0, xs.length - 1).join(', ')} and ${xs.last}';

/// Next month: the average of the last 3 full months that have records (at least 2 needed).
CashForecast cashForecast(FarmData d) {
  final next = addMonths(today(d).substring(0, 7), 1);
  final full = monthsBack(d, 4).sublist(1).where(hasRecords).toList();
  const baseMethod = 'Average of the last full months with records';
  if (full.length < 2) {
    return CashForecast(
      ok: false,
      reason:
          'Needs at least 2 full months of money records; there ${full.length == 1 ? 'is 1' : 'are ${full.length}'}.',
      month: next,
      income: 0,
      spent: 0,
      net: 0,
      monthsUsed: full.length,
      method: baseMethod,
    );
  }
  final income = jsRound(mean(full.map((m) => m.income).toList()));
  final spent = jsRound(mean(full.map((m) => m.spent).toList()));
  return CashForecast(
    ok: true,
    month: next,
    income: income,
    spent: spent,
    net: income - spent,
    monthsUsed: full.length,
    method: 'Average of ${_fmtList(full.map((m) => fmtMonth(m.month)).toList())}',
  );
}

class Unusual {
  const Unusual(this.id, this.category, this.amount, this.usual, this.at);
  final String id;
  final String category;
  final double amount;
  final double usual;
  final String at;
}

/// Single expenses at least 3 times the usual size for their category (needs 5 earlier ones).
List<Unusual> unusualExpenses(FarmData d) {
  final day = today(d);
  final from = '${addMonths(day.substring(0, 7), -1)}-01';
  final exp = alive(d.expenses);
  final out = <Unusual>[];
  for (final e in exp) {
    final at = recDay(e, 'at') ?? '';
    if (at.compareTo(from) < 0 || at.compareTo(day) > 0) continue;
    final prior = exp
        .where(
          (o) => o.id != e.id && o.body['category'] == e.body['category'] && (recDay(o, 'at') ?? '').compareTo(at) < 0,
        )
        .map((o) => num0(o.body['amount']))
        .toList();
    if (prior.length < 5) continue;
    final usual = median(prior);
    final amt = num0(e.body['amount']);
    if (usual > 0 && amt >= usual * 3 && amt - usual >= 20000) {
      out.add(Unusual(e.id, '${e.body['category']}', amt, jsRound(usual), at));
    }
  }
  return stableSort(out, (a, b) => b.amount.compareTo(a.amount));
}

List<Finding> financeFindings(FarmData d) {
  final out = <Finding>[];
  final day = today(d);
  final ms = monthsBack(d, 5);
  final cur = ms[0];
  final prev = ms[1];
  final older = ms.sublist(2);
  for (final u in unusualExpenses(d)) {
    out.add(
      Finding(
        id: 'spend-unusual-${u.id}',
        module: 'finance',
        severity: u.amount >= u.usual * 6 ? Severity.high : Severity.medium,
        title: 'Large ${catLabel(u.category).toLowerCase()} expense: ${fmtUgx(u.amount)}',
        why:
            'Recorded ${u.at}. A usual ${catLabel(u.category).toLowerCase()} expense on this farm is about ${fmtUgx(u.usual)}.',
        action: 'Check the amount is right and that there is a receipt.',
        method: Method.statistical,
        links: const [Link('Money', '/money/')],
        subjects: [u.id],
      ),
    );
  }
  final dom = int.parse(day.substring(8, 10));
  if (dom >= 10) {
    final full = [...older, prev].where(hasRecords).toList();
    if (full.length >= 2) {
      for (final c in cur.byCategory) {
        final avg = mean(
          full.map((m) {
            for (final x in m.byCategory) {
              if (x.category == c.category) return x.amount;
            }
            return 0.0;
          }).toList(),
        );
        if (avg > 0 && c.amount >= avg * 1.5 && c.amount - avg >= 50000) {
          out.add(
            Finding(
              id: 'spend-category-${c.category}-${cur.month}',
              module: 'finance',
              severity: c.amount >= avg * 2.5 ? Severity.high : Severity.medium,
              title:
                  '${catLabel(c.category)} spending is ${jsRound((c.amount / avg) * 100 - 100).toInt()}% above usual',
              why:
                  '${fmtUgx(c.amount)} so far in ${fmtMonth(cur.month)}, against an average of ${fmtUgx(avg)} a month before.',
              action: 'Look at this month’s expenses in this category for anything unexpected.',
              method: Method.calculated,
              links: const [Link('Money', '/money/')],
            ),
          );
        }
      }
    }
  }
  if (hasRecords(prev) && prev.net < 0) {
    out.add(
      Finding(
        id: 'month-loss-${prev.month}',
        module: 'finance',
        severity: Severity.high,
        title: '${fmtMonth(prev.month)} ended with a loss of ${fmtUgx(-prev.net)}',
        why: 'Spent ${fmtUgx(prev.spent)}; milk sales and other income ${fmtUgx(prev.income)}.',
        action:
            'Biggest cost: ${prev.byCategory.isNotEmpty ? '${catLabel(prev.byCategory[0].category)} (${fmtUgx(prev.byCategory[0].amount)})' : 'none recorded'}. Check that all milk sales were recorded.',
        method: Method.calculated,
        links: const [Link('Reports', '/reports/')],
      ),
    );
  }
  if (prev.costPerLitre != null && older.isNotEmpty && older[0].costPerLitre != null) {
    final ch = pctChange(prev.costPerLitre!, older[0].costPerLitre!);
    if (ch != null && ch >= 20) {
      out.add(
        Finding(
          id: 'cost-litre-up-${prev.month}',
          module: 'finance',
          severity: Severity.medium,
          title: 'Cost per litre rose $ch%',
          why:
              '${fmtUgx(prev.costPerLitre!)} a litre in ${fmtMonth(prev.month)} (${fmtL(prev.litres)}), against ${fmtUgx(older[0].costPerLitre!)} in ${fmtMonth(older[0].month)}.',
          action: 'Compare feed and wages with the milk they produce.',
          method: Method.calculated,
          links: const [Link('Reports', '/reports/')],
        ),
      );
    }
  }
  return out;
}
