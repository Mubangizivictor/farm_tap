// Tests for the three-layer AI (decision 0028): the request classifier, the
// extra built-in insights and the daily AI allowance (shared/aiRoute.ts,
// aiInsights.ts, aiQuota.ts), run against the copies in src/shared.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { addDays, type Rec } from '../shared/aiCore.ts';
import { defaultAiConfig } from '../shared/aiAccess.ts';
import type { FarmData, MilkIn } from '../shared/aiData.ts';
import { classify, answerInternally } from '../shared/aiRoute.ts';
import { herdMilkChange, herdChangeText, insightFindings, recordCompleteness } from '../shared/aiInsights.ts';
import {
  aiErrorText,
  assistantConfigFrom,
  backoffMs,
  commit,
  defaultAssistantConfig,
  nextResetMs,
  providerErrorKind,
  quotaDay,
  release,
  reserve,
  retryable,
  usageFrom,
  usageView,
  usageWarning,
  type UsageDoc,
} from '../shared/aiQuota.ts';

const NOW = '2026-11-07T09:00:00';
const TODAY = '2026-11-07';
let n = 0;
const r = <B>(body: B, createdAt: string): Rec<B> => ({ id: `r${++n}`, createdAt, body });
const day = (back: number) => addDays(TODAY, -back);
const cfg = defaultAiConfig;

function farm(extra: Partial<FarmData> = {}): FarmData {
  return {
    now: NOW,
    animals: [
      { id: 'bella', body: { name: 'Bella', tagNumber: 'FT-001', sex: 'female', status: 'active', dairyStatus: 'milking', dateOfBirth: '2021-01-01' } },
      { id: 'zuri', body: { name: 'Zuri', tagNumber: 'FT-002', sex: 'female', status: 'active', dairyStatus: 'milking' } },
    ],
    ...extra,
  };
}
const milk = (back: number, litres: number, session = 'morning'): Rec<MilkIn> => r({ animalId: null, session, litres }, `${day(back)}T07:00:00`);

// ---------------------------------------------------------------- Classifier

const routeOf = (q: string, extra: Partial<FarmData> = {}, files = 0) => classify(q, farm(extra), { role: 'owner', cfg, files });

test('the table in the brief goes to the right layer', () => {
  const d = { milk: [milk(1, 120), milk(2, 118)], expenses: [r({ category: 'feed', amount: 50000, at: `${TODAY}T08:00:00` }, `${TODAY}T08:00:00`)] };
  const want: [string, string][] = [
    ['How many cows do I have?', 'records'],
    ['How much milk did I produce today?', 'insight'],
    ['Which cows have reduced production?', 'insight'],
    ['When is my next vaccination?', 'insight'],
    ['How much did I spend this month?', 'insight'],
    ['Why is milk production declining?', 'ai'],
    ["Explain my farm's performance", 'ai'],
    ['Recommend improvements to my feeding system', 'ai'],
  ];
  for (const [q, layer] of want) assert.equal(routeOf(q, d).layer, layer, q);
});

test('a built-in answer is kept as facts for an AI question', () => {
  const rt = routeOf('Why is milk production declining?', { milk: [milk(1, 85), milk(2, 120)] });
  assert.equal(rt.layer, 'ai');
  assert.equal(rt.reason, 'reasoning');
  assert.ok(rt.answer?.text.includes('29.2%'));
});

test('files always go to the AI; empty and too-long questions never do', () => {
  assert.equal(routeOf('How much milk today?', {}, 1).layer, 'ai');
  assert.equal(routeOf('', {}).reason, 'empty');
  assert.equal(classify('x'.repeat(50), farm(), { role: 'owner', cfg, maxChars: 20 }).reason, 'tooLong');
});

test('unknown questions go to the AI; priorities stays built-in', () => {
  assert.equal(routeOf('Tell me about Ankole cattle history').layer, 'ai');
  assert.equal(routeOf('What should we prioritise today?').layer, 'insight');
});

