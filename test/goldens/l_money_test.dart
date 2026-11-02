// Section L — money & reports (L01-L04), 8 goldens per screen + small screens.
// flutter test --update-goldens test/goldens/l_money_test.dart
import 'package:farm_tap/core/money/data/fake/fake_money_repository.dart';
import 'package:farm_tap/core/people/data/fake/fake_staff_access_repository.dart';
import 'package:farm_tap/sectors/cattle/breeding/data/fake/fake_breeding_repository.dart';
import 'package:farm_tap/sectors/cattle/feeding/data/fake/fake_feed_repository.dart';
import 'package:farm_tap/sectors/cattle/health/data/fake/fake_treatment_repository.dart';
import 'package:farm_tap/sectors/cattle/home/data/fake/fake_home_repository.dart';
import 'package:farm_tap/sectors/cattle/milk/data/fake/fake_milk_repository.dart';
import 'package:farm_tap/sectors/cattle/money/data/fake/fake_farm_money_repository.dart';
import 'package:farm_tap/sectors/cattle/money/presentation/pages/money_pages.dart';
import 'package:farm_tap/sectors/cattle/owner_reports/data/fake/fake_daily_report_repository.dart';
import 'package:farm_tap/sectors/cattle/workers/data/fake/fake_workers_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_deps.dart';
import '../helpers/screen_golden.dart';
import '../helpers/shell_wrap.dart';

void main() {
  final clock = FixedClock();
  late FakeDailyReportRepository daily;

  /// The same wiring as the app: every feature writes into one money store.
  FakeFarmMoneyRepository farm() {
    final money = FakeMoneyRepository(clock);
    final t = FakeTreatmentRepository(clock);
    final milk = FakeMilkRepository(clock, t);
    final feed = FakeFeedRepository(clock, milk, money);
    final breeding = FakeBreedingRepository(clock, money);
    final workers = FakeWorkersRepository(clock, FakeStaffAccessRepository(), money, milk);
    final f = FakeFarmMoneyRepository(clock, money, milk);
    daily = FakeDailyReportRepository(
      clock: clock,
      farmName: () => 'Rwemera Dairy Farm',
      home: FakeHomeRepository(clock, t, breeding: breeding, feed: feed, workers: workers),
      milk: milk,
      treatments: t,
      feed: feed,
      money: f,
    );
    return f;
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  screenGoldens(
    'L01_money_overview',
    (_) => inShell(MoneyPage(repo: farm(), onAddExpense: () async {}), current: '/money'),
    act: (tester, _) => settle(tester),
  );

  screenGoldens(
    'L02_add_expense',
    (_) => inShell(
      AddExpensePage(repo: farm(), onSaved: (_) {}, initialAmount: '60,000', initialNote: 'Vet visit — Kasheshe'),
      current: '/money',
      parent: '/money',
    ),
    act: (tester, _) => settle(tester),
  );

  screenGoldens(
    'L03_reports',
    (_) => inShell(
      ReportsPage(money: farm(), farmName: 'Rwemera Dairy Farm', onDaily: () {}),
      current: '/reports',
    ),
    act: (tester, _) => settle(tester),
  );

  screenGoldens(
    'L04_whatsapp_report_preview',
    (_) {
      farm();
      return inShell(DailyReportPage(repo: daily), current: '/reports', parent: '/reports');
    },
    act: (tester, _) => settle(tester),
  );
}
