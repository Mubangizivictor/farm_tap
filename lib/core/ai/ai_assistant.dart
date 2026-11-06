// FarmTap AI engine: Farm Assistant (decision 0025). Hand port of
// shared/aiAssistant.ts.
//
// Questions are matched to a fixed list of things FarmTap can work out
// exactly from the farm's records. Every number comes from those records;
// when a question does not match, the assistant says so and suggests what it
// can answer.
import 'ai_access.dart';
import 'ai_core.dart';
import 'ai_data.dart';
import 'ai_herd.dart';
import 'ai_milk.dart';
import 'ai_money.dart';
import 'ai_risk.dart';
import 'ai_stock.dart';

class Answer {
  const Answer({
    required this.intent,
    required this.ok,
    required this.text,
    this.bullets = const [],
    this.links = const [],
    required this.method,
  });
  final String intent;
  final bool ok;
  final String text;
  final List<String> bullets;
  final List<Link> links;
  final Method method;
}

class Period {
  const Period(this.from, this.to, this.label);
  final String from;
  final String to;
  final String label;
}

/// "today", "yesterday", "this/last week", "this/last month", "last N days".
Period periodOf(String q, String day, [String fallback = 'today']) {
  final s = q.toLowerCase();
  final n = RegExp(r'(?:last|past)\s+(\d{1,3})\s+days?').firstMatch(s);
  if (n != null) return Period(addDays(day, -(int.parse(n.group(1)!) - 1)), day, 'the last ${n.group(1)} days');
  if (RegExp('yesterday').hasMatch(s)) return Period(addDays(day, -1), addDays(day, -1), 'yesterday');
  if (RegExp(r'last\s+week|previous\s+week').hasMatch(s))
    return Period(addDays(day, -13), addDays(day, -7), 'the week before last 7 days');
  if (RegExp(r'this\s+week|past\s+week|last\s+7').hasMatch(s)) return Period(addDays(day, -6), day, 'the last 7 days');
  if (RegExp(r'last\s+month|previous\s+month').hasMatch(s)) {
    final m = addMonths(day.substring(0, 7), -1);
    return Period('$m-01', addDays('${day.substring(0, 7)}-01', -1), fmtMonth(m));
  }
  if (RegExp(r'this\s+month|month').hasMatch(s))
    return Period('${day.substring(0, 7)}-01', day, '${fmtMonth(day.substring(0, 7))} so far');
  if (RegExp('today|now').hasMatch(s)) return Period(day, day, 'today');
  if (fallback == 'month') return Period('${day.substring(0, 7)}-01', day, '${fmtMonth(day.substring(0, 7))} so far');
  if (fallback == 'week') return Period(addDays(day, -6), day, 'the last 7 days');
  return Period(day, day, 'today');
}

bool _inP(String? day, Period p) => day != null && day.compareTo(p.from) >= 0 && day.compareTo(p.to) <= 0;

class _Ctx {
  _Ctx(this.d, this.q, this.day, this.role, this._findings);
  final FarmData d;
  final String q;
  final String day;
  final String role;
  final List<FindingWithState> Function() _findings;
  List<FindingWithState>? _cache;
  List<FindingWithState> findings() => _cache ??= _findings();
}

class _Intent {
  const _Intent(this.key, this.match, this.run, {this.money = false});
  final String key;
  final List<RegExp> match;
  final bool money;
  final Answer Function(_Ctx c) run;
}

Answer _a(
  String text, {
  bool ok = true,
  List<String> bullets = const [],
  List<Link> links = const [],
  Method method = Method.calculated,
}) => Answer(intent: '', ok: ok, text: text, bullets: bullets, links: links, method: method);

String _upperFirst(String k) => k.isEmpty ? k : '${k[0].toUpperCase()}${k.substring(1)}';

