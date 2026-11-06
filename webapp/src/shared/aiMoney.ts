// GENERATED from shared/ by `node shared/sync.mjs`. Edit the file in shared/, not this copy.
// FarmTap AI engine — money (decision 0025). Every figure is a sum of the
// farm's own expenses, income and milk sales. Nothing is estimated except
// the next-month cash figure, which says how it was made.

import { addMonths, alive, fmtL, fmtMonth, fmtUgx, mean, median, num, pctChange, recDay, sum, type Finding } from './aiCore.ts';
import { today, type FarmData } from './aiData.ts';

export const categoryName: Record<string, string> = {
  feed: 'Feed',
  vet: 'Health and vet',
  breeding: 'Breeding',
  wages: 'Worker pay',
  transport: 'Transport',
  fuel: 'Fuel',
  equipment: 'Equipment and repairs',
  other: 'Other',
};
export const catLabel = (c: string) => categoryName[c] ?? (c ? c[0].toUpperCase() + c.slice(1).replace(/([A-Z])/g, ' $1').toLowerCase() : 'Other');

export interface MonthMoney {
  month: string;
  spent: number;
  milkSales: number;
  otherIncome: number;
  income: number;
  net: number;
  litres: number;
  costPerLitre: number | null;
  byCategory: { category: string; amount: number }[];
}

export function monthMoney(d: FarmData, month: string): MonthMoney {
  const exp = alive(d.expenses).filter((e) => recDay(e, 'at')?.startsWith(month));
  const inc = alive(d.income).filter((e) => recDay(e, 'at')?.startsWith(month));
  const sales = alive(d.milkSales).filter((s) => recDay(s)?.startsWith(month));
  const litres = sum(alive(d.milk).filter((m) => recDay(m)?.startsWith(month)).map((m) => num(m.body.litres)));
  const by = new Map<string, number>();
  for (const e of exp) by.set(e.body.category || 'other', (by.get(e.body.category || 'other') ?? 0) + num(e.body.amount));
  const spent = sum(exp.map((e) => num(e.body.amount)));
  const milkSales = sum(sales.map((s) => num(s.body.litres) * num(s.body.pricePerLitre)));
  const otherIncome = sum(inc.map((e) => num(e.body.amount)));
  return {
    month,
    spent: Math.round(spent),
    milkSales: Math.round(milkSales),
    otherIncome: Math.round(otherIncome),
    income: Math.round(milkSales + otherIncome),
    net: Math.round(milkSales + otherIncome - spent),
    litres: Math.round(litres * 10) / 10,
    costPerLitre: litres > 0 && spent > 0 ? Math.round(spent / litres) : null,
    byCategory: [...by.entries()].map(([category, amount]) => ({ category, amount: Math.round(amount) })).sort((a, b) => b.amount - a.amount),
  };
}

/** This month and the [n]-1 before it, newest first. */
export function monthsBack(d: FarmData, n: number): MonthMoney[] {
  const m = today(d).slice(0, 7);
  return Array.from({ length: n }, (_, i) => monthMoney(d, addMonths(m, -i)));
}

const hasRecords = (m: MonthMoney) => m.spent > 0 || m.income > 0;

export interface CashForecast {
  ok: boolean;
  reason?: string;
  month: string;
  income: number;
  spent: number;
  net: number;
  monthsUsed: number;
  method: string;
}

/** Next month: the average of the last 3 full months that have records (at least 2 needed). */
export function cashForecast(d: FarmData): CashForecast {
  const next = addMonths(today(d).slice(0, 7), 1);
  const full = monthsBack(d, 4).slice(1).filter(hasRecords);
  const base = { month: next, income: 0, spent: 0, net: 0, monthsUsed: full.length, method: 'Average of the last full months with records' };
  if (full.length < 2) return { ok: false, reason: `Needs at least 2 full months of money records; there ${full.length === 1 ? 'is 1' : `are ${full.length}`}.`, ...base };
  const income = Math.round(mean(full.map((m) => m.income)));
  const spent = Math.round(mean(full.map((m) => m.spent)));
  return { ok: true, ...base, income, spent, net: income - spent, method: `Average of ${fmtList(full.map((m) => fmtMonth(m.month)))}` };
}
const fmtList = (xs: string[]) => (xs.length <= 1 ? xs.join('') : `${xs.slice(0, -1).join(', ')} and ${xs[xs.length - 1]}`);

export interface Unusual {
  id: string;
  category: string;
  amount: number;
  usual: number;
  at: string;
}

