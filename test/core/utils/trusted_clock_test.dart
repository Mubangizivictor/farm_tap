import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/core/utils/trusted_clock.dart';
import 'package:flutter_test/flutter_test.dart';

class _PhoneClock extends Clock {
  DateTime at = DateTime(2026, 11, 15, 9);
  @override
  DateTime now() => at;
}

void main() {
  test('turning the phone date back does not give back trial days', () {
    final phone = _PhoneClock();
    DateTime? saved;
    final trusted = TrustedClock(phone, save: (t) => saved = t);
    expect(trusted.today(), DateTime(2026, 11, 15));
    phone.at = DateTime(2026, 11, 3, 9); // user sets the date back
    expect(trusted.today(), DateTime(2026, 11, 15));
    expect(saved, DateTime(2026, 11, 15, 9));
  });

  test('the latest time is remembered across restarts', () {
    final phone = _PhoneClock()..at = DateTime(2026, 11, 3);
    final trusted = TrustedClock(phone, lastSeen: DateTime(2026, 11, 15, 9));
    expect(trusted.today(), DateTime(2026, 11, 15));
  });

  test('normal time moves forward as usual', () {
    final phone = _PhoneClock();
    final trusted = TrustedClock(phone, lastSeen: DateTime(2026, 11, 14));
    expect(trusted.now(), phone.at);
    phone.at = phone.at.add(const Duration(hours: 3));
    expect(trusted.now(), phone.at);
  });
}
