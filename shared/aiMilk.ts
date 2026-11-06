// FarmTap AI engine — milk: daily analysis, cows dropping, unusual days,
// losses, forecasts, batches, cooling and expiry (decision 0025).

import {
  addDays,
  alive,
  fitLine,
  fmtDay,
  fmtL,
  mean,
  median,
  msOf,
  num,
  pctChange,
  plural,
  recDay,
  robustZ,
  round1,
  sum,
  weekdayOf,
  type Finding,
  type Rec,
} from './aiCore.ts';
import {
  animalHref,
  animalMap,
  animalName,
  breedingState,
  cowDays,
  defaultShelfRules,
  milkDays,
  today,
  type FarmData,
  type MilkBatchIn,
  type ShelfRule,
  type StorageReadingIn,
} from './aiData.ts';

// ---------------------------------------------------------------- Daily

export interface MilkSummary {
  today: number;
  yesterday: number;
  todayRecorded: boolean;
  /** Average of recorded days in the last 7 (today excluded when it is not finished). */
  avg7: number | null;
  avgPrev7: number | null;
  weekChangePct: number | null;
  last30: { day: string; litres: number; recorded: boolean }[];
  recordedDays30: number;
  /** Month so far and the same days last month. */
  monthToDate: number;
  lastMonthSameDays: number;
}

export function milkSummary(d: FarmData): MilkSummary {
  const days = milkDays(d, 60);
  const last30 = days.slice(-30);
  const t = days[days.length - 1];
  const y = days[days.length - 2];
  const prior = days.slice(0, -1); // finished days
  const rec = (xs: typeof days) => xs.filter((x) => x.recorded).map((x) => x.litres);
  const w1 = rec(prior.slice(-7));
  const w0 = rec(prior.slice(-14, -7));
  const avg7 = w1.length >= 3 ? mean(w1) : null;
  const avgPrev7 = w0.length >= 3 ? mean(w0) : null;
  const day = today(d);
  const month = day.slice(0, 7);
  const dom = +day.slice(8, 10);
  const monthToDate = sum(alive(d.milk).filter((r) => recDay(r)?.startsWith(month)).map((r) => num(r.body.litres)));
  const lm = addDays(`${month}-01`, -1).slice(0, 7);
  const lastMonthSameDays = sum(
    alive(d.milk)
      .filter((r) => {
        const rd = recDay(r);
        return rd?.startsWith(lm) && +rd.slice(8, 10) <= dom;
      })
      .map((r) => num(r.body.litres)),
  );
  return {
    today: t.litres,
    yesterday: y.litres,
    todayRecorded: t.recorded,
    avg7,
    avgPrev7,
    weekChangePct: avg7 != null && avgPrev7 != null ? pctChange(avg7, avgPrev7) : null,
    last30,
    recordedDays30: last30.filter((x) => x.recorded).length,
    monthToDate,
    lastMonthSameDays,
  };
}

// ---------------------------------------------------------------- Cows

export interface CowTrend {
  animalId: string;
  name: string;
  recent: number;
  before: number;
  changePct: number;
  daysRecent: number;
  daysBefore: number;
  daysInMilk: number | null;
}

/**
 * Cows whose last 7 days average is clearly below the 14 days before.
 * Needs at least 3 recorded days in each window, and only farms that
 * record milk per cow. A cow late in lactation (over 200 days in milk)
 * drops naturally; that is said in the reason, not hidden.
 */
export function cowTrends(d: FarmData): CowTrend[] {
  const days = cowDays(d, 22);
  const animals = animalMap(d);
  const end = addDays(today(d), -1);
  const out: CowTrend[] = [];
  for (const [id, m] of days) {
    const a = animals.get(id);
    if (a && a.body.status && a.body.status !== 'active') continue;
    const recent: number[] = [];
    const before: number[] = [];
    for (const [day, l] of m) {
      if (day > end) continue;
      const age = Math.round((msOf(end)! - msOf(day)!) / 86_400_000);
      if (age < 7) recent.push(l);
      else if (age < 21) before.push(l);
    }
    if (recent.length < 3 || before.length < 3) continue;
    const r = mean(recent);
    const b = mean(before);
    const pct = pctChange(r, b);
    if (pct == null) continue;
    out.push({
      animalId: id,
      name: animalName(a),
      recent: round1(r),
      before: round1(b),
      changePct: pct,
      daysRecent: recent.length,
      daysBefore: before.length,
      daysInMilk: breedingState(id, d.breeding ?? [], today(d)).daysInMilk,
    });
  }
  return out.sort((x, y) => x.changePct - y.changePct);
}

