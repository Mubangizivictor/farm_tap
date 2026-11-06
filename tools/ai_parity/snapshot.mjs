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
const photo = await sh('aiPhoto.ts');

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
  { signs: ['abortion', 'afterbirthStuck'], daysSinceCalving: 1 },
  { signs: ['weakRough', 'paleGums', 'weightLoss'], tempC: 40.1 },
  { signs: ['swollenBrisket', 'strangeBehaviour', 'ticksMany'], tempC: 41.5 },
  { signs: ['staggering', 'notEating'] },
  { signs: ['grainOverload', 'diarrhoea', 'lame'], days: 1 },
  { signs: ['ringLesions', 'hairLoss'] },
  { signs: ['itching', 'hairLoss', 'ticksMany'] },
  { signs: ['calfScours', 'sunkenEyes', 'calfNotSuckling'], tempC: 37 },
  { signs: ['navelSwollen', 'swollenJoint'], tempC: 40 },
  { signs: ['prolapse', 'calvingStraining'], daysSinceCalving: 0 },
  { signs: ['eatingStrange', 'weightLoss'] },
  { signs: ['swollenJoint', 'lame'] },
  { signs: ['sunkenEyes', 'diarrhoea', 'notEating'], days: 2 },
];
const goodPhoto = JSON.stringify({ imageUsable: true, summary: 'Several firm round lumps on the side and neck.', signs: [{ what: 'Firm round lumps on the skin', where: 'side and neck', certainty: 'clear' }], possibleCauses: [{ name: 'Lumpy skin disease', why: 'Many firm round nodules on the skin.' }], urgency: 'soon', reportToAuthorities: false, whatToDoNow: ['Keep her apart from the herd.', 'Control flies and ticks.'], retakeAdvice: null, questionsForFarmer: ['Do other animals have lumps?'] });
export const photoCases = [
  { check: 'skin', reply: goodPhoto },
  { check: 'skin', reply: '```json\n' + goodPhoto + '\n```' },
  { check: 'skin', reply: 'Here is the answer: ' + goodPhoto + ' Hope it helps.' },
  { check: 'udder', reply: JSON.stringify({ imageUsable: true, summary: 'Looks like mastitis. Give 10 ml of oxytetracycline daily. The udder is swollen.', signs: [{ what: 'Swollen rear left quarter', where: 'udder', certainty: 'possible' }], possibleCauses: [{ name: 'Mastitis', why: 'Swollen quarter. Treat with antibiotics.' }], urgency: 'soon', whatToDoNow: ['Inject penicillin into the muscle.', 'Keep her in shade.', 'She has foot and mouth disease for sure.', 'Dose at 5 mg per kg.', 'Milk her last.'], questionsForFarmer: ['Is the milk clotted?'] }) },
  { check: 'bcs', reply: JSON.stringify({ imageUsable: true, summary: 'The cow cannot get up and her left side is swollen (bloat).', signs: [], possibleCauses: [], urgency: 'routine', whatToDoNow: [] }) },
  { check: 'skin', reply: JSON.stringify({ imageUsable: true, summary: 'Healthy-looking skin.', signs: [], possibleCauses: [], urgency: 'none', whatToDoNow: [], retakeAdvice: null }) },
  { check: 'feed', reply: JSON.stringify({ imageUsable: true, summary: 'Clean dry feed.', signs: [], possibleCauses: [], urgency: 'none', whatToDoNow: [] }) },
  { check: 'feed', reply: JSON.stringify({ imageUsable: true, summary: 'Grey-green mould on wet maize bran.', signs: [{ what: 'Mould on the feed', where: 'bottom of the heap', certainty: 'clear' }], possibleCauses: [{ name: 'Wet storage', why: 'Feed looks damp.' }], urgency: 'routine', whatToDoNow: ['Throw the mouldy feed away.', 'Store it dry, off the floor.'] }) },
  { check: 'skin', reply: JSON.stringify({ imageUsable: false, summary: 'Too dark.', signs: [], possibleCauses: [], urgency: 'none' }) },
  { check: 'mouth', reply: JSON.stringify({ imageUsable: true, summary: 'Blisters on the tongue and a lot of drool.', signs: [{ what: 'Blisters on the tongue', where: 'mouth', certainty: 'clear' }, { what: 'Drooling', where: 'mouth', certainty: 'weird' }], possibleCauses: [{ name: 'Foot and mouth disease', why: 'Blisters and drooling together.' }, { name: 'Dipping with acaricide', why: 'x' }], urgency: 'routine', reportToAuthorities: false, whatToDoNow: ['Keep the herd in.', 'Do not move animals.'], retakeAdvice: 'Open the mouth a little wider.' }) },
  { check: 'dung', reply: 'I cannot help with that' },
  { check: 'dung', reply: '' },
  { check: 'dung', reply: '[]' },
  { check: 'calf', reply: JSON.stringify({ imageUsable: true, summary: 'Wet swollen navel. The calf looks weak.', signs: Array.from({ length: 9 }, (_, i) => ({ what: `sign ${i}`, where: 'x', certainty: 'possible' })), possibleCauses: Array.from({ length: 6 }, (_, i) => ({ name: `cause ${i}`, why: 'y' })), urgency: 'soon', whatToDoNow: Array.from({ length: 9 }, (_, i) => `step ${i}.`), questionsForFarmer: ['a', 'b', 'c', 'd', 'e'] }) },
];
export function photoSnapshot() {
  return photoCases.map((c) => JSON.parse(JSON.stringify(photo.readPhotoReply(c.reply, photo.photoCheckByKey(c.check)), (k, v) => (v === undefined ? null : v))));
}
export function vetSnapshot() {
  return vetCases.map((c) => JSON.parse(JSON.stringify(vet.assess(c), (k, v) => (v === undefined ? null : v))));
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const farms = JSON.parse(readFileSync(join(root, 'test', 'core', 'ai', 'fixtures', 'farms.json'), 'utf8'));
  const expected = { farms: farms.map((f) => snapshot(f)), vet: vetSnapshot(), vetCases, photo: photoSnapshot(), photoCases, photoChecks: photo.photoChecks.map((c) => [c.key, c.label, c.kind, c.how, c.focus]), photoPrompt: photo.photoChecks.map((c) => photo.buildPhotoPrompt({ check: c, note: ' Is it  serious?\n', animal: 'cow', daysSinceCalving: 12 })) };
  writeFileSync(join(root, 'test', 'core', 'ai', 'fixtures', 'expected.json'), JSON.stringify(expected));
  console.log(`wrote expected.json for ${farms.length} farms`);
}
