// FarmTap AI engine: milk. Daily analysis, cows dropping, unusual days,
// losses, forecasts, batches, cooling and expiry (decision 0025). Hand port
// of shared/aiMilk.ts.
import 'dart:math' as math;

import 'package:farm_tap/core/ai/ai_core.dart';
import 'package:farm_tap/core/ai/ai_data.dart';

// ---------------------------------------------------------------- Daily

class MilkSummary {
  const new({
    required this.today,
    required this.yesterday,
    required this.todayRecorded,
    required this.avg7,
    required this.avgPrev7,
    required this.weekChangePct,
    required this.last30,
    required this.recordedDays30,
    required this.monthToDate,
    required this.lastMonthSameDays,
  });
  final double today;
  final double yesterday;
  final bool todayRecorded;
  final double? avg7;
  final double? avgPrev7;
  final int? weekChangePct;
  final List<MilkDay> last30;
  final int recordedDays30;
  final double monthToDate;
  final double lastMonthSameDays;
}

MilkSummary milkSummary(FarmData d) {
  final days = milkDays(d, 60);
  final last30 = days.sublist(days.length - 30);
  final t = days.last;
  final y = days[days.length - 2];
  final prior = days.sublist(0, days.length - 1);
  List<double> rec(List<MilkDay> xs) => xs.where((x) => x.recorded).map((x) => x.litres).toList();
  final w1 = rec(prior.sublist(prior.length - 7));
  final w0 = rec(prior.sublist(prior.length - 14, prior.length - 7));
  final avg7 = w1.length >= 3 ? mean(w1) : null;
  final avgPrev7 = w0.length >= 3 ? mean(w0) : null;
  final day = today(d);
  final month = day.substring(0, 7);
  final dom = int.parse(day.substring(8, 10));
  final monthToDate = sum(
    alive(d.milk).where((r) => recDay(r)?.startsWith(month) ?? false).map((r) => num0(r.body['litres'])),
  );
  final lm = addDays('$month-01', -1).substring(0, 7);
  final lastMonthSameDays = sum(
    alive(d.milk)
        .where((r) {
          final rd = recDay(r);
          return rd != null && rd.startsWith(lm) && int.parse(rd.substring(8, 10)) <= dom;
        })
        .map((r) => num0(r.body['litres'])),
  );
  return MilkSummary(
    today: t.litres,
    yesterday: y.litres,
    todayRecorded: t.recorded,
    avg7: avg7,
    avgPrev7: avgPrev7,
    weekChangePct: avg7 != null && avgPrev7 != null ? pctChange(avg7, avgPrev7) : null,
    last30: last30,
    recordedDays30: last30.where((x) => x.recorded).length,
    monthToDate: monthToDate,
    lastMonthSameDays: lastMonthSameDays,
  );
}

// ---------------------------------------------------------------- Cows

class CowTrend {
  const new({
    required this.animalId,
    required this.name,
    required this.recent,
    required this.before,
    required this.changePct,
    required this.daysRecent,
    required this.daysBefore,
    required this.daysInMilk,
  });
  final String animalId;
  final String name;
  final double recent;
  final double before;
  final int changePct;
  final int daysRecent;
  final int daysBefore;
  final int? daysInMilk;
}

/// Cows whose last 7 days average is clearly below the 14 days before.
/// Needs at least 3 recorded days in each window.
List<CowTrend> cowTrends(FarmData d) {
  final days = cowDays(d, 22);
  final animals = animalMap(d);
  final end = addDays(today(d), -1);
  final out = <CowTrend>[];
  for (final e in days.entries) {
    final id = e.key;
    final a = animals[id];
    final st = a?.str('status');
    if (a != null && st != null && st.isNotEmpty && st != 'active') continue;
    final recent = <double>[];
    final before = <double>[];
    for (final p in e.value.entries) {
      if (p.key.compareTo(end) > 0) continue;
      final age = jsRound((msOf(end)! - msOf(p.key)!) / 86400000).toInt();
      if (age < 7) {
        recent.add(p.value);
      } else if (age < 21) {
        before.add(p.value);
      }
    }
    if (recent.length < 3 || before.length < 3) continue;
    final r = mean(recent);
    final b = mean(before);
    final pct = pctChange(r, b);
    if (pct == null) continue;
    out.add(
      CowTrend(
        animalId: id,
        name: animalName(a),
        recent: round1(r),
        before: round1(b),
        changePct: pct,
        daysRecent: recent.length,
        daysBefore: before.length,
        daysInMilk: breedingState(id, d.breeding, today(d)).daysInMilk,
      ),
    );
  }
  // Dart's List.sort is not stable; keep input order for equal values.
  final idx = {for (var i = 0; i < out.length; i++) out[i]: i};
  out.sort((x, y) => x.changePct != y.changePct ? x.changePct - y.changePct : idx[x]! - idx[y]!);
  return out;
}

