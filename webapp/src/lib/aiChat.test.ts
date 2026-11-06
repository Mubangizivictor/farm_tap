// Tests for the chat engine (shared/aiChat.ts, decision 0027).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { animalHealth } from '../shared/aiHerd.ts';
import type { FarmData, MilkIn } from '../shared/aiData.ts';
import type { Rec } from '../shared/aiCore.ts';
import { addDays } from '../shared/aiCore.ts';
import { animalFacts, chatTopics, googleLinks, buildChatPrompt, chatActions, caseText, chatAssessmentBody, chatDoActions, chatFailureOf, chatModels, cleanTemp, filterChatText, languageLine, needsSearch, nextDay, openCaseQuestions, partialChatText, triageOf, vetSummary, whatsappLink, chatFileKind, chatFollowUps, chatHistory, chatTitle, cleanSources, findAnimalMention, readChatReply } from '../shared/aiChat.ts';

const TODAY = '2026-11-06';
const NOW = `${TODAY}T09:00:00`;
let n = 0;
const r = <B>(body: B, createdAt: string): Rec<B> => ({ id: `r${++n}`, createdAt, body });
const at = (d: string) => `${d}T07:00:00`;

const animals = [
  { id: 'bella', name: 'Bella', tag: 'FT-001' },
  { id: 'zuri', name: 'Zuri', tag: 'FT-002' },
  { id: 'ox', name: 'Ox', tag: null },
];

test('finds the one animal a message names, by name or tag, and not part of a word', () => {
  assert.equal(findAnimalMention('Bella has not eaten since morning', animals), 'bella');
  assert.equal(findAnimalMention('why is ft-002 giving less milk?', animals), 'zuri');
  assert.equal(findAnimalMention('the box was heavy', animals), null);
  assert.equal(findAnimalMention('Bella and Zuri both limp', animals), null);
  assert.equal(findAnimalMention('how is the herd today', animals), null);
});

test('facts come from the records and never contain a name or tag', () => {
  const milk: Rec<MilkIn>[] = [];
  for (let b = 1; b <= 20; b++) milk.push(r({ animalId: 'bella', session: 'morning', litres: b <= 7 ? 7 : 10 }, at(addDays(TODAY, -b))));
  const d: FarmData = { now: NOW, animals: [{ id: 'bella', body: { name: 'Bella', tagNumber: 'FT-001', sex: 'female', status: 'active', dairyStatus: 'milking', dateOfBirth: '2021-03-01' } }], milk };
  const facts = animalFacts(animalHealth(d, 'bella'), d.animals![0].body, TODAY);
  const text = facts.join(' ');
  assert.match(text, /down 30%/);
  assert.match(text, /Age: about 5 years/);
  assert.ok(!/bella|FT-001/i.test(text));
});

test('the prompt holds facts, the calculated answer, what is attached and the question', () => {
  const p = buildChatPrompt({ message: 'Animal 1 is not eating', facts: ['Treated 2 times in the last 90 days.'], calculated: 'Milk today: 40 L', files: [{ kind: 'photo' }, { kind: 'pdf' }] });
  assert.match(p, /FARM FACTS:\n- Treated 2 times/);
  assert.match(p, /CALCULATED ANSWER[^\n]*\nMilk today: 40 L/);
  assert.match(p, /ATTACHED: photo, pdf\./);
  assert.match(p, /QUESTION: Animal 1 is not eating$/);
});

test('drugs, doses and sure diagnoses are removed; lists and line breaks stay', () => {
  const reply = readChatReply('She may have a udder problem.\n- Milk her out often.\n- Give her 10 ml of oxytetracycline.\n- Give her clean water and shade.\nThis is definitely mastitis.', 'my cow is sick');
  assert.ok(!/oxytetracycline|10 ml|definitely/i.test(reply.text));
  assert.match(reply.text, /- Milk her out often\./);
  assert.match(reply.text, /- Give her clean water and shade\./);
  assert.equal(reply.removed, 2);
  assert.equal(reply.health, true);
});

