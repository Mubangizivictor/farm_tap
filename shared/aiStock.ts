// FarmTap AI engine — feed and stores (decision 0025).

import { addDays, alive, fmtDay, fmtL, fmtUgx, num, plural, recDay, robustZ, round1, sum, type Finding } from './aiCore.ts';
import { isActive, milkDays, today, type FarmData } from './aiData.ts';

/** The phone's built-in feeds (domain.feedName). Custom feeds use their feedTypes record. */
export const builtInFeeds: Record<string, { name: string; unit: string }> = {
  dairyMeal: { name: 'Dairy meal', unit: 'kg' },
  maizeBran: { name: 'Maize bran', unit: 'kg' },
  mineralLick: { name: 'Mineral lick', unit: 'kg' },
  silage: { name: 'Silage', unit: 'kg' },
  napierGrass: { name: 'Napier grass', unit: 'kg' },
  hay: { name: 'Hay', unit: 'bales' },
  cottonSeedCake: { name: 'Cotton seed cake', unit: 'kg' },
  brewersWaste: { name: "Brewers' waste", unit: 'kg' },
};

export interface FeedView {
  feed: string;
  name: string;
  unit: string;
  left: number;
  /** Average used per day over the last 14 days with any feeding. */
  perDay: number;
  daysLeft: number | null;
  runsOut: string | null;
  lowAt: number | null;
  /** Bought in the last 30 days, and what it cost. */
  bought30: number;
  spent30: number;
  /** Days in the last 14 where far more was fed than usual. */
  heavyDays: { day: string; amount: number; usual: number }[];
  hasCount: boolean;
}

export function feedViews(d: FarmData): FeedView[] {
  const day = today(d);
  const keys = new Set<string>();
  for (const m of alive(d.stockMoves)) if (m.body.feed) keys.add(m.body.feed);
  for (const u of alive(d.feedUses)) if (u.body.feed) keys.add(u.body.feed);
  const types = new Map(alive(d.feedTypes).map((t) => [t.id, t.body]));
  return [...keys].map((feed) => {
    const t = types.get(feed);
    const meta = builtInFeeds[feed] ?? { name: t?.name ?? feed, unit: t?.unit ?? 'kg' };
    const moves = alive(d.stockMoves).filter((m) => m.body.feed === feed);
    const counts = moves.filter((m) => m.body.kind === 'count').sort((a, b) => (recDay(b, 'at') ?? '').localeCompare(recDay(a, 'at') ?? '') || (b.body.at ?? '').localeCompare(a.body.at ?? ''));
    const last = counts[0];
    const from = last?.body.at ?? '';
    let left = last ? num(last.body.amount) : 0;
    for (const m of moves) if (m.body.kind === 'purchase' && (m.body.at ?? '') > from) left += num(m.body.amount);
    const uses = alive(d.feedUses).filter((u) => u.body.feed === feed);
    for (const u of uses) if ((u.body.at ?? '') > from) left -= num(u.body.amount);
    const byDay = new Map<string, number>();
    for (const u of uses) {
      const ud = recDay(u, 'at');
      if (ud) byDay.set(ud, (byDay.get(ud) ?? 0) + num(u.body.amount));
    }
    const recent = [...byDay.entries()].filter(([k]) => k > addDays(day, -14) && k <= day);
    const perDay = recent.length ? sum(recent.map(([, v]) => v)) / 14 : 0;
    const daysLeft = perDay > 0 ? Math.floor(Math.max(0, left) / perDay) : null;
    const from30 = addDays(day, -29);
    const bought = moves.filter((m) => m.body.kind === 'purchase' && (recDay(m, 'at') ?? '') >= from30);
    const heavyDays: FeedView['heavyDays'] = [];
    for (const [k, v] of recent) {
      const hist = [...byDay.entries()].filter(([h]) => h < k && h >= addDays(k, -30)).map(([, x]) => x);
      const z = robustZ(v, hist, 10);
      if (z != null && z >= 3) heavyDays.push({ day: k, amount: round1(v), usual: round1(hist.length ? hist.sort((a, b) => a - b)[Math.floor(hist.length / 2)] : 0) });
    }
    const lowAt = t?.lowAt != null ? num(t.lowAt) : null;
    return {
      feed,
      name: meta.name,
      unit: meta.unit,
      left: round1(left),
      perDay: round1(perDay),
      daysLeft,
      runsOut: daysLeft != null ? addDays(day, daysLeft) : null,
      lowAt,
      bought30: round1(sum(bought.map((m) => num(m.body.amount)))),
      spent30: Math.round(sum(bought.map((m) => num(m.body.amount) * num(m.body.pricePerUnit)))),
      heavyDays,
      hasCount: !!last,
    };
  });
}

