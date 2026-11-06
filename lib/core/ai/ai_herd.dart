// FarmTap AI engine: animal health and breeding (decision 0025). Hand port
// of shared/aiHerd.ts.
import 'package:farm_tap/core/ai/ai_core.dart';
import 'package:farm_tap/core/ai/ai_data.dart';
import 'package:farm_tap/core/ai/ai_milk.dart';

class VaccineDue {
  const new({
    required this.vaccine,
    required this.animalIds,
    required this.due,
    required this.overdueDays,
    required this.doseId,
  });
  final String vaccine;

  /// Empty = the whole herd.
  final List<String> animalIds;
  final String due;
  final int overdueDays;
  final String doseId;
}

List<String> _ids(Rec r) => ((r.body['animalIds'] as List?) ?? const []).map((e) => '$e').toList();

/// Doses whose next one is due within 7 days or overdue, and not yet given
/// again: a later dose of the same vaccine to the same animals (or the herd)
/// closes the earlier one.
List<VaccineDue> vaccinesDue(FarmData d) {
  final day = today(d);
  final vs = alive(d.vaccinations);
  bool covers(Rec later, List<String> ids) {
    final l = _ids(later);
    return l.isEmpty || (ids.isNotEmpty && ids.every(l.contains));
  }

  final out = <VaccineDue>[];
  for (final v in vs) {
    final due = dayOf(v.body['nextDue']);
    if (due == null || due.compareTo(addDays(day, 7)) > 0) continue;
    final given = recDay(v, 'given') ?? '';
    final ids = _ids(v);
    final redone = vs.any(
      (o) =>
          o.id != v.id &&
          o.body['vaccine'] == v.body['vaccine'] &&
          (recDay(o, 'given') ?? '').compareTo(given) > 0 &&
          covers(o, ids),
    );
    if (redone) continue;
    final od = daysBetween(due, day);
    out.add(
      VaccineDue(vaccine: '${v.body['vaccine']}', animalIds: ids, due: due, overdueDays: od > 0 ? od : 0, doseId: v.id),
    );
  }
  return stableSort(
    out,
    (a, b) => b.overdueDays != a.overdueDays ? b.overdueDays - a.overdueDays : a.due.compareTo(b.due),
  );
}

class ConditionCount {
  const new(this.condition, this.times, this.last);
  final String condition;
  final int times;
  final String last;
}

class AnimalHealth {
  const new({
    required this.animalId,
    required this.name,
    required this.treatments90,
    required this.conditions,
    required this.lastTreatment,
    required this.inWithdrawal,
    required this.safeFrom,
    required this.followUp,
    required this.vaccinesDue,
    required this.milkChangePct,
    required this.breeding,
    required this.attention,
  });
  final String animalId;
  final String name;
  final int treatments90;
  final List<ConditionCount> conditions;
  final String? lastTreatment;
  final bool inWithdrawal;
  final String? safeFrom;
  final String? followUp;
  final List<VaccineDue> vaccinesDue;
  final int? milkChangePct;
  final BreedingState breeding;

  /// Plain reasons this animal needs attention, most serious first.
  final List<String> attention;
}

String _cond(Rec t) {
  final c = t.str('condition');
  return (c == null || c.isEmpty ? 'other' : c).toLowerCase();
}

