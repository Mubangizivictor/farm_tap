// Tests for the chat engine (shared/aiChat.ts, decision 0027).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { animalHealth } from '../shared/aiHerd.ts';
import type { FarmData, MilkIn } from '../shared/aiData.ts';
import { contextFacts, cowSpark, farmToday } from '../shared/aiToday.ts';
import type { Rec } from '../shared/aiCore.ts';
import { addDays } from '../shared/aiCore.ts';
import { readPins, readHeard, chatCategory, animalFacts, buildChatPrompt, chatTopics, googleLinks, CHAT_SIGNS, questionKind, chatActions, caseText, chatAssessmentBody, chatDoActions, chatFailureOf, chatModels, cleanTemp, filterChatText, languageLine, needsSearch, nextDay, openCaseQuestions, partialChatText, triageOf, vetSummary, whatsappLink, chatFileKind, chatFollowUps, chatHistory, chatTitle, cleanSources, findAnimalMention, readChatReply } from '../shared/aiChat.ts';

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

test('"is sick" with no signs asks what the signs are, and shows no emergency card', () => {
  assert.equal(questionKind('Bihogo is sick, what do you know about bihogo'), 'signs');
  assert.equal(questionKind('what do you know about Bella'), 'records');
  assert.equal(questionKind('Bella is sick and has a swollen udder'), 'normal');
  assert.equal(questionKind('How do I stop mastitis?'), 'normal');
  const reply = readChatReply('She is a female, 22 months. Call your vet today. What signs do you see?', 'Bihogo is sick');
  assert.equal(triageOf(reply, 'Bihogo is sick'), null);
  assert.ok(triageOf(reply, 'Bihogo is sick and has a swollen udder'));
  assert.deepEqual(chatFollowUps({ question: 'Bihogo is sick', answer: '', health: true }), CHAT_SIGNS);
  assert.match(buildChatPrompt({ message: 'Bihogo is sick', facts: [], calculated: null, files: [], search: false, language: 'auto' }), /what signs do they see/);
});

test('free topics and Google links', () => {
  assert.deepEqual(chatTopics('How do I stop mastitis?').map((t) => t.wiki), ['Mastitis']);
  assert.deepEqual(chatTopics('my cow has lumpy skin and ticks').map((t) => t.wiki), ['Lumpy_skin_disease', 'Tick']);
  assert.deepEqual(chatTopics('hello', 'Check for ticks.').map((t) => t.wiki), ['Tick']);
  assert.equal(chatTopics('How much milk today?').length, 0);
  assert.match(googleLinks('mastitis in dairy cows').images, /tbm=isch&q=mastitis%20in%20dairy%20cows/);
});

test('pins: read, clamp, drop the unsafe and remove the line', () => {
  const t = 'Thin calf with lumps.\nPINS: [{"n":1,"x":42,"y":65,"label":"Raised lumps on the skin","tone":"red","sure":"likely"},{"n":2,"x":150,"y":-3,"label":"Ribs showing"},{"n":3,"x":50,"y":50,"label":"Give 5 ml of penicillin"},{"x":"a"}]';
  const r = readPins(t);
  assert.equal(r.text, 'Thin calf with lumps.');
  assert.equal(r.pins.length, 2);
  assert.deepEqual(r.pins[0], { n: 1, x: 42, y: 65, label: 'Raised lumps on the skin', tone: 'red', sure: 'likely' });
  assert.equal(r.pins[1].x, 96);
  assert.equal(r.pins[1].y, 4);
  assert.equal(r.pins[1].tone, 'gold');
  assert.deepEqual(readPins('No pins here.'), { text: 'No pins here.', pins: [] });
  assert.equal(readPins('Text\nPINS: [broken').pins.length, 0);
  assert.equal(readPins('Text\nPINS: [broken').text, 'Text');
});

test('the PINS line never shows while the answer streams in', () => {
  assert.equal(partialChatText('Thin calf. Lumps on skin.\nPINS: [{"n":1,"x":4'), 'Thin calf. Lumps on skin.');
});

test('"I heard:" is split from a voice-note answer', () => {
  assert.deepEqual(readHeard('I heard: "my cow is not eating"\nShe may be unwell.'), { heard: 'my cow is not eating', text: 'She may be unwell.' });
  assert.deepEqual(readHeard('Plain answer.'), { heard: null, text: 'Plain answer.' });
});

test('chats are sorted into categories for the history filters', () => {
  assert.equal(chatCategory({ question: 'what is this', hadMedia: true }), 'photos');
  assert.equal(chatCategory({ question: 'cow has fever' }), 'health');
  assert.equal(chatCategory({ question: 'litres of milk this week' }), 'milk');
  assert.equal(chatCategory({ question: 'what is my profit' }), 'money');
  assert.equal(chatCategory({ question: 'is she in heat' }), 'breeding');
  assert.equal(chatCategory({ question: 'best napier feed' }), 'feed');
  assert.equal(chatCategory({ question: 'hello' }), 'other');
});

test('today on the farm and the records a farmer can attach', () => {
  const d = { now: `${TODAY}T09:00:00`, milk: [r({ litres: 100 }, at(addDays(TODAY, -2))), r({ litres: 120 }, at(TODAY))], treatments: [r({ animalId: 'bella', condition: 'mastitis', given: at(addDays(TODAY, -1)), withdrawalDays: 4 }, at(TODAY))], vaccinations: [r({ vaccine: 'FMD', nextDue: addDays(TODAY, 3) }, at(addDays(TODAY, -100)))], income: [r({ source: 'milk', amount: 5000, at: at(TODAY) }, at(TODAY))], expenses: [r({ category: 'feed', amount: 2000, at: at(TODAY) }, at(TODAY))] } as never;
  const t = farmToday(d);
  assert.equal(t.milk?.litres, 120);
  assert.equal(t.milk?.day, 'today');
  assert.equal(t.withdrawal, 1);
  assert.deepEqual(t.vaccine, { name: 'FMD', days: 3 });
  assert.ok(contextFacts('milk', d)[0].includes('220'));
  assert.ok(contextFacts('money', d).some((l) => l.includes('3000')));
  assert.ok(contextFacts('health', d).some((l) => l.includes('mastitis')));
  assert.equal(cowSpark(d, 'nobody').length, 7);
});

import { groupChats, upsertChat, type SavedChat } from './aiChatStore.ts';

test('chat history: a pinned chat stays pinned when saved again, sits first and is never dropped', () => {
  const mk = (id: string, at: number, pinned?: boolean): SavedChat => ({ id, title: id, updatedAt: at, turns: [], pinned });
  let list: SavedChat[] = [mk('keep', 1, true)];
  for (let i = 2; i < 60; i++) list = upsertChat(list, mk(String(i), i));
  assert.ok(list.some((c) => c.id === 'keep'));
  list = upsertChat(list, mk('keep', 100));
  assert.equal(list.find((c) => c.id === 'keep')?.pinned, true);
  assert.equal(groupChats(list, Date.now())[0].label, 'Pinned');
});
