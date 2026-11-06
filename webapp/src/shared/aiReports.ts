// GENERATED from shared/ by `node shared/sync.mjs`. Edit the file in shared/, not this copy.
// FarmTap AI engine — Smart Farm Reports (decision 0025). A request in the
// farmer's own words ("milk report for last month") picks a report and a
// period; the report is a table made only from the farm's records, which
// the apps print or download as PDF or spreadsheet.

import { addDays, alive, daysBetween, fmtDay, fmtL, fmtUgx, num, recDay, round1, sum, type Rec } from './aiCore.ts';
import { seesMoney, type FarmRole } from './aiAccess.ts';
import { periodOf, type Period } from './aiAssistant.ts';
import { animalName, breedingState, isActive, today, type FarmData } from './aiData.ts';
import { animalHealth, calvingInterval, vaccinesDue } from './aiHerd.ts';
import { batchViews, qualitySummary } from './aiMilk.ts';
import { catLabel } from './aiMoney.ts';
import { drugViews, feedEconomics, feedViews } from './aiStock.ts';

export const reportKinds = [
  { key: 'overall', label: 'Overall farm performance', words: /overall|performance|summary|everything|whole farm|general/, money: false },
  { key: 'milk', label: 'Milk production', words: /milk|production|litre|yield/, money: false },
  { key: 'health', label: 'Animal health', words: /health|treat|sick|vaccin|disease/, money: false },
  { key: 'profit', label: 'Farm profitability', words: /profit|loss|income|revenue|money|financ/, money: true },
  { key: 'expenses', label: 'Farm expenses', words: /expens|spend|spent|cost/, money: true },
  { key: 'feed', label: 'Feed consumption', words: /feed|silage|hay|fodder/, money: false },
  { key: 'breeding', label: 'Breeding performance', words: /breed|calv|pregnan|heat|insemina/, money: false },
  { key: 'quality', label: 'Milk quality', words: /quality|reject|test|expir|batch|cool|temperat/, money: false },
  { key: 'inventory', label: 'Inventory', words: /inventor|stock|store|drug/, money: false },
] as const;
export type ReportKind = (typeof reportKinds)[number]['key'];

export interface Report {
  kind: ReportKind;
  title: string;
  period: Period;
  summary: string[];
  columns: string[];
  rows: (string | number)[][];
}

/** Which report and period a request asks for; null when no report matches. */
export function parseReportRequest(text: string, day: string, role: FarmRole): { kind: ReportKind; period: Period } | null {
  const q = text.toLowerCase();
  const order: ReportKind[] = ['quality', 'expenses', 'profit', 'feed', 'breeding', 'health', 'inventory', 'milk', 'overall'];
  const k = order.find((key) => {
    const r = reportKinds.find((x) => x.key === key)!;
    return r.words.test(q) && (!r.money || seesMoney(role));
  });
  if (!k) return null;
  return { kind: k, period: periodOf(q, day, 'month') };
}

const inP = (day: string | null, p: Period) => !!day && day >= p.from && day <= p.to;
const within = <B extends object>(rs: Rec<B>[] | undefined, p: Period, field?: string) => alive(rs).filter((r) => inP(recDay(r, field), p));