export interface FeedEconomics {
  /** Feed spending in the last 30 days (Money "feed" expenses, else purchases). */
  feedSpend30: number;
  litres30: number;
  costPerLitre: number | null;
  /** Active animals and feed spend per animal per day. */
  animals: number;
  costPerAnimalDay: number | null;
  /** Litres of milk per 1,000 UGX of feed. */
  litresPer1000: number | null;
}

export function feedEconomics(d: FarmData): FeedEconomics {
  const day = today(d);
  const from = addDays(day, -29);
  const exp = alive(d.expenses).filter((e) => e.body.category === 'feed' && (recDay(e, 'at') ?? '') >= from && (recDay(e, 'at') ?? '') <= day);
  const spend = exp.length ? sum(exp.map((e) => num(e.body.amount))) : sum(feedViews(d).map((f) => f.spent30));
  const litres = sum(milkDays(d, 30).map((x) => x.litres));
  const animals = alive(d.animals).filter(isActive).length;
  return {
    feedSpend30: Math.round(spend),
    litres30: round1(litres),
    costPerLitre: litres > 0 && spend > 0 ? Math.round(spend / litres) : null,
    animals,
    costPerAnimalDay: animals > 0 && spend > 0 ? Math.round(spend / animals / 30) : null,
    litresPer1000: spend > 0 ? round1((litres / spend) * 1000) : null,
  };
}

export interface DrugView {
  id: string;
  name: string;
  stock: number | null;
  unit: string;
  reorderAt: number | null;
  used30: number;
}

export function drugViews(d: FarmData): DrugView[] {
  const from = addDays(today(d), -29);
  return alive(d.stockItems)
    .filter((s) => s.body.kind === 'drug')
    .map((s) => ({
      id: s.id,
      name: s.body.name?.trim() || 'Drug',
      stock: s.body.stock == null ? null : num(s.body.stock),
      unit: s.body.unit ?? '',
      reorderAt: s.body.reorderAt != null ? num(s.body.reorderAt) : s.body.lowAt != null ? num(s.body.lowAt) : null,
      used30: alive(d.treatments).filter((t) => t.body.drugId === s.id && (recDay(t, 'given') ?? '') >= from).length,
    }));
}

