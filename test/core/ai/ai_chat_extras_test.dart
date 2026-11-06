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
}