export function buildReport(kind: ReportKind, period: Period, d: FarmData): Report {
  const title = reportKinds.find((r) => r.key === kind)!.label;
  const base = { kind, title, period };
  const days = Math.max(1, daysBetween(period.from, period.to) + 1);
  switch (kind) {
    case 'milk': {
      const rows: (string | number)[][] = [];
      for (let i = 0; i < days; i++) {
        const day = addDays(period.from, i);
        const rs = alive(d.milk).filter((r) => recDay(r) === day);
        if (!rs.length) continue;
        const m = sum(rs.filter((r) => r.body.session === 'morning').map((r) => num(r.body.litres)));
        const e = sum(rs.filter((r) => r.body.session === 'evening').map((r) => num(r.body.litres)));
        rows.push([fmtDay(day), round1(m), round1(e), round1(m + e)]);
      }
      const total = sum(rows.map((r) => r[3] as number));
      return {
        ...base,
        summary: rows.length ? [`${fmtL(total)} over ${rows.length} recorded days`, `${fmtL(total / rows.length)} a recorded day`] : ['No milk recorded in this period'],
        columns: ['Day', 'Morning (L)', 'Evening (L)', 'Total (L)'],
        rows,
      };
    }
    case 'health': {
      const ts = within(d.treatments, period, 'given');
      const animals = new Map(alive(d.animals).map((a) => [a.id, a]));
      const due = vaccinesDue(d);
      return {
        ...base,
        summary: [`${ts.length} treatments`, `${due.filter((v) => v.overdueDays > 0).length} vaccinations overdue today`],
        columns: ['Day', 'Animal', 'Condition', 'Withdrawal days', 'Cost (UGX)'],
        rows: ts
          .sort((a, b) => (recDay(a, 'given') ?? '').localeCompare(recDay(b, 'given') ?? ''))
          .map((t) => [fmtDay(recDay(t, 'given')!), animalName(animals.get(t.body.animalId)), t.body.condition ?? '', num(t.body.withdrawalDays), num(t.body.cost)]),
      };
    }
    case 'profit': {
      const exp = within(d.expenses, period, 'at');
      const inc = within(d.income, period, 'at');
      const sales = within(d.milkSales, period);
      const milk = sum(within(d.milk, period).map((r) => num(r.body.litres)));
      const spent = sum(exp.map((e) => num(e.body.amount)));
      const milkSales = sum(sales.map((s) => num(s.body.litres) * num(s.body.pricePerLitre)));
      const other = sum(inc.map((e) => num(e.body.amount)));
      return {
        ...base,
        summary: [`${milkSales + other - spent >= 0 ? 'Profit' : 'Loss'}: ${fmtUgx(Math.abs(milkSales + other - spent))}`, ...(milk > 0 && spent > 0 ? [`Cost per litre: ${fmtUgx(spent / milk)}`] : [])],
        columns: ['Item', 'UGX'],
        rows: [['Milk sales', Math.round(milkSales)], ['Other income', Math.round(other)], ['Total income', Math.round(milkSales + other)], ['Expenses', Math.round(spent)], ['Net', Math.round(milkSales + other - spent)], ['Milk produced (L)', round1(milk)]],
      };
    }
    case 'expenses': {
      const exp = within(d.expenses, period, 'at');
      const by = new Map<string, { n: number; amount: number }>();
      for (const e of exp) {
        const c = by.get(e.body.category) ?? { n: 0, amount: 0 };
        by.set(e.body.category, { n: c.n + 1, amount: c.amount + num(e.body.amount) });
      }
      const total = sum(exp.map((e) => num(e.body.amount)));
      return {
        ...base,
        summary: [`${fmtUgx(total)} in ${exp.length} expenses`],
        columns: ['Category', 'Expenses', 'UGX', 'Share'],
        rows: [...by.entries()].sort((a, b) => b[1].amount - a[1].amount).map(([c, v]) => [catLabel(c), v.n, Math.round(v.amount), `${total ? Math.round((v.amount / total) * 100) : 0}%`]),
      };
    }
    case 'feed': {
      const uses = within(d.feedUses, period, 'at');
      const views = new Map(feedViews(d).map((f) => [f.feed, f]));
      const by = new Map<string, number>();
      for (const u of uses) by.set(u.body.feed, (by.get(u.body.feed) ?? 0) + num(u.body.amount));
      const e = feedEconomics(d);
      return {
        ...base,
        summary: [...(e.costPerLitre != null ? [`Feed cost per litre (last 30 days): ${fmtUgx(e.costPerLitre)}`] : []), `${uses.length} feedings recorded`],
        columns: ['Feed', 'Fed', 'A day', 'Left now', 'Days left'],
        rows: [...by.entries()].map(([f, amt]) => {
          const v = views.get(f);
          return [v?.name ?? f, `${round1(amt)} ${v?.unit ?? ''}`.trim(), round1(amt / days), v ? `${v.left} ${v.unit}` : '', v?.daysLeft ?? ''];
        }),
      };
    }
    case 'breeding': {
      const day = today(d);
      const ev = within(d.breeding, period, 'at');
      const ci = calvingInterval(d);
      const cows = alive(d.animals).filter((a) => isActive(a) && a.body.sex !== 'male' && !['calf', 'bull'].includes(a.body.dairyStatus ?? ''));
      return {
        ...base,
        summary: [
          `${ev.filter((e) => e.body.type === 'ai' || (e.body.type === 'service' && e.body.kind !== 'heat')).length} services, ${ev.filter((e) => e.body.type === 'calving').length} calvings in the period`,
          ci.avgDays != null ? `Average calving interval: ${ci.avgDays} days` : 'Calving interval: needs 2 or more recorded intervals',
        ],
        columns: ['Cow', 'State', 'Served', 'Due (estimate)', 'Next heat (estimate)'],
        rows: cows.map((a) => {
          const b = breedingState(a.id, d.breeding ?? [], day);
          return [animalName(a), b.pregnant ? (b.confirmed ? 'In calf (confirmed)' : 'Served') : 'Open', b.servedDay ? fmtDay(b.servedDay) : '', b.due ? fmtDay(b.due) : '', b.nextHeat ? fmtDay(b.nextHeat) : ''];
        }),
      };
    }
    case 'quality': {
      const q = qualitySummary(d);
      const b = batchViews(d).filter((x) => inP(x.collectedAt.slice(0, 10), period));
      return {
        ...base,
        summary: [`Centre (last 30 days): ${q.deliveries} deliveries, ${q.rejected} rejected (${fmtL(q.rejectedLitres)}), ${q.notTested} not tested`, `${b.length} farm batches in the period`],
        columns: ['Collected', 'Place', 'Litres', 'Status', 'Highest °C', 'Use by'],
        rows: b.map((x) => [x.collectedAt.replace('T', ' ').slice(0, 16), x.place, x.litres, x.state === 'closed' ? x.status : x.state, x.highest ?? 'no reading', x.useBy.replace('T', ' ')]),
      };
    }
    case 'inventory': {
      return {
        ...base,
        summary: ['Stock today'],
        columns: ['Item', 'Kind', 'Left', 'A day', 'Days left'],
        rows: [
          ...feedViews(d).map((f) => [f.name, 'Feed', `${f.left} ${f.unit}`, f.perDay, f.daysLeft ?? '']),
          ...drugViews(d).map((x) => [x.name, 'Drug', x.stock == null ? 'not counted' : `${x.stock} ${x.unit}`.trim(), '', '']),
        ],
      };
    }
    case 'overall':
    default: {
      const milk = sum(within(d.milk, period).map((r) => num(r.body.litres)));
      const active = alive(d.animals).filter(isActive);
      const attention = active.filter((a) => animalHealth(d, a.id).attention.length).length;
      return {
        ...base,
        summary: [`${fmtL(milk)} of milk`, `${active.length} animals, ${attention} needing attention today`],
        columns: ['Measure', 'Value'],
        rows: [
          ['Milk produced (L)', round1(milk)],
          ['Animals', active.length],
          ['Treatments', within(d.treatments, period, 'given').length],
          ['Calvings', within(d.breeding, period, 'at').filter((e) => e.body.type === 'calving').length],
          ['Feedings recorded', within(d.feedUses, period, 'at').length],
          ['Animals needing attention today', attention],
        ],
      };
    }
  }
}

/** A money report asked for by someone who may not see money: refuse rather than build it. */
export function canBuild(kind: ReportKind, role: FarmRole) {
  return !reportKinds.find((r) => r.key === kind)!.money || seesMoney(role);
}
