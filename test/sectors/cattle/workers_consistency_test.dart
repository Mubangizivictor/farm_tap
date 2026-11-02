// Who is in, days worked, balances and wage expenses come from attendance
// and payment records only; Home and unlock read the same records.
import 'package:farm_tap/core/money/data/fake/fake_money_repository.dart';
import 'package:farm_tap/core/money/domain/money_models.dart';
import 'package:farm_tap/core/people/data/fake/fake_staff_access_repository.dart';
import 'package:farm_tap/sectors/cattle/breeding/data/fake/fake_breeding_repository.dart';
import 'package:farm_tap/sectors/cattle/feeding/data/fake/fake_feed_repository.dart';
import 'package:farm_tap/sectors/cattle/health/data/fake/fake_treatment_repository.dart';
import 'package:farm_tap/sectors/cattle/home/data/fake/fake_home_repository.dart';
import 'package:farm_tap/sectors/cattle/milk/data/fake/fake_milk_repository.dart';
import 'package:farm_tap/sectors/cattle/workers/data/fake/fake_workers_repository.dart';
import 'package:farm_tap/sectors/cattle/workers/domain/workers_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_deps.dart';

void main() {
  final clock = FixedClock();
  late FakeMoneyRepository money;
  late FakeStaffAccessRepository staff;
  late FakeWorkersRepository repo;

  setUp(() {
    money = FakeMoneyRepository(clock);
    staff = FakeStaffAccessRepository();
    repo = FakeWorkersRepository(clock, staff, money);
  });

  FakeHomeRepository home() {
    final t = FakeTreatmentRepository(clock);
    return FakeHomeRepository(
      clock,
      t,
      breeding: FakeBreedingRepository(clock, money),
      feed: FakeFeedRepository(clock, FakeMilkRepository(clock, t), money),
      workers: repo,
    );
  }

  test('K01/K04/Home: 4 of 5 on shift are in; the vet visits', () async {
    final today = (await repo.today()).data!;
    expect(today.length, 6);
    final shift = today.where((t) => t.onShift);
    expect(shift.length, 5);
    expect(shift.where((t) => t.isIn).map((t) => t.staff.name), [
      'Mugisha Tom',
      'Twinomujuni Amos',
      'Ahimbisibwe Joy',
      'Katusiime Rita',
    ]);
    final s = (await home().summary()).data!;
    expect((s.workersIn, s.workersTotal), (4, 5));
  });

  test('K02: days this month and balance owed come from the records', () async {
    expect((await repo.daysThisMonth('staff-ta')).data, 7);
    expect((await repo.daysThisMonth('staff-np')).data, 6);
    final amos = (await repo.wages()).data!.lines.firstWhere((l) => l.staff.id == 'staff-ta');
    expect((amos.wage, amos.advances, amos.toPay), (300000, 120000, 180000));
  });

  test('K06: totals are sums of the lines; advances are wage expenses', () async {
    final w = (await repo.wages()).data!;
    expect(w.wages, 1520000);
    expect(w.advances, 240000);
    final e = (await money.expenses(category: ExpenseCategory.wages)).data!;
    expect(e.fold<int>(0, (s, x) => s + x.amount), 240000);
  });

  test('K06 pay: records one wage expense and clears to-pay', () async {
    final p = (await repo.pay('staff-ta', kind: PayKind.wage, amount: 180000)).data!;
    final e = (await money.expenses(category: ExpenseCategory.wages)).data!;
    expect(e.where((x) => x.sourceId == p.id).single.amount, 180000);
    final amos = (await repo.wages()).data!.lines.firstWhere((l) => l.staff.id == 'staff-ta');
    expect(amos.toPay, 0);
  });

  test('K04 clock by typed card number: Peter has no card; Rita clocks out', () async {
    expect((await repo.clockByCard('0207')).data, isNull);
    final rita = (await repo.clockByCard('168')).data!;
    expect(rita.isIn, isFalse);
    expect(rita.record!.outAt, clock.now());
  });

  test('K03: assigned card works for unlock and attendance; taken card refused', () async {
    expect((await staff.nextBlankCard()).data, '0207');
    final peter = (await staff.assignCard('staff-np', '0207')).data!;
    expect(peter.cardNumber, '0207');
    expect((await staff.findByCard('0207')).data!.id, 'staff-np');
    expect((await staff.nextBlankCard()).data, '0208');
    expect((await repo.clockByCard('0207')).data!.isIn, isTrue);
    expect((await staff.assignCard('staff-np', '0142')).isSuccess, isFalse);
  });

  test('Home worker day: clock-in time and tasks come from workers', () async {
    final day = (await home().workerDay('staff-ta')).data!;
    expect(day.clockedInAt, DateTime(2026, 11, 7, 5, 45));
    expect(day.tasks.map((t) => (t.title, t.done)), [('Move heifers to paddock 3', true)]);
  });
}
