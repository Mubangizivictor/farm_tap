// Parity snapshot of the shared TypeScript AI engine (decision 0025).
// Phone AI (phase 2): the Dart engine in lib/core/ai must give the same
// answers as shared/ai*.ts on the same records. This file makes the
// "expected" side: `node tools/ai_parity/snapshot.mjs` writes
// test/core/ai/fixtures/expected.json from farms.json. The Dart test
// test/core/ai/ai_parity_test.dart makes the same snapshot and compares.
import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..', '..');
const sh = (f) => import(join(root, 'shared', f));
const core = await sh('aiCore.ts');
const access = await sh('aiAccess.ts');
const milk = await sh('aiMilk.ts');
const herd = await sh('aiHerd.ts');
const stock = await sh('aiStock.ts');
const money = await sh('aiMoney.ts');
const risk = await sh('aiRisk.ts');
const assistant = await sh('aiAssistant.ts');
const reports = await sh('aiReports.ts');
const vet = await sh('aiVet.ts');
const data = await sh('aiData.ts');

const finding = (f) => ({ id: f.id, module: f.module, severity: f.severity, title: f.title, why: f.why, action: f.action, method: f.method, links: f.links.map((l) => [l.label, l.href]), subjects: f.subjects, state: f.state ?? null });
const answer = (a) => ({ intent: a.intent, ok: a.ok, text: a.text, bullets: a.bullets, links: a.links.map((l) => [l.label, l.href]), method: a.method });
const forecast = (f) => ({ ok: f.ok, reason: f.reason ?? null, daysUsed: f.daysUsed, next7: f.next7.map((n) => [n.day, n.litres, n.low, n.high]), total7: f.total7, total30: f.total30, trendPerDay: f.trendPerDay, confidence: f.confidence, method: f.method });

export const questions = [...assistant.suggestedQuestions, 'milk yesterday', 'milk in the last 10 days', 'how much milk last week', 'profit this month', 'what is our cost per litre', 'how many cows do we have', 'which animals are in withdrawal', 'what feed is running out', 'tell me a joke', ''];

export function snapshot(farm) {
  const d = farm;
  const out = {};
  const cfg = access.defaultAiConfig;
  for (const role of ['owner', 'clerk', 'worker']) {
    out[`findings_${role}`] = risk.allFindings(d, { role, cfg }).map(finding);
    out[`asks_${role}`] = questions.map((q) => answer(assistant.ask(q, d, { role, cfg })));
  }
  const states = new Map([[out.findings_owner[0]?.id, { status: 'acknowledged' }], [out.findings_owner[1]?.id, { status: 'resolved' }]]);
  out.findings_states = risk.allFindings(d, { role: 'owner', cfg, states }).map(finding);
  const s = milk.milkSummary(d);
  out.milkSummary = { today: s.today, yesterday: s.yesterday, todayRecorded: s.todayRecorded, avg7: s.avg7, avgPrev7: s.avgPrev7, weekChangePct: s.weekChangePct, recordedDays30: s.recordedDays30, monthToDate: s.monthToDate, lastMonthSameDays: s.lastMonthSameDays };
  out.herdForecast = forecast(milk.herdForecast(d));
  out.cowForecasts = (d.animals ?? []).map((a) => [a.id, forecast(milk.cowForecast(d, a.id))]);
  out.cowTrends = milk.cowTrends(d).map((c) => [c.animalId, c.name, c.recent, c.before, c.changePct, c.daysRecent, c.daysBefore, c.daysInMilk]);
  out.anomalies = milk.milkAnomalies(d).map((a) => [a.day, a.litres, a.usual, a.z]);
  out.balance = milk.milkBalance(d);
  out.batches = milk.batchViews(d).map((b) => [b.id, b.litres, b.place, b.collectedAt, b.useBy, b.hoursLeft, b.state, b.readings, b.highest, b.warm, b.unverified, b.status]);
  out.breaches = milk.temperatureBreaches(d).map((b) => [b.id, b.place, b.tempC, b.at, b.limit]);
  out.quality = milk.qualitySummary(d);
  out.feedViews = stock.feedViews(d).map((f) => ({ ...f }));
  out.feedEconomics = stock.feedEconomics(d);
  out.drugs = stock.drugViews(d);
  out.months = money.monthsBack(d, 5);
  out.cash = money.cashForecast(d);
  out.unusual = money.unusualExpenses(d);
  out.vaccines = herd.vaccinesDue(d);
  out.calving = herd.calvingInterval(d);
  out.health = (d.animals ?? []).map((a) => [a.id, herd.animalHealth(d, a.id)]);
  const day = data.today(d);
  out.breeding = (d.animals ?? []).map((a) => [a.id, data.breedingState(a.id, d.breeding ?? [], day)]);
  out.reports = {};
  for (const role of ['owner', 'worker']) {
    for (const text of ['milk report', 'milk report for last month', 'health report last 30 days', 'profit this month', 'expenses last month', 'feed report', 'breeding report', 'quality report', 'inventory', 'overall performance last week', 'something unrelated']) {
      const req = reports.parseReportRequest(text, day, role);
      out.reports[`${role}|${text}`] = req ? { kind: req.kind, period: req.period, report: reports.buildReport(req.kind, req.period, d) } : null;
    }
  }
  return JSON.parse(JSON.stringify(out, (k, v) => (v === undefined ? null : v)));
}

export const vetCases = [
  { signs: [] },
  { signs: ['udderSwollen', 'milkClots', 'milkDrop'], tempC: 40 },
  { signs: ['lymphSwollen', 'ticksMany', 'breathingHard'], tempC: 41.2 },
  { signs: ['leftSideSwollen'] },
  { signs: ['coldEars', 'downCannotRise'], daysSinceCalving: 1 },
  { signs: ['eatingLess', 'milkDrop'], daysSinceCalving: 20, days: 2 },
  { signs: ['skinLumps', 'notEating'], tempC: 39.8, days: 3 },
  { signs: ['wound'], tempC: 37 },
  { signs: ['diarrhoea', 'weightLoss', 'paleGums'] },
  { signs: ['bloodOpenings', 'otherDied'], tempC: 41 },
  { signs: ['lame'] },
  { signs: ['afterbirthStuck', 'badDischarge'], daysSinceCalving: 2, tempC: 40 },
];
export function vetSnapshot() {
  return vetCases.map((c) => JSON.parse(JSON.stringify(vet.assess(c), (k, v) => (v === undefined ? null : v))));
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const farms = JSON.parse(readFileSync(join(root, 'test', 'core', 'ai', 'fixtures', 'farms.json'), 'utf8'));
  const expected = { farms: farms.map((f) => snapshot(f)), vet: vetSnapshot(), vetCases };
  writeFileSync(join(root, 'test', 'core', 'ai', 'fixtures', 'expected.json'), JSON.stringify(expected));
  console.log(`wrote expected.json for ${farms.length} farms`);
}