export function feedFindings(d: FarmData): Finding[] {
  const day = today(d);
  const out: Finding[] = [];
  for (const f of feedViews(d)) {
    const link = [{ label: f.name, href: '/feeds/' }];
    if (f.daysLeft != null && f.daysLeft <= 7)
      out.push({
        id: `feed-runout-${f.feed}-${day}`,
        module: 'feed',
        severity: f.daysLeft <= 2 ? 'critical' : f.daysLeft <= 4 ? 'high' : 'medium',
        title: f.daysLeft === 0 ? `${f.name} has run out` : `${f.name} runs out in about ${plural(f.daysLeft, 'day')}`,
        why: `${f.left} ${f.unit} left${f.hasCount ? '' : ' (no stock count yet, from purchases and feedings only)'}; the herd uses about ${f.perDay} ${f.unit} a day (last 14 days).`,
        action: `Buy ${f.name.toLowerCase()} before ${fmtDay(f.runsOut!)}. About ${Math.ceil(f.perDay * 14)} ${f.unit} covers two weeks.`,
        method: 'calculated',
        links: link,
        subjects: [f.feed],
      });
    else if (f.lowAt != null && f.left <= f.lowAt)
      out.push({
        id: `feed-low-${f.feed}-${day}`,
        module: 'feed',
        severity: 'medium',
        title: `${f.name} is below your reorder level`,
        why: `${f.left} ${f.unit} left; you asked to be warned at ${f.lowAt} ${f.unit}.`,
        action: `Buy ${f.name.toLowerCase()} soon.`,
        method: 'calculated',
        links: link,
        subjects: [f.feed],
      });
    if (f.left < 0)
      out.push({
        id: `feed-negative-${f.feed}-${day}`,
        module: 'inventory',
        severity: 'low',
        title: `${f.name}: more fed than bought`,
        why: `Feedings since the last count add up to more than the stock (${f.left} ${f.unit}). A purchase may be missing.`,
        action: 'Count what is in the store and record the count.',
        method: 'calculated',
        links: link,
        subjects: [f.feed],
      });
    for (const h of f.heavyDays)
      out.push({
        id: `feed-heavy-${f.feed}-${h.day}`,
        module: 'feed',
        severity: 'low',
        title: `Much more ${f.name.toLowerCase()} fed on ${fmtDay(h.day)}`,
        why: `${h.amount} ${f.unit} recorded, against a usual ${h.usual} ${f.unit} a day.`,
        action: 'Check the entry was typed correctly; if it was, check for waste or theft.',
        method: 'statistical',
        links: link,
        subjects: [f.feed],
      });
  }
  const e = feedEconomics(d);
  const last7 = milkDays(d, 8).slice(0, -1).filter((x) => x.recorded).map((x) => x.litres);
  if (e.costPerLitre != null && last7.length >= 3) {
    const sale = alive(d.milkSales).filter((s) => (recDay(s) ?? '') >= addDays(day, -29));
    const price = sale.length ? sum(sale.map((s) => num(s.body.litres) * num(s.body.pricePerLitre))) / Math.max(1, sum(sale.map((s) => num(s.body.litres)))) : null;
    if (price && e.costPerLitre >= price * 0.6)
      out.push({
        id: `feed-cost-litre-${day.slice(0, 7)}`,
        module: 'finance',
        severity: e.costPerLitre >= price ? 'high' : 'medium',
        title: `Feed costs ${fmtUgx(e.costPerLitre)} per litre`,
        why: `Last 30 days: ${fmtUgx(e.feedSpend30)} on feed for ${fmtL(e.litres30)}. Milk sold for about ${fmtUgx(price)} a litre (${Math.round((e.costPerLitre / price) * 100)}% of the price).`,
        action: 'Feed the most to the cows giving the most milk, and check bought feed against home-grown fodder.',
        method: 'calculated',
        links: [{ label: 'Money', href: '/money/' }],
        subjects: [],
      });
  }
  return out;
}

export function drugFindings(d: FarmData): Finding[] {
  const day = today(d);
  return drugViews(d)
    .filter((x) => x.stock != null && x.reorderAt != null && x.stock <= x.reorderAt)
    .map((x) => ({
      id: `drug-low-${x.id}-${day}`,
      module: 'inventory' as const,
      severity: x.stock === 0 ? ('high' as const) : ('medium' as const),
      title: x.stock === 0 ? `${x.name} is out of stock` : `${x.name} is low`,
      why: `${x.stock} ${x.unit} left; reorder level ${x.reorderAt} ${x.unit}.${x.used30 ? ` Used in ${plural(x.used30, 'treatment')} in the last 30 days.` : ''}`,
      action: 'Buy more from your drug shop or vet.',
      method: 'calculated' as const,
      links: [{ label: 'Drug stock', href: '/health/' }],
      subjects: [x.id],
    }));
}

