// FarmTap AI engine — animal health and breeding (decision 0025).

import { addDays, alive, daysBetween, dayOf, fmtDay, num, plural, recDay, type Finding, type Rec } from './aiCore.ts';
import { animalHref, animalMap, animalName, breedingState, isActive, today, type AnimalIn, type FarmData, type VaccinationIn } from './aiData.ts';
import { cowTrends, DROP_PCT } from './aiMilk.ts';

// ---------------------------------------------------------------- Vaccinations

export interface VaccineDue {
  vaccine: string;
  /** Empty = the whole herd. */
  animalIds: string[];
  due: string;
  overdueDays: number;
  doseId: string;
}

/**
 * Doses whose next one is due within 7 days or overdue, and not yet given
 * again: a later dose of the same vaccine to the same animals (or the herd)
 * closes the earlier one.
 */
export function vaccinesDue(d: FarmData): VaccineDue[] {
  const day = today(d);
  const vs = alive(d.vaccinations);
  const covers = (later: Rec<VaccinationIn>, ids: string[]) => {
    const l = later.body.animalIds ?? [];
    return !l.length || (ids.length > 0 && ids.every((i) => l.includes(i)));
  };
  const out: VaccineDue[] = [];
  for (const v of vs) {
    const due = dayOf(v.body.nextDue);
    if (!due || due > addDays(day, 7)) continue;
    const given = recDay(v, 'given') ?? '';
    const ids = v.body.animalIds ?? [];
    const redone = vs.some((o) => o.id !== v.id && o.body.vaccine === v.body.vaccine && (recDay(o, 'given') ?? '') > given && covers(o, ids));
    if (redone) continue;
    out.push({ vaccine: v.body.vaccine, animalIds: ids, due, overdueDays: Math.max(0, daysBetween(due, day)), doseId: v.id });
  }
  return out.sort((a, b) => b.overdueDays - a.overdueDays || a.due.localeCompare(b.due));
}

// ---------------------------------------------------------------- Animal summary

export interface AnimalHealth {
  animalId: string;
  name: string;
  treatments90: number;
  conditions: { condition: string; times: number; last: string }[];
  lastTreatment: string | null;
  inWithdrawal: boolean;
  safeFrom: string | null;
  followUp: string | null;
  vaccinesDue: VaccineDue[];
  milkChangePct: number | null;
  breeding: ReturnType<typeof breedingState>;
  /** Plain reasons this animal needs attention, most serious first. */
  attention: string[];
}

export function animalHealth(d: FarmData, animalId: string): AnimalHealth {
  const day = today(d);
  const a = animalMap(d).get(animalId);
  const ts = alive(d.treatments)
    .filter((t) => t.body.animalId === animalId)
    .sort((x, y) => (recDay(y, 'given') ?? '').localeCompare(recDay(x, 'given') ?? ''));
  const from90 = addDays(day, -90);
  const recent = ts.filter((t) => (recDay(t, 'given') ?? '') >= from90);
  const byCond = new Map<string, { times: number; last: string }>();
  for (const t of recent) {
    const c = (t.body.condition || 'other').toLowerCase();
    const g = recDay(t, 'given') ?? day;
    const cur = byCond.get(c);
    byCond.set(c, { times: (cur?.times ?? 0) + 1, last: cur && cur.last > g ? cur.last : g });
  }
  const last = ts[0];
  const lastDay = last ? recDay(last, 'given') : null;
  const safe = last && lastDay ? addDays(lastDay, num(last.body.withdrawalDays)) : null;
  const inWithdrawal = !!safe && num(last?.body.withdrawalDays) > 0 && safe > day;
  const course = last && lastDay && num(last.body.courseDays) > 1 ? addDays(lastDay, num(last.body.courseDays) - 1) : null;
  const followUp = course && course >= day ? course : null;
  const vd = vaccinesDue(d).filter((v) => !v.animalIds.length || v.animalIds.includes(animalId));
  const trend = cowTrends(d).find((c) => c.animalId === animalId);
  const breeding = breedingState(animalId, d.breeding ?? [], day);
  const conditions = [...byCond.entries()].map(([condition, v]) => ({ condition, ...v })).sort((x, y) => y.times - x.times);
  const attention: string[] = [];
  if (recent.length >= 3) attention.push(`Treated ${recent.length} times in 90 days`);
  for (const c of conditions.filter((c) => c.times >= 2)) attention.push(`${cap(c.condition)} ${c.times} times in 90 days`);
  if (trend && trend.changePct <= DROP_PCT) attention.push(`Milk down ${Math.abs(trend.changePct)}% this week`);
  for (const v of vd.filter((v) => v.overdueDays > 0)) attention.push(`${v.vaccine} overdue ${plural(v.overdueDays, 'day')}`);
  if (followUp) attention.push(`Treatment course ends ${fmtDay(followUp)}`);
  if (breeding.due && daysBetween(day, breeding.due) <= 14 && daysBetween(day, breeding.due) >= -7) attention.push(`Due to calve ${fmtDay(breeding.due)}`);
  return {
    animalId,
    name: animalName(a),
    treatments90: recent.length,
    conditions,
    lastTreatment: lastDay,
    inWithdrawal,
    safeFrom: inWithdrawal ? safe : null,
    followUp,
    vaccinesDue: vd,
    milkChangePct: trend?.changePct ?? null,
    breeding,
    attention,
  };
}