test('health answers always point to the vet; others do not', () => {
  assert.match(readChatReply('Keep her cool and watch her eat.', 'she looks sick').text, /Call your vet/);
  const feed = readChatReply('Napier grass is a good feed in the rainy season.', 'what grass is best');
  assert.equal(feed.health, false);
  assert.equal(feed.callVet, null);
  assert.equal(feed.risk, 'low');
});

test('emergencies say now and reportable diseases are flagged', () => {
  const down = readChatReply('Keep her in the shade.', 'she cannot get up');
  assert.equal(down.callVet, 'now');
  assert.equal(down.risk, 'critical');
  assert.match(down.text, /^Call your vet now\./);
  const fmd = readChatReply('Blisters on the mouth can happen with foot and mouth disease. Keep her away from other cattle.', 'blisters in the mouth');
  assert.equal(fmd.report, true);
  assert.equal(fmd.callVet, 'today');
});

test('a question about the foot and mouth vaccine is not a reported case', () => {
  const v = readChatReply('The foot and mouth vaccination is due next month. Ask your vet to book it.', 'when is the foot and mouth vaccine due');
  assert.equal(v.report, false);
  assert.equal(v.callVet, null);
});

test('an answer that is all unsafe becomes a plain refusal, not an empty box', () => {
  const t = readChatReply('Inject 5 ml of penicillin.', 'what do I give').text;
  assert.ok(t.length > 10);
  assert.ok(!/penicillin|5 ml/i.test(t));
});

test('file kinds: Gemini can read photos, video, pdf and text; not Word or Excel', () => {
  assert.equal(chatFileKind('image/jpeg'), 'photo');
  assert.equal(chatFileKind('video/mp4'), 'video');
  assert.equal(chatFileKind('application/pdf'), 'pdf');
  assert.equal(chatFileKind('text/csv'), 'text');
  assert.equal(chatFileKind('application/vnd.openxmlformats-officedocument.wordprocessingml.document'), null);
});

test('the saved record keeps words, not files', () => {
  const body = chatAssessmentBody('bella', 'is she ok?', readChatReply('Watch her closely. Call your vet if she gets worse.', 'is she ok?'), ['photo'], 'gemini-x', NOW);
  assert.equal(body.kind, 'chat');
  assert.equal(body.photo, null);
  assert.deepEqual(body.files, ['photo']);
  assert.ok(body.summary.length > 0 && body.summary.length <= 600);
});

test('history starts with the farmer and never repeats a side', () => {
  const h = chatHistory([
    { role: 'model', text: 'Hello' },
    { role: 'user', text: 'a' },
    { role: 'user', text: 'b' },
    { role: 'model', text: '' },
    { role: 'model', text: 'c' },
  ]);
  assert.deepEqual(h, [
    { role: 'user', text: 'a\nb' },
    { role: 'model', text: 'c' },
  ]);
  assert.deepEqual(chatHistory([{ role: 'model', text: 'x' }]), []);
});

test('chat title is short', () => {
  assert.equal(chatTitle('  '), 'New chat');
  assert.equal(chatTitle('x'.repeat(80)).length, 46);
});

test('only https sources are kept, once each', () => {
  const s = cleanSources([{ uri: 'http://a.com' }, { uri: 'https://www.b.com/x', title: '' }, { uri: 'https://www.b.com/x' }, { uri: 'https://c.com', title: 'C' }]);
  assert.deepEqual(s, [
    { title: 'b.com', uri: 'https://www.b.com/x' },
    { title: 'C', uri: 'https://c.com' },
  ]);
});