final _intents = <_Intent>[
  _Intent('priorities', [RegExp(r"priori|focus|what should (we|i) do|today'?s (plan|work)|most important|urgent")], (
    c,
  ) {
    final fs = c.findings().where((f) => f.finding.severity != Severity.low).take(6).toList();
    if (fs.isEmpty)
      return _a(
        'Nothing urgent in your records today.',
        bullets: ['Keep recording milk, feed and treatments so FarmTap can keep watching.'],
      );
    return _a(
      '${plural(fs.length, 'thing')} to look at first, most serious first:',
      bullets: fs.map((f) => '${f.finding.title}. ${f.finding.action}').toList(),
      links: fs.expand((f) => f.finding.links).take(6).toList(),
    );
  }),
  _Intent(
    'milkForecast',
    [RegExp(r'(predict|forecast|expect|next week|tomorrow|will).*milk|milk.*(predict|forecast|next week|tomorrow)')],
    (c) {
      final f = herdForecast(c.d);
      if (!f.ok)
        return _a(
          'No forecast yet. ${f.reason}',
          ok: false,
          links: const [Link('Record milk', '/milk/?new=1')],
          method: Method.statistical,
        );
      final t = f.next7.length > 1 ? f.next7[1] : null;
      return _a(
        'About ${fmtL(f.total7)} over the next 7 days (${f.confidence} confidence).',
        bullets: [
          'Tomorrow: about ${fmtL((t ?? f.next7[0]).litres)} (likely ${fmtL(t?.low ?? 0)} to ${fmtL(t?.high ?? 0)}).',
          f.trendPerDay == 0
              ? 'Milk is steady.'
              : 'Trend: ${f.trendPerDay > 0 ? 'rising' : 'falling'} about ${fmtL(f.trendPerDay.abs())} a day.',
          if (f.total30 != null) 'Next 30 days: about ${fmtL(f.total30!)}.',
          'Made from ${f.daysUsed} recorded days. ${f.method}.',
        ],
        links: const [Link('Production predictions', '/ai/predictions/')],
        method: Method.statistical,
      );
    },
  ),
  _Intent(
    'cowsDropping',
    [RegExp(r'(less|lower|drop|declin|fall|reduc|decreas).*(milk|produc)|(cow|animal)s?.*(less|drop|declin)')],
    (c) {
      final t = cowTrends(c.d);
      if (t.isEmpty) {
        return _a(
          'I cannot tell yet: this needs milk recorded per cow on at least 3 days this week and 3 days the 2 weeks before.',
          ok: false,
          links: const [Link('Milk', '/milk/')],
        );
      }
      final down = t.where((x) => x.changePct <= dropPct).toList();
      if (down.isEmpty)
        return _a('No cow dropped by more than ${-dropPct}% this week (${plural(t.length, 'cow')} compared).');
      return _a(
        '${plural(down.length, 'cow')} gave clearly less milk this week than the 2 weeks before:',
        bullets: down
            .take(10)
            .map(
              (x) =>
                  '${x.name}: ${fmtL(x.recent)} a day, down ${x.changePct.abs()}% from ${fmtL(x.before)}${x.daysInMilk != null && x.daysInMilk! > 200 ? ' (late lactation, ${x.daysInMilk} days in milk)' : ''}.',
            )
            .toList(),
        links: down.take(5).map((x) => Link(x.name, animalHref(x.animalId))).toList(),
      );
    },
  ),
  _Intent('attention', [RegExp(r'(need|require).*(attention|check|look)|sick|ill\b|unwell|attention')], (c) {
    final list = alive(c.d.animals)
        .where(isActive)
        .map((a) => (a: a, h: animalHealth(c.d, a.id)))
        .where((x) => x.h.attention.isNotEmpty)
        .take(12)
        .toList();
    if (list.isEmpty)
      return _a(
        'No animal stands out in the records today.',
        bullets: ['Repeat treatments, milk drops, overdue vaccines and calvings are all checked.'],
      );
    return _a(
      '${plural(list.length, 'animal')} need attention:',
      bullets: list.map((x) => '${x.h.name}: ${x.h.attention.join('; ')}.').toList(),
      links: list.take(6).map((x) => Link(x.h.name, animalHref(x.a.id))).toList(),
    );
  }),
  _Intent('vaccinations', [RegExp(r'vaccin|jab|injection due')], (c) {
    final v = vaccinesDue(c.d);
    final animals = {for (final a in alive(c.d.animals)) a.id: a};
    if (v.isEmpty) {
      return _a(
        'No vaccination is overdue or due in the next 7 days.',
        bullets: alive(c.d.vaccinations).isNotEmpty
            ? const []
            : const ['No vaccinations are recorded yet, so FarmTap cannot tell what is missing.'],
        links: const [Link('Health', '/health/')],
      );
    }
    return _a(
      '${plural(v.where((x) => x.overdueDays > 0).length, 'vaccination')} overdue, ${plural(v.where((x) => x.overdueDays == 0).length, 'more')} due within a week:',
      bullets: v
          .map(
            (x) =>
                '${x.vaccine} for ${x.animalIds.isNotEmpty ? x.animalIds.map((i) => animalName(animals[i])).join(', ') : 'the whole herd'}: ${x.overdueDays > 0 ? '${plural(x.overdueDays, 'day')} overdue' : 'due ${fmtDay(x.due)}'}.',
          )
          .toList(),
      links: const [Link('Health', '/health/')],
    );
  }),
  _Intent(
    'feedSpend',
    [RegExp(r'(spend|spent|cost|money|pay|paid).*(feed)|feed.*(spend|spent|cost|money)')],
    money: true,
    (c) {
      final p = periodOf(c.q, c.day, 'month');
      final exp = alive(c.d.expenses).where((e) => e.str('category') == 'feed' && _inP(recDay(e, 'at'), p)).toList();
      final total = sum(exp.map((e) => num0(e.body['amount'])));
      return _a(
        exp.isNotEmpty
            ? '${fmtUgx(total)} spent on feed in ${p.label}.'
            : 'No feed expense is recorded for ${p.label}.',
        ok: exp.isNotEmpty,
        bullets: exp.isNotEmpty ? ['${plural(exp.length, 'expense')}.'] : const [],
        links: const [Link('Money', '/money/')],
      );
    },
  ),
  _Intent(
    'expensive',
    [RegExp(r'expensive|biggest (cost|expense)|most (money|spend|cost)|where.*money go|costs?\b.*(most|top)')],
    money: true,
    (c) {
      final p = periodOf(c.q, c.day, 'month');
      final m = monthMoney(c.d, p.from.substring(0, 7));
      if (m.byCategory.isEmpty)
        return _a(
          'No expenses are recorded for ${fmtMonth(m.month)}.',
          ok: false,
          links: const [Link('Money', '/money/')],
        );
      return _a(
        'Biggest costs in ${fmtMonth(m.month)} (${fmtUgx(m.spent)} in all):',
        bullets: m.byCategory
            .take(5)
            .map(
              (x) => '${catLabel(x.category)}: ${fmtUgx(x.amount)} (${jsRound((x.amount / m.spent) * 100).toInt()}%).',
            )
            .toList(),
        links: const [Link('Money', '/money/')],
      );
    },
  ),
  _Intent('profit', [RegExp(r'profit|loss|income|earn|revenue|made money|net')], money: true, (c) {
    final p = periodOf(c.q, c.day, 'month');
    final m = monthMoney(c.d, p.from.substring(0, 7));
    return _a(
      '${fmtMonth(m.month)}: ${m.net >= 0 ? 'profit' : 'loss'} of ${fmtUgx(m.net.abs())}${m.month == c.day.substring(0, 7) ? ' so far' : ''}.',
      bullets: [
        'Milk sales ${fmtUgx(m.milkSales)}, other income ${fmtUgx(m.otherIncome)}, spent ${fmtUgx(m.spent)}.',
        if (m.costPerLitre != null) 'Cost per litre: ${fmtUgx(m.costPerLitre!)} (${fmtL(m.litres)} produced).',
      ],
      links: const [Link('Reports', '/reports/')],
    );
  }),
  _Intent('costPerLitre', [RegExp(r'cost (per|a|of a) (litre|liter)')], money: true, (c) {
    final m = monthMoney(c.d, periodOf(c.q, c.day, 'month').from.substring(0, 7));
    return m.costPerLitre == null
        ? _a('Not enough records for ${fmtMonth(m.month)}: it needs both expenses and milk.', ok: false)
        : _a(
            '${fmtUgx(m.costPerLitre!)} per litre in ${fmtMonth(m.month)}.',
            bullets: ['${fmtUgx(m.spent)} spent, ${fmtL(m.litres)} produced.'],
            links: const [Link('Money', '/money/')],
          );
  }),
  _Intent('expiry', [RegExp(r'expir|spoil|use.?by|batch|cooler|go bad|old milk')], (c) {
    final b = batchViews(c.d).where((x) => x.state != 'closed').toList();
    if (b.isEmpty) {
      return _a(
        'No milk batch is in storage.',
        ok: false,
        bullets: const ['Add batches in Milk Quality and Expiry to track use-by times.'],
        links: const [Link('Milk batches', '/ai/quality/')],
      );
    }
    final soon = b.where((x) => x.state != 'fresh').toList();
    return _a(
      soon.isNotEmpty
          ? '${plural(soon.length, 'batch', 'batches')} expired or must go soon:'
          : 'All ${plural(b.length, 'batch', 'batches')} in storage are within their use-by.',
      bullets: (soon.isNotEmpty ? soon : b)
          .map(
            (x) =>
                '${fmtL(x.litres)} in ${x.place}: ${x.state == 'expired' ? 'past its use-by' : 'use within ${jsNum(x.hoursLeft)} hours'}${x.unverified ? ' (no temperature reading)' : ''}.',
          )
          .toList(),
      links: const [Link('Milk batches', '/ai/quality/')],
    );
  }),
  _Intent('pregnant', [RegExp(r'pregnan|in calf|due to calve|calving')], (c) {
    final list = stableSort(
      alive(c.d.animals)
          .where((a) => isActive(a) && a.str('sex') != 'male')
          .map((a) => (a: a, b: breedingState(a.id, c.d.breeding, c.day)))
          .where((x) => x.b.pregnant),
      (x, y) => (x.b.due ?? '').compareTo(y.b.due ?? ''),
    );
    if (list.isEmpty)
      return _a('No animal is recorded as served or pregnant.', links: const [Link('Breeding', '/breeding/')]);
    return _a(
      '${plural(list.length, 'animal')} served or in calf:',
      bullets: list
          .map(
            (x) =>
                '${animalName(x.a)}: due about ${fmtDay(x.b.due!)}${x.b.confirmed ? ', confirmed by a check' : ', not yet confirmed'}.',
          )
          .toList(),
      links: const [Link('Breeding', '/breeding/')],
    );
  }),
  _Intent('breedingDue', [RegExp(r'heat|breed|serve|insemina|\bai\b|bull')], (c) {
    final list = alive(c.d.animals)
        .where(
          (a) => isActive(a) && a.str('sex') != 'male' && !const ['calf', 'bull'].contains(a.str('dairyStatus') ?? ''),
        )
        .map((a) => (a: a, b: breedingState(a.id, c.d.breeding, c.day)))
        .where((x) => !x.b.pregnant && (x.b.nextHeat != null || (x.b.daysInMilk ?? 0) > 60))
        .toList();
    if (list.isEmpty) {
      return _a(
        'No open cow with a heat expected is recorded.',
        bullets: const ['Record heats, services and calvings so FarmTap can work out the next heat.'],
        links: const [Link('Breeding', '/breeding/')],
      );
    }
    return _a(
      '${plural(list.length, 'cow')} not in calf:',
      bullets: list
          .map(
            (x) =>
                '${animalName(x.a)}: ${x.b.nextHeat != null ? 'next heat about ${fmtDay(x.b.nextHeat!)}' : 'no heat recorded'}${x.b.daysInMilk != null ? ', ${x.b.daysInMilk} days since calving' : ''}.',
          )
          .toList(),
      links: const [Link('Breeding', '/breeding/')],
    );
  }),
  _Intent('feedLeft', [RegExp(r'feed|stock|run out|silage|hay|dairy meal|bran')], (c) {
    final f = feedViews(c.d);
    if (f.isEmpty)
      return _a(
        'No feed purchases, counts or feedings are recorded yet.',
        ok: false,
        links: const [Link('Feeds', '/feeds/')],
      );
    return _a(
      'Feed in store:',
      bullets: f
          .map(
            (x) =>
                '${x.name}: ${jsNum(x.left)} ${x.unit}${x.daysLeft != null ? ', about ${plural(x.daysLeft!, 'day')} at ${jsNum(x.perDay)} ${x.unit} a day' : ''}.',
          )
          .toList(),
      links: const [Link('Feeds', '/feeds/')],
    );
  }),
  _Intent('withdrawal', [RegExp(r'withdraw|treated|medicine|drug|antibiotic')], (c) {
    final list = alive(c.d.animals)
        .where(isActive)
        .map((a) => animalHealth(c.d, a.id))
        .where((h) => h.inWithdrawal)
        .toList();
    return list.isNotEmpty
        ? _a(
            '${plural(list.length, 'animal')} in withdrawal (milk must not be sold):',
            bullets: list.map((h) => '${h.name}: safe from ${fmtDay(h.safeFrom!)}.').toList(),
            links: const [Link('Health', '/health/')],
          )
        : _a('No animal is in a drug withdrawal period today.', links: const [Link('Health', '/health/')]);
  }),
  _Intent('milkAmount', [RegExp(r'milk|litre|liter|produc')], (c) {
    final p = periodOf(c.q, c.day);
    final rs = alive(c.d.milk).where((r) => _inP(recDay(r), p)).toList();
    final total = sum(rs.map((r) => num0(r.body['litres'])));
    if (rs.isEmpty)
      return _a('No milk is recorded for ${p.label}.', ok: false, links: const [Link('Record milk', '/milk/?new=1')]);
    final days = rs.map((r) => recDay(r)).toSet().length;
    final s = milkSummary(c.d);
    final morning = sum(rs.where((r) => r.str('session') == 'morning').map((r) => num0(r.body['litres'])));
    final evening = sum(rs.where((r) => r.str('session') == 'evening').map((r) => num0(r.body['litres'])));
    return _a(
      '${fmtL(total)} of milk ${p.label == 'today' || p.label == 'yesterday' ? p.label : 'in ${p.label}'}.',
      bullets: [
        if (p.from == p.to)
          'Morning ${fmtL(morning)}, evening ${fmtL(evening)}.'
        else
          '${plural(days, 'day')} recorded, about ${fmtL(total / (days < 1 ? 1 : days))} a day.',
        if (p.label == 'today' && s.avg7 != null) 'The last 7 days averaged ${fmtL(s.avg7!)} a day.',
      ],
      links: const [Link('Milk records', '/milk/')],
    );
  }),
  _Intent('herdSize', [RegExp(r'how many (cows|animals|cattle)|herd size|number of (cows|animals)')], (c) {
    final a = alive(c.d.animals).where(isActive).toList();
    final by = <String, int>{};
    for (final x in a) {
      final k = x.str('dairyStatus') ?? 'other';
      by[k] = (by[k] ?? 0) + 1;
    }
    return _a(
      '${plural(a.length, 'animal')} on the farm.',
      bullets: [for (final e in by.entries) '${_upperFirst(e.key)}: ${e.value}'],
      links: const [Link('Herd', '/herd/')],
    );
  }),
];

