// Section H — health (H01-H06), 8 goldens per screen + small screens.
// flutter test --update-goldens test/goldens/h_health_test.dart
import 'package:farm_tap/sectors/cattle/health/data/fake/fake_treatment_repository.dart';
import 'package:farm_tap/sectors/cattle/health/domain/health_models.dart';
import 'package:farm_tap/sectors/cattle/health/presentation/pages/health_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_deps.dart';
import '../helpers/screen_golden.dart';
import '../helpers/shell_wrap.dart';

void main() {
  final clock = FixedClock();
  final now = clock.now();
  FakeTreatmentRepository repo() => FakeTreatmentRepository(clock);

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  Widget treatment() => inShell(
    AddTreatmentPage(
      repo: repo(),
      animalId: 'animal-FT-022',
      onDone: (_) {},
      onScan: () {},
      now: now,
      initialCondition: Condition.mastitis,
    ),
    current: '/health',
    parent: '/health',
  );

  screenGoldens(
    'H01_health_home',
    (_) => inShell(HealthHomePage(repo: repo(), onOpen: (_) {}, now: now), current: '/health'),
  );

  screenGoldens('H02_add_treatment', (_) => treatment(), act: (tester, _) => settle(tester));

  screenGoldens(
    'H03_treatment_saved',
    (_) => treatment(),
    act: (tester, _) async {
      await settle(tester);
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await settle(tester);
      await tester.tap(find.text('Yes, save'));
      await settle(tester);
      await tester.pump(const Duration(seconds: 4));
    },
  );

  screenGoldens(
    'H04_drug_stock',
    (_) => inShell(DrugStockPage(repo: repo()), current: '/health', parent: '/health'),
  );

  screenGoldens(
    'H05_health_schedule',
    (_) => inShell(HealthCalendarPage(repo: repo(), now: now), current: '/health', parent: '/health'),
  );

  screenGoldens(
    'H06_withdrawal_list',
    (_) => inShell(
      WithdrawalListPage(repo: repo(), onAnimal: (_) {}, now: now),
      current: '/health',
      parent: '/health',
    ),
  );
}