AnimalHealth animalHealth(FarmData d, String animalId) {
  final day = today(d);
  final a = animalMap(d)[animalId];
  final ts = stableSort(
    alive(d.treatments).where((t) => t.str('animalId') == animalId),
    (x, y) => (recDay(y, 'given') ?? '').compareTo(recDay(x, 'given') ?? ''),
  );
  final from90 = addDays(day, -90);
  final recent = ts.where((t) => (recDay(t, 'given') ?? '').compareTo(from90) >= 0).toList();
  final byCond = <String, List<Object>>{};
  for (final t in recent) {
    final c = _cond(t);
    final g = recDay(t, 'given') ?? day;
    final cur = byCond[c];
    byCond[c] = [
      (cur == null ? 0 : cur[0] as int) + 1,
      if (cur != null && (cur[1] as String).compareTo(g) > 0) cur[1] else g,
    ];
  }
  final last = ts.isEmpty ? null : ts.first;
  final lastDay = last == null ? null : recDay(last, 'given');
  final safe = last != null && lastDay != null ? addDays(lastDay, num0(last.body['withdrawalDays']).toInt()) : null;
  final inWithdrawal = safe != null && num0(last?.body['withdrawalDays']) > 0 && safe.compareTo(day) > 0;
  final course = last != null && lastDay != null && num0(last.body['courseDays']) > 1
      ? addDays(lastDay, num0(last.body['courseDays']).toInt() - 1)
      : null;
  final followUp = course != null && course.compareTo(day) >= 0 ? course : null;
  final vd = vaccinesDue(d).where((v) => v.animalIds.isEmpty || v.animalIds.contains(animalId)).toList();
  final trend = cowTrends(d).where((c) => c.animalId == animalId).firstOrNull;
  final breeding = breedingState(animalId, d.breeding, day);
  final conditions = stableSort([
    for (final e in byCond.entries) ConditionCount(e.key, e.value[0] as int, e.value[1] as String),
  ], (x, y) => y.times - x.times);
  final attention = <String>[];
  if (recent.length >= 3) attention.add('Treated ${recent.length} times in 90 days');
  for (final c in conditions.where((c) => c.times >= 2)) {
    attention.add('${cap(c.condition)} ${c.times} times in 90 days');
  }
  if (trend != null && trend.changePct <= dropPct) attention.add('Milk down ${trend.changePct.abs()}% this week');
  for (final v in vd.where((v) => v.overdueDays > 0)) {
    attention.add('${v.vaccine} overdue ${plural(v.overdueDays, 'day')}');
  }
  if (followUp != null) attention.add('Treatment course ends ${fmtDay(followUp)}');
  if (breeding.due != null && daysBetween(day, breeding.due!) <= 14 && daysBetween(day, breeding.due!) >= -7) {
    attention.add('Due to calve ${fmtDay(breeding.due!)}');
  }
  return AnimalHealth(
    animalId: animalId,
    name: animalName(a),
    treatments90: recent.length,
    conditions: conditions,
    lastTreatment: lastDay,
    inWithdrawal: inWithdrawal,
    safeFrom: inWithdrawal ? safe : null,
    followUp: followUp,
    vaccinesDue: vd,
    milkChangePct: trend?.changePct,
    breeding: breeding,
    attention: attention,
  );
}

// ---------------------------------------------------------------- Findings

