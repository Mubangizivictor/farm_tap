// FarmTap AI engine: extra built-in insights (decision 0028, layer 2).
// Hand port of shared/aiInsights.ts; the parity test checks both give the
// same findings. Plain calculations on the farm's own records: no model, no
// internet, no credits. Health wording is a risk to check with the vet,
// never a diagnosis.
import 'package:farm_tap/core/ai/ai_core.dart';
import 'package:farm_tap/core/ai/ai_data.dart';
import 'package:farm_tap/core/ai/ai_milk.dart';
import 'package:farm_tap/core/ai/ai_money.dart';

// ---------------------------------------------------------------- Milk against the previous recording

/// A drop at least this big (percent) raises a warning; twice as big, a high one.
const herdDropWarnPct = 10;

class DayLitres {
  const new(this.day, this.litres);
  final String day;
  final double litres;
}

class HerdMilkChange {
  const new({required this.latest, required this.previous, required this.changePct, required this.direction});
  final DayLitres latest;
  final DayLitres previous;

  /// One decimal, negative when milk fell.
  final double changePct;

  /// 'down', 'up' or 'steady'.
  final String direction;
}

/// The herd's milk on the latest recorded day against the recorded day before
/// it. Today counts only once its evening milking is in (or after 9 pm).
HerdMilkChange? herdMilkChange(FarmData d) {
  final day = today(d);
  final days = milkDays(d, 30).where((x) => x.recorded && x.litres > 0).toList();
  final todayDone =
      alive(d.milk).any((r) => recDay(r) == day && r.str('session') == 'evening') ||
      int.parse(d.now.substring(11, 13)) >= 21;
  final usable = days.where((x) => x.day != day || todayDone).toList();
  if (usable.length < 2) return null;
  final latest = usable[usable.length - 1];
  final previous = usable[usable.length - 2];
  final changePct = round1((latest.litres - previous.litres) / previous.litres * 100);
  return HerdMilkChange(
    latest: DayLitres(latest.day, round1(latest.litres)),
    previous: DayLitres(previous.day, round1(previous.litres)),
    changePct: changePct,
    direction: changePct <= -1
        ? 'down'
        : changePct >= 1
        ? 'up'
        : 'steady',
  );
}

/// "Milk production has declined by 29.2% compared with the previous recording."
String herdChangeText(HerdMilkChange c) {
  if (c.direction == 'steady') {
    return 'Milk production is steady compared with the previous recording (${fmtL(c.latest.litres)} against ${fmtL(c.previous.litres)}).';
  }
  final word = c.direction == 'down' ? 'declined' : 'increased';
  return 'Milk production has $word by ${jsNum(c.changePct.abs())}% compared with the previous recording.';
}

const herdDropAction = 'Review animal health, feeding records and recent management changes.';

// ---------------------------------------------------------------- Animal records

class RecordGap {
  const new(this.animalId, this.name, this.missing);
  final String animalId;
  final String name;
  final List<String> missing;
}

class Completeness {
  const new({required this.animals, required this.complete, required this.pct, required this.gaps});
  final int animals;
  final int complete;

  /// 0 to 100.
  final int pct;
  final List<RecordGap> gaps;
}

const _needed = <(String, String)>[
  ('tagNumber', 'tag number'),
  ('sex', 'sex'),
  ('dateOfBirth', 'date of birth'),
  ('dairyStatus', 'status (milking, dry, heifer…)'),
];

/// Active animals whose record is missing something the analyses need.
Completeness recordCompleteness(FarmData d) {
  final animals = alive(d.animals).where(isActive).toList();
  final gaps = <RecordGap>[];
  for (final a in animals) {
    final missing = [
      for (final (k, label) in _needed)
        if ((a.str(k) ?? '').trim().isEmpty) label,
    ];
    if (missing.isNotEmpty) gaps.add(RecordGap(a.id, animalName(a), missing));
  }
  final complete = animals.length - gaps.length;
  return Completeness(
    animals: animals.length,
    complete: complete,
    pct: animals.isEmpty ? 100 : jsRound(complete / animals.length * 100).toInt(),
    gaps: gaps,
  );
}

// ---------------------------------------------------------------- Findings

List<Finding> insightFindings(FarmData d) {
  final out = <Finding>[];
  final c = herdMilkChange(d);
  if (c != null && c.changePct <= -herdDropWarnPct) {
    out.add(
      Finding(
        id: 'milk-change-${c.latest.day}',
        module: 'milk',
        severity: c.changePct <= -2 * herdDropWarnPct ? Severity.high : Severity.medium,
        title: 'Milk down ${jsNum(c.changePct.abs())}% on the previous recording',
        why:
            '${fmtL(c.latest.litres)} on ${fmtDay(c.latest.day)} against ${fmtL(c.previous.litres)} on ${fmtDay(c.previous.day)}.',
        action:
            '$herdDropAction A health problem is only a possibility: ask your vet to check any cow that looks unwell.',
        method: Method.calculated,
        links: const [Link('Milk records', '/milk/')],
      ),
    );
  }
  final r = recordCompleteness(d);
  if (r.gaps.isNotEmpty) {
    out.add(
      Finding(
        id: 'records-incomplete-${r.gaps.length}-${today(d).substring(0, 7)}',
        module: 'health',
        severity: Severity.low,
        title: '${plural(r.gaps.length, 'animal record')} incomplete',
        why:
            '${r.pct}% of animal records are complete. Missing details make milk, breeding and health checks less accurate.',
        action: 'Open each animal and fill in what is missing.',
        method: Method.calculated,
        links: [for (final g in r.gaps.take(3)) Link(g.name, animalHref(g.animalId))],
        subjects: [for (final g in r.gaps) g.animalId],
      ),
    );
  }
  return out;
}

