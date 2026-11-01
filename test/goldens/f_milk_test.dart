// Section F — milk (F01-F10), 8 goldens per screen + small screens.
// flutter test --update-goldens test/goldens/f_milk_test.dart
import 'package:farm_tap/sectors/cattle/health/data/fake/fake_treatment_repository.dart';
import 'package:farm_tap/sectors/cattle/milk/data/fake/fake_milk_repository.dart';
import 'package:farm_tap/sectors/cattle/milk/presentation/pages/milk_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_deps.dart';
import '../helpers/screen_golden.dart';
import '../helpers/shell_wrap.dart';

void main() {
  final clock = FixedClock();
  final now = clock.now();
  FakeMilkRepository repo() => FakeMilkRepository(clock, FakeTreatmentRepository(clock));

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> keys(WidgetTester tester, String digits) async {
    for (final d in digits.split('')) {
      await tester.tap(find.text(d).last);
      await tester.pump();
    }
    // Let the key ripples fade.
    await tester.pump(const Duration(seconds: 1));
  }

  Widget keypad() => inShell(
    MilkKeypadPage(repo: repo(), cowId: 'animal-FT-014', recorderName: 'Amos', onDone: (_, _) {}, now: now),
    current: '/milk',
    parent: '/milk/record',
  );

  Widget pick() => inShell(
    PickCowPage(repo: repo(), onCow: (_, {required notForSale}) {}, now: now),
    current: '/milk',
    parent: '/milk',
  );

  screenGoldens(
    'F01_milk_today',
    (_) => inShell(
      MilkTodayPage(repo: repo(), onRecord: () {}, onTool: (_) {}, today: now),
      current: '/milk',
    ),
  );

  screenGoldens('F02_milk_pick_cow', (_) => pick());

  screenGoldens('F03_milk_keypad', (_) => keypad(), act: (tester, _) => keys(tester, '9.5'));

  screenGoldens(
    'F04_milk_read_back',
    (_) => keypad(),
    act: (tester, _) async {
      await keys(tester, '9.5');
      await tester.tap(find.text('Next'));
      await settle(tester);
    },
  );

  screenGoldens(
    'F05_milk_saved',
    (_) => keypad(),
    act: (tester, _) async {
      await keys(tester, '9.5');
      await tester.tap(find.text('Next'));
      await settle(tester);
      await tester.tap(find.text('Yes, save'));
      await settle(tester);
    },
  );

  screenGoldens(
    'F06_treated_cow_warning',
    (_) => pick(),
    act: (tester, _) async {
      await tester.tap(find.text('Kasheshe'));
      await settle(tester);
    },
  );

  screenGoldens(
    'F07_milk_herd_total',
    (_) => inShell(
      QuickTotalPage(repo: repo(), onSaved: () {}, now: DateTime(2026, 11, 7, 18)),
      current: '/milk',
      parent: '/milk',
    ),
    act: (tester, _) => keys(tester, '143'),
  );

  screenGoldens(
    'F08_milk_use_split',
    (_) => inShell(
      MilkUsePage(repo: repo(), onSaved: () {}),
      current: '/milk',
      parent: '/milk',
    ),
  );

  screenGoldens(
    'F09_milk_sales',
    (_) => inShell(
      MilkSalesPage(repo: repo()),
      current: '/milk',
      parent: '/milk',
    ),
  );

  screenGoldens(
    'F10_milk_trends',
    (_) => inShell(
      MilkTrendsPage(repo: repo(), today: now),
      current: '/milk',
      parent: '/milk',
    ),
  );
}