export const DROP_PCT = -15;

// ---------------------------------------------------------------- Unusual days

export interface MilkAnomaly {
  day: string;
  litres: number;
  usual: number;
  z: number;
}

/** Finished days in the last 14 that were unusually low or high against the 30 recorded days before them. */
export function milkAnomalies(d: FarmData): MilkAnomaly[] {
  const days = milkDays(d, 45).slice(0, -1);
  const out: MilkAnomaly[] = [];
  for (let i = days.length - 14; i < days.length; i++) {
    const x = days[i];
    if (!x?.recorded) continue;
    const hist = days.slice(Math.max(0, i - 30), i).filter((h) => h.recorded).map((h) => h.litres);
    const z = robustZ(x.litres, hist, 10);
    if (z != null && Math.abs(z) >= 3) out.push({ day: x.day, litres: round1(x.litres), usual: round1(median(hist)), z: round1(z) });
  }
  return out;
}

// ---------------------------------------------------------------- Losses

export interface MilkBalance {
  days: number;
  produced: number;
  sold: number;
  homeUse: number;
  discarded: number;
  /** Produced minus everything accounted for; null when sales are not recorded. */
  unaccounted: number | null;
}

/** Last 7 finished days: milk produced against milk sold, kept for the home or thrown away. */
export function milkBalance(d: FarmData, days = 7): MilkBalance {
  const end = addDays(today(d), -1);
  const from = addDays(end, -(days - 1));
  const inRange = (day: string | null) => !!day && day >= from && day <= end;
  const milk = alive(d.milk).filter((r) => inRange(recDay(r)));
  const produced = sum(milk.map((r) => num(r.body.litres)));
  const homeUse = sum(milk.filter((r) => r.body.notForSale).map((r) => num(r.body.litres)));
  const sales = alive(d.milkSales).filter((r) => inRange(recDay(r)));
  const sold = sum(sales.map((r) => num(r.body.litres)));
  const discarded = sum(
    alive(d.milkBatches)
      .filter((b) => b.body.status === 'discarded' && inRange((b.body.closedAt ?? b.body.collectedAt)?.slice(0, 10) ?? null))
      .map((b) => num(b.body.litres)),
  );
  return {
    days,
    produced: round1(produced),
    sold: round1(sold),
    homeUse: round1(homeUse),
    discarded: round1(discarded),
    unaccounted: sales.length ? round1(produced - sold - homeUse - discarded) : null,
  };
}

// ---------------------------------------------------------------- Forecast

export interface Forecast {
  ok: boolean;
  /** Why there is no forecast, in plain words. */
  reason?: string;
  daysUsed: number;
  next7: { day: string; litres: number; low: number; high: number }[];
  total7: number;
  total30: number | null;
  /** Litres per day per day: + rising, − falling. */
  trendPerDay: number;
  confidence: 'low' | 'medium' | 'high';
  method: string;
}

export const MIN_FORECAST_DAYS = 14;

/**
 * Herd (or one cow) forecast: a weighted straight-line trend over the last
 * 28 recorded days (recent days count more), plus a weekday effect when
 * there are at least 4 weeks of records, and an 80% band from what the
 * line got wrong. Fewer than 14 recorded days: no forecast, and it says so.
 */
