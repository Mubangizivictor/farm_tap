import 'package:farm_tap/core/people/data/fake/fake_staff_access_repository.dart';
import 'package:farm_tap/core/people/data/pin_security.dart';
import 'package:farm_tap/core/people/domain/staff_member.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const hasher = PinHasher(iterations: 1000);

  test('PIN is stored hashed and salted, and checks offline', () {
    final a = hasher.hash('1234');
    final b = hasher.hash('1234');
    expect(a, isNot(contains(r'1234$')));
    expect(a, startsWith(r'pbkdf2-sha256$1000$'));
    expect(a, isNot(b)); // different salt
    expect(hasher.verify('1234', a), isTrue);
    expect(hasher.verify('4321', a), isFalse);
    expect(hasher.verify('1234', 'garbage'), isFalse);
  });

  test('PBKDF2-HMAC-SHA256 matches the RFC 7914 test vector', () {
    // RFC 7914 §11: P="passwd", S="salt", c=1 (first 32 bytes).
    const stored = r'pbkdf2-sha256$1$c2FsdA==$VawEblbjCJ/sFpHCJUS2BflBhSFt3gRl5oudV8INrLw=';
    expect(hasher.verify('passwd', stored), isTrue);
  });

  test('5 wrong PINs lock that person for 5 minutes, then it opens again', () async {
    var now = DateTime(2026, 11, 7, 6, 52);
    final repo = FakeStaffAccessRepository(now: () => now);
    for (var i = 0; i < 4; i++) {
      expect((await repo.verifyPin('staff-mt', '0000')).data, isA<PinRejected>());
    }
    expect((await repo.verifyPin('staff-mt', '0000')).data, isA<PinLocked>());
    expect((await repo.verifyPin('staff-mt', FakeStaffAccessRepository.pin)).data, isA<PinLocked>());
    now = now.add(const Duration(minutes: 5, seconds: 1));
    expect((await repo.verifyPin('staff-mt', FakeStaffAccessRepository.pin)).data, isA<PinAccepted>());
  });
}
