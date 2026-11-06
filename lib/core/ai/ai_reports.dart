// FarmTap AI engine: Smart Farm Reports (decision 0025). A request in the
// farmer's own words picks a report and a period; the report is a table made
// only from the farm's records. Hand port of shared/aiReports.ts.
import 'package:farm_tap/core/ai/ai_access.dart';
import 'package:farm_tap/core/ai/ai_assistant.dart';
import 'package:farm_tap/core/ai/ai_core.dart';
import 'package:farm_tap/core/ai/ai_data.dart';
import 'package:farm_tap/core/ai/ai_herd.dart';
import 'package:farm_tap/core/ai/ai_milk.dart';
import 'package:farm_tap/core/ai/ai_money.dart';
import 'package:farm_tap/core/ai/ai_stock.dart';

class ReportKindInfo {
  const new(this.key, this.label, this.words, this.money);
  final String key;
  final String label;
  final RegExp words;
  final bool money;
}

final reportKinds = <ReportKindInfo>[
  ReportKindInfo(
    'overall',
    'Overall farm performance',
    RegExp('overall|performance|summary|everything|whole farm|general'),
    false,
  ),
  ReportKindInfo('milk', 'Milk production', RegExp('milk|production|litre|yield'), false),
  ReportKindInfo('health', 'Animal health', RegExp('health|treat|sick|vaccin|disease'), false),
  ReportKindInfo('profit', 'Farm profitability', RegExp('profit|loss|income|revenue|money|financ'), true),
  ReportKindInfo('expenses', 'Farm expenses', RegExp('expens|spend|spent|cost'), true),
  ReportKindInfo('feed', 'Feed consumption', RegExp('feed|silage|hay|fodder'), false),
  ReportKindInfo('breeding', 'Breeding performance', RegExp('breed|calv|pregnan|heat|insemina'), false),
  ReportKindInfo('quality', 'Milk quality', RegExp('quality|reject|test|expir|batch|cool|temperat'), false),
  ReportKindInfo('inventory', 'Inventory', RegExp('inventor|stock|store|drug'), false),
];

ReportKindInfo _info(String key) => reportKinds.firstWhere((r) => r.key == key);

class Report {
  const new({
    required this.kind,
    required this.title,
    required this.period,
    required this.summary,
    required this.columns,
    required this.rows,
  });
  final String kind;
  final String title;
  final Period period;
  final List<String> summary;
  final List<String> columns;

  /// Cells are String or num.
  final List<List<Object>> rows;
}

/// A table cell as text.
String cellText(Object c) => c is num ? jsNum(c) : '$c';

/// Which report and period a request asks for; null when no report matches.
({String kind, Period period})? parseReportRequest(String text, String day, String role) {
  final q = text.toLowerCase();
  const order = ['quality', 'expenses', 'profit', 'feed', 'breeding', 'health', 'inventory', 'milk', 'overall'];
  String? k;
  for (final key in order) {
    final r = _info(key);
    if (r.words.hasMatch(q) && (!r.money || seesMoney(role))) {
      k = key;
      break;
    }
  }
  if (k == null) return null;
  return (kind: k, period: periodOf(q, day, 'month'));
}

bool _inP(String? day, Period p) => day != null && day.compareTo(p.from) >= 0 && day.compareTo(p.to) <= 0;
List<Rec> _within(List<Rec>? rs, Period p, [String? field]) =>
    alive(rs).where((r) => _inP(recDay(r, field), p)).toList();