List<Finding> healthFindings(FarmData d) {
  final day = today(d);
  final animals = animalMap(d);
  final out = <Finding>[];
  final from90 = addDays(day, -90);
  final from60 = addDays(day, -60);
  final perAnimal = <String, List<Rec>>{};
  for (final t in alive(d.treatments)) {
    if ((recDay(t, 'given') ?? '').compareTo(from90) < 0) continue;
    final id = '${t.body['animalId']}';
    final a = animals[id];
    if (a != null && !isActive(a)) continue;
    perAnimal.putIfAbsent(id, () => []).add(t);
  }
  for (final e in perAnimal.entries) {
    final id = e.key;
    final ts = e.value;
    final name = animalName(animals[id]);
    final conds = <String, int>{};
    for (final t in ts.where((t) => (recDay(t, 'given') ?? '').compareTo(from60) >= 0)) {
      final c = _cond(t);
      conds[c] = (conds[c] ?? 0) + 1;
    }
    final reps = stableSort(conds.entries.where((x) => x.value >= 2), (a, b) => b.value - a.value);
    final repeat = reps.isEmpty ? null : reps.first;
    if (repeat != null || ts.length >= 3) {
      out.add(
        Finding(
          id: 'repeat-illness-$id-${day.substring(0, 7)}',
          module: 'health',
          severity: ts.length >= 4 || (repeat != null && repeat.value >= 3) ? Severity.high : Severity.medium,
          title: repeat != null
              ? '$name: ${repeat.key} came back (${repeat.value} times)'
              : '$name was treated ${ts.length} times',
          why: repeat != null
              ? '${repeat.value} treatments for ${repeat.key} in the last 60 days; ${ts.length} treatments in 90 days.'
              : '${ts.length} treatments in the last 90 days.',
          action: 'Ask the vet to examine her. An illness that keeps coming back may need a different treatment, or culling may be cheaper.',
          method: Method.calculated,
          links: [Link(name, animalHref(id))],
          subjects: [id],
        ),
      );
    }
  }
  for (final v in vaccinesDue(d)) {
    final who = v.animalIds.isNotEmpty
        ? v.animalIds.map((i) => animalName(animals[i])).take(3).join(', ') +
              (v.animalIds.length > 3 ? ' and ${v.animalIds.length - 3} more' : '')
        : 'the whole herd';
    out.add(
      Finding(
        id: 'vaccine-${v.doseId}',
        module: 'health',
        severity: v.overdueDays > 14
            ? Severity.high
            : v.overdueDays > 0
            ? Severity.medium
            : Severity.low,
        title: v.overdueDays > 0
            ? '${v.vaccine} is ${plural(v.overdueDays, 'day')} overdue'
            : '${v.vaccine} due ${fmtDay(v.due)}',
        why: 'The last dose for $who said the next is due ${fmtDay(v.due)}, and no later dose is recorded.',
        action: 'Book the vet or vaccinator, then record the dose.',
        method: Method.calculated,
        links: const [Link('Vaccinations', '/health/')],
        subjects: v.animalIds,
      ),
    );
  }
  for (final t in alive(d.treatments)) {
    final g = recDay(t, 'given');
    final days = num0(t.body['courseDays']).toInt();
    if (g == null || days <= 1) continue;
    final end = addDays(g, days - 1);
    if (end.compareTo(day) < 0 || g.compareTo(day) > 0) continue;
    final aid = '${t.body['animalId']}';
    final name = animalName(animals[aid]);
    final cond = t.str('condition');
    out.add(
      Finding(
        id: 'course-${t.id}-$day',
        module: 'health',
        severity: Severity.low,
        title: '$name: treatment course, day ${daysBetween(g, day) + 1} of $days',
        why: '${cap(cond == null || cond.isEmpty ? 'Treatment' : cond)} started ${fmtDay(g)} for $days days.',
        action: 'Give today’s treatment as the vet said and record it.',
        method: Method.calculated,
        links: [Link(name, animalHref(aid))],
        subjects: [aid],
      ),
    );
  }
  return out;
}