const dropPct = -15;

// ---------------------------------------------------------------- Unusual days

class MilkAnomaly {
  const new(this.day, this.litres, this.usual, this.z);
  final String day;
  final double litres;
  final double usual;
  final double z;
}

/// Finished days in the last 14 that were unusually low or high.
List<MilkAnomaly> milkAnomalies(FarmData d) {
  final all = milkDays(d, 45);
  final days = all.sublist(0, all.length - 1);
  final out = <MilkAnomaly>[];
  for (var i = days.length - 14; i < days.length; i++) {
    final x = days[i];
    if (!x.recorded) continue;
    final hist = days.sublist(math.max(0, i - 30), i).where((h) => h.recorded).map((h) => h.litres).toList();
    final z = robustZ(x.litres, hist, minPoints: 10);
    if (z != null && z.abs() >= 3) out.add(MilkAnomaly(x.day, round1(x.litres), round1(median(hist)), round1(z)));
  }
  return out;
}

// ---------------------------------------------------------------- Losses

class MilkBalance {
  const new({
    required this.days,
    required this.produced,
    required this.sold,
    required this.homeUse,
    required this.discarded,
    required this.unaccounted,
  });
  final int days;
  final double produced;
  final double sold;
  final double homeUse;
  final double discarded;
  final double? unaccounted;
}

bool _truthy(Object? v) => v != null && v != false && v != 0 && v != '';

/// Last 7 finished days: milk produced against sold, kept for the home or thrown away.
MilkBalance milkBalance(FarmData d, [int days = 7]) {
  final end = addDays(today(d), -1);
  final from = addDays(end, -(days - 1));
  bool inRange(String? day) => day != null && day.compareTo(from) >= 0 && day.compareTo(end) <= 0;
  final milk = alive(d.milk).where((r) => inRange(recDay(r))).toList();
  final produced = sum(milk.map((r) => num0(r.body['litres'])));
  final homeUse = sum(milk.where((r) => _truthy(r.body['notForSale'])).map((r) => num0(r.body['litres'])));
  final sales = alive(d.milkSales).where((r) => inRange(recDay(r))).toList();
  final sold = sum(sales.map((r) => num0(r.body['litres'])));
  final discarded = sum(
    alive(d.milkBatches)
        .where((b) {
          if (b.str('status') != 'discarded') return false;
          final at = b.str('closedAt') ?? b.str('collectedAt');
          return inRange(at == null ? null : (at.length >= 10 ? at.substring(0, 10) : at));
        })
        .map((b) => num0(b.body['litres'])),
  );
  return MilkBalance(
    days: days,
    produced: round1(produced),
    sold: round1(sold),
    homeUse: round1(homeUse),
    discarded: round1(discarded),
    unaccounted: sales.isNotEmpty ? round1(produced - sold - homeUse - discarded) : null,
  );
}

// ---------------------------------------------------------------- Forecast

class ForecastDay {
  const new(this.day, this.litres, this.low, this.high);
  final String day;
  final double litres;
  final double low;
  final double high;
}

class Forecast {
  const new({
    required this.ok,
    required this.daysUsed,
    this.reason,
    this.next7 = const [],
    this.total7 = 0,
    this.total30,
    this.trendPerDay = 0,
    this.confidence = 'low',
    this.method = 'Trend of recorded days',
  });
  final bool ok;
  final String? reason;
  final int daysUsed;
  final List<ForecastDay> next7;
  final double total7;
  final double? total30;
  final double trendPerDay;
  final String confidence;
  final String method;
}

const minForecastDays = 14;

int _daysFrom(String a, String b) => jsRound((msOf(b)! - msOf(a)!) / 86400000).toInt();

