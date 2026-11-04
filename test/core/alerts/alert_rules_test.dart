import 'package:farm_tap/core/alerts/alert_rules.dart';
import 'package:flutter_test/flutter_test.dart';

/// The same cases as functions/src/launch.test.ts: the phone and the
/// server must give the same reminders with the same ids.
void main() {
  AlertInput base({
    List<AlertRec> duties = const [],
    List<AlertRec> absences = const [],
    List<AlertRec> vaccinations = const [],
    List<AlertRec> breeding = const [],
    String? trialEndsAt,
    String? paidUntil,
    AlertSettings settings = const AlertSettings(),
  }) => AlertInput(
    today: '2026-11-09', // a Monday
    duties: duties,
    absences: absences,
    vaccinations: vaccinations,
    breeding: breeding,
    animals: const [
      AlertRec('c1', {'name': 'Kasheshe', 'tagNumber': 'RW-014', 'status': 'active'}),
    ],
    staffNames: const {'s1': 'Akello', 's2': 'Byaruhanga'},
    trialEndsAt: trialEndsAt,
    paidUntil: paidUntil,
    settings: settings,
  );

  test('duties: the person on, or the stand-in when they are away', () {
    const duties = [
      AlertRec('d1', {
        'activity': 'milking',
        'staffId': 's1',
        'standInId': 's2',
        'days': [1],
        'shift': 'morning',
      }),
    ];
    final on = alertsFor(base(duties: duties));
    expect(on, hasLength(1));
    expect(on.first.id, 'duty-2026-11-09-d1');
    expect(on.first.staffIds, ['s1']);
    final away = alertsFor(
      base(
        duties: duties,
        absences: const [
          AlertRec('a', {'staffId': 's1', 'from': '2026-11-08', 'to': '2026-11-10'}),
        ],
      ),
    );
    expect(away.first.staffIds, ['s2']);
    expect(away.first.body, contains('stand in for Akello'));
    expect(
      alertsFor(
        base(
          duties: const [
            AlertRec('d2', {
              'activity': 'feeding',
              'staffId': 's1',
              'days': [2],
            }),
          ],
        ),
      ),
      isEmpty,
    );
    expect(alertsFor(base(duties: duties, settings: const AlertSettings(duties: false))), isEmpty);
  });

  test('vaccinations due tomorrow, today, overdue; not after a later dose', () {
    AlertRec v(String id, String nextDue) =>
        AlertRec(id, {'vaccine': 'Lumpy skin', 'animalIds': <String>[], 'nextDue': nextDue});
    expect(alertsFor(base(vaccinations: [v('v1', '2026-11-10')])).first.title, contains('tomorrow'));
    expect(alertsFor(base(vaccinations: [v('v1', '2026-11-09')])).first.title, contains('today'));
    expect(alertsFor(base(vaccinations: [v('v1', '2026-11-05')])).first.title, contains('overdue'));
    expect(alertsFor(base(vaccinations: [v('v1', '2026-11-20')])), isEmpty);
    expect(alertsFor(base(vaccinations: [v('v1', '2026-11-09'), v('v2', '2027-05-09')])), isEmpty);
  });

  test('calving 7 days, 1 day and the day; pregnancy check at 60 days; heat every 21', () {
    AlertRec served(String at) => AlertRec('b1', {'type': 'ai', 'kind': 'ai', 'animalId': 'c1', 'at': at});
    expect(alertsFor(base(breeding: [served('2026-02-06T08:00:00')])).first.title, contains('calves in 7 days'));
    expect(alertsFor(base(breeding: [served('2026-01-30T08:00:00')])).first.title, contains('due to calve today'));
    expect(alertsFor(base(breeding: [served('2026-02-01T08:00:00')])), isEmpty);
    expect(alertsFor(base(breeding: [served('2026-09-10T08:00:00')])).first.kind, 'pregnancyCheck');
    final heat = alertsFor(
      base(
        breeding: const [
          AlertRec('h', {'type': 'service', 'kind': 'heat', 'animalId': 'c1', 'at': '2026-10-19'}),
        ],
      ),
    );
    expect(heat.first.kind, 'heat');
    expect(heat.first.id, 'heat-2026-11-09-c1');
  });

  test('trial and plan ending reminders, 3 days and 1 day before', () {
    expect(alertsFor(base(trialEndsAt: '2026-11-12T00:00:00Z')).first.title, contains('Free trial ends in 3 days'));
    expect(alertsFor(base(trialEndsAt: '2026-11-10T00:00:00Z')).first.title, contains('1 day'));
    expect(alertsFor(base(trialEndsAt: '2026-11-11T00:00:00Z')), isEmpty);
    expect(alertsFor(base(paidUntil: '2026-11-12T00:00:00Z', trialEndsAt: '2026-10-01')).first.kind, 'plan');
  });

  test('alert settings fall back to defaults', () {
    final d = AlertSettings.fromBody(null);
    expect(d.hour, 6);
    expect(d.whatsapp, isTrue);
    expect(d.sms, isFalse);
    expect(AlertSettings.fromBody({'hour': 30, 'sms': true}).hour, 6);
    expect(AlertSettings.fromBody({'sms': true}).sms, isTrue);
  });

  test('message text names the farm and stays short', () {
    const a = FarmAlert(id: 'x', kind: 'duty', title: 'Milking today', body: 'Morning');
    expect(a.text('Rwemera'), 'FarmTap Rwemera: Milking today. Morning');
  });
}
