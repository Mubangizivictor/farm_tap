// The three-layer AI (decision 0028) on the phone: request classifier, extra
// built-in insights and the daily allowance. Same cases as
// webapp/src/lib/aiLayers.test.ts so the phone and the web agree.
import 'package:farm_tap/core/ai/ai_access.dart';
import 'package:farm_tap/core/ai/ai_core.dart';
import 'package:farm_tap/core/ai/ai_data.dart';
import 'package:farm_tap/core/ai/ai_insights.dart';
import 'package:farm_tap/core/ai/ai_quota.dart';
import 'package:farm_tap/core/ai/ai_route.dart';
import 'package:flutter_test/flutter_test.dart';

const _today = '2026-11-07';
var _n = 0;

Rec _milk(int back, double litres, [String session = 'morning']) => Rec(
  id: 'm${++_n}',
  createdAt: '${addDays(_today, -back)}T07:00:00',
  body: {'animalId': null, 'session': session, 'litres': litres},
);

FarmData _farm({List<Rec> milk = const [], List<Rec> expenses = const []}) => FarmData(
  now: '${_today}T09:00:00',
  animals: const [
    Rec(
      id: 'bella',
      body: {
        'name': 'Bella',
        'tagNumber': 'FT-001',
        'sex': 'female',
        'status': 'active',
        'dairyStatus': 'milking',
        'dateOfBirth': '2021-01-01',
      },
    ),
    Rec(
      id: 'zuri',
      body: {'name': 'Zuri', 'tagNumber': 'FT-002', 'sex': 'female', 'status': 'active', 'dairyStatus': 'milking'},
    ),
  ],
  milk: milk,
  expenses: expenses,
);

void main() {
  final cfg = defaultAiConfig;

  test('the table in the brief goes to the right layer', () {
    final d = _farm(
      milk: [_milk(1, 120), _milk(2, 118)],
      expenses: [
        const Rec(
          id: 'e1',
          createdAt: '${_today}T08:00:00',
          body: {'category': 'feed', 'amount': 50000, 'at': '${_today}T08:00:00'},
        ),
      ],
    );
    const want = {
      'How many cows do I have?': Layer.records,
      'How much milk did I produce today?': Layer.insight,
      'Which cows have reduced production?': Layer.insight,
      'When is my next vaccination?': Layer.insight,
      'How much did I spend this month?': Layer.insight,
      'Why is milk production declining?': Layer.ai,
      "Explain my farm's performance": Layer.ai,
      'Recommend improvements to my feeding system': Layer.ai,
    };
    for (final e in want.entries) {
      expect(classify(e.key, d, role: 'owner', cfg: cfg).layer, e.value, reason: e.key);
    }
  });

  test('files always go to the AI; empty and too-long questions never do', () {
    expect(classify('How much milk today?', _farm(), role: 'owner', cfg: cfg, files: 1).layer, Layer.ai);
    expect(classify('', _farm(), role: 'owner', cfg: cfg).reason, RouteReason.empty);
    expect(classify('x' * 50, _farm(), role: 'owner', cfg: cfg, maxChars: 20).reason, RouteReason.tooLong);
  });

  test('120 L to 85 L is a 29.2% decline with the brief’s wording', () {
    final d = _farm(milk: [_milk(1, 85), _milk(2, 120)]);
    final c = herdMilkChange(d)!;
    expect(c.changePct, -29.2);
    expect(herdChangeText(c), 'Milk production has declined by 29.2% compared with the previous recording.');
    final a = answerInternally('Has milk dropped?', d, role: 'owner', cfg: cfg);
    expect(
      a.text,
      'Milk production has declined by 29.2% compared with the previous recording. Review animal health, feeding records and recent management changes.',
    );
    expect(insightFindings(d).first.severity, Severity.high);
  });

  test('a morning-only today is not compared with a full day', () {
    final c = herdMilkChange(_farm(milk: [_milk(0, 40), _milk(1, 120), _milk(2, 118)]))!;
    expect(c.latest.day, addDays(_today, -1));
  });

  test('record completeness lists what is missing', () {
    final c = recordCompleteness(_farm());
    expect(c.pct, 50);
    expect(c.gaps.first.missing, ['date of birth']);
  });

  test('workers never get money answers', () {
    final a = answerInternally('How much did I spend this month?', _farm(), role: 'worker', cfg: cfg);
    expect(a.ok, isFalse);
  });

  test('config: defaults and the old photo switch', () {
    expect(assistantConfigFrom(null).dailyLimit, 10);
    expect(assistantConfigFrom(null).warnPct, 80);
    expect(assistantConfigFrom(null).timezone, 'Africa/Kampala');
    expect(assistantConfigFrom({'photo': {'enabled': true}}).enabled, isTrue);
    expect(assistantConfigFrom({'assistant': {'dailyLimit': 25, 'route': 'server'}}).dailyLimit, 25);
    expect(aiConfigFrom({'assistant': {'route': 'server'}}).assistant.route, 'server');
  });

  test('usage: 80% warning and 100% message', () {
    expect(usageView(3, 10, 80).remaining, 7);
    final w = usageView(8, 10, 80);
    expect(w.level, UsageLevel.warn);
    expect(
      usageWarning(w)!.message,
      "You're approaching your daily AI limit. You have 2 AI responses remaining today. Farm Tap's built-in intelligence and farm-management features remain unlimited.",
    );
    expect(usageView(10, 10, 80).level, UsageLevel.out);
    expect(usageWarning(usageView(10, 10, 80))!.title, 'Your daily AI allowance has been reached.');
  });

  test('server errors become kinds; usage is read from the details', () {
    expect(kindOfCallError('RESOURCE_EXHAUSTED', {'kind': 'limit'}), AiErrorKind.limit);
    expect(kindOfCallError('RESOURCE_EXHAUSTED', null), AiErrorKind.capacity);
    expect(kindOfCallError('DEADLINE_EXCEEDED', null), AiErrorKind.timeout);
    expect(kindOfCallError('INTERNAL', null), AiErrorKind.unavailable);
    final u = UsageView.fromJson({'used': 10, 'limit': 10, 'remaining': 0, 'level': 'out', 'resetAt': 0})!;
    expect(u.level, UsageLevel.out);
    expect(aiErrorText(AiErrorKind.limit, limit: 10).message, contains('all 10 AI-powered responses'));
  });
}
