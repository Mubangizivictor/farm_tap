// Section C — staff unlock (C01-C05), 8 goldens per screen + small screens.
// flutter test --update-goldens test/goldens/c_staff_test.dart
import 'package:farm_tap/core/people/data/fake/fake_staff_access_repository.dart';
import 'package:farm_tap/core/people/presentation/pages/unlock_pages.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/screen_golden.dart';

Future<void> _keys(WidgetTester tester, String digits) async {
  for (final d in digits.split('')) {
    await tester.tap(find.text(d).last);
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  final amos = FakeStaffAccessRepository.staff[1];

  screenGoldens(
    'C01_staff_tap_card',
    (_) => TapCardPage(
      farmName: 'Rwemera Dairy Farm',
      access: FakeStaffAccessRepository(),
      onCard: (_) {},
      onTypeNumber: () {},
      showSimulate: false,
    ),
  );

  screenGoldens(
    'C02_staff_card_number',
    (_) => CardNumberPage(access: FakeStaffAccessRepository(), onFound: (_) {}),
    act: (tester, _) => _keys(tester, '0142'),
  );

  screenGoldens(
    'C03_staff_pin',
    (_) => StaffPinPage(staff: amos, access: FakeStaffAccessRepository(), onUnlocked: (_) {}),
    act: (tester, _) => _keys(tester, '12'),
  );

  screenGoldens(
    'C04_staff_pin_wrong',
    (_) => StaffPinPage(staff: amos, access: FakeStaffAccessRepository(), onUnlocked: (_) {}),
    act: (tester, _) async {
      for (var i = 0; i < 3; i++) {
        await _keys(tester, '1111');
      }
    },
  );

  screenGoldens(
    'C05_nfc_unavailable',
    (_) => TapCardPage(
      farmName: 'Rwemera Dairy Farm',
      access: FakeStaffAccessRepository(nfc: false),
      onCard: (_) {},
      onTypeNumber: () {},
      showSimulate: false,
    ),
  );
}
