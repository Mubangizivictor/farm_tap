// Tests for the shared AI engine (shared/ai*.ts, decision 0025), run
// against the copies in src/shared. Fixed "now": Sat 7 Nov 2026, 9:00 am.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { addDays, rankFindings, robustZ, type Finding, type Rec } from '../shared/aiCore.ts';
import { aiConfigFrom, defaultAiConfig, moduleOn } from '../shared/aiAccess.ts';
import type { FarmData, MilkIn } from '../shared/aiData.ts';
import { batchViews, cowTrends, forecastSeries, herdForecast, milkAnomalies, milkBalance, milkSummary } from '../shared/aiMilk.ts';
import { animalHealth, breedingFindings, healthFindings, vaccinesDue } from '../shared/aiHerd.ts';
import { feedViews, feedFindings } from '../shared/aiStock.ts';
import { cashForecast, monthMoney, unusualExpenses } from '../shared/aiMoney.ts';
import { allFindings, todaysInsights } from '../shared/aiRisk.ts';
import { ask, suggestedQuestions } from '../shared/aiAssistant.ts';
import { assess } from '../shared/aiVet.ts';
import { buildPrompt, inventedNumbers, nameLabels, redact, restore } from '../shared/aiPrivacy.ts';
import { buildReport, parseReportRequest } from '../shared/aiReports.ts';

const NOW = '2026-11-07T09:00:00';
const TODAY = '2026-11-07';
let n = 0;
const r = <B>(body: B, createdAt = `${TODAY}T08:00:00`): Rec<B> => ({ id: `r${++n}`, createdAt, body });
const at = (day: string, h = 7) => `${day}T${String(h).padStart(2, '0')}:00:00`;
const day = (back: number) => addDays(TODAY, -back);
const cfg = defaultAiConfig;

/** Herd totals of [litres(daysBack)] for the last [days] days (today excluded unless asked). */
function herdMilk(days: number, litres: (back: number) => number, includeToday = false): Rec<MilkIn>[] {
  const out: Rec<MilkIn>[] = [];
  for (let b = includeToday ? 0 : 1; b <= days; b++) out.push(r({ animalId: null, session: 'morning', litres: litres(b) }, at(day(b))));
  return out;
}

function farm(extra: Partial<FarmData> = {}): FarmData {
  return {
    now: NOW,
    animals: [
      { id: 'bella', body: { name: 'Bella', tagNumber: 'FT-001', sex: 'female', status: 'active', dairyStatus: 'milking' } },
      { id: 'zuri', body: { name: 'Zuri', tagNumber: 'FT-002', sex: 'female', status: 'active', dairyStatus: 'milking' } },
    ],
    ...extra,
  };
}

// ---------------------------------------------------------------- Milk

test('milk summary: today, yesterday and the week change come from the records', () => {
  const milk = [...herdMilk(20, (b) => (b <= 7 ? 80 : 100)), r({ animalId: null, session: 'morning', litres: 42.5 }, at(TODAY))];
  const s = milkSummary(farm({ milk }));
  assert.equal(s.today, 42.5);
  assert.equal(s.yesterday, 80);
  assert.equal(s.avg7, 80);
  assert.equal(s.avgPrev7, 100);
  assert.equal(s.weekChangePct, -20);
});

test('a cow giving 30% less is found; a steady cow is not', () => {
  const milk: Rec<MilkIn>[] = [];
  for (let b = 1; b <= 20; b++) {
    milk.push(r({ animalId: 'bella', session: 'morning', litres: b <= 7 ? 7 : 10 }, at(day(b))));
    milk.push(r({ animalId: 'zuri', session: 'morning', litres: 12 }, at(day(b))));
  }
  const t = cowTrends(farm({ milk }));
  assert.equal(t[0].animalId, 'bella');
  assert.equal(t[0].changePct, -30);
  assert.equal(t.find((x) => x.animalId === 'zuri')?.changePct, 0);
});

test('forecast refuses with fewer than 14 recorded days and says why', () => {
  const f = herdForecast(farm({ milk: herdMilk(10, () => 100) }));
  assert.equal(f.ok, false);
  assert.match(f.reason!, /14 days/);
});

test('forecast of a steady herd stays near its level with high confidence', () => {
  const f = herdForecast(farm({ milk: herdMilk(28, (b) => 100 + (b % 2 ? 1 : -1)) }));
  assert.equal(f.ok, true);
  assert.equal(f.next7.length, 7);
  assert.equal(f.next7[0].day, TODAY);
  for (const x of f.next7) assert.ok(Math.abs(x.litres - 100) < 3, `${x.litres}`);
  assert.equal(f.confidence, 'high');
  assert.ok(f.total30! > 2900 && f.total30! < 3100);
});

