// FarmTap AI engine — Farm Assistant (decision 0025).
//
// Questions are matched to a fixed list of things FarmTap can work out
// exactly from the farm's records. Every number comes from those records;
// when a question does not match, the assistant says so and suggests what
// it can answer. An optional self-hosted model (aiPrivacy.ts) may only
// rephrase an answer made here; it never makes numbers up.

import { addDays, addMonths, alive, fmtDay, fmtL, fmtMonth, fmtUgx, num, plural, recDay, sum, type Link, type Method } from './aiCore.ts';
import { seesMoney, type FarmRole } from './aiAccess.ts';
import { animalHref, animalName, breedingState, isActive, today, type FarmData } from './aiData.ts';
import { animalHealth, vaccinesDue } from './aiHerd.ts';
import { batchViews, cowTrends, DROP_PCT, herdForecast, milkSummary } from './aiMilk.ts';
import { catLabel, monthMoney } from './aiMoney.ts';
import { allFindings, type FindingWithState } from './aiRisk.ts';
import { feedViews } from './aiStock.ts';
import type { AiConfig } from './aiAccess.ts';

export interface Answer {
  intent: string;
  ok: boolean;
  text: string;
  bullets: string[];
  links: Link[];
  method: Method;
}

export interface Period {
  from: string;
  to: string;
  label: string;
}

/** "today", "yesterday", "this/last week", "this/last month", "last N days". Defaults to [fallback]. */
export function periodOf(q: string, day: string, fallback: 'today' | 'month' | 'week' = 'today'): Period {
  const s = q.toLowerCase();
  const n = /(?:last|past)\s+(\d{1,3})\s+days?/.exec(s);
  if (n) return { from: addDays(day, -(+n[1] - 1)), to: day, label: `the last ${n[1]} days` };
  if (/yesterday/.test(s)) return { from: addDays(day, -1), to: addDays(day, -1), label: 'yesterday' };
  if (/last\s+week|previous\s+week/.test(s)) return { from: addDays(day, -13), to: addDays(day, -7), label: 'the week before last 7 days' };
  if (/this\s+week|past\s+week|last\s+7/.test(s)) return { from: addDays(day, -6), to: day, label: 'the last 7 days' };
  if (/last\s+month|previous\s+month/.test(s)) {
    const m = addMonths(day.slice(0, 7), -1);
    return { from: `${m}-01`, to: addDays(`${day.slice(0, 7)}-01`, -1), label: fmtMonth(m) };
  }
  if (/this\s+month|month/.test(s)) return { from: `${day.slice(0, 7)}-01`, to: day, label: `${fmtMonth(day.slice(0, 7))} so far` };
  if (/today|now/.test(s)) return { from: day, to: day, label: 'today' };
  if (fallback === 'month') return { from: `${day.slice(0, 7)}-01`, to: day, label: `${fmtMonth(day.slice(0, 7))} so far` };
  if (fallback === 'week') return { from: addDays(day, -6), to: day, label: 'the last 7 days' };
  return { from: day, to: day, label: 'today' };
}

const inP = (day: string | null, p: Period) => !!day && day >= p.from && day <= p.to;

interface Ctx {
  d: FarmData;
  q: string;
  day: string;
  role: FarmRole;
  findings: () => FindingWithState[];
}

interface Intent {
  key: string;
  /** All words of one group must appear (any group matches). */
  match: RegExp[];
  money?: boolean;
  run: (c: Ctx) => Omit<Answer, 'intent' | 'ok'> & { ok?: boolean };
}

