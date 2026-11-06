// Section K — workers (K01-K06), 8 goldens per screen + small screens.
// flutter test --update-goldens test/goldens/k_workers_test.dart
import 'package:farm_tap/core/money/data/fake/fake_money_repository.dart';
import 'package:farm_tap/core/people/data/fake/fake_staff_access_repository.dart';
import 'package:farm_tap/sectors/cattle/health/data/fake/fake_treatment_repository.dart';
import 'package:farm_tap/sectors/cattle/milk/data/fake/fake_milk_repository.dart';
import 'package:farm_tap/sectors/cattle/workers/data/fake/fake_workers_repository.dart';
import 'package:farm_tap/sectors/cattle/workers/presentation/pages/workers_pages.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_deps.dart';
import '../helpers/screen_golden.dart';
import '../helpers/shell_wrap.dart';

void main() {
  final clock = FixedClock();
  final now = clock.now();
  late FakeStaffAccessRepository staff;
  FakeWorkersRepository repo() {
    staff = FakeStaffAccessRepository();
    return FakeWorkersRepository(
      clock,
      staff,
      FakeMoneyRepository(clock),
      FakeMilkRepository(clock, FakeTreatmentRepository(clock)),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  screenGoldens(
    'K01_staff_list',
    (_) => inShell(
      WorkersPage(repo: repo(), onStaff: (_) {}, onOpen: (_) {}, onAdd: () async {}),
      current: '/workers',
    ),
    act: (tester, _) => settle(tester),
  );

  screenGoldens('K02_staff_detail', (_) {
    final r = repo();
    return inShell(
      StaffDetailPage(repo: r, directory: staff, staffId: 'staff-ta', onAssignCard: () async {}, onEdit: () async {}),
      current: '/workers',
      parent: '/workers',
    );
  }, act: (tester, _) => settle(tester));

  screenGoldens('K03_assign_card', (_) {
    repo();
    return inShell(
      AssignCardPage(directory: staff, staffId: 'staff-np', farmName: 'Rwemera Dairy Farm', onDone: () {}),
      current: '/workers',
      parent: '/workers',
    );
  }, act: (tester, _) => settle(tester));

  screenGoldens('K04_attendance', (_) {
    final r = repo();
    return inShell(
      AttendancePage(repo: r, directory: staff, now: now),
      current: '/workers',
      parent: '/workers',
    );
  }, act: (tester, _) => settle(tester));

  screenGoldens('K05_tasks', (_) {
    final r = repo();
    return inShell(
      TasksPage(repo: r, directory: staff, now: now),
      current: '/workers',
      parent: '/workers',
    );
  }, act: (tester, _) => settle(tester));

  screenGoldens(
    'K06_wages',
    (_) => inShell(
      WagesPage(repo: repo()),
      current: '/workers',
      parent: '/workers',
    ),
    act: (tester, _) => settle(tester),
  );
}