Report buildReport(String kind, Period period, FarmData d) {
  final title = _info(kind).label;
  Report make(List<String> summary, List<String> columns, List<List<Object>> rows) =>
      Report(kind: kind, title: title, period: period, summary: summary, columns: columns, rows: rows);
  final bd = daysBetween(period.from, period.to) + 1;
  final days = bd < 1 ? 1 : bd;
  switch (kind) {
    case 'milk':
      {
        final rows = <List<Object>>[];
        for (var i = 0; i < days; i++) {
          final day = addDays(period.from, i);
          final rs = alive(d.milk).where((r) => recDay(r) == day).toList();
          if (rs.isEmpty) continue;
          final m = sum(rs.where((r) => r.str('session') == 'morning').map((r) => num0(r.body['litres'])));
          final e = sum(rs.where((r) => r.str('session') == 'evening').map((r) => num0(r.body['litres'])));
          rows.add([fmtDay(day), round1(m), round1(e), round1(m + e)]);
        }
        final total = sum(rows.map((r) => (r[3] as num).toDouble()));
        return make(
          rows.isNotEmpty
              ? ['${fmtL(total)} over ${rows.length} recorded days', '${fmtL(total / rows.length)} a recorded day']
              : ['No milk recorded in this period'],
          ['Day', 'Morning (L)', 'Evening (L)', 'Total (L)'],
          rows,
        );
      }
    case 'health':
      {
        final ts = stableSort(
          _within(d.treatments, period, 'given'),
          (a, b) => (recDay(a, 'given') ?? '').compareTo(recDay(b, 'given') ?? ''),
        );
        final animals = {for (final a in alive(d.animals)) a.id: a};
        final due = vaccinesDue(d);
        return make(
          ['${ts.length} treatments', '${due.where((v) => v.overdueDays > 0).length} vaccinations overdue today'],
          ['Day', 'Animal', 'Condition', 'Withdrawal days', 'Cost (UGX)'],
          [
            for (final t in ts)
              [
                fmtDay(recDay(t, 'given')!),
                animalName(animals['${t.body['animalId']}']),
                t.str('condition') ?? '',
                num0(t.body['withdrawalDays']),
                num0(t.body['cost']),
              ],
          ],
        );
      }
    case 'profit':
      {
        final exp = _within(d.expenses, period, 'at');
        final inc = _within(d.income, period, 'at');
        final sales = _within(d.milkSales, period);
        final milk = sum(_within(d.milk, period).map((r) => num0(r.body['litres'])));
        final spent = sum(exp.map((e) => num0(e.body['amount'])));
        final milkSales = sum(sales.map((s) => num0(s.body['litres']) * num0(s.body['pricePerLitre'])));
        final other = sum(inc.map((e) => num0(e.body['amount'])));
        final net = milkSales + other - spent;
        return make(
          [
            '${net >= 0 ? 'Profit' : 'Loss'}: ${fmtUgx(net.abs())}',
            if (milk > 0 && spent > 0) 'Cost per litre: ${fmtUgx(spent / milk)}',
          ],
          ['Item', 'UGX'],
          [
            ['Milk sales', jsRound(milkSales)],
            ['Other income', jsRound(other)],
            ['Total income', jsRound(milkSales + other)],
            ['Expenses', jsRound(spent)],
            ['Net', jsRound(net)],
            ['Milk produced (L)', round1(milk)],
          ],
        );
      }
    case 'expenses':
      {
        final exp = _within(d.expenses, period, 'at');
        final by = <String, List<double>>{};
        for (final e in exp) {
          final c = by.putIfAbsent('${e.body['category']}', () => [0, 0]);
          c[0] += 1;
          c[1] += num0(e.body['amount']);
        }
        final total = sum(exp.map((e) => num0(e.body['amount'])));
        final entries = stableSort(by.entries, (a, b) => b.value[1].compareTo(a.value[1]));
        return make(['${fmtUgx(total)} in ${exp.length} expenses'], ['Category', 'Expenses', 'UGX', 'Share'], [
          for (final e in entries)
            [
              catLabel(e.key),
              e.value[0],
              jsRound(e.value[1]),
              '${total != 0 ? jsRound((e.value[1] / total) * 100).toInt() : 0}%',
            ],
        ]);
      }
    case 'feed':
      {
        final uses = _within(d.feedUses, period, 'at');
        final views = {for (final f in feedViews(d)) f.feed: f};
        final by = <String, double>{};
        for (final u in uses) {
          final k = '${u.body['feed']}';
          by[k] = (by[k] ?? 0) + num0(u.body['amount']);
        }
        final e = feedEconomics(d);
        return make(
          [
            if (e.costPerLitre != null) 'Feed cost per litre (last 30 days): ${fmtUgx(e.costPerLitre!)}',
            '${uses.length} feedings recorded',
          ],
          ['Feed', 'Fed', 'A day', 'Left now', 'Days left'],
          [
            for (final en in by.entries)
              () {
                final v = views[en.key];
                return <Object>[
                  (v?.name ?? en.key),
                  '${jsNum(round1(en.value))} ${v?.unit ?? ''}'.trim(),
                  round1(en.value / days),
                  if (v != null) '${jsNum(v.left)} ${v.unit}' else '',
                  v?.daysLeft ?? '',
                ];
              }(),
          ],
        );
      }
    case 'breeding':
      {
        final day = today(d);
        final ev = _within(d.breeding, period, 'at');
        final ci = calvingInterval(d);
        final cows = alive(d.animals)
            .where(
              (a) =>
                  isActive(a) && a.str('sex') != 'male' && !const ['calf', 'bull'].contains(a.str('dairyStatus') ?? ''),
            )
            .toList();
        return make(
          [
            '${ev.where((e) => e.str('type') == 'ai' || (e.str('type') == 'service' && e.str('kind') != 'heat')).length} services, ${ev.where((e) => e.str('type') == 'calving').length} calvings in the period',
            if (ci.avgDays != null)
              'Average calving interval: ${ci.avgDays} days'
            else
              'Calving interval: needs 2 or more recorded intervals',
          ],
          ['Cow', 'State', 'Served', 'Due (estimate)', 'Next heat (estimate)'],
          [
            for (final a in cows)
              () {
                final b = breedingState(a.id, d.breeding, day);
                return <Object>[
                  animalName(a),
                  if (b.pregnant) b.confirmed ? 'In calf (confirmed)' : 'Served' else 'Open',
                  if (b.servedDay != null) fmtDay(b.servedDay!) else '',
                  if (b.due != null) fmtDay(b.due!) else '',
                  if (b.nextHeat != null) fmtDay(b.nextHeat!) else '',
                ];
              }(),
          ],
        );
      }
    case 'quality':
      {
        final q = qualitySummary(d);
        final b = batchViews(d)
            .where((x) => _inP(x.collectedAt.length >= 10 ? x.collectedAt.substring(0, 10) : x.collectedAt, period))
            .toList();
        String s16(String s) => s.length > 16 ? s.substring(0, 16) : s;
        return make(
          [
            'Centre (last 30 days): ${q.deliveries} deliveries, ${q.rejected} rejected (${fmtL(q.rejectedLitres)}), ${q.notTested} not tested',
            '${b.length} farm batches in the period',
          ],
          ['Collected', 'Place', 'Litres', 'Status', 'Highest °C', 'Use by'],
          [
            for (final x in b)
              [
                s16(x.collectedAt.replaceFirst('T', ' ')),
                x.place,
                x.litres,
                if (x.state == 'closed') x.status else x.state,
                x.highest ?? 'no reading',
                x.useBy.replaceFirst('T', ' '),
              ],
          ],
        );
      }
    case 'inventory':
      return make(['Stock today'], ['Item', 'Kind', 'Left', 'A day', 'Days left'], [
        for (final f in feedViews(d))
          <Object>[f.name, 'Feed', '${jsNum(f.left)} ${f.unit}', f.perDay, f.daysLeft ?? ''],
        for (final x in drugViews(d))
          <Object>[
            x.name,
            'Drug',
            if (x.stock == null) 'not counted' else '${jsNum(x.stock!)} ${x.unit}'.trim(),
            '',
            '',
          ],
      ]);
    default:
      {
        final milk = sum(_within(d.milk, period).map((r) => num0(r.body['litres'])));
        final active = alive(d.animals).where(isActive).toList();
        final attention = active.where((a) => animalHealth(d, a.id).attention.isNotEmpty).length;
        return make(
          ['${fmtL(milk)} of milk', '${active.length} animals, $attention needing attention today'],
          ['Measure', 'Value'],
          [
            ['Milk produced (L)', round1(milk)],
            ['Animals', active.length],
            ['Treatments', _within(d.treatments, period, 'given').length],
            ['Calvings', _within(d.breeding, period, 'at').where((e) => e.str('type') == 'calving').length],
            ['Feedings recorded', _within(d.feedUses, period, 'at').length],
            ['Animals needing attention today', attention],
          ],
        );
      }
  }
}

/// A money report asked for by someone who may not see money: refuse rather than build it.
bool canBuild(String kind, String role) => !_info(kind).money || seesMoney(role);
