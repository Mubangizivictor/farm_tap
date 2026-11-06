// The chat helpers added with Google Search and the action buttons. Same cases
// as webapp/src/lib/aiChat.test.ts so the phone and the web agree.
import 'package:farm_tap/core/ai/ai_chat.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('history starts with the farmer and never repeats a side', () {
    final h = chatHistory([
      (fromUser: false, text: 'Hello'),
      (fromUser: true, text: 'a'),
      (fromUser: true, text: 'b'),
      (fromUser: false, text: ''),
      (fromUser: false, text: 'c'),
    ]);
    expect(h, [(fromUser: true, text: 'a\nb'), (fromUser: false, text: 'c')]);
    expect(chatHistory([(fromUser: false, text: 'x')]), isEmpty);
  });

  test('chat title is short', () {
    expect(chatTitle('  '), 'New chat');
    expect(chatTitle('x' * 80).length, 46);
  });

  test('only https sources are kept, once each', () {
    final s = cleanSources([
      (title: null, uri: 'http://a.com'),
      (title: '', uri: 'https://www.b.com/x'),
      (title: null, uri: 'https://www.b.com/x'),
      (title: 'C', uri: 'https://c.com'),
    ]);
    expect([for (final x in s) '${x.title}|${x.uri}'], ['b.com|https://www.b.com/x', 'C|https://c.com']);
  });

  test('actions follow the topic', () {
    final a = chatActions(
      question: 'Bella gives sour milk',
      answer: 'It may be mastitis.',
      health: true,
      callVet: 'soon',
      animal: (id: 'bella', name: 'Bella'),
    );
    expect([for (final x in a) x.href], ['/herd/?animal=bella', '/ai/vet/?animal=bella', '/contacts/', '/milk/']);
    final m = chatActions(
      question: 'How much milk did I get this week?',
      answer: '90 litres.',
      health: false,
      callVet: null,
      animal: null,
    );
    expect([for (final x in m) x.href], ['/milk/']);
    expect(chatActions(question: 'hello', answer: 'Hi', health: false, callVet: null, animal: null), isEmpty);
  });

  test('follow-ups depend on the topic', () {
    expect(chatFollowUps(question: 'cow has fever', answer: '', health: true)[1], 'When must I call the vet?');
    expect(chatFollowUps(question: 'milk', answer: '', health: false).first, 'Why would milk go down?');
    expect(chatFollowUps(question: 'hi', answer: '', health: false), hasLength(3));
  });

  test('Google errors become plain failures', () {
    expect(chatFailureOf('[403] Firebase AI Logic API has not been used in project'), ChatFailure.setup);
    expect(chatFailureOf('[403] App Check token is invalid'), ChatFailure.appCheck);
    expect(chatFailureOf('[404] models/gemini-2.5-flash is not found'), ChatFailure.model);
    expect(chatFailureOf('[429] Resource has been exhausted (quota)'), ChatFailure.busy);
    expect(chatFailureOf('TypeError: Failed to fetch'), ChatFailure.network);
    expect(chatFailureOf('weird'), ChatFailure.unreadable);
  });

  test('streaming text is cut at a finished sentence', () {
    expect(partialChatText('Keep her clean. Give 20 ml of oxytetracycline. Watch for'), 'Keep her clean.');
    expect(partialChatText('Half a sen'), '');
    expect(filterChatText('Keep her clean.\nGive 20 ml of oxytetracycline.').removed, 1);
  });

  test('photos start with the stronger model', () {
    expect(chatModels('gemini-3.5-flash-lite', hasMedia: true), ['gemini-3.8-flash', 'gemini-3.5-flash-lite']);
    expect(chatModels('gemini-3.5-flash-lite', hasMedia: false), ['gemini-3.5-flash-lite', 'gemini-3.8-flash']);
  });

  test('language and search lines reach the prompt', () {
    expect(languageLine('auto'), isNull);
    expect(languageLine('lg'), contains('Luganda'));
    final p = buildChatPrompt(message: 'hello there friend', facts: [], fileKinds: [], search: true, language: 'sw');
    expect(p, contains('SEARCH GOOGLE FIRST'));
    expect(p, contains('Kiswahili'));
    expect(needsSearch('How do I stop mastitis?', calculated: false), isTrue);
    expect(needsSearch('milk this week', calculated: true), isFalse);
  });

  test('triage card, vet questions and message', () {
    final lsd = readChatReply('This could be lumpy skin disease. She cannot get up.', 'lumps on skin');
    final t = triageOf(lsd)!;
    expect(t.level, 'now');
    expect(t.report, isTrue);
    expect(t.doNow.first, startsWith('Call your vet now'));
    expect(triageOf(readChatReply('Dry hay is fine.', 'what feed')), isNull);
    expect(cleanTemp('40,5'), '40.5');
    expect(cleanTemp('140'), isNull);
    expect(caseText({'since': 'Today', 'temp': '40.5'}), 'Since: Today. Temperature: 40.5 °C');
    final m = vetSummary(
      farm: 'Mbarara farm',
      animal: (
        label: 'Bella (FT-001)',
        facts: ['This question is about one animal on the farm.', 'Calved 40 days ago.'],
      ),
      question: 'Bella gives sour milk',
      answer: 'Her udder is hot. Check the milk. Call your vet today.',
      answers: {'temp': '40.5'},
      triage: triageOf(readChatReply('Her udder is hot.', 'sour milk'), question: 'sour milk'),
      hasPhoto: true,
      day: '2026-11-06',
    );
    expect(m, contains('Animal: Bella (FT-001)'));
    expect(m, contains('Temperature: 40.5 °C'));
    expect(m, isNot(contains('This question is about')));
  });

  test('WhatsApp link and one-tap buttons', () {
    expect(whatsappLink('0772 123 456', 'Hi'), 'https://wa.me/256772123456?text=Hi');
    expect(whatsappLink('12', 'x'), isNull);
    expect(whatsappLink(null, 'x'), 'https://wa.me/?text=x');
    expect(nextDay('2026-11-30'), '2026-12-01');
    final tr = triageOf(readChatReply('Her udder is hot.', 'sour milk'));
    final a = chatDoActions(animal: (id: 'b1', name: 'Bella'), triage: tr, day: '2026-11-06');
    expect(
      [for (final x in a) x.href],
      ['/health/?new=1&animal=b1', '/tasks/?new=1&title=Recheck%20Bella&due=2026-11-07'],
    );
  });
}
