// GENERATED from shared/ by `node shared/sync.mjs`. Edit the file in shared/, not this copy.
// FarmTap AI engine: "today on your farm" numbers for the chat's first screen, the small milk chart
// under an animal's answer, and the farm records a farmer can attach to a question (decision 0027).
// Pure. Uses only totals, never names, so what is attached is safe to send.

import { addDays, alive, daysBetween, dayOf, fmtDay, num, plural, recDay } from './aiCore.ts';
import { cowDays, milkDays, today, type FarmData } from './aiData.ts';
import { vaccinesDue } from './aiHerd.ts';

export interface FarmToday {
  /** Litres for the latest day with a milk record in the last 2 days, else null. */
  milk: { litres: number; day: 'today' | 'yesterday'; changePct: number | null } | null;
  /** Animals whose milk is not for sale because of a treatment. */
  withdrawal: number;
  /** The vaccine due soonest (or overdue), with days until it is due (negative = overdue). */
  vaccine: { name: string; days: number } | null;
}

export function farmToday(d: FarmData): FarmToday {
  const days = milkDays(d, 9);
  const last = days[days.length - 1];
  const prev = days[days.length - 2];
  const pick = last.recorded ? { rec: last, label: 'today' as const, before: days.slice(0, -1) } : prev.recorded ? { rec: prev, label: 'yesterday' as const, before: days.slice(0, -2) } : null;
  let milk: FarmToday['milk'] = null;
  if (pick) {
    const base = pick.before.filter((x) => x.recorded);
    const avg = base.length ? base.reduce((t, x) => t + x.litres, 0) / base.length : 0;
    milk = { litres: Math.round(pick.rec.litres), day: pick.label, changePct: avg > 0 ? Math.round(((pick.rec.litres - avg) / avg) * 100) : null };
  }
  const day = today(d);
  const held = new Set<string>();
  for (const t of alive(d.treatments)) {
    const g = recDay(t, 'given');
    const w = num(t.body.withdrawalDays);
    if (g && w > 0 && addDays(g, w) > day) held.add(t.body.animalId);
  }
  const v = vaccinesDue(d)[0];
  return { milk, withdrawal: held.size, vaccine: v ? { name: v.vaccine, days: daysBetween(day, v.due) } : null };
}

/** Litres a cow gave each of the last [days] days (0 when nothing was recorded), oldest first. */
export function cowSpark(d: FarmData, animalId: string, days = 7): number[] {
  const m = cowDays(d, days).get(animalId);
  const end = today(d);
  const out: number[] = [];
  for (let i = days - 1; i >= 0; i--) out.push(Math.round((m?.get(addDays(end, -i)) ?? 0) * 10) / 10);
  return out;
}

export type ContextKind = 'milk' | 'health' | 'money';

export const CONTEXT_KINDS: { id: ContextKind; label: string; hint: string }[] = [
  { id: 'milk', label: 'Milk this week', hint: 'Litres by day' },
  { id: 'health', label: 'Health and vaccines', hint: 'Treatments and due dates' },
  { id: 'money', label: 'Money summary', hint: 'This month’s income and costs' },
];

/** Plain facts about the farm for one kind of record, to send with the question. */
export function contextFacts(kind: ContextKind, d: FarmData): string[] {
  const day = today(d);
  if (kind === 'milk') {
    const days = milkDays(d, 7);
    const got = days.filter((x) => x.recorded);
    const total = got.reduce((t, x) => t + x.litres, 0);
    const out = [`Milk collected in the last 7 days: ${Math.round(total)} litres in total.`];
    if (got.length) out.push(`Average per recorded day: ${Math.round(total / got.length)} litres.`);
    out.push(...days.map((x) => `${fmtDay(x.day)}: ${x.recorded ? `${Math.round(x.litres)} litres` : 'no record'}.`));
    return out;
  }
  if (kind === 'health') {
    const from = addDays(day, -30);
    const ts = alive(d.treatments).filter((t) => (recDay(t, 'given') ?? '') >= from);
    const conds = new Map<string, number>();
    for (const t of ts) conds.set((t.body.condition || 'other').toLowerCase(), (conds.get((t.body.condition || 'other').toLowerCase()) ?? 0) + 1);
    const out = [`Treatments in the last 30 days: ${ts.length}.`, ...[...conds].sort((a, b) => b[1] - a[1]).slice(0, 5).map(([c, n]) => `${c}: ${plural(n, 'time')}.`)];
    for (const v of vaccinesDue(d).slice(0, 4)) out.push(v.overdueDays > 0 ? `${v.vaccine} vaccine is ${plural(v.overdueDays, 'day')} overdue.` : `${v.vaccine} vaccine is due ${fmtDay(v.due)}.`);
    return out;
  }
  const from = `${day.slice(0, 8)}01`;
  const sum = (rows: { body: { amount: number; at?: string } }[]) => rows.filter((r) => (dayOf(r.body.at) ?? day) >= from).reduce((t, r) => t + num(r.body.amount), 0);
  const income = sum(alive(d.income));
  const spent = sum(alive(d.expenses));
  return [`This month so far, income: ${Math.round(income)} shillings.`, `This month so far, costs: ${Math.round(spent)} shillings.`, `This month so far, left over: ${Math.round(income - spent)} shillings.`];
}