test('built-in answers are the same every time and need no network (unlimited)', () => {
  const d = farm({ milk: [milk(1, 85), milk(2, 120)] });
  const first = answerInternally('Has milk production dropped?', d, { role: 'owner', cfg });
  for (let i = 0; i < 500; i++) assert.deepEqual(answerInternally('Has milk production dropped?', d, { role: 'owner', cfg }), first);
});

test('workers never get money answers from the built-in layer', () => {
  const a = answerInternally('How much did I spend this month?', farm(), { role: 'worker', cfg });
  assert.equal(a.ok, false);
  assert.match(a.text, /owner and managers/);
});

// ---------------------------------------------------------------- Insights

test('120 L to 85 L is a 29.2% decline with the brief’s wording', () => {
  const c = herdMilkChange(farm({ milk: [milk(1, 85), milk(2, 120)] }))!;
  assert.equal(c.changePct, -29.2);
  assert.equal(herdChangeText(c), 'Milk production has declined by 29.2% compared with the previous recording.');
  const a = answerInternally('Has milk dropped?', farm({ milk: [milk(1, 85), milk(2, 120)] }), { role: 'owner', cfg });
  assert.equal(a.text, 'Milk production has declined by 29.2% compared with the previous recording. Review animal health, feeding records and recent management changes.');
  const f = insightFindings(farm({ milk: [milk(1, 85), milk(2, 120)] }));
  assert.equal(f[0].severity, 'high');
  assert.match(f[0].action, /vet/);
  assert.doesNotMatch(f[0].action + f[0].why, /diagnos(is|ed) (is|as)/);
});

test('a morning-only today is not compared with a full day', () => {
  const c = herdMilkChange(farm({ milk: [milk(0, 40), milk(1, 120), milk(2, 118)] }))!;
  assert.equal(c.latest.day, day(1));
  const done = herdMilkChange(farm({ milk: [milk(0, 40), milk(0, 50, 'evening'), milk(1, 120)] }))!;
  assert.equal(done.latest.day, TODAY);
});

test('record completeness lists what is missing', () => {
  const c = recordCompleteness(farm());
  assert.equal(c.pct, 50);
  assert.deepEqual(c.gaps[0].missing, ['date of birth']);
});

// ---------------------------------------------------------------- Allowance

test('config: defaults, limits and the old photo switch', () => {
  assert.equal(assistantConfigFrom(undefined).dailyLimit, 10);
  assert.equal(assistantConfigFrom(undefined).warnPct, 80);
  assert.equal(assistantConfigFrom(undefined).timezone, 'Africa/Kampala');
  assert.equal(assistantConfigFrom({ photo: { enabled: true, model: 'gemini-x-1' } }).enabled, true);
  assert.equal(assistantConfigFrom({ photo: { enabled: true, model: 'gemini-x-1' } }).model, 'gemini-x-1');
  const c = assistantConfigFrom({ assistant: { dailyLimit: 25, timezone: 'Mars/Base', route: 'server', maxChars: 5, provider: 'nope' } });
  assert.equal(c.dailyLimit, 25);
  assert.equal(c.timezone, 'Africa/Kampala');
  assert.equal(c.route, 'server');
  assert.equal(c.maxChars, defaultAssistantConfig.maxChars);
  assert.equal(c.provider, 'gemini');
});

test('the day turns at midnight Kampala (UTC+3), not the device or UTC', () => {
  // 20:59 UTC = 23:59 Kampala, 21:00 UTC = 00:00 Kampala next day.
  assert.equal(quotaDay(Date.UTC(2026, 10, 6, 20, 59, 59)), '2026-11-06');
  assert.equal(quotaDay(Date.UTC(2026, 10, 6, 21, 0, 0)), '2026-11-07');
  assert.equal(nextResetMs(Date.UTC(2026, 10, 6, 12, 0, 0)), Date.UTC(2026, 10, 6, 21, 0, 0));
  assert.equal(nextResetMs(Date.UTC(2026, 10, 6, 21, 0, 0)), Date.UTC(2026, 10, 7, 21, 0, 0));
  // Another zone still works (Europe/London, winter UTC+0).
  assert.equal(nextResetMs(Date.UTC(2026, 11, 1, 10), 'Europe/London'), Date.UTC(2026, 11, 2, 0));
});

