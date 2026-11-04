import 'package:farm_tap/app/router/app_router.dart';
import 'package:farm_tap/core/onboarding/domain/farm_setup.dart';
import 'package:farm_tap/core/people/data/fake/fake_staff_access_repository.dart';
import 'package:farm_tap/core/people/domain/staff_member.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the worker added in onboarding is saved with their job, pay, PIN and card', () async {
    final staff = FakeStaffAccessRepository(withSamples: false);
    await saveFirstWorker(
      staff,
      const FirstWorker(
        name: 'Kemigisha Ruth',
        role: StaffRole.clerk,
        title: "Farmer's daughter",
        phone: '772 000 111',
        monthlyWage: 250000,
        pin: '4821',
        cardNumber: '0301',
      ),
    );
    final ruth = (await staff.staff()).data!.single;
    expect(ruth.title, "Farmer's daughter");
    expect(ruth.role, StaffRole.clerk);
    expect(ruth.monthlyWage, 250000);
    expect(ruth.cardNumber, '0301');
    expect((await staff.findByCard('0301')).data?.id, ruth.id);
    expect((await staff.verifyPin(ruth.id, '4821')).data, isA<PinAccepted>());
  });
}