export function forecastSeries(series: { day: string; litres: number; recorded: boolean }[], end: string): Forecast {
  const rec = series.filter((s) => s.recorded && s.day < end).slice(-28);
  const base: Forecast = { ok: false, daysUsed: rec.length, next7: [], total7: 0, total30: null, trendPerDay: 0, confidence: 'low', method: 'Trend of recorded days' };
  if (rec.length < MIN_FORECAST_DAYS)
    return { ...base, reason: `Needs at least ${MIN_FORECAST_DAYS} days of milk records; there are ${rec.length} in the last 4 weeks.` };
  const x0 = msOf(rec[0].day)!;
  const xs = rec.map((r) => (msOf(r.day)! - x0) / 86_400_000);
  const ys = rec.map((r) => r.litres);
  const last = xs[xs.length - 1];
  const ws = xs.map((x) => Math.exp(-(last - x) / 14));
  const fit = fitLine(xs, ys, ws)!;
  // Weekday effect: average leftover per weekday, only with 4 weeks of data.
  const weekday = new Array(7).fill(0);
  if (rec.length >= 24) {
    const groups: number[][] = Array.from({ length: 7 }, () => []);
    rec.forEach((r, i) => groups[weekdayOf(r.day)].push(ys[i] - (fit.intercept + fit.slope * xs[i])));
    groups.forEach((g, i) => (weekday[i] = g.length >= 3 ? median(g) : 0));
  }
  const level = mean(ys.slice(-7));
  // Do not let a steep short trend run away: cap the daily change to 3% of the level.
  const slope = Math.max(-0.03 * level, Math.min(0.03 * level, fit.slope));
  const anchor = fit.intercept + fit.slope * last;
  const band = 1.2816 * fit.residualSd;
  const lastDay = rec[rec.length - 1].day;
  // Days ahead of the last record; the trend is held flat after 14 days so a month is not a runaway line.
  const at = (day: string) => {
    const k = Math.min(daysFrom(lastDay, day), 14);
    return Math.max(0, anchor + slope * k + weekday[weekdayOf(day)]);
  };
  const next7 = Array.from({ length: 7 }, (_, j) => {
    const day = addDays(end, j);
    const v = at(day);
    return { day, litres: round1(v), low: round1(Math.max(0, v - band)), high: round1(v + band) };
  });
  const cv = level > 0 ? fit.residualSd / level : 1;
  const stale = daysFrom(lastDay, end) > 3;
  const confidence = stale ? 'low' : rec.length >= 24 && cv < 0.08 ? 'high' : cv < 0.15 ? 'medium' : 'low';
  const total30 = rec.length >= 21 ? round1(sum(Array.from({ length: 30 }, (_, j) => at(addDays(end, j))))) : null;
  return {
    ok: true,
    daysUsed: rec.length,
    next7,
    total7: round1(sum(next7.map((n) => n.litres))),
    total30,
    trendPerDay: round1(slope),
    confidence,
    method: rec.length >= 24 ? 'Weighted trend with weekday pattern, last 28 recorded days' : 'Weighted trend, recorded days in the last 4 weeks',
  };
}
const daysFrom = (a: string, b: string) => Math.round((msOf(b)! - msOf(a)!) / 86_400_000);

export function herdForecast(d: FarmData): Forecast {
  return forecastSeries(milkDays(d, 29), today(d));
}

export function cowForecast(d: FarmData, animalId: string): Forecast {
  const m = cowDays(d, 29).get(animalId) ?? new Map<string, number>();
  const series = [];
  for (let i = 28; i >= 0; i--) {
    const day = addDays(today(d), -i);
    series.push({ day, litres: m.get(day) ?? 0, recorded: m.has(day) });
  }
  return forecastSeries(series, today(d));
}

// ---------------------------------------------------------------- Batches and cooling

export type BatchState = 'fresh' | 'useSoon' | 'expired' | 'closed';

export interface BatchView {
  id: string;
  litres: number;
  place: string;
  collectedAt: string;
  rule: ShelfRule;
  /** Use by, local ISO. */
  useBy: string;
  hoursLeft: number;
  state: BatchState;
  readings: number;
  highest: number | null;
  /** A reading above the rule's limit (or not cooled at all): the warm rule applies. */
  warm: boolean;
  /** Cooled, but no temperature reading: the use-by is not verified. */
  unverified: boolean;
  status: string;
}

export function shelfRule(d: FarmData, product?: string): ShelfRule {
  const rules = d.shelfRules?.length ? d.shelfRules : defaultShelfRules;
  return rules.find((r) => r.product === (product ?? 'rawMilk')) ?? rules[0];
}

