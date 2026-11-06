// GENERATED from shared/ by `node shared/sync.mjs`. Edit the file in shared/, not this copy.
// FarmTap AI engine — extra built-in insights (decision 0028, layer 2).
//
// Plain calculations on the farm's own records. No model, no internet, no
// credits. Health wording is a risk to check with the vet, never a diagnosis.

import { addDays, alive, fmtDay, fmtL, fmtMonth, fmtUgx, plural, recDay, round1, sum, type Finding, type Link, type Method } from './aiCore.ts';
import { animalHref, animalName, isActive, milkDays, today, type FarmData } from './aiData.ts';
import { catLabel, monthMoney } from './aiMoney.ts';
import { milkSummary } from './aiMilk.ts';

// ---------------------------------------------------------------- Milk against the previous recording

/** A drop at least this big (percent) raises a warning; twice as big, a high one. */
export const HERD_DROP_WARN_PCT = 10;

export interface HerdMilkChange {
  latest: { day: string; litres: number };
  previous: { day: string; litres: number };
  /** One decimal, negative when milk fell. */
  changePct: number;
  direction: 'down' | 'up' | 'steady';
}

/**
 * The herd's milk on the latest recorded day against the recorded day before it.
 * Today counts only once its evening milking is in (or after 9 pm), so a
 * morning-only total is never compared with a full day.
 */
export function herdMilkChange(d: FarmData): HerdMilkChange | null {
  const day = today(d);
  const days = milkDays(d, 30).filter((x) => x.recorded && x.litres > 0);
  const todayDone = alive(d.milk).some((r) => recDay(r) === day && r.body.session === 'evening') || +d.now.slice(11, 13) >= 21;
  const usable = days.filter((x) => x.day !== day || todayDone);
  if (usable.length < 2) return null;
  const latest = usable[usable.length - 1];
  const previous = usable[usable.length - 2];
  const changePct = round1(((latest.litres - previous.litres) / previous.litres) * 100);
  return {
    latest: { day: latest.day, litres: round1(latest.litres) },
    previous: { day: previous.day, litres: round1(previous.litres) },
    changePct,
    direction: changePct <= -1 ? 'down' : changePct >= 1 ? 'up' : 'steady',
  };
}

/** The farmer-facing sentence, e.g. "Milk production has declined by 29.2% compared with the previous recording." */
export function herdChangeText(c: HerdMilkChange): string {
  if (c.direction === 'steady') return `Milk production is steady compared with the previous recording (${fmtL(c.latest.litres)} against ${fmtL(c.previous.litres)}).`;
  const word = c.direction === 'down' ? 'declined' : 'increased';
  return `Milk production has ${word} by ${Math.abs(c.changePct)}% compared with the previous recording.`;
}

export const HERD_DROP_ACTION = 'Review animal health, feeding records and recent management changes.';

// ---------------------------------------------------------------- Animal records

export interface RecordGap {
  animalId: string;
  name: string;
  missing: string[];
}

export interface Completeness {
  animals: number;
  complete: number;
  /** 0 to 100. */
  pct: number;
  gaps: RecordGap[];
}

const NEEDED: [keyof NonNullable<FarmData['animals']>[number]['body'], string][] = [
  ['tagNumber', 'tag number'],
  ['sex', 'sex'],
  ['dateOfBirth', 'date of birth'],
  ['dairyStatus', 'status (milking, dry, heifer…)'],
];

/** Active animals whose record is missing something the analyses need. */
export function recordCompleteness(d: FarmData): Completeness {
  const animals = alive(d.animals).filter(isActive);
  const gaps: RecordGap[] = [];
  for (const a of animals) {
    const b = a.body as unknown as Record<string, unknown>;
    const missing = NEEDED.filter(([k]) => typeof b[k] !== 'string' || !(b[k] as string).trim()).map(([, label]) => label);
    if (missing.length) gaps.push({ animalId: a.id, name: animalName(a), missing });
  }
  const complete = animals.length - gaps.length;
  return { animals: animals.length, complete, pct: animals.length ? Math.round((complete / animals.length) * 100) : 100, gaps };
}

// ---------------------------------------------------------------- Findings

export function insightFindings(d: FarmData): Finding[] {
  const out: Finding[] = [];
  const c = herdMilkChange(d);
  if (c && c.changePct <= -HERD_DROP_WARN_PCT)
    out.push({
      id: `milk-change-${c.latest.day}`,
      module: 'milk',
      severity: c.changePct <= -2 * HERD_DROP_WARN_PCT ? 'high' : 'medium',
      title: `Milk down ${Math.abs(c.changePct)}% on the previous recording`,
      why: `${fmtL(c.latest.litres)} on ${fmtDay(c.latest.day)} against ${fmtL(c.previous.litres)} on ${fmtDay(c.previous.day)}.`,
      action: `${HERD_DROP_ACTION} A health problem is only a possibility: ask your vet to check any cow that looks unwell.`,
      method: 'calculated',
      links: [{ label: 'Milk records', href: '/milk/' }],
      subjects: [],
    });
  const r = recordCompleteness(d);
  if (r.gaps.length)
    out.push({
      id: `records-incomplete-${r.gaps.length}-${today(d).slice(0, 7)}`,
      module: 'health',
      severity: 'low',
      title: `${plural(r.gaps.length, 'animal record')} incomplete`,
      why: `${r.pct}% of animal records are complete. Missing details make milk, breeding and health checks less accurate.`,
      action: 'Open each animal and fill in what is missing.',
      method: 'calculated',
      links: r.gaps.slice(0, 3).map((g) => ({ label: g.name, href: animalHref(g.animalId) })),
      subjects: r.gaps.map((g) => g.animalId),
    });
  return out;
}

// ---------------------------------------------------------------- Extra questions

