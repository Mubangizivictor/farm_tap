// Section J — breeding (J01-J03), 8 goldens per screen + small screens.
// flutter test --update-goldens test/goldens/j_breeding_test.dart
import 'package:farm_tap/core/money/data/fake/fake_money_repository.dart';
import 'package:farm_tap/sectors/cattle/breeding/data/fake/fake_breeding_repository.dart';
import 'package:farm_tap/sectors/cattle/breeding/presentation/pages/breeding_pages.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_deps.dart';
import '../helpers/screen_golden.dart';
import '../helpers/shell_wrap.dart';

void main() {
  final clock = FixedClock();
  final now = clock.now();
  FakeBreedingRepository repo() => FakeBreedingRepository(clock, FakeMoneyRepository(clock));

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  screenGoldens(
    'J01_breeding_calendar',
    (_) => inShell(BreedingPage(repo: repo(), onAnimal: (_) {}, now: now), current: '/breeding'),
  );

  screenGoldens(
    'J02_record_service_sheet',
    (_) => inShell(
      BreedingPage(repo: repo(), onAnimal: (_) {}, now: now, start: BreedingStart.serve),
      current: '/breeding',
    ),
    act: (tester, _) => settle(tester),
  );

  screenGoldens(
    'J03_pregnancy_confirmed',
    (_) => inShell(
      BreedingPage(repo: repo(), onAnimal: (_) {}, now: now, start: BreedingStart.confirmed),
      current: '/breeding',
    ),
    act: (tester, _) async {
      await settle(tester);
      await tester.pump(const Duration(seconds: 1));
    },
  );
}