test('forecast follows a falling trend but never goes below zero', () => {
  const f = forecastSeries(
    Array.from({ length: 28 }, (_, i) => ({ day: day(28 - i), litres: 50 - i, recorded: true })),
    TODAY,
  );
  assert.ok(f.trendPerDay < 0);
  assert.ok(f.next7.every((x) => x.litres >= 0 && x.low >= 0));
});

test('an unusually low day is flagged as statistical, ordinary days are not', () => {
  const milk = herdMilk(40, (b) => (b === 3 ? 40 : 100 + (b % 3)));
  const a = milkAnomalies(farm({ milk }));
  assert.equal(a.length, 1);
  assert.equal(a[0].day, day(3));
  assert.ok(robustZ(100, [100, 101, 102, 100, 101, 102, 100]) !== null);
});

test('unaccounted milk only when sales are recorded', () => {
  const milk = herdMilk(7, () => 100);
  assert.equal(milkBalance(farm({ milk })).unaccounted, null);
  const milkSales = Array.from({ length: 7 }, (_, i) => r({ litres: 80, pricePerLitre: 1200 }, at(day(i + 1), 10)));
  assert.equal(milkBalance(farm({ milk, milkSales })).unaccounted, 140);
});

// ---------------------------------------------------------------- Batches

test('cooled milk keeps 48 h; a warm reading cuts it to 3 h; no reading is unverified', () => {
  const milkBatches = [
    { id: 'b1', body: { litres: 40, collectedAt: '2026-11-06T18:00:00', cooled: true, place: 'Cooler 1', status: 'stored' } },
    { id: 'b2', body: { litres: 20, collectedAt: '2026-11-07T05:00:00', cooled: true, place: 'Cooler 2', status: 'stored' } },
    { id: 'b3', body: { litres: 10, collectedAt: '2026-11-07T07:30:00', cooled: true, place: 'Can A', status: 'stored' } },
  ];
  const storageReadings = [
    r({ place: 'Cooler 1', tempC: 3.5, at: '2026-11-06T20:00:00' }),
    r({ batchId: 'b2', tempC: 9, at: '2026-11-07T06:00:00' }),
  ];
  const v = batchViews(farm({ milkBatches, storageReadings }));
  const b1 = v.find((x) => x.id === 'b1')!;
  assert.equal(b1.state, 'fresh');
  assert.equal(b1.useBy, '2026-11-08T18:00');
  assert.equal(b1.unverified, false);
  const b2 = v.find((x) => x.id === 'b2')!;
  assert.equal(b2.warm, true);
  assert.equal(b2.state, 'expired');
  const b3 = v.find((x) => x.id === 'b3')!;
  assert.equal(b3.unverified, true);
});

// ---------------------------------------------------------------- Health and breeding

test('an overdue vaccination is listed until a later dose covers it', () => {
  const v1 = r({ vaccine: 'Lumpy skin', animalIds: [], given: '2025-11-01', nextDue: '2026-11-01' });
  assert.equal(vaccinesDue(farm({ vaccinations: [v1] }))[0].overdueDays, 6);
  const v2 = r({ vaccine: 'Lumpy skin', animalIds: [], given: '2026-11-05', nextDue: '2027-11-05' });
  assert.equal(vaccinesDue(farm({ vaccinations: [v1, v2] })).length, 0);
});

test('mastitis three times in 60 days is a repeat-illness alert', () => {
  const treatments = [10, 30, 50].map((b) => r({ animalId: 'bella', condition: 'mastitis', given: day(b), withdrawalDays: 4 }));
  const f = healthFindings(farm({ treatments }));
  const alert = f.find((x) => x.id.startsWith('repeat-illness-bella'))!;
  assert.equal(alert.severity, 'high');
  assert.match(alert.title, /mastitis came back \(3 times\)/);
  assert.ok(animalHealth(farm({ treatments }), 'bella').attention.length > 0);
});