const cap = (s: string) => (s ? s[0].toUpperCase() + s.slice(1) : s);

// ---------------------------------------------------------------- Findings

export function healthFindings(d: FarmData): Finding[] {
  const day = today(d);
  const animals = animalMap(d);
  const out: Finding[] = [];
  const from90 = addDays(day, -90);
  const from60 = addDays(day, -60);
  const perAnimal = new Map<string, Rec<{ condition?: string; given?: string }>[]>();
  for (const t of alive(d.treatments)) {
    if ((recDay(t, 'given') ?? '') < from90) continue;
    const a = animals.get(t.body.animalId);
    if (a && !isActive(a)) continue;
    perAnimal.set(t.body.animalId, [...(perAnimal.get(t.body.animalId) ?? []), t]);
  }
  for (const [id, ts] of perAnimal) {
    const name = animalName(animals.get(id));
    const conds = new Map<string, number>();
    for (const t of ts.filter((t) => (recDay(t, 'given') ?? '') >= from60)) {
      const c = (t.body.condition || 'other').toLowerCase();
      conds.set(c, (conds.get(c) ?? 0) + 1);
    }
    const repeat = [...conds.entries()].filter(([, n]) => n >= 2).sort((a, b) => b[1] - a[1])[0];
    if (repeat || ts.length >= 3)
      out.push({
        id: `repeat-illness-${id}-${day.slice(0, 7)}`,
        module: 'health',
        severity: ts.length >= 4 || (repeat && repeat[1] >= 3) ? 'high' : 'medium',
        title: repeat ? `${name}: ${repeat[0]} came back (${repeat[1]} times)` : `${name} was treated ${ts.length} times`,
        why: repeat ? `${repeat[1]} treatments for ${repeat[0]} in the last 60 days; ${ts.length} treatments in 90 days.` : `${ts.length} treatments in the last 90 days.`,
        action: 'Ask the vet to examine her. An illness that keeps coming back may need a different treatment, or culling may be cheaper.',
        method: 'calculated',
        links: [{ label: name, href: animalHref(id) }],
        subjects: [id],
      });
  }
  for (const v of vaccinesDue(d)) {
    const who = v.animalIds.length ? v.animalIds.map((i) => animalName(animals.get(i))).slice(0, 3).join(', ') + (v.animalIds.length > 3 ? ` and ${v.animalIds.length - 3} more` : '') : 'the whole herd';
    out.push({
      id: `vaccine-${v.doseId}`,
      module: 'health',
      severity: v.overdueDays > 14 ? 'high' : v.overdueDays > 0 ? 'medium' : 'low',
      title: v.overdueDays > 0 ? `${v.vaccine} is ${plural(v.overdueDays, 'day')} overdue` : `${v.vaccine} due ${fmtDay(v.due)}`,
      why: `The last dose for ${who} said the next is due ${fmtDay(v.due)}, and no later dose is recorded.`,
      action: 'Book the vet or vaccinator, then record the dose.',
      method: 'calculated',
      links: [{ label: 'Vaccinations', href: '/health/' }],
      subjects: v.animalIds,
    });
  }
  for (const t of alive(d.treatments)) {
    const g = recDay(t, 'given');
    const days = num(t.body.courseDays);
    if (!g || days <= 1) continue;
    const end = addDays(g, days - 1);
    if (end < day || g > day) continue;
    const name = animalName(animals.get(t.body.animalId));
    out.push({
      id: `course-${t.id}-${day}`,
      module: 'health',
      severity: 'low',
      title: `${name}: treatment course, day ${daysBetween(g, day) + 1} of ${days}`,
      why: `${cap(t.body.condition || 'Treatment')} started ${fmtDay(g)} for ${days} days.`,
      action: 'Give today’s treatment as the vet said and record it.',
      method: 'calculated',
      links: [{ label: name, href: animalHref(t.body.animalId) }],
      subjects: [t.body.animalId],
    });
  }
  return out;
}