/**
 * Every stored batch with its use-by time. Cooled milk with every reading
 * at or below the limit keeps for the rule's cooled hours; milk not cooled,
 * or with any reading above the limit, keeps only the warm hours from
 * collection. With no reading the cooled use-by is shown as not verified.
 * A use-by is never a safety test: FarmTap cannot tell if milk is safe.
 */
export function batchViews(d: FarmData): BatchView[] {
  const now = msOf(d.now)!;
  const readings = alive(d.storageReadings);
  return alive(d.milkBatches).map((b) => batchView(b, readings, d, now));
}

function batchView(b: Rec<MilkBatchIn>, readings: Rec<StorageReadingIn>[], d: FarmData, now: number): BatchView {
  const rule = shelfRule(d, b.body.product);
  const start = msOf(b.body.collectedAt) ?? now;
  const closed = b.body.status && b.body.status !== 'stored';
  const end = closed ? (msOf(b.body.closedAt) ?? now) : now;
  const mine = readings.filter((r) => {
    const at = msOf(r.body.at);
    if (at == null || at < start || at > end) return false;
    if (r.body.batchId) return r.body.batchId === b.id;
    return !!b.body.place && !!r.body.place && r.body.place.trim().toLowerCase() === b.body.place.trim().toLowerCase();
  });
  const temps = mine.map((r) => num(r.body.tempC));
  const highest = temps.length ? Math.max(...temps) : null;
  const warm = !b.body.cooled || (highest != null && highest > rule.maxTempC);
  const hours = warm ? rule.warmHours : rule.cooledHours;
  const useByMs = start + hours * 3_600_000;
  const hoursLeft = Math.round(((useByMs - now) / 3_600_000) * 10) / 10;
  const state: BatchState = closed ? 'closed' : hoursLeft <= 0 ? 'expired' : hoursLeft <= Math.max(2, hours * 0.25) ? 'useSoon' : 'fresh';
  return {
    id: b.id,
    litres: num(b.body.litres),
    place: b.body.place?.trim() || 'Not named',
    collectedAt: b.body.collectedAt,
    rule,
    useBy: new Date(useByMs).toISOString().slice(0, 16),
    hoursLeft,
    state,
    readings: mine.length,
    highest,
    warm,
    unverified: !!b.body.cooled && mine.length === 0,
    status: b.body.status ?? 'stored',
  };
}

/** Readings above a rule's limit in the last 7 days, by place. */
export function temperatureBreaches(d: FarmData): { id: string; place: string; tempC: number; at: string; limit: number }[] {
  const from = addDays(today(d), -7);
  const limit = shelfRule(d).maxTempC;
  return alive(d.storageReadings)
    .filter((r) => (r.body.at ?? '').slice(0, 10) >= from && num(r.body.tempC) > limit)
    .map((r) => ({ id: r.id, place: r.body.place?.trim() || 'Not named', tempC: num(r.body.tempC), at: r.body.at, limit }));
}

// ---------------------------------------------------------------- Centre quality

export interface QualitySummary {
  deliveries: number;
  litres: number;
  rejected: number;
  rejectedLitres: number;
  notTested: number;
  byFarmer: { farmerId: string; deliveries: number; rejected: number; rate: number }[];
}

/** Deliveries in the last 30 days: rejections and missing tests. */
export function qualitySummary(d: FarmData): QualitySummary {
  const from = addDays(today(d), -29);
  const ds = alive(d.deliveries).filter((r) => (recDay(r, 'at') ?? '') >= from);
  const by = new Map<string, { deliveries: number; rejected: number }>();
  for (const r of ds) {
    const f = by.get(r.body.farmerId) ?? { deliveries: 0, rejected: 0 };
    f.deliveries++;
    if (r.body.test === 'failed') f.rejected++;
    by.set(r.body.farmerId, f);
  }
  const failed = ds.filter((r) => r.body.test === 'failed');
  return {
    deliveries: ds.length,
    litres: round1(sum(ds.map((r) => num(r.body.litres)))),
    rejected: failed.length,
    rejectedLitres: round1(sum(failed.map((r) => num(r.body.litres)))),
    notTested: ds.filter((r) => !r.body.test || r.body.test === 'notDone').length,
    byFarmer: [...by.entries()]
      .map(([farmerId, f]) => ({ farmerId, ...f, rate: Math.round((f.rejected / f.deliveries) * 100) }))
      .sort((a, b) => b.rate - a.rate),
  };
}