// ---------------------------------------------------------------- Extra questions

class InsightAnswer {
  const new({
    required this.intent,
    required this.ok,
    required this.text,
    this.bullets = const [],
    this.links = const [],
    this.method = Method.calculated,
  });
  final String intent;
  final bool ok;
  final String text;
  final List<String> bullets;
  final List<Link> links;
  final Method method;
}

final _cowWord = RegExp(r'\b(cows?|animals?|which|heifers?)\b');
final _milkChange = RegExp(
  r'((milk|production|yield).*(declin|drop|fall|fell|down|change|compar|previous|differ|trend|up\b|increase))|((declin|drop|fall|compar|change|trend).*(milk|production|yield))',
);
final _records = RegExp(
  '(incomplete|missing|complete).*(record|detail|info)|(record|detail|info).*(incomplete|missing|complete)',
);
final _spend = RegExp(r'\b(spend|spent|spending|expenses?|costs)\b');
final _summary = RegExp(r'\b(summary|summari[sz]e|overview|how is (the|my|our) farm|farm (doing|performance))\b');

/// Questions the original assistant (ask) does not cover. Checked before it.
InsightAnswer? askInsight(String question, FarmData d, {required bool seesMoney}) {
  final q = question.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  final day = today(d);
  if (!_cowWord.hasMatch(q) && _milkChange.hasMatch(q)) {
    final c = herdMilkChange(d);
    if (c == null) {
      return const InsightAnswer(
        intent: 'milkChange',
        ok: false,
        text: 'I need milk recorded on at least two days to compare.',
        links: [Link('Record milk', '/milk/?new=1')],
      );
    }
    final s = milkSummary(d);
    return InsightAnswer(
      intent: 'milkChange',
      ok: true,
      text: c.changePct <= -herdDropWarnPct ? '${herdChangeText(c)} $herdDropAction' : herdChangeText(c),
      bullets: [
        '${fmtDay(c.latest.day)}: ${fmtL(c.latest.litres)}. ${fmtDay(c.previous.day)}: ${fmtL(c.previous.litres)}.',
        if (s.weekChangePct != null)
          'Last 7 days against the 7 before: ${s.weekChangePct! > 0 ? '+' : ''}${s.weekChangePct}%.',
      ],
      links: const [Link('Milk records', '/milk/')],
    );
  }
  if (_records.hasMatch(q)) {
    final r = recordCompleteness(d);
    if (r.animals == 0) {
      return const InsightAnswer(
        intent: 'completeness',
        ok: true,
        text: 'No animals are recorded yet.',
        links: [Link('Herd', '/herd/')],
      );
    }
    return InsightAnswer(
      intent: 'completeness',
      ok: true,
      text: r.gaps.isNotEmpty
          ? '${r.pct}% of animal records are complete. ${plural(r.gaps.length, 'animal')} miss something:'
          : 'All ${plural(r.animals, 'animal record')} are complete.',
      bullets: [for (final g in r.gaps.take(12)) '${g.name}: no ${g.missing.join(', no ')}.'],
      links: [for (final g in r.gaps.take(5)) Link(g.name, animalHref(g.animalId))],
    );
  }
  if (!q.contains('feed') && !RegExp('most|biggest|top|expensive').hasMatch(q) && _spend.hasMatch(q)) {
    if (!seesMoney) {
      return const InsightAnswer(
        intent: 'spending',
        ok: false,
        text: 'Money questions are for the farm owner and managers.',
      );
    }
    final month = RegExp('last month|previous month').hasMatch(q)
        ? addDays('${day.substring(0, 7)}-01', -1).substring(0, 7)
        : day.substring(0, 7);
    final m = monthMoney(d, month);
    final n = alive(d.expenses).where((e) => (recDay(e, 'at') ?? '').startsWith(month)).length;
    if (n == 0) {
      return InsightAnswer(
        intent: 'spending',
        ok: true,
        text: 'No expenses are recorded for ${fmtMonth(month)}.',
        links: const [Link('Money', '/money/')],
      );
    }
    return InsightAnswer(
      intent: 'spending',
      ok: true,
      text:
          '${fmtUgx(m.spent)} spent in ${fmtMonth(month)}${month == day.substring(0, 7) ? ' so far' : ''} (${plural(n, 'expense')}).',
      bullets: [for (final x in m.byCategory.take(4)) '${catLabel(x.category)}: ${fmtUgx(x.amount)}.'],
      links: const [Link('Money', '/money/')],
    );
  }
  if (_summary.hasMatch(q) && !RegExp(r'\b(why|explain)\b').hasMatch(q)) {
    final s = milkSummary(d);
    final herd = alive(d.animals).where(isActive).length;
    final m = monthMoney(d, day.substring(0, 7));
    final c = herdMilkChange(d);
    final milk7 = sum(milkDays(d, 7).map((x) => x.litres));
    return InsightAnswer(
      intent: 'farmSummary',
      ok: true,
      text: 'Your farm in numbers (${fmtDay(day)}):',
      bullets: [
        '${plural(herd, 'animal')} on the farm.',
        'Milk: ${fmtL(milk7)} in the last 7 days${s.avg7 != null ? ', about ${fmtL(s.avg7!)} a day' : ''}.',
        if (c != null) herdChangeText(c),
        if (seesMoney)
          '${fmtMonth(m.month)} so far: income ${fmtUgx(m.income)}, spent ${fmtUgx(m.spent)}, ${m.net >= 0 ? 'profit' : 'loss'} ${fmtUgx(m.net.abs())}.',
      ],
      links: const [Link('Reports', '/reports/')],
    );
  }
  return null;
}