/// A weighted straight-line trend over the last 28 recorded days (recent
/// days count more), a weekday effect with at least 4 weeks of records, and
/// an 80% band. Fewer than 14 recorded days: no forecast, and it says so.
Forecast forecastSeries(List<MilkDay> series, String end) {
  var rec = series.where((s) => s.recorded && s.day.compareTo(end) < 0).toList();
  if (rec.length > 28) rec = rec.sublist(rec.length - 28);
  if (rec.length < minForecastDays) {
    return Forecast(
      ok: false,
      daysUsed: rec.length,
      reason: 'Needs at least $minForecastDays days of milk records; there are ${rec.length} in the last 4 weeks.',
    );
  }
  final x0 = msOf(rec.first.day)!;
  final xs = rec.map((r) => (msOf(r.day)! - x0) / 86400000).toList();
  final ys = rec.map((r) => r.litres).toList();
  final last = xs.last;
  final ws = xs.map((x) => math.exp(-(last - x) / 14)).toList();
  final fit = fitLine(xs, ys, ws)!;
  final weekday = List<double>.filled(7, 0);
  if (rec.length >= 24) {
    final groups = List.generate(7, (_) => <double>[]);
    for (var i = 0; i < rec.length; i++) {
      groups[weekdayOf(rec[i].day)].add(ys[i] - (fit.intercept + fit.slope * xs[i]));
    }
    for (var i = 0; i < 7; i++) {
      weekday[i] = groups[i].length >= 3 ? median(groups[i]) : 0;
    }
  }
  final level = mean(ys.sublist(ys.length - 7));
  final slope = math.max(-0.03 * level, math.min(0.03 * level, fit.slope));
  final anchor = fit.intercept + fit.slope * last;
  final band = 1.2816 * fit.residualSd;
  final lastDay = rec.last.day;
  double at(String day) {
    final k = math.min(_daysFrom(lastDay, day), 14);
    return math.max(0, anchor + slope * k + weekday[weekdayOf(day)]);
  }

  final next7 = List.generate(7, (j) {
    final day = addDays(end, j);
    final v = at(day);
    return ForecastDay(day, round1(v), round1(math.max(0, v - band)), round1(v + band));
  });
  final cv = level > 0 ? fit.residualSd / level : 1;
  final stale = _daysFrom(lastDay, end) > 3;
  final confidence = stale
      ? 'low'
      : rec.length >= 24 && cv < 0.08
      ? 'high'
      : cv < 0.15
      ? 'medium'
      : 'low';
  final total30 = rec.length >= 21 ? round1(sum(List.generate(30, (j) => at(addDays(end, j))))) : null;
  return Forecast(
    ok: true,
    daysUsed: rec.length,
    next7: next7,
    total7: round1(sum(next7.map((n) => n.litres))),
    total30: total30,
    trendPerDay: round1(slope),
    confidence: confidence,
    method: rec.length >= 24
        ? 'Weighted trend with weekday pattern, last 28 recorded days'
        : 'Weighted trend, recorded days in the last 4 weeks',
  );
}

Forecast herdForecast(FarmData d) => forecastSeries(milkDays(d, 29), today(d));

Forecast cowForecast(FarmData d, String animalId) {
  final m = cowDays(d, 29)[animalId] ?? <String, double>{};
  final series = <MilkDay>[];
  for (var i = 28; i >= 0; i--) {
    final day = addDays(today(d), -i);
    series.add(
      MilkDay(day)
        ..litres = m[day] ?? 0
        ..recorded = m.containsKey(day),
    );
  }
  return forecastSeries(series, today(d));
}

// ---------------------------------------------------------------- Batches and cooling

class BatchView {
  const new({
    required this.id,
    required this.litres,
    required this.place,
    required this.collectedAt,
    required this.rule,
    required this.useBy,
    required this.hoursLeft,
    required this.state,
    required this.readings,
    required this.highest,
    required this.warm,
    required this.unverified,
    required this.status,
  });
  final String id;
  final double litres;
  final String place;
  final String collectedAt;
  final ShelfRule rule;

  /// Use by, local ISO to the minute.
  final String useBy;
  final double hoursLeft;

  /// fresh, useSoon, expired or closed.
  final String state;
  final int readings;
  final double? highest;
  final bool warm;
  final bool unverified;
  final String status;
}

ShelfRule shelfRule(FarmData d, [String? product]) {
  final rules = (d.shelfRules != null && d.shelfRules!.isNotEmpty) ? d.shelfRules! : defaultShelfRules;
  final p = product ?? 'rawMilk';
  return rules.firstWhere((r) => r.product == p, orElse: () => rules.first);
}

/// Every stored batch with its use-by time. Never a safety test: FarmTap
/// cannot tell if milk is safe.
List<BatchView> batchViews(FarmData d) {
  final now = msOf(d.now)!;
  final readings = alive(d.storageReadings);
  return alive(d.milkBatches).map((b) => _batchView(b, readings, d, now)).toList();
}