const suggestedQuestions = <String>[
  'How much milk did we produce today?',
  'Which cows are producing less milk?',
  'Which animals need attention?',
  'Which cows have missed vaccinations?',
  'How much did we spend on feed this month?',
  'Which milk batches expire soon?',
  'What are our most expensive costs this month?',
  'Which animals are pregnant?',
  'Which cows are due for breeding?',
  'What was our production last month?',
  'How much milk do we expect next week?',
  'What should we prioritise today?',
];

/// Answer a question from the farm's records. Never throws.
Answer ask(String question, FarmData d, {required String role, required AiConfig cfg, bool farmAiOn = true}) {
  final q = question.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  final day = today(d);
  final ctx = _Ctx(d, q, day, role, () => allFindings(d, role: role, cfg: cfg, farmAiOn: farmAiOn));
  if (q.isEmpty)
    return Answer(
      intent: 'empty',
      ok: false,
      text: 'Type a question about your farm.',
      bullets: suggestedQuestions.take(4).toList(),
      method: Method.calculated,
    );
  _Intent? hit;
  for (final i in _intents) {
    if (i.match.any((r) => r.hasMatch(q))) {
      hit = i;
      break;
    }
  }
  if (hit == null) {
    return Answer(
      intent: 'unknown',
      ok: false,
      text: 'I cannot answer that from your records yet. I only answer what I can work out exactly. Try one of these:',
      bullets: suggestedQuestions.take(6).toList(),
      method: Method.calculated,
    );
  }
  if (hit.money && !seesMoney(role)) {
    return Answer(
      intent: hit.key,
      ok: false,
      text: 'Money questions are for the farm owner and managers.',
      method: Method.calculated,
    );
  }
  try {
    final r = hit.run(ctx);
    return Answer(intent: hit.key, ok: r.ok, text: r.text, bullets: r.bullets, links: r.links, method: r.method);
  } on Object {
    return Answer(
      intent: hit.key,
      ok: false,
      text: 'Something in the records could not be read, so I will not guess. Please try again or check the records page.',
      method: Method.calculated,
    );
  }
}

final intentKeys = _intents.map((i) => i.key).toList();