// ---------------------------------------------------------------- Findings

export function milkFindings(d: FarmData): Finding[] {
  const out: Finding[] = [];
  const day = today(d);
  const s = milkSummary(d);
  if (s.weekChangePct != null && s.weekChangePct <= -10)
    out.push({
      id: `milk-week-drop-${day}`,
      module: 'milk',
      severity: s.weekChangePct <= -20 ? 'high' : 'medium',
      title: `Milk is down ${Math.abs(s.weekChangePct)}% on last week`,
      why: `Recorded days in the last 7 averaged ${fmtL(s.avg7!)} a day; the 7 before averaged ${fmtL(s.avgPrev7!)}.`,
      action: 'Check feed and water, and look at the cows dropping most. Rule out mastitis and sick cows first.',
      method: 'calculated',
      links: [{ label: 'Milk records', href: '/milk/' }],
      subjects: [],
    });
  for (const c of cowTrends(d).filter((c) => c.changePct <= DROP_PCT).slice(0, 10)) {
    const late = c.daysInMilk != null && c.daysInMilk > 200;
    out.push({
      id: `cow-drop-${c.animalId}-${day}`,
      module: 'milk',
      severity: c.changePct <= -30 && !late ? 'high' : 'medium',
      title: `${c.name} gives ${Math.abs(c.changePct)}% less milk`,
      why: `${fmtL(c.recent)} a day over ${plural(c.daysRecent, 'recorded day')} this week, against ${fmtL(c.before)} the 2 weeks before.${late ? ` She is ${c.daysInMilk} days into her lactation, when milk falls naturally.` : ''}`,
      action: late ? 'Likely the normal fall of late lactation. Check her condition and plan drying off.' : 'Look at her udder, appetite, feet and temperature today. Call the vet if she is sick.',
      method: 'calculated',
      links: [{ label: c.name, href: animalHref(c.animalId) }],
      subjects: [c.animalId],
    });
  }
  for (const a of milkAnomalies(d).filter((a) => a.z < 0))
    out.push({
      id: `milk-low-day-${a.day}`,
      module: 'milk',
      severity: 'medium',
      title: `Unusually little milk on ${fmtDay(a.day)}`,
      why: `${fmtL(a.litres)} recorded, against a usual ${fmtL(a.usual)} (much lower than any normal day in the month before).`,
      action: 'Check that every milking that day was recorded. If it was, find what changed (feed, water, sickness, a missed milking).',
      method: 'statistical',
      links: [{ label: 'Milk records', href: '/milk/' }],
      subjects: [],
    });
  const bal = milkBalance(d);
  if (bal.unaccounted != null && bal.produced > 0 && bal.unaccounted > Math.max(5, bal.produced * 0.05))
    out.push({
      id: `milk-unaccounted-${day}`,
      module: 'milk',
      severity: bal.unaccounted > bal.produced * 0.15 ? 'high' : 'medium',
      title: `${fmtL(bal.unaccounted)} of milk not accounted for this week`,
      why: `Last 7 days: ${fmtL(bal.produced)} produced, ${fmtL(bal.sold)} sold, ${fmtL(bal.homeUse)} for the home, ${fmtL(bal.discarded)} thrown away.`,
      action: 'Check that every sale and home use was recorded. Then look for spills, spoilt milk or missing milk.',
      method: 'calculated',
      links: [{ label: 'Milk sales', href: '/milk/' }],
      subjects: [],
    });
  if (!s.todayRecorded && +d.now.slice(11, 13) >= 11 && s.recordedDays30 >= 7)
    out.push({
      id: `milk-not-recorded-${day}`,
      module: 'milk',
      severity: 'low',
      title: 'No milk recorded yet today',
      why: `Milk was recorded on ${s.recordedDays30} of the last 30 days, but nothing yet today.`,
      action: 'Record this morning’s milking.',
      method: 'calculated',
      links: [{ label: 'Record milk', href: '/milk/?new=1' }],
      subjects: [],
    });
  return out;
}