String _isoMinute(int ms) {
  final t = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  String p(int n) => n.toString().padLeft(2, '0');
  return '${t.year.toString().padLeft(4, '0')}-${p(t.month)}-${p(t.day)}T${p(t.hour)}:${p(t.minute)}';
}

BatchView _batchView(Rec b, List<Rec> readings, FarmData d, int now) {
  final rule = shelfRule(d, b.str('product'));
  final start = msOf(b.body['collectedAt']) ?? now;
  final status = b.str('status');
  final closed = status != null && status.isNotEmpty && status != 'stored';
  final end = closed ? (msOf(b.body['closedAt']) ?? now) : now;
  final place = b.str('place');
  final mine = readings.where((r) {
    final at = msOf(r.body['at']);
    if (at == null || at < start || at > end) return false;
    final bid = r.str('batchId');
    if (bid != null && bid.isNotEmpty) return bid == b.id;
    final rp = r.str('place');
    return place != null &&
        place.isNotEmpty &&
        rp != null &&
        rp.isNotEmpty &&
        rp.trim().toLowerCase() == place.trim().toLowerCase();
  }).toList();
  final temps = mine.map((r) => num0(r.body['tempC'])).toList();
  final highest = temps.isEmpty ? null : temps.reduce(math.max);
  final cooled = _truthy(b.body['cooled']);
  final warm = !cooled || (highest != null && highest > rule.maxTempC);
  final hours = warm ? rule.warmHours : rule.cooledHours;
  final useByMs = start + (hours * 3600000).round();
  final hoursLeft = jsRound(((useByMs - now) / 3600000) * 10) / 10;
  final state = closed
      ? 'closed'
      : hoursLeft <= 0
      ? 'expired'
      : hoursLeft <= math.max(2, hours * 0.25)
      ? 'useSoon'
      : 'fresh';
  return BatchView(
    id: b.id,
    litres: num0(b.body['litres']),
    place: (place?.trim().isNotEmpty ?? false) ? place!.trim() : 'Not named',
    collectedAt: b.str('collectedAt') ?? '',
    rule: rule,
    useBy: _isoMinute(useByMs),
    hoursLeft: hoursLeft,
    state: state,
    readings: mine.length,
    highest: highest,
    warm: warm,
    unverified: cooled && mine.isEmpty,
    status: status ?? 'stored',
  );
}

class TempBreach {
  const new(this.id, this.place, this.tempC, this.at, this.limit);
  final String id;
  final String place;
  final double tempC;
  final String at;
  final double limit;
}

/// Readings above a rule's limit in the last 7 days.
List<TempBreach> temperatureBreaches(FarmData d) {
  final from = addDays(today(d), -7);
  final limit = shelfRule(d).maxTempC;
  return alive(d.storageReadings)
      .where((r) {
        final at = r.str('at') ?? '';
        return (at.length >= 10 ? at.substring(0, 10) : at).compareTo(from) >= 0 && num0(r.body['tempC']) > limit;
      })
      .map((r) {
        final p = r.str('place')?.trim();
        return TempBreach(
          r.id,
          (p != null && p.isNotEmpty) ? p : 'Not named',
          num0(r.body['tempC']),
          r.str('at') ?? '',
          limit,
        );
      })
      .toList();
}

// ---------------------------------------------------------------- Centre quality

class FarmerQuality {
  const new(this.farmerId, this.deliveries, this.rejected, this.rate);
  final String farmerId;
  final int deliveries;
  final int rejected;
  final int rate;
}

class QualitySummary {
  const new({
    required this.deliveries,
    required this.litres,
    required this.rejected,
    required this.rejectedLitres,
    required this.notTested,
    required this.byFarmer,
  });
  final int deliveries;
  final double litres;
  final int rejected;
  final double rejectedLitres;
  final int notTested;
  final List<FarmerQuality> byFarmer;
}