const intents: Intent[] = [
  {
    key: 'priorities',
    match: [/priori|focus|what should (we|i) do|today'?s (plan|work)|most important|urgent/],
    run: (c) => {
      const fs = c.findings().filter((f) => f.severity !== 'low').slice(0, 6);
      if (!fs.length) return { text: 'Nothing urgent in your records today.', bullets: ['Keep recording milk, feed and treatments so FarmTap can keep watching.'], links: [], method: 'calculated' };
      return {
        text: `${plural(fs.length, 'thing')} to look at first, most serious first:`,
        bullets: fs.map((f) => `${f.title}. ${f.action}`),
        links: fs.flatMap((f) => f.links).slice(0, 6),
        method: 'calculated',
      };
    },
  },
  {
    key: 'milkForecast',
    match: [/(predict|forecast|expect|next week|tomorrow|will).*milk|milk.*(predict|forecast|next week|tomorrow)/],
    run: (c) => {
      const f = herdForecast(c.d);
      if (!f.ok) return { ok: false, text: `No forecast yet. ${f.reason}`, bullets: [], links: [{ label: 'Record milk', href: '/milk/?new=1' }], method: 'statistical' };
      return {
        text: `About ${fmtL(f.total7)} over the next 7 days (${f.confidence} confidence).`,
        bullets: [
          `Tomorrow: about ${fmtL(f.next7[1]?.litres ?? f.next7[0].litres)} (likely ${fmtL(f.next7[1]?.low ?? 0)} to ${fmtL(f.next7[1]?.high ?? 0)}).`,
          f.trendPerDay === 0 ? 'Milk is steady.' : `Trend: ${f.trendPerDay > 0 ? 'rising' : 'falling'} about ${fmtL(Math.abs(f.trendPerDay))} a day.`,
          ...(f.total30 != null ? [`Next 30 days: about ${fmtL(f.total30)}.`] : []),
          `Made from ${f.daysUsed} recorded days. ${f.method}.`,
        ],
        links: [{ label: 'Production predictions', href: '/ai/predictions/' }],
        method: 'statistical',
      };
    },
  },
  {
    key: 'cowsDropping',
    match: [/(less|lower|drop|declin|fall|reduc|decreas).*(milk|produc)|(cow|animal)s?.*(less|drop|declin)/],
    run: (c) => {
      const t = cowTrends(c.d);
      if (!t.length) return { ok: false, text: 'I cannot tell yet: this needs milk recorded per cow on at least 3 days this week and 3 days the 2 weeks before.', bullets: [], links: [{ label: 'Milk', href: '/milk/' }], method: 'calculated' };
      const down = t.filter((x) => x.changePct <= DROP_PCT);
      if (!down.length) return { text: `No cow dropped by more than ${-DROP_PCT}% this week (${plural(t.length, 'cow')} compared).`, bullets: [], links: [], method: 'calculated' };
      return {
        text: `${plural(down.length, 'cow')} gave clearly less milk this week than the 2 weeks before:`,
        bullets: down.slice(0, 10).map((x) => `${x.name}: ${fmtL(x.recent)} a day, down ${Math.abs(x.changePct)}% from ${fmtL(x.before)}${x.daysInMilk != null && x.daysInMilk > 200 ? ` (late lactation, ${x.daysInMilk} days in milk)` : ''}.`),
        links: down.slice(0, 5).map((x) => ({ label: x.name, href: animalHref(x.animalId) })),
        method: 'calculated',
      };
    },
  },
  {
    key: 'attention',
    match: [/(need|require).*(attention|check|look)|sick|ill\b|unwell|attention/],
    run: (c) => {
      const list = alive(c.d.animals)
        .filter(isActive)
        .map((a) => ({ a, h: animalHealth(c.d, a.id) }))
        .filter((x) => x.h.attention.length)
        .slice(0, 12);
      if (!list.length) return { text: 'No animal stands out in the records today.', bullets: ['Repeat treatments, milk drops, overdue vaccines and calvings are all checked.'], links: [], method: 'calculated' };
      return {
        text: `${plural(list.length, 'animal')} need attention:`,
        bullets: list.map((x) => `${x.h.name}: ${x.h.attention.join('; ')}.`),
        links: list.slice(0, 6).map((x) => ({ label: x.h.name, href: animalHref(x.a.id) })),
        method: 'calculated',
      };
    },
  },
  {
    key: 'vaccinations',
    match: [/vaccin|jab|injection due/],
    run: (c) => {
      const v = vaccinesDue(c.d);
      const animals = new Map(alive(c.d.animals).map((a) => [a.id, a]));
      if (!v.length) return { text: 'No vaccination is overdue or due in the next 7 days.', bullets: alive(c.d.vaccinations).length ? [] : ['No vaccinations are recorded yet, so FarmTap cannot tell what is missing.'], links: [{ label: 'Health', href: '/health/' }], method: 'calculated' };
      return {
        text: `${plural(v.filter((x) => x.overdueDays > 0).length, 'vaccination')} overdue, ${plural(v.filter((x) => x.overdueDays === 0).length, 'more')} due within a week:`,
        bullets: v.map((x) => `${x.vaccine} for ${x.animalIds.length ? x.animalIds.map((i) => animalName(animals.get(i))).join(', ') : 'the whole herd'}: ${x.overdueDays > 0 ? `${plural(x.overdueDays, 'day')} overdue` : `due ${fmtDay(x.due)}`}.`),
        links: [{ label: 'Health', href: '/health/' }],
        method: 'calculated',
      };
    },
  },
  {
    key: 'feedSpend',
    money: true,
    match: [/(spend|spent|cost|money|pay|paid).*(feed)|feed.*(spend|spent|cost|money)/],
    run: (c) => {
      const p = periodOf(c.q, c.day, 'month');
      const exp = alive(c.d.expenses).filter((e) => e.body.category === 'feed' && inP(recDay(e, 'at'), p));
      const total = sum(exp.map((e) => num(e.body.amount)));
      return {
        ok: exp.length > 0,
        text: exp.length ? `${fmtUgx(total)} spent on feed in ${p.label}.` : `No feed expense is recorded for ${p.label}.`,
        bullets: exp.length ? [`${plural(exp.length, 'expense')}.`] : [],
        links: [{ label: 'Money', href: '/money/' }],
        method: 'calculated',
      };
    },
  },
  {
    key: 'expensive',
    money: true,
    match: [/expensive|biggest (cost|expense)|most (money|spend|cost)|where.*money go|costs?\b.*(most|top)/],
    run: (c) => {
      const p = periodOf(c.q, c.day, 'month');
      const m = monthMoney(c.d, p.from.slice(0, 7));
      if (!m.byCategory.length) return { ok: false, text: `No expenses are recorded for ${fmtMonth(m.month)}.`, bullets: [], links: [{ label: 'Money', href: '/money/' }], method: 'calculated' };
      return {
        text: `Biggest costs in ${fmtMonth(m.month)} (${fmtUgx(m.spent)} in all):`,
        bullets: m.byCategory.slice(0, 5).map((x) => `${catLabel(x.category)}: ${fmtUgx(x.amount)} (${Math.round((x.amount / m.spent) * 100)}%).`),
        links: [{ label: 'Money', href: '/money/' }],
        method: 'calculated',
      };
    },
  },
  {
    key: 'profit',
    money: true,
    match: [/profit|loss|income|earn|revenue|made money|net/],
    run: (c) => {
      const p = periodOf(c.q, c.day, 'month');
      const m = monthMoney(c.d, p.from.slice(0, 7));
      return {
        text: `${fmtMonth(m.month)}: ${m.net >= 0 ? 'profit' : 'loss'} of ${fmtUgx(Math.abs(m.net))}${m.month === c.day.slice(0, 7) ? ' so far' : ''}.`,
        bullets: [`Milk sales ${fmtUgx(m.milkSales)}, other income ${fmtUgx(m.otherIncome)}, spent ${fmtUgx(m.spent)}.`, ...(m.costPerLitre != null ? [`Cost per litre: ${fmtUgx(m.costPerLitre)} (${fmtL(m.litres)} produced).`] : [])],
        links: [{ label: 'Reports', href: '/reports/' }],
        method: 'calculated',
      };
    },
  },
  {
    key: 'costPerLitre',
    money: true,
    match: [/cost (per|a|of a) (litre|liter)/],
    run: (c) => {
      const m = monthMoney(c.d, periodOf(c.q, c.day, 'month').from.slice(0, 7));
      return m.costPerLitre == null
        ? { ok: false, text: `Not enough records for ${fmtMonth(m.month)}: it needs both expenses and milk.`, bullets: [], links: [], method: 'calculated' }
        : { text: `${fmtUgx(m.costPerLitre)} per litre in ${fmtMonth(m.month)}.`, bullets: [`${fmtUgx(m.spent)} spent, ${fmtL(m.litres)} produced.`], links: [{ label: 'Money', href: '/money/' }], method: 'calculated' };
    },
  },
  {
    key: 'expiry',
    match: [/expir|spoil|use.?by|batch|cooler|go bad|old milk/],
    run: (c) => {
      const b = batchViews(c.d).filter((x) => x.state !== 'closed');
      if (!b.length) return { ok: false, text: 'No milk batch is in storage.', bullets: ['Add batches in Milk Quality and Expiry to track use-by times.'], links: [{ label: 'Milk batches', href: '/ai/quality/' }], method: 'calculated' };
      const soon = b.filter((x) => x.state !== 'fresh');
      return {
        text: soon.length ? `${plural(soon.length, 'batch', 'batches')} expired or must go soon:` : `All ${plural(b.length, 'batch', 'batches')} in storage are within their use-by.`,
        bullets: (soon.length ? soon : b).map((x) => `${fmtL(x.litres)} in ${x.place}: ${x.state === 'expired' ? 'past its use-by' : `use within ${x.hoursLeft} hours`}${x.unverified ? ' (no temperature reading)' : ''}.`),
        links: [{ label: 'Milk batches', href: '/ai/quality/' }],
        method: 'calculated',
      };
    },
  },
  {
    key: 'pregnant',
    match: [/pregnan|in calf|due to calve|calving/],
    run: (c) => {
      const list = alive(c.d.animals)
        .filter((a) => isActive(a) && a.body.sex !== 'male')
        .map((a) => ({ a, b: breedingState(a.id, c.d.breeding ?? [], c.day) }))
        .filter((x) => x.b.pregnant)
        .sort((x, y) => (x.b.due ?? '').localeCompare(y.b.due ?? ''));
      if (!list.length) return { text: 'No animal is recorded as served or pregnant.', bullets: [], links: [{ label: 'Breeding', href: '/breeding/' }], method: 'calculated' };
      return {
        text: `${plural(list.length, 'animal')} served or in calf:`,
        bullets: list.map((x) => `${animalName(x.a)}: due about ${fmtDay(x.b.due!)}${x.b.confirmed ? ', confirmed by a check' : ', not yet confirmed'}.`),
        links: [{ label: 'Breeding', href: '/breeding/' }],
        method: 'calculated',
      };
    },
  },
  {
    key: 'breedingDue',
    match: [/heat|breed|serve|insemina|\bai\b|bull/],
    run: (c) => {
      const list = alive(c.d.animals)
        .filter((a) => isActive(a) && a.body.sex !== 'male' && !['calf', 'bull'].includes(a.body.dairyStatus ?? ''))
        .map((a) => ({ a, b: breedingState(a.id, c.d.breeding ?? [], c.day) }))
        .filter((x) => !x.b.pregnant && (x.b.nextHeat || (x.b.daysInMilk ?? 0) > 60));
      if (!list.length) return { text: 'No open cow with a heat expected is recorded.', bullets: ['Record heats, services and calvings so FarmTap can work out the next heat.'], links: [{ label: 'Breeding', href: '/breeding/' }], method: 'calculated' };
      return {
        text: `${plural(list.length, 'cow')} not in calf:`,
        bullets: list.map((x) => `${animalName(x.a)}: ${x.b.nextHeat ? `next heat about ${fmtDay(x.b.nextHeat)}` : 'no heat recorded'}${x.b.daysInMilk != null ? `, ${x.b.daysInMilk} days since calving` : ''}.`),
        links: [{ label: 'Breeding', href: '/breeding/' }],
        method: 'calculated',
      };
    },
  },
  {
    key: 'feedLeft',
    match: [/feed|stock|run out|silage|hay|dairy meal|bran/],
    run: (c) => {
      const f = feedViews(c.d);
      if (!f.length) return { ok: false, text: 'No feed purchases, counts or feedings are recorded yet.', bullets: [], links: [{ label: 'Feeds', href: '/feeds/' }], method: 'calculated' };
      return {
        text: 'Feed in store:',
        bullets: f.map((x) => `${x.name}: ${x.left} ${x.unit}${x.daysLeft != null ? `, about ${plural(x.daysLeft, 'day')} at ${x.perDay} ${x.unit} a day` : ''}.`),
        links: [{ label: 'Feeds', href: '/feeds/' }],
        method: 'calculated',
      };
    },
  },
  {
    key: 'withdrawal',
    match: [/withdraw|treated|medicine|drug|antibiotic/],
    run: (c) => {
      const list = alive(c.d.animals)
        .filter(isActive)
        .map((a) => animalHealth(c.d, a.id))
        .filter((h) => h.inWithdrawal);
      return list.length
        ? { text: `${plural(list.length, 'animal')} in withdrawal (milk must not be sold):`, bullets: list.map((h) => `${h.name}: safe from ${fmtDay(h.safeFrom!)}.`), links: [{ label: 'Health', href: '/health/' }], method: 'calculated' }
        : { text: 'No animal is in a drug withdrawal period today.', bullets: [], links: [{ label: 'Health', href: '/health/' }], method: 'calculated' };
    },
  },
  {
    key: 'milkAmount',
    match: [/milk|litre|liter|produc/],
    run: (c) => {
      const p = periodOf(c.q, c.day);
      const rs = alive(c.d.milk).filter((r) => inP(recDay(r), p));
      const total = sum(rs.map((r) => num(r.body.litres)));
      if (!rs.length) return { ok: false, text: `No milk is recorded for ${p.label}.`, bullets: [], links: [{ label: 'Record milk', href: '/milk/?new=1' }], method: 'calculated' };
      const days = new Set(rs.map((r) => recDay(r))).size;
      const s = milkSummary(c.d);
      const morning = sum(rs.filter((r) => r.body.session === 'morning').map((r) => num(r.body.litres)));
      const evening = sum(rs.filter((r) => r.body.session === 'evening').map((r) => num(r.body.litres)));
      return {
        text: `${fmtL(total)} of milk ${p.label === 'today' || p.label === 'yesterday' ? p.label : `in ${p.label}`}.`,
        bullets: [
          ...(p.from === p.to ? [`Morning ${fmtL(morning)}, evening ${fmtL(evening)}.`] : [`${plural(days, 'day')} recorded, about ${fmtL(total / Math.max(1, days))} a day.`]),
          ...(p.label === 'today' && s.avg7 != null ? [`The last 7 days averaged ${fmtL(s.avg7)} a day.`] : []),
        ],
        links: [{ label: 'Milk records', href: '/milk/' }],
        method: 'calculated',
      };
    },
  },
  {
    key: 'herdSize',
    match: [/how many (cows|animals|cattle)|herd size|number of (cows|animals)/],
    run: (c) => {
      const a = alive(c.d.animals).filter(isActive);
      const by = new Map<string, number>();
      for (const x of a) by.set(x.body.dairyStatus ?? 'other', (by.get(x.body.dairyStatus ?? 'other') ?? 0) + 1);
      return { text: `${plural(a.length, 'animal')} on the farm.`, bullets: [...by.entries()].map(([k, n]) => `${k[0].toUpperCase()}${k.slice(1)}: ${n}`), links: [{ label: 'Herd', href: '/herd/' }], method: 'calculated' };
    },
  },
];

export const suggestedQuestions = [
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

/** Answer a question from the farm's records. Never throws. */
export function ask(question: string, d: FarmData, opts: { role: FarmRole; cfg: AiConfig; farmAiOn?: boolean }): Answer {
  const q = question.trim().toLowerCase().replace(/\s+/g, ' ');
  const day = today(d);
  let cache: FindingWithState[] | null = null;
  const ctx: Ctx = { d, q, day, role: opts.role, findings: () => (cache ??= allFindings(d, { role: opts.role, cfg: opts.cfg, farmAiOn: opts.farmAiOn })) };
  if (!q) return { intent: 'empty', ok: false, text: 'Type a question about your farm.', bullets: suggestedQuestions.slice(0, 4), links: [], method: 'calculated' };
  const hit = intents.find((i) => i.match.some((r) => r.test(q)));
  if (!hit)
    return {
      intent: 'unknown',
      ok: false,
      text: 'I cannot answer that from your records yet. I only answer what I can work out exactly. Try one of these:',
      bullets: suggestedQuestions.slice(0, 6),
      links: [],
      method: 'calculated',
    };
  if (hit.money && !seesMoney(opts.role))
    return { intent: hit.key, ok: false, text: 'Money questions are for the farm owner and managers.', bullets: [], links: [], method: 'calculated' };
  try {
    const r = hit.run(ctx);
    return { intent: hit.key, ok: r.ok ?? true, text: r.text, bullets: r.bullets, links: r.links, method: r.method };
  } catch {
    return { intent: hit.key, ok: false, text: 'Something in the records could not be read, so I will not guess. Please try again or check the records page.', bullets: [], links: [], method: 'calculated' };
  }
}

export const intentKeys = intents.map((i) => i.key);
