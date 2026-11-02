// L01/L03 agree with every other screen: expenses only from core/money,
// income only from milk sales, litres from milk records; feed per litre is
// I01's figure.
import 'package:farm_tap/core/money/data/fake/fake_money_repository.dart';
import 'package:farm_tap/core/money/domain/money_models.dart';
import 'package:farm_tap/core/people/data/fake/fake_staff_access_repository.dart';
import 'package:farm_tap/sectors/cattle/breeding/data/fake/fake_breeding_repository.dart';
import 'package:farm_tap/sectors/cattle/feeding/data/fake/fake_feed_repository.dart';
import 'package:farm_tap/sectors/cattle/health/data/fake/fake_treatment_repository.dart';
import 'package:farm_tap/sectors/cattle/milk/data/fake/fake_milk_repository.dart';
import 'package:farm_tap/sectors/cattle/milk/domain/milk_models.dart';
import 'package:farm_tap/sectors/cattle/money/data/fake/fake_farm_money_repository.dart';
import 'package:farm_tap/sectors/cattle/money/domain/farm_money_models.dart';
import 'package:farm_tap/sectors/cattle/workers/data/fake/fake_workers_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_deps.dart';

void main() {
  final clock = FixedClock();
  final monthStart = DateTime(2026, 11);
  late FakeMoneyRepository money;
  late FakeMilkRepository milk;
  late FakeFeedRepository feed;
  late FakeFarmMoneyRepository farm;

  setUp(() async {
    money = FakeMoneyRepository(clock);
    final t = FakeTreatmentRepository(clock);
    milk = FakeMilkRepository(clock, t);
    feed = FakeFeedRepository(clock, milk, money);
    FakeBreedingRepository(clock, money);
    FakeWorkersRepository(clock, FakeStaffAccessRepository(), money, milk);
    farm = FakeFarmMoneyRepository(clock, money, milk);
    await Future<void>.delayed(Duration.zero);
  });

  test('litres: F month total = sum of milk records = L01 litres', () async {
    final records = (await milk.records(from: monthStart)).data!;
    final sum = records.fold<double>(0, (s, r) => s + r.litres);
    final f = (await milk.trend(TrendRange.month)).data!.total;
    final m = (await farm.month()).data!;
    expect(f, closeTo(sum, 1e-6));
    expect(m.litresProduced, f);
    // 1-6 Nov as on Home's week, plus this morning so far.
    expect(f, closeTo(296 + 300 + 293 + 302 + 305 + 301 + 142.8 + 9.5 + 8.8 + 7.4, 1e-6));
  });

  test('feed per litre: L01 = I01', () async {
    final m = (await farm.month()).data!;
    expect(m.feedPerLitre, (await feed.summary()).data!.costPerLitre);
    expect(m.byGroup[ExpenseGroup.feed], (await feed.summary()).data!.costThisMonth);
  });

  test('expenses: every one comes from core/money', () async {
    final m = (await farm.month()).data!;
    final all = (await money.expenses(from: monthStart)).data!;
    expect(m.totalExpenses, all.fold<int>(0, (s, e) => s + e.amount));
    // Feed 1,844,000 + advances 240,000 + vet 60,000 + diesel 45,000.
    expect(m.totalExpenses, 2189000);
    expect(m.byGroup[ExpenseGroup.wages], 240000);
  });

  test('income: sum of the milk sales this month (F09 ledger)', () async {
    final sales = (await milk.salesSince(monthStart)).data!;
    final m = (await farm.month()).data!;
    expect(m.income, sales.fold<int>(0, (s, x) => s + x.amount));
    expect(m.income, 6 * (220 * 1100 + 40 * 1400 + 12 * 1500));
    expect(m.profit, m.income - m.totalExpenses);
    expect(m.costPerLitre, (m.totalExpenses / m.litresProduced).round());
  });

  test('L02 add expense lands in core/money once and in L01', () async {
    final before = (await farm.month()).data!.totalExpenses;
    final e = (await farm.addExpense(group: ExpenseGroup.drugsVet, amount: 60000, note: 'Vet visit')).data!;
    expect(e.category, ExpenseCategory.vet);
    expect((await farm.month()).data!.totalExpenses, before + 60000);
  });

  test('F09 sales summary reads the same ledger', () async {
    final s = (await milk.sales()).data!;
    final unpaid = (await milk.salesSince(monthStart)).data!.where((x) => !x.paid);
    expect(s.owed, unpaid.fold<int>(0, (t, x) => t + x.amount));
    expect(s.buyersOwing, 1);
  });
}