List<Finding> breedingFindings(FarmData d) {
  final day = today(d);
  final out = <Finding>[];
  for (final a in alive(d.animals)) {
    if (!isActive(a) || a.str('sex') == 'male') continue;
    if (const ['calf', 'bull'].contains(a.str('dairyStatus') ?? '')) continue;
    final b = breedingState(a.id, d.breeding, day);
    final name = animalName(a);
    final link = [Link(name, animalHref(a.id))];
    if (b.due != null) {
      final left = daysBetween(day, b.due!);
      if (left <= 30 && left >= -14) {
        out.add(
          Finding(
            id: 'calving-${a.id}-${b.due}',
            module: 'breeding',
            severity: left < 0
                ? Severity.high
                : left <= 7
                ? Severity.medium
                : Severity.low,
            title: left < 0
                ? '$name is ${plural(-left, 'day')} past her calving date'
                : '$name due to calve ${fmtDay(b.due!)}',
            why:
                'Served ${fmtDay(b.servedDay!)}; ${b.confirmed ? 'pregnancy confirmed' : 'pregnancy not yet confirmed by a check'}. The date is an estimate (283 days), not a vet finding.',
            action: left < 0
                ? 'Ask the vet to check her.'
                : left <= 14
                ? 'Move her to a clean calving place, stop milking if she is still milked, and have the vet’s number ready.'
                : 'Plan drying off about 60 days before calving.',
            method: Method.calculated,
            links: link,
            subjects: [a.id],
          ),
        );
      }
    }
    if (b.checkDue != null && b.checkDue!.compareTo(addDays(day, 3)) <= 0) {
      out.add(
        Finding(
          id: 'pregcheck-${a.id}-${b.servedDay}',
          module: 'breeding',
          severity: daysBetween(b.checkDue!, day) > 14 ? Severity.medium : Severity.low,
          title: '$name needs a pregnancy check',
          why: 'Served ${fmtDay(b.servedDay!)}; a check is due from ${fmtDay(b.checkDue!)} and none is recorded.',
          action: 'Ask the vet or technician to check her.',
          method: Method.calculated,
          links: link,
          subjects: [a.id],
        ),
      );
    }
    if (b.nextHeat != null && daysBetween(day, b.nextHeat!) <= 2 && daysBetween(day, b.nextHeat!) >= 0) {
      out.add(
        Finding(
          id: 'heat-${a.id}-${b.nextHeat}',
          module: 'breeding',
          severity: Severity.low,
          title: '$name may come on heat ${b.nextHeat == day ? 'today' : fmtDay(b.nextHeat!)}',
          why:
              '21 days after her last heat sign${b.lastHeat != null ? ' (${fmtDay(b.lastHeat!)})' : ''}. An estimate: watch for mounting, mucus and restlessness.',
          action: 'Watch her morning and evening. Call the AI technician when she stands to be mounted.',
          method: Method.calculated,
          links: link,
          subjects: [a.id],
        ),
      );
    }
    if (!b.pregnant && b.daysInMilk != null && b.daysInMilk! > 90 && b.servedDay == null) {
      out.add(
        Finding(
          id: 'open-${a.id}-${day.substring(0, 7)}',
          module: 'breeding',
          severity: b.daysInMilk! > 150 ? Severity.high : Severity.medium,
          title: '$name not served ${b.daysInMilk} days after calving',
          why:
              'Calved ${fmtDay(b.calvedDay!)} and no service is recorded since. Most farms aim to serve by about 90 days to keep one calf a year.',
          action: 'Watch her for heat, or ask the vet why she is not showing.',
          method: Method.calculated,
          links: link,
          subjects: [a.id],
        ),
      );
    }
    if (b.failedServices >= 3) {
      out.add(
        Finding(
          id: 'repeat-breeder-${a.id}-${b.calvedDay ?? 'none'}',
          module: 'breeding',
          severity: Severity.medium,
          title: '$name: ${b.failedServices} services without a pregnancy',
          why:
              '${b.servicesSinceCalving} services since ${b.calvedDay != null ? 'calving on ${fmtDay(b.calvedDay!)}' : 'records began'}, none confirmed.',
          action: 'Ask the vet to examine her before paying for another service.',
          method: Method.calculated,
          links: link,
          subjects: [a.id],
        ),
      );
    }
  }
  return out;
}

/// Average calving interval in days (null with fewer than 2 intervals).
({int? avgDays, int intervals}) calvingInterval(FarmData d) {
  final byAnimal = <String, List<String>>{};
  for (final e in alive(d.breeding)) {
    final aid = e.str('animalId');
    if (e.str('type') != 'calving' || aid == null || aid.isEmpty) continue;
    final day = dayOf(e.body['at']);
    if (day != null) byAnimal.putIfAbsent(aid, () => []).add(day);
  }
  final gaps = <int>[];
  for (final days in byAnimal.values) {
    days.sort();
    for (var i = 1; i < days.length; i++) {
      gaps.add(daysBetween(days[i - 1], days[i]));
    }
  }
  return (
    avgDays: gaps.length >= 2 ? jsRound(gaps.fold<int>(0, (t, g) => t + g) / gaps.length).toInt() : null,
    intervals: gaps.length,
  );
}