/// Deliveries in the last 30 days: rejections and missing tests.
QualitySummary qualitySummary(FarmData d) {
  final from = addDays(today(d), -29);
  final ds = alive(d.deliveries).where((r) => (recDay(r, 'at') ?? '').compareTo(from) >= 0).toList();
  final by = <String, List<int>>{};
  for (final r in ds) {
    final f = by.putIfAbsent('${r.body['farmerId']}', () => [0, 0]);
    f[0]++;
    if (r.str('test') == 'failed') f[1]++;
  }
  final failed = ds.where((r) => r.str('test') == 'failed').toList();
  final list = [
    for (final e in by.entries)
      FarmerQuality(e.key, e.value[0], e.value[1], jsRound(e.value[1] / e.value[0] * 100).toInt()),
  ];
  final idx = {for (var i = 0; i < list.length; i++) list[i]: i};
  list.sort((a, b) => a.rate != b.rate ? b.rate - a.rate : idx[a]! - idx[b]!);
  return QualitySummary(
    deliveries: ds.length,
    litres: round1(sum(ds.map((r) => num0(r.body['litres'])))),
    rejected: failed.length,
    rejectedLitres: round1(sum(failed.map((r) => num0(r.body['litres'])))),
    notTested: ds.where((r) {
      final t = r.str('test');
      return t == null || t.isEmpty || t == 'notDone';
    }).length,
    byFarmer: list,
  );
}

// ---------------------------------------------------------------- Findings

String _slice16(String s) => (s.length > 16 ? s.substring(0, 16) : s);

List<Finding> milkFindings(FarmData d) {
  final out = <Finding>[];
  final day = today(d);
  final s = milkSummary(d);
  if (s.weekChangePct != null && s.weekChangePct! <= -10) {
    out.add(
      Finding(
        id: 'milk-week-drop-$day',
        module: 'milk',
        severity: s.weekChangePct! <= -20 ? Severity.high : Severity.medium,
        title: 'Milk is down ${s.weekChangePct!.abs()}% on last week',
        why: 'Recorded days in the last 7 averaged ${fmtL(s.avg7!)} a day; the 7 before averaged ${fmtL(s.avgPrev7!)}.',
        action: 'Check feed and water, and look at the cows dropping most. Rule out mastitis and sick cows first.',
        method: Method.calculated,
        links: const [Link('Milk records', '/milk/')],
      ),
    );
  }
  for (final c in cowTrends(d).where((c) => c.changePct <= dropPct).take(10)) {
    final late = c.daysInMilk != null && c.daysInMilk! > 200;
    out.add(
      Finding(
        id: 'cow-drop-${c.animalId}-$day',
        module: 'milk',
        severity: c.changePct <= -30 && !late ? Severity.high : Severity.medium,
        title: '${c.name} gives ${c.changePct.abs()}% less milk',
        why:
            '${fmtL(c.recent)} a day over ${plural(c.daysRecent, 'recorded day')} this week, against ${fmtL(c.before)} the 2 weeks before.${late ? ' She is ${c.daysInMilk} days into her lactation, when milk falls naturally.' : ''}',
        action: late
            ? 'Likely the normal fall of late lactation. Check her condition and plan drying off.'
            : 'Look at her udder, appetite, feet and temperature today. Call the vet if she is sick.',
        method: Method.calculated,
        links: [Link(c.name, animalHref(c.animalId))],
        subjects: [c.animalId],
      ),
    );
  }
  for (final a in milkAnomalies(d).where((a) => a.z < 0)) {
    out.add(
      Finding(
        id: 'milk-low-day-${a.day}',
        module: 'milk',
        severity: Severity.medium,
        title: 'Unusually little milk on ${fmtDay(a.day)}',
        why:
            '${fmtL(a.litres)} recorded, against a usual ${fmtL(a.usual)} (much lower than any normal day in the month before).',
        action: 'Check that every milking that day was recorded. If it was, find what changed (feed, water, sickness, a missed milking).',
        method: Method.statistical,
        links: const [Link('Milk records', '/milk/')],
      ),
    );
  }
  final bal = milkBalance(d);
  if (bal.unaccounted != null && bal.produced > 0 && bal.unaccounted! > math.max(5, bal.produced * 0.05)) {
    out.add(
      Finding(
        id: 'milk-unaccounted-$day',
        module: 'milk',
        severity: bal.unaccounted! > bal.produced * 0.15 ? Severity.high : Severity.medium,
        title: '${fmtL(bal.unaccounted!)} of milk not accounted for this week',
        why:
            'Last 7 days: ${fmtL(bal.produced)} produced, ${fmtL(bal.sold)} sold, ${fmtL(bal.homeUse)} for the home, ${fmtL(bal.discarded)} thrown away.',
        action: 'Check that every sale and home use was recorded. Then look for spills, spoilt milk or missing milk.',
        method: Method.calculated,
        links: const [Link('Milk sales', '/milk/')],
      ),
    );
  }
  if (!s.todayRecorded && int.parse(d.now.substring(11, 13)) >= 11 && s.recordedDays30 >= 7) {
    out.add(
      Finding(
        id: 'milk-not-recorded-$day',
        module: 'milk',
        severity: Severity.low,
        title: 'No milk recorded yet today',
        why: 'Milk was recorded on ${s.recordedDays30} of the last 30 days, but nothing yet today.',
        action: 'Record this morning’s milking.',
        method: Method.calculated,
        links: const [Link('Record milk', '/milk/?new=1')],
      ),
    );
  }
  return out;
}

