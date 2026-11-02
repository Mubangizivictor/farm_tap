// DAIRY-WRK-01: a typed card number at clock in/out needs a manager PIN;
// a card tap does not.
import 'package:farm_tap/core/money/data/fake/fake_money_repository.dart';
import 'package:farm_tap/core/people/data/fake/fake_staff_access_repository.dart';
import 'package:farm_tap/sectors/cattle/health/data/fake/fake_treatment_repository.dart';
import 'package:farm_tap/sectors/cattle/milk/data/fake/fake_milk_repository.dart';
import 'package:farm_tap/sectors/cattle/workers/data/fake/fake_workers_repository.dart';
import 'package:farm_tap/sectors/cattle/workers/presentation/pages/workers_pages.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_deps.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/shell_wrap.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  final clock = FixedClock();
  late FakeStaffAccessRepository staff;
  late FakeWorkersRepository repo;

  Future<void> open(WidgetTester tester, {bool simulate = false}) async {
    staff = FakeStaffAccessRepository();
    repo = FakeWorkersRepository(
      clock,
      staff,
      FakeMoneyRepository(clock),
      FakeMilkRepository(clock, FakeTreatmentRepository(clock)),
    );
    await pumpFarmTap(
      tester,
      inShell(
        AttendancePage(repo: repo, directory: staff, now: clock.now(), showSimulate: simulate),
        current: '/workers',
        parent: '/workers',
      ),
    );
    await _settle(tester);
  }

  Future<void> typeCard(WidgetTester tester, String card) async {
    await tester.tap(find.text('Clock in / out — tap card'));
    await _settle(tester);
    for (final d in card.split('')) {
      await tester.tap(find.text(d).last);
      await tester.pump();
    }
    await tester.tap(find.text('Use this card'));
    await _settle(tester);
  }

  Future<void> pin(WidgetTester tester, String digits) async {
    for (final d in digits.split('')) {
      await tester.tap(find.text(d).last);
      await tester.pump(const Duration(milliseconds: 50));
    }
    await _settle(tester);
  }

  Future<bool> ritaIn() async => (await repo.today()).data!.firstWhere((t) => t.staff.id == 'staff-kr').isIn;

  testWidgets('typed number: manager PIN first, wrong PIN keeps it locked', (tester) async {
    await open(tester);
    await typeCard(tester, '0168');
    expect(find.text('Manager PIN needed'), findsOneWidget);
    await pin(tester, '9999');
    expect(find.text('Manager PIN needed'), findsOneWidget);
    expect(await ritaIn(), isTrue);
    await pin(tester, '1234');
    expect(find.text('Manager PIN needed'), findsNothing);
    expect(await ritaIn(), isFalse);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('typed number: Cancel records nothing', (tester) async {
    await open(tester);
    await typeCard(tester, '0168');
    await tester.tap(find.text('Cancel'));
    await _settle(tester);
    expect(await ritaIn(), isTrue);
  });

  testWidgets('card tap: no manager PIN', (tester) async {
    await open(tester, simulate: true);
    await tester.tap(find.text('Simulate tap (debug)'));
    await _settle(tester);
    expect(find.text('Manager PIN needed'), findsNothing);
    expect(await ritaIn(), isFalse);
    await tester.pump(const Duration(seconds: 4));
  });
}