const fresh = (): UsageDoc => usageFrom(null, '2026-11-07');
const res = (u: UsageDoc, id: string, nowMs = 1000, limit = 10) => reserve(u, { id, nowMs, limit, holdMs: 90000, resetAt: 5 });

test('one successful answer uses one; a failure gives it back', () => {
  let u = fresh();
  const a = res(u, 'a');
  assert.ok(a.ok);
  u = commit(a.next, 'a');
  assert.equal(u.used, 1);
  assert.equal(commit(u, 'a').used, 1, 'the same answer never counts twice');
  const b = res(u, 'b');
  u = release(b.next, 'b');
  assert.equal(u.used, 1);
  assert.equal(u.failed, 1);
  assert.deepEqual(u.pending, {});
});

test('requests in flight hold their place, so the limit cannot be passed at once', () => {
  let u = fresh();
  let granted = 0;
  for (let i = 0; i < 25; i++) {
    const x = res(u, `q${i}`);
    u = x.next;
    if (x.ok) granted++;
  }
  assert.equal(granted, 10);
  assert.equal(u.limitHits, 15);
});

test('a crashed request lapses and its place comes back', () => {
  let u = fresh();
  for (let i = 0; i < 10; i++) u = res(u, `q${i}`).next;
  assert.equal(res(u, 'late', 2000).ok, false);
  assert.equal(res(u, 'later', 1000 + 90001).ok, true);
});

test('limit 0 means AI is off for the day', () => {
  const x = res(fresh(), 'a', 1, 0);
  assert.equal(x.ok, false);
  assert.equal(x.ok === false && x.reason, 'disabled');
});

test('usage view: 80% warning and 100% message', () => {
  assert.equal(usageView(3, 10, 80, 0).remaining, 7);
  assert.equal(usageView(3, 10, 80, 0).level, 'ok');
  const w = usageView(8, 10, 80, 0);
  assert.equal(w.level, 'warn');
  assert.equal(
    usageWarning(w)!.message,
    "You're approaching your daily AI limit. You have 2 AI responses remaining today. Farm Tap's built-in intelligence and farm-management features remain unlimited.",
  );
  const o = usageView(10, 10, 80, 0);
  assert.equal(o.level, 'out');
  assert.equal(usageWarning(o)!.title, 'Your daily AI allowance has been reached.');
  assert.equal(usageView(12, 10, 80, 0).used, 10);
});

test('error texts A to G', () => {
  assert.match(aiErrorText('limit', 10).message, /all 10 AI-powered responses/);
  assert.equal(aiErrorText('unavailable').title, 'AI temporarily unavailable');
  assert.match(aiErrorText('network').message, /has not been consumed/);
  assert.match(aiErrorText('timeout').message, /has not been consumed/);
  assert.equal(aiErrorText('disabled').title, 'AI assistant temporarily disabled');
  assert.equal(aiErrorText('invalid').message, 'Please rephrase your question and try again.');
  assert.equal(aiErrorText('capacity').title, 'AI service capacity reached');
});

test('provider errors are sorted, and only some are retried', () => {
  assert.equal(providerErrorKind(429, 'RESOURCE_EXHAUSTED'), 'capacity');
  assert.equal(providerErrorKind(503, 'overloaded'), 'unavailable');
  assert.equal(providerErrorKind(0, 'fetch failed'), 'network');
  assert.equal(providerErrorKind(0, 'The operation was aborted'), 'timeout');
  assert.equal(providerErrorKind(400, 'Request blocked by safety'), 'invalid');
  assert.equal(retryable('timeout'), false);
  assert.equal(retryable('invalid'), false);
  assert.equal(retryable('capacity'), true);
  assert.ok(backoffMs(0) >= 500 && backoffMs(10) <= 5000);
});