test('breeding: due date is 283 days after service; open cow 100 days after calving', () => {
  const breeding = [
    r({ type: 'ai', kind: 'ai', animalId: 'bella', at: addDays(TODAY, -275) }),
    r({ type: 'calving', animalId: 'zuri', at: addDays(TODAY, -100) }),
  ];
  const f = breedingFindings(farm({ breeding }));
  const calving = f.find((x) => x.id.startsWith('calving-bella'))!;
  assert.match(calving.title, /due to calve/);
  assert.match(calving.why, /estimate/);
  assert.ok(f.some((x) => x.id.startsWith('open-zuri')));
});

// ---------------------------------------------------------------- Feed and money

test('feed: days left from the last count, purchases and 14 days of feeding', () => {
  const stockMoves = [r({ kind: 'count', feed: 'dairyMeal', amount: 100, at: at(day(10)) }), r({ kind: 'purchase', feed: 'dairyMeal', amount: 50, pricePerUnit: 1500, at: at(day(5)) })];
  const feedUses = Array.from({ length: 14 }, (_, i) => r({ feed: 'dairyMeal', group: 'milkingCows', amount: 10, at: at(day(i), 8) }));
  const v = feedViews(farm({ stockMoves, feedUses }))[0];
  assert.equal(v.perDay, 10);
  assert.equal(v.left, 150 - 110); // 11 feedings (days 10 to 0, 8 am) after the 7 am count
  assert.equal(v.daysLeft, 4);
  assert.ok(feedFindings(farm({ stockMoves, feedUses })).some((f) => f.id.startsWith('feed-runout-dairyMeal')));
});

test('money: month totals, a large expense, and no cash forecast without 2 months', () => {
  const expenses = [
    ...[40, 35, 30, 25, 20].map((b) => r({ category: 'vet', amount: 30000, at: day(b) })),
    r({ category: 'vet', amount: 250000, at: day(2) }),
  ];
  const milkSales = [r({ litres: 100, pricePerLitre: 1200 }, at(day(1), 10))];
  const m = monthMoney(farm({ expenses, milkSales }), '2026-11');
  assert.equal(m.milkSales, 120000);
  assert.equal(m.spent, 250000);
  assert.equal(unusualExpenses(farm({ expenses }))[0].amount, 250000);
  assert.equal(cashForecast(farm({ expenses: expenses.slice(-1) })).ok, false);
});

// ---------------------------------------------------------------- Roles, states, insights

test('workers never see money findings; a resolved alert disappears, an acknowledged one stays', () => {
  const expenses = [...[40, 35, 30, 25, 20].map((b) => r({ category: 'vet', amount: 30000, at: day(b) })), r({ category: 'vet', amount: 250000, at: day(2) })];
  const d = farm({ expenses, vaccinations: [r({ vaccine: 'FMD', animalIds: [], given: '2026-05-01', nextDue: '2026-10-01' })] });
  assert.ok(allFindings(d, { role: 'owner', cfg }).some((f) => f.module === 'finance'));
  const w = allFindings(d, { role: 'worker', cfg });
  assert.ok(!w.some((f) => f.module === 'finance'));
  const vid = w.find((f) => f.id.startsWith('vaccine-'))!.id;
  assert.ok(!allFindings(d, { role: 'worker', cfg, states: new Map([[vid, { status: 'resolved' as const }]]) }).some((f) => f.id === vid));
  const ack = allFindings(d, { role: 'worker', cfg, states: new Map([[vid, { status: 'acknowledged' as const }]]) });
  assert.equal(ack.find((f) => f.id === vid)?.state, 'acknowledged');
  assert.equal(todaysInsights(ack, 5)[0].state, ack.some((f) => f.state === 'new') ? 'new' : 'acknowledged');
});

test('switches: platform off, module off, farm off, experimental off', () => {
  assert.equal(moduleOn('milk', cfg, 'worker'), true);
  assert.equal(moduleOn('finance', cfg, 'worker'), false);
  assert.equal(moduleOn('milk', { ...cfg, enabled: false }, 'owner'), false);
  assert.equal(moduleOn('milk', cfg, 'owner', false), false);
  assert.equal(moduleOn('screening', { ...cfg, experimental: false }, 'owner'), false);
  const parsed = aiConfigFrom({ enabled: false, modules: { milk: false, junk: true }, llm: { model: 'bad model; rm', timeoutMs: 5 } });
  assert.equal(parsed.enabled, false);
  assert.equal(parsed.modules.milk, false);
  assert.equal(parsed.modules.feed, true);
  assert.equal(parsed.llm.model, defaultAiConfig.llm.model);
  assert.equal(parsed.llm.timeoutMs, defaultAiConfig.llm.timeoutMs);
});

