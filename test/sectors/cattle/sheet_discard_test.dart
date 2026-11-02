// Dirty form sheets (I03, H04, H05) ask "Discard changes?" before closing
// by drag or scrim; untouched sheets close straight away.
import 'package:farm_tap/core/money/data/fake/fake_money_repository.dart';
import 'package:farm_tap/sectors/cattle/feeding/data/fake/fake_feed_repository.dart';
import 'package:farm_tap/sectors/cattle/feeding/presentation/pages/feeding_pages.dart';
import 'package:farm_tap/sectors/cattle/health/data/fake/fake_treatment_repository.dart';
import 'package:farm_tap/sectors/cattle/health/presentation/pages/health_pages.dart';
import 'package:farm_tap/sectors/cattle/milk/data/fake/fake_milk_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_deps.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/shell_wrap.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  final clock = FixedClock();

  Future<void> check(
    WidgetTester tester, {
    required Widget page,
    required Future<void> Function() open,
    required String sheetText,
    required Future<void> Function() edit,
  }) async {
    await pumpFarmTap(tester, page);
    await _settle(tester);

    // Untouched: drag closes without asking.
    await open();
    await tester.fling(find.text(sheetText), const Offset(0, 600), 2000);
    await _settle(tester);
    expect(find.text(sheetText), findsNothing);
    expect(find.text('Discard changes?'), findsNothing);

    // Dirty: drag asks, Keep editing keeps it.
    await open();
    await edit();
    await tester.fling(find.text(sheetText), const Offset(0, 600), 2000);
    await _settle(tester);
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await _settle(tester);
    expect(find.text(sheetText), findsOneWidget);

    // Dirty: scrim asks too; Discard closes.
    await tester.tapAt(const Offset(20, 20));
    await _settle(tester);
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await _settle(tester);
    expect(find.text(sheetText), findsNothing);
    await tester.pump(const Duration(seconds: 4));
  }

  testWidgets('I03 buy feed', (tester) async {
    final repo = FakeFeedRepository(
      clock,
      FakeMilkRepository(clock, FakeTreatmentRepository(clock)),
      FakeMoneyRepository(clock),
    );
    await check(
      tester,
      page: inShell(
        FeedStockPage(repo: repo, onRecord: () {}),
        current: '/feeding',
      ),
      open: () async {
        await tester.tap(find.byTooltip('Buy feed'));
        await _settle(tester);
      },
      sheetText: 'Save purchase',
      edit: () async {
        await tester.enterText(find.widgetWithText(TextField, '10'), '12');
        await _settle(tester);
      },
    );
  });

  testWidgets('H04 add drug', (tester) async {
    await check(
      tester,
      page: inShell(
        DrugStockPage(repo: FakeTreatmentRepository(clock)),
        current: '/health',
        parent: '/health',
      ),
      open: () async {
        await tester.tap(find.byTooltip('Add drug'));
        await _settle(tester);
      },
      sheetText: 'Save drug',
      edit: () async {
        await tester.enterText(find.byType(TextField).first, 'Ivermectin');
        await _settle(tester);
      },
    );
  });

  testWidgets('H05 add task', (tester) async {
    await check(
      tester,
      page: inShell(
        HealthCalendarPage(repo: FakeTreatmentRepository(clock), now: clock.now()),
        current: '/health',
        parent: '/health',
      ),
      open: () async {
        await tester.tap(find.text('Add to calendar').first);
        await _settle(tester);
      },
      sheetText: 'What needs doing?',
      edit: () async {
        await tester.enterText(find.byType(TextField).first, 'Spray calves');
        await _settle(tester);
      },
    );
  });
}