export function qualityFindings(d: FarmData): Finding[] {
  const out: Finding[] = [];
  for (const b of batchViews(d)) {
    if (b.state === 'expired')
      out.push({
        id: `batch-expired-${b.id}`,
        module: 'quality',
        severity: 'critical',
        title: `${fmtL(b.litres)} in ${b.place} is past its use-by`,
        why: `Collected ${b.collectedAt.replace('T', ' ').slice(0, 16)}; ${b.warm ? `${b.rule.warmHours} hours when warm` : `${b.rule.cooledHours} hours when cooled`} under your ${b.rule.label.toLowerCase()} rule.`,
        action: 'Do not sell it as fresh milk. Test it or throw it away, then mark the batch.',
        method: 'calculated',
        links: [{ label: 'Milk batches', href: '/ai/quality/' }],
        subjects: [b.id],
      });
    else if (b.state === 'useSoon')
      out.push({
        id: `batch-soon-${b.id}`,
        module: 'quality',
        severity: 'high',
        title: `${fmtL(b.litres)} in ${b.place} must go within ${b.hoursLeft} hours`,
        why: `Use by ${b.useBy.replace('T', ' ')} under your ${b.rule.label.toLowerCase()} rule${b.unverified ? ' (no temperature reading yet, so not verified)' : ''}.`,
        action: 'Sell or deliver this milk first.',
        method: 'calculated',
        links: [{ label: 'Milk batches', href: '/ai/quality/' }],
        subjects: [b.id],
      });
    if (b.status === 'stored' && b.unverified)
      out.push({
        id: `batch-no-temp-${b.id}`,
        module: 'quality',
        severity: 'low',
        title: `No temperature for the milk in ${b.place}`,
        why: 'The batch is marked cooled but has no reading, so its use-by is not verified.',
        action: 'Read the cooler’s thermometer and record it.',
        method: 'calculated',
        links: [{ label: 'Record a temperature', href: '/ai/quality/' }],
        subjects: [b.id],
      });
  }
  for (const t of temperatureBreaches(d))
    out.push({
      id: `temp-high-${t.id}`,
      module: 'quality',
      severity: t.tempC > t.limit + 4 ? 'high' : 'medium',
      title: `${t.place} was ${t.tempC} °C`,
      why: `Recorded ${t.at.replace('T', ' ').slice(0, 16)}; the limit for cooled milk is ${t.limit} °C.`,
      action: 'Check the cooler and its power. Milk kept above the limit follows the shorter warm use-by.',
      method: 'calculated',
      links: [{ label: 'Temperatures', href: '/ai/quality/' }],
      subjects: [t.id],
    });
  const q = qualitySummary(d);
  if (q.deliveries >= 10 && q.notTested / q.deliveries >= 0.2)
    out.push({
      id: `quality-untested-${today(d)}`,
      module: 'quality',
      severity: 'medium',
      title: `${q.notTested} of ${q.deliveries} deliveries were not tested`,
      why: 'Deliveries in the last 30 days with no quality test recorded.',
      action: 'Test every delivery before it goes in the cooler.',
      method: 'calculated',
      links: [{ label: 'Milk suppliers', href: '/farmers/' }],
      subjects: [],
    });
  for (const f of q.byFarmer.filter((f) => f.deliveries >= 5 && f.rate >= 20).slice(0, 5))
    out.push({
      id: `quality-farmer-${f.farmerId}-${today(d)}`,
      module: 'quality',
      severity: 'medium',
      title: `A supplier’s milk failed ${f.rate}% of tests`,
      why: `${f.rejected} of ${f.deliveries} deliveries rejected in the last 30 days.`,
      action: 'Talk to the farmer about milking hygiene, cooling and transport.',
      method: 'calculated',
      links: [{ label: 'Supplier', href: `/farmers/?farmer=${encodeURIComponent(f.farmerId)}` }],
      subjects: [f.farmerId],
    });
  return out;
}