export interface InsightAnswer {
  intent: string;
  ok: boolean;
  text: string;
  bullets: string[];
  links: Link[];
  method: Method;
  money?: boolean;
}

const inMonth = (day: string | null, m: string) => !!day && day.startsWith(m);

/**
 * Questions the original assistant (aiAssistant.ask) does not cover. Checked
 * before it. Returns null when none matches.
 */
export function askInsight(question: string, d: FarmData, opts: { seesMoney: boolean }): InsightAnswer | null {
  const q = question.trim().toLowerCase().replace(/\s+/g, ' ');
  const day = today(d);
  const noCow = !/\b(cows?|animals?|which|heifers?)\b/.test(q);
  // "Has milk dropped?", "compare milk with the last recording", "is production declining"
  if (noCow && /((milk|production|yield).*(declin|drop|fall|fell|down|change|compar|previous|differ|trend|up\b|increase))|((declin|drop|fall|compar|change|trend).*(milk|production|yield))/.test(q)) {
    const c = herdMilkChange(d);
    if (!c) return { intent: 'milkChange', ok: false, text: 'I need milk recorded on at least two days to compare.', bullets: [], links: [{ label: 'Record milk', href: '/milk/?new=1' }], method: 'calculated' };
    const s = milkSummary(d);
    return {
      intent: 'milkChange',
      ok: true,
      text: c.changePct <= -HERD_DROP_WARN_PCT ? `${herdChangeText(c)} ${HERD_DROP_ACTION}` : herdChangeText(c),
      bullets: [
        `${fmtDay(c.latest.day)}: ${fmtL(c.latest.litres)}. ${fmtDay(c.previous.day)}: ${fmtL(c.previous.litres)}.`,
        ...(s.weekChangePct != null ? [`Last 7 days against the 7 before: ${s.weekChangePct > 0 ? '+' : ''}${s.weekChangePct}%.`] : []),
      ],
      links: [{ label: 'Milk records', href: '/milk/' }],
      method: 'calculated',
    };
  }
  if (/(incomplete|missing|complete).*(record|detail|info)|(record|detail|info).*(incomplete|missing|complete)/.test(q)) {
    const r = recordCompleteness(d);
    if (!r.animals) return { intent: 'completeness', ok: true, text: 'No animals are recorded yet.', bullets: [], links: [{ label: 'Herd', href: '/herd/' }], method: 'calculated' };
    return {
      intent: 'completeness',
      ok: true,
      text: r.gaps.length ? `${r.pct}% of animal records are complete. ${plural(r.gaps.length, 'animal')} miss something:` : `All ${plural(r.animals, 'animal record')} are complete.`,
      bullets: r.gaps.slice(0, 12).map((g) => `${g.name}: no ${g.missing.join(', no ')}.`),
      links: r.gaps.slice(0, 5).map((g) => ({ label: g.name, href: animalHref(g.animalId) })),
      method: 'calculated',
    };
  }
  // "How much did I spend this month?" (feed-only questions stay with the original assistant)
  if (!/feed/.test(q) && !/most|biggest|top|expensive/.test(q) && /\b(spend|spent|spending|expenses?|costs)\b/.test(q)) {
    if (!opts.seesMoney) return { intent: 'spending', ok: false, text: 'Money questions are for the farm owner and managers.', bullets: [], links: [], method: 'calculated', money: true };
    const month = /last month|previous month/.test(q) ? addDays(`${day.slice(0, 7)}-01`, -1).slice(0, 7) : day.slice(0, 7);
    const m = monthMoney(d, month);
    const n = alive(d.expenses).filter((e) => inMonth(recDay(e, 'at'), month)).length;
    if (!n) return { intent: 'spending', ok: true, text: `No expenses are recorded for ${fmtMonth(month)}.`, bullets: [], links: [{ label: 'Money', href: '/money/' }], method: 'calculated', money: true };
    return {
      intent: 'spending',
      ok: true,
      text: `${fmtUgx(m.spent)} spent in ${fmtMonth(month)}${month === day.slice(0, 7) ? ' so far' : ''} (${plural(n, 'expense')}).`,
      bullets: m.byCategory.slice(0, 4).map((x) => `${catLabel(x.category)}: ${fmtUgx(x.amount)}.`),
      links: [{ label: 'Money', href: '/money/' }],
      method: 'calculated',
      money: true,
    };
  }
  // "Farm summary", "how is the farm doing" (a numbers summary; "explain" goes to the AI)
  if (/\b(summary|summari[sz]e|overview|how is (the|my|our) farm|farm (doing|performance))\b/.test(q) && !/\b(why|explain)\b/.test(q)) {
    const s = milkSummary(d);
    const herd = alive(d.animals).filter(isActive).length;
    const m = monthMoney(d, day.slice(0, 7));
    const c = herdMilkChange(d);
    const milk7 = sum(milkDays(d, 7).map((x) => x.litres));
    return {
      intent: 'farmSummary',
      ok: true,
      text: `Your farm in numbers (${fmtDay(day)}):`,
      bullets: [
        `${plural(herd, 'animal')} on the farm.`,
        `Milk: ${fmtL(milk7)} in the last 7 days${s.avg7 != null ? `, about ${fmtL(s.avg7)} a day` : ''}.`,
        ...(c ? [herdChangeText(c)] : []),
        ...(opts.seesMoney ? [`${fmtMonth(m.month)} so far: income ${fmtUgx(m.income)}, spent ${fmtUgx(m.spent)}, ${m.net >= 0 ? 'profit' : 'loss'} ${fmtUgx(Math.abs(m.net))}.`] : []),
      ],
      links: [{ label: 'Reports', href: '/reports/' }],
      method: 'calculated',
    };
  }
  return null;
}