/** Single expenses at least 3 times the usual size for their category (needs 5 earlier ones). */
export function unusualExpenses(d: FarmData): Unusual[] {
  const day = today(d);
  const from = `${addMonths(day.slice(0, 7), -1)}-01`;
  const exp = alive(d.expenses);
  const out: Unusual[] = [];
  for (const e of exp) {
    const at = recDay(e, 'at') ?? '';
    if (at < from || at > day) continue;
    const prior = exp.filter((o) => o.id !== e.id && o.body.category === e.body.category && (recDay(o, 'at') ?? '') < at).map((o) => num(o.body.amount));
    if (prior.length < 5) continue;
    const usual = median(prior);
    if (usual > 0 && num(e.body.amount) >= usual * 3 && num(e.body.amount) - usual >= 20_000)
      out.push({ id: e.id, category: e.body.category, amount: num(e.body.amount), usual: Math.round(usual), at });
  }
  return out.sort((a, b) => b.amount - a.amount);
}

export function financeFindings(d: FarmData): Finding[] {
  const out: Finding[] = [];
  const day = today(d);
  const [cur, prev, ...older] = monthsBack(d, 5);
  for (const u of unusualExpenses(d))
    out.push({
      id: `spend-unusual-${u.id}`,
      module: 'finance',
      severity: u.amount >= u.usual * 6 ? 'high' : 'medium',
      title: `Large ${catLabel(u.category).toLowerCase()} expense: ${fmtUgx(u.amount)}`,
      why: `Recorded ${u.at}. A usual ${catLabel(u.category).toLowerCase()} expense on this farm is about ${fmtUgx(u.usual)}.`,
      action: 'Check the amount is right and that there is a receipt.',
      method: 'statistical',
      links: [{ label: 'Money', href: '/money/' }],
      subjects: [u.id],
    });
  // A category this month (so far, scaled to a full month only after day 10) far above its 3-month average.
  const dom = +day.slice(8, 10);
  if (dom >= 10) {
    const full = older.concat(prev).filter(hasRecords);
    if (full.length >= 2)
      for (const c of cur.byCategory) {
        const avg = mean(full.map((m) => m.byCategory.find((x) => x.category === c.category)?.amount ?? 0));
        if (avg > 0 && c.amount >= avg * 1.5 && c.amount - avg >= 50_000)
          out.push({
            id: `spend-category-${c.category}-${cur.month}`,
            module: 'finance',
            severity: c.amount >= avg * 2.5 ? 'high' : 'medium',
            title: `${catLabel(c.category)} spending is ${Math.round((c.amount / avg) * 100 - 100)}% above usual`,
            why: `${fmtUgx(c.amount)} so far in ${fmtMonth(cur.month)}, against an average of ${fmtUgx(avg)} a month before.`,
            action: 'Look at this month’s expenses in this category for anything unexpected.',
            method: 'calculated',
            links: [{ label: 'Money', href: '/money/' }],
            subjects: [],
          });
      }
  }
  if (hasRecords(prev) && prev.net < 0)
    out.push({
      id: `month-loss-${prev.month}`,
      module: 'finance',
      severity: 'high',
      title: `${fmtMonth(prev.month)} ended with a loss of ${fmtUgx(-prev.net)}`,
      why: `Spent ${fmtUgx(prev.spent)}; milk sales and other income ${fmtUgx(prev.income)}.`,
      action: `Biggest cost: ${prev.byCategory[0] ? `${catLabel(prev.byCategory[0].category)} (${fmtUgx(prev.byCategory[0].amount)})` : 'none recorded'}. Check that all milk sales were recorded.`,
      method: 'calculated',
      links: [{ label: 'Reports', href: '/reports/' }],
      subjects: [],
    });
  if (prev.costPerLitre != null && older[0]?.costPerLitre != null) {
    const ch = pctChange(prev.costPerLitre, older[0].costPerLitre);
    if (ch != null && ch >= 20)
      out.push({
        id: `cost-litre-up-${prev.month}`,
        module: 'finance',
        severity: 'medium',
        title: `Cost per litre rose ${ch}%`,
        why: `${fmtUgx(prev.costPerLitre)} a litre in ${fmtMonth(prev.month)} (${fmtL(prev.litres)}), against ${fmtUgx(older[0].costPerLitre)} in ${fmtMonth(older[0].month)}.`,
        action: 'Compare feed and wages with the milk they produce.',
        method: 'calculated',
        links: [{ label: 'Reports', href: '/reports/' }],
        subjects: [],
      });
  }
  return out;
}