export function breedingFindings(d: FarmData): Finding[] {
  const day = today(d);
  const out: Finding[] = [];
  for (const a of alive(d.animals)) {
    if (!isActive(a) || a.body.sex === 'male') continue;
    if (['calf', 'bull'].includes(a.body.dairyStatus ?? '')) continue;
    const b = breedingState(a.id, d.breeding ?? [], day);
    const name = animalName(a);
    const link = [{ label: name, href: animalHref(a.id) }];
    if (b.due) {
      const left = daysBetween(day, b.due);
      if (left <= 30 && left >= -14)
        out.push({
          id: `calving-${a.id}-${b.due}`,
          module: 'breeding',
          severity: left < 0 ? 'high' : left <= 7 ? 'medium' : 'low',
          title: left < 0 ? `${name} is ${plural(-left, 'day')} past her calving date` : `${name} due to calve ${fmtDay(b.due)}`,
          why: `Served ${fmtDay(b.servedDay!)}; ${b.confirmed ? 'pregnancy confirmed' : 'pregnancy not yet confirmed by a check'}. The date is an estimate (283 days), not a vet finding.`,
          action: left < 0 ? 'Ask the vet to check her.' : left <= 14 ? 'Move her to a clean calving place, stop milking if she is still milked, and have the vet’s number ready.' : 'Plan drying off about 60 days before calving.',
          method: 'calculated',
          links: link,
          subjects: [a.id],
        });
    }
    if (b.checkDue && b.checkDue <= addDays(day, 3))
      out.push({
        id: `pregcheck-${a.id}-${b.servedDay}`,
        module: 'breeding',
        severity: daysBetween(b.checkDue, day) > 14 ? 'medium' : 'low',
        title: `${name} needs a pregnancy check`,
        why: `Served ${fmtDay(b.servedDay!)}; a check is due from ${fmtDay(b.checkDue)} and none is recorded.`,
        action: 'Ask the vet or technician to check her.',
        method: 'calculated',
        links: link,
        subjects: [a.id],
      });
    if (b.nextHeat && daysBetween(day, b.nextHeat) <= 2 && daysBetween(day, b.nextHeat) >= 0)
      out.push({
        id: `heat-${a.id}-${b.nextHeat}`,
        module: 'breeding',
        severity: 'low',
        title: `${name} may come on heat ${b.nextHeat === day ? 'today' : fmtDay(b.nextHeat)}`,
        why: `21 days after her last heat sign${b.lastHeat ? ` (${fmtDay(b.lastHeat)})` : ''}. An estimate: watch for mounting, mucus and restlessness.`,
        action: 'Watch her morning and evening. Call the AI technician when she stands to be mounted.',
        method: 'calculated',
        links: link,
        subjects: [a.id],
      });
    if (!b.pregnant && b.daysInMilk != null && b.daysInMilk > 90 && !b.servedDay)
      out.push({
        id: `open-${a.id}-${day.slice(0, 7)}`,
        module: 'breeding',
        severity: b.daysInMilk > 150 ? 'high' : 'medium',
        title: `${name} not served ${b.daysInMilk} days after calving`,
        why: `Calved ${fmtDay(b.calvedDay!)} and no service is recorded since. Most farms aim to serve by about 90 days to keep one calf a year.`,
        action: 'Watch her for heat, or ask the vet why she is not showing.',
        method: 'calculated',
        links: link,
        subjects: [a.id],
      });
    if (b.failedServices >= 3)
      out.push({
        id: `repeat-breeder-${a.id}-${b.calvedDay ?? 'none'}`,
        module: 'breeding',
        severity: 'medium',
        title: `${name}: ${b.failedServices} services without a pregnancy`,
        why: `${b.servicesSinceCalving} services since ${b.calvedDay ? `calving on ${fmtDay(b.calvedDay)}` : 'records began'}, none confirmed.`,
        action: 'Ask the vet to examine her before paying for another service.',
        method: 'calculated',
        links: link,
        subjects: [a.id],
      });
  }
  return out;
}

/** Animals with a date of birth and recorded calvings: average calving interval in days (null with fewer than 2 intervals). */
export function calvingInterval(d: FarmData): { avgDays: number | null; intervals: number } {
  const byAnimal = new Map<string, string[]>();
  for (const e of alive(d.breeding)) {
    if (e.body.type !== 'calving' || !e.body.animalId) continue;
    const day = dayOf(e.body.at);
    if (day) byAnimal.set(e.body.animalId, [...(byAnimal.get(e.body.animalId) ?? []), day]);
  }
  const gaps: number[] = [];
  for (const days of byAnimal.values()) {
    days.sort();
    for (let i = 1; i < days.length; i++) gaps.push(daysBetween(days[i - 1], days[i]));
  }
  return { avgDays: gaps.length >= 2 ? Math.round(gaps.reduce((t, g) => t + g, 0) / gaps.length) : null, intervals: gaps.length };
}

export type { AnimalIn };