List<Finding> qualityFindings(FarmData d) {
  final out = <Finding>[];
  for (final b in batchViews(d)) {
    if (b.state == 'expired') {
      out.add(
        Finding(
          id: 'batch-expired-${b.id}',
          module: 'quality',
          severity: Severity.critical,
          title: '${fmtL(b.litres)} in ${b.place} is past its use-by',
          why:
              'Collected ${_slice16(b.collectedAt.replaceFirst('T', ' '))}; ${b.warm ? '${jsNum(b.rule.warmHours)} hours when warm' : '${jsNum(b.rule.cooledHours)} hours when cooled'} under your ${b.rule.label.toLowerCase()} rule.',
          action: 'Do not sell it as fresh milk. Test it or throw it away, then mark the batch.',
          method: Method.calculated,
          links: const [Link('Milk batches', '/ai/quality/')],
          subjects: [b.id],
        ),
      );
    } else if (b.state == 'useSoon') {
      out.add(
        Finding(
          id: 'batch-soon-${b.id}',
          module: 'quality',
          severity: Severity.high,
          title: '${fmtL(b.litres)} in ${b.place} must go within ${jsNum(b.hoursLeft)} hours',
          why:
              'Use by ${b.useBy.replaceFirst('T', ' ')} under your ${b.rule.label.toLowerCase()} rule${b.unverified ? ' (no temperature reading yet, so not verified)' : ''}.',
          action: 'Sell or deliver this milk first.',
          method: Method.calculated,
          links: const [Link('Milk batches', '/ai/quality/')],
          subjects: [b.id],
        ),
      );
    }
    if (b.status == 'stored' && b.unverified) {
      out.add(
        Finding(
          id: 'batch-no-temp-${b.id}',
          module: 'quality',
          severity: Severity.low,
          title: 'No temperature for the milk in ${b.place}',
          why: 'The batch is marked cooled but has no reading, so its use-by is not verified.',
          action: 'Read the cooler’s thermometer and record it.',
          method: Method.calculated,
          links: const [Link('Record a temperature', '/ai/quality/')],
          subjects: [b.id],
        ),
      );
    }
  }
  for (final t in temperatureBreaches(d)) {
    out.add(
      Finding(
        id: 'temp-high-${t.id}',
        module: 'quality',
        severity: t.tempC > t.limit + 4 ? Severity.high : Severity.medium,
        title: '${t.place} was ${jsNum(t.tempC)} °C',
        why: 'Recorded ${_slice16(t.at.replaceFirst('T', ' '))}; the limit for cooled milk is ${jsNum(t.limit)} °C.',
        action: 'Check the cooler and its power. Milk kept above the limit follows the shorter warm use-by.',
        method: Method.calculated,
        links: const [Link('Temperatures', '/ai/quality/')],
        subjects: [t.id],
      ),
    );
  }
  final q = qualitySummary(d);
  if (q.deliveries >= 10 && q.notTested / q.deliveries >= 0.2) {
    out.add(
      Finding(
        id: 'quality-untested-${today(d)}',
        module: 'quality',
        severity: Severity.medium,
        title: '${q.notTested} of ${q.deliveries} deliveries were not tested',
        why: 'Deliveries in the last 30 days with no quality test recorded.',
        action: 'Test every delivery before it goes in the cooler.',
        method: Method.calculated,
        links: const [Link('Milk suppliers', '/farmers/')],
      ),
    );
  }
  for (final f in q.byFarmer.where((f) => f.deliveries >= 5 && f.rate >= 20).take(5)) {
    out.add(
      Finding(
        id: 'quality-farmer-${f.farmerId}-${today(d)}',
        module: 'quality',
        severity: Severity.medium,
        title: 'A supplier’s milk failed ${f.rate}% of tests',
        why: '${f.rejected} of ${f.deliveries} deliveries rejected in the last 30 days.',
        action: 'Talk to the farmer about milking hygiene, cooling and transport.',
        method: Method.calculated,
        links: [Link('Supplier', '/farmers/?farmer=${Uri.encodeComponent(f.farmerId)}')],
        subjects: [f.farmerId],
      ),
    );
  }
  return out;
}