test('same alert id twice is shown once, most serious first', () => {
  const f = (id: string, severity: Finding['severity']): Finding => ({ id, module: 'milk', severity, title: id, why: '', action: '', method: 'calculated', links: [], subjects: [] });
  const ranked = rankFindings([f('a', 'low'), f('b', 'critical'), f('a', 'low')]);
  assert.deepEqual(ranked.map((x) => x.id), ['b', 'a']);
});

// ---------------------------------------------------------------- Assistant

test('every suggested question is understood', () => {
  const d = farm({ milk: herdMilk(20, () => 100, true) });
  for (const q of suggestedQuestions) assert.notEqual(ask(q, d, { role: 'owner', cfg }).intent, 'unknown', q);
});

test('assistant answers with the real total and refuses to guess', () => {
  const d = farm({ milk: [r({ animalId: null, session: 'morning', litres: 61.5 }, at(TODAY)), r({ animalId: null, session: 'evening', litres: 20 }, at(TODAY, 18))] });
  const a = ask('How much milk did we produce today?', d, { role: 'worker', cfg });
  assert.equal(a.intent, 'milkAmount');
  assert.match(a.text, /81\.5 L/);
  assert.equal(a.method, 'calculated');
  assert.equal(ask('What is the weather in Mbarara?', d, { role: 'owner', cfg }).intent, 'unknown');
  assert.equal(ask('How much did we spend on feed?', d, { role: 'worker', cfg }).ok, false);
  assert.equal(ask('Which milk batches expire soon?', d, { role: 'owner', cfg }).intent, 'expiry');
});

// ---------------------------------------------------------------- Vet

test('vet guide: bloat is critical, udder signs point to mastitis, never a dose', () => {
  const bloat = assess({ signs: ['leftSideSwollen', 'breathingHard'] });
  assert.equal(bloat.risk, 'critical');
  assert.equal(bloat.callVet, 'now');
  const m = assess({ signs: ['udderSwollen', 'milkClots', 'milkDrop'], tempC: 39.8 });
  assert.equal(m.possible[0].key, 'mastitis');
  assert.equal(m.fever, 'fever');
  const milkFever = assess({ signs: ['downCannotRise', 'coldEars'], daysSinceCalving: 1 });
  assert.equal(milkFever.possible[0].key, 'milkFever');
  for (const x of [bloat, m, milkFever]) {
    const all = [...x.steps, ...x.possible.map((p) => p.advice)].join(' ');
    assert.doesNotMatch(all, /\b\d+\s?(mg|ml|cc|g\/kg)\b|dose of|inject \d/i);
    assert.match(x.disclaimer, /not a diagnosis/);
  }
  assert.equal(assess({ signs: [] }).possible.length, 0);
});

// ---------------------------------------------------------------- Privacy

test('names, tags and phone numbers never reach the model, and invented numbers are caught', () => {
  const names = nameLabels({ animals: [{ name: 'Bella', tagNumber: 'FT-001' }], people: ['Okello John'], places: ['Kashari'] });
  const out = redact('Bella (FT-001) seen by Okello John in Kashari, call +256 772 123456', names);
  assert.doesNotMatch(out, /Bella|FT-001|Okello|Kashari|772/);
  const p = buildPrompt('Is Bella sick?', { intent: 'x', ok: true, text: 'Bella gives 7 L', bullets: [], links: [], method: 'calculated' }, names);
  assert.doesNotMatch(p.user, /Bella/);
  assert.equal(restore('Animal 1 gives 7 L', names), 'Bella gives 7 L');
  assert.deepEqual(inventedNumbers('Animal 1 gives 9 L', { intent: 'x', ok: true, text: 'Bella gives 7 L', bullets: [], links: [], method: 'calculated' }), ['9']);
});

// ---------------------------------------------------------------- Reports

test('a report request picks the report and the period; money is refused for workers', () => {
  const p = parseReportRequest('milk report for last month', TODAY, 'owner')!;
  assert.equal(p.kind, 'milk');
  assert.equal(p.period.from, '2026-10-01');
  assert.equal(p.period.to, '2026-10-31');
  assert.equal(parseReportRequest('profit report', TODAY, 'worker'), null);
  const rep = buildReport('milk', p.period, farm({ milk: [r({ animalId: null, session: 'morning', litres: 50 }, '2026-10-12T07:00:00')] }));
  assert.equal(rep.rows.length, 1);
  assert.deepEqual(rep.rows[0].slice(1), [50, 0, 50]);
});