test('a milk question about a named cow opens milk, the cow and the vet when sick', () => {
  const a = chatActions({ question: 'Bella gives sour milk', answer: 'It may be mastitis.', health: true, callVet: 'soon', animal: { id: 'bella', name: 'Bella' } });
  assert.deepEqual(a.map((x) => x.href), ['/herd/?animal=bella', '/ai/vet/?animal=bella', '/contacts/', '/milk/']);
  const m = chatActions({ question: 'How much milk did I get this week?', answer: '90 litres.', health: false, callVet: null, animal: null });
  assert.deepEqual(m.map((x) => x.href), ['/milk/']);
  assert.deepEqual(chatActions({ question: 'hello', answer: 'Hi', health: false, callVet: null, animal: null }), []);
});

test('follow-ups depend on the topic', () => {
  assert.equal(chatFollowUps({ question: 'cow has fever', answer: '', health: true })[1], 'When must I call the vet?');
  assert.equal(chatFollowUps({ question: 'milk', answer: '', health: false })[0], 'Why would milk go down?');
  assert.equal(chatFollowUps({ question: 'hi', answer: '', health: false }).length, 3);
});

test('Google errors become plain failures', () => {
  assert.equal(chatFailureOf('AI: Error fetching from https://x: [403] Firebase AI Logic API has not been used in project'), 'setup');
  assert.equal(chatFailureOf('[403] App Check token is invalid'), 'appCheck');
  assert.equal(chatFailureOf('[404] models/gemini-2.5-flash is not found'), 'model');
  assert.equal(chatFailureOf('[429] Resource has been exhausted (quota)'), 'busy');
  assert.equal(chatFailureOf('TypeError: Failed to fetch'), 'network');
  assert.equal(chatFailureOf('weird'), 'unreadable');
});

test('saved chats: newest first, searchable, grouped by day', async () => {
  const { upsertChat, searchChats, groupChats } = await import('./aiChatStore.ts');
  const now = new Date(2026, 10, 6, 12).getTime();
  const mk = (id: string, title: string, ago: number, text = '') => ({ id, title, updatedAt: now - ago, turns: [{ id: 1, who: 'me' as const, text }] });
  let list = upsertChat([], mk('a', 'Milk drop', 3_600_000, 'Bella milk is low'));
  list = upsertChat(list, mk('b', 'Feed mix', 86_400_000 + 1000));
  list = upsertChat(list, mk('c', 'Old one', 20 * 86_400_000));
  list = upsertChat(list, mk('a', 'Milk drop', 100, 'again'));
  assert.deepEqual(list.map((c) => c.id), ['a', 'b', 'c']);
  assert.deepEqual(searchChats(list, 'feed').map((c) => c.id), ['b']);
  assert.deepEqual(searchChats(list, 'milk again').map((c) => c.id), ['a']);
  assert.deepEqual(groupChats(list, now).map((g) => g.label), ['Today', 'Yesterday', 'Older']);
});

test('bad milk counts as a health question', () => {
  assert.equal(readChatReply('Check her udder.', 'My cow gives sour milk').health, true);
  assert.equal(readChatReply('Yes.', 'How do I sell milk?').health, false);
});

test('streaming text is cut at a finished sentence and unsafe sentences never show', () => {
  assert.equal(partialChatText('Keep her clean. Give 20 ml of oxytetracycline. Watch for'), 'Keep her clean.');
  assert.equal(partialChatText('Half a sen'), '');
  assert.equal(filterChatText('Keep her clean.\nGive 20 ml of oxytetracycline.').removed, 1);
});

test('photos start with the stronger model and every list has a second model', () => {
  assert.deepEqual(chatModels('gemini-3.5-flash-lite', true), ['gemini-3.8-flash', 'gemini-3.5-flash-lite']);
  assert.deepEqual(chatModels('gemini-3.5-flash-lite', false), ['gemini-3.5-flash-lite', 'gemini-3.8-flash']);
  assert.equal(chatModels('gemini-3.8-flash', false).length, 2);
});

test('language and search lines reach the prompt', () => {
  assert.equal(languageLine('auto'), null);
  assert.match(languageLine('lg') ?? '', /Luganda/);
  const p = buildChatPrompt({ message: 'hello there friend', facts: [], files: [], search: true, language: 'sw' });
  assert.match(p, /SEARCH GOOGLE FIRST/);
  assert.match(p, /Kiswahili/);
  assert.equal(needsSearch('How do I stop mastitis?', { calculated: false, animal: false }), true);
  assert.equal(needsSearch('milk this week', { calculated: true, animal: false }), false);
  assert.equal(needsSearch('hi', { calculated: false, animal: false }), false);
});

test('triage card: urgency, safe steps, milk and reportable disease', () => {
  const sick = readChatReply('Her udder is hot. Check the milk.', 'Bella gives sour milk');
  const t = triageOf(sick, 'sour milk')!;
  assert.equal(t.level, 'soon');
  assert.ok(t.doNow.some((x) => /milk/i.test(x)));
  assert.ok(t.doNow.every((x) => !/\b(mg|ml)\b/i.test(x)));
  const lsd = readChatReply('This could be lumpy skin disease. She cannot get up.', 'lumps on skin');
  const t2 = triageOf(lsd)!;
  assert.equal(t2.level, 'now');
  assert.equal(t2.report, true);
  assert.match(t2.doNow[0], /Call your vet now/);
  assert.equal(triageOf(readChatReply('Dry hay is fine.', 'what feed')), null);
});

test('the vet questions, temperature check and message', () => {
  assert.equal(cleanTemp('40,5'), '40.5');
  assert.equal(cleanTemp('140'), null);
  assert.equal(openCaseQuestions({ since: 'Today' }, true).some((q) => q.id === 'age' || q.id === 'since'), false);
  assert.equal(caseText({ since: 'Today', temp: '40.5' }), 'Since: Today. Temperature: 40.5 °C');
  const triage = triageOf(readChatReply('Her udder is hot.', 'sour milk'), 'sour milk');
  const m = vetSummary({ farm: 'Mbarara farm', animal: { label: 'Bella (FT-001)', facts: ['This question is about one animal on the farm.', 'Calved 40 days ago.'] }, question: 'Bella gives sour milk', answer: 'Her udder is hot. Check the milk. Call your vet today.', answers: { temp: '40.5' }, triage, hasPhoto: true, day: TODAY });
  assert.match(m, /Animal: Bella \(FT-001\)/);
  assert.match(m, /Temperature: 40.5 °C/);
  assert.match(m, /Calved 40 days ago/);
  assert.match(m, /photo is attached/);
  assert.doesNotMatch(m, /This question is about/);
});

test('WhatsApp link uses the Uganda country code', () => {
  assert.equal(whatsappLink('0772 123 456', 'Hi'), 'https://wa.me/256772123456?text=Hi');
  assert.equal(whatsappLink('+256772123456', 'a b'), 'https://wa.me/256772123456?text=a%20b');
  assert.equal(whatsappLink('12', 'x'), null);
  assert.equal(whatsappLink(null, 'x'), 'https://wa.me/?text=x');
});

test('record treatment and reminder buttons', () => {
  assert.equal(nextDay('2026-11-30'), '2026-12-01');
  const t = triageOf(readChatReply('Her udder is hot.', 'sour milk'));
  const a = chatDoActions({ animal: { id: 'b1', name: 'Bella' }, triage: t, day: TODAY });
  assert.deepEqual(a.map((x) => x.href), ['/health/?new=1&animal=b1', '/tasks/?new=1&title=Recheck%20Bella&due=2026-11-07']);
  assert.deepEqual(chatDoActions({ animal: null, triage: null, day: TODAY }), []);
});

test('free topics and Google links', () => {
  assert.deepEqual(chatTopics('How do I stop mastitis?').map((t) => t.wiki), ['Mastitis']);
  assert.deepEqual(chatTopics('my cow has lumpy skin and ticks').map((t) => t.wiki), ['Lumpy_skin_disease', 'Tick']);
  assert.equal(chatTopics('How much milk today?').length, 0);
  assert.match(googleLinks('mastitis in dairy cows').images, /tbm=isch&q=mastitis%20in%20dairy%20cows/);
});
