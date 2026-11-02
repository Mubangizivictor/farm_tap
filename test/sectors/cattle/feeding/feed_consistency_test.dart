// Feed numbers come from the count, purchase and feeding records only.
import 'package:farm_tap/core/money/data/fake/fake_money_repository.dart';
import 'package:farm_tap/core/money/domain/money_models.dart';
import 'package:farm_tap/sectors/cattle/feeding/data/fake/fake_feed_repository.dart';
import 'package:farm_tap/sectors/cattle/feeding/domain/feeding_models.dart';
import 'package:farm_tap/sectors/cattle/health/data/fake/fake_treatment_repository.dart';
import 'package:farm_tap/sectors/cattle/milk/data/fake/fake_milk_repository.dart';
import 'package:farm_tap/sectors/cattle/milk/domain/milk_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_deps.dart';

void main() {
  final clock = FixedClock();
  late FakeMilkRepository milk;
  late FakeMoneyRepository money;
  late FakeFeedRepository repo;

  setUp(() {
    milk = FakeMilkRepository(clock, FakeTreatmentRepository(clock));
    money = FakeMoneyRepository(clock);
    repo = FakeFeedRepository(clock, milk, money);
  });

  Future<FeedStock> row(FeedKind k) async => (await repo.summary()).data!.stock.firstWhere((s) => s.feed == k);

  test('I01 sample: stock, rate and days left match the mockup', () async {
    final dm = await row(FeedKind.dairyMeal);
    expect((dm.left, dm.perDay, dm.daysLeft, dm.reorder), (2.0, 0.7, 3, true));
    final mb = await row(FeedKind.maizeBran);
    expect((mb.left, mb.perDay, mb.daysLeft, mb.reorder), (14.0, 1.0, 14, false));
    final ml = await row(FeedKind.mineralLick);
    expect((ml.left, ml.daysLeft), (6.0, 30));
    final si = await row(FeedKind.silage);
    expect((si.left, si.perDay, si.daysLeft), (3000.0, 250.0, 12));
  });

  test('cost per litre = purchases this month / milk this month', () async {
    final s = (await repo.summary()).data!;
    final litres = (await milk.trend(TrendRange.month)).data!.total;
    expect(s.costThisMonth, 1844000);
    expect(s.costPerLitre, (1844000 / litres).round());
    // Calendar month: 1,844,000 / 1,965.5 L (1-7 Nov milk records).
    expect(s.costPerLitre, 938);
  });

  test('a purchase adds stock and cost; a feeding takes stock away', () async {
    await repo.addPurchase(feed: FeedKind.dairyMeal, amount: 10, pricePerUnit: 52000);
    expect((await row(FeedKind.dairyMeal)).left, 12);
    expect((await repo.summary()).data!.costThisMonth, 1844000 + 520000);
    await repo.recordFeeding(feed: FeedKind.dairyMeal, group: FeedGroup.milkingCows, amount: 1.5);
    expect((await row(FeedKind.dairyMeal)).left, 10.5);
  });

  test('DAIRY-FEED-02: each purchase is one feed expense in the money repository', () async {
    final feed = (await money.expenses(category: ExpenseCategory.feed)).data!;
    expect(feed.length, 4);
    expect(feed.every((e) => e.sourceId != null), isTrue);
    final p = (await repo.addPurchase(feed: FeedKind.dairyMeal, amount: 10, pricePerUnit: 52000)).data!;
    final after = (await money.expenses(category: ExpenseCategory.feed)).data!;
    expect(after.where((e) => e.sourceId == p.id).single.amount, 520000);
    // I01's cost is read back from those expenses, not kept separately.
    final monthStart = DateTime(clock.now().year, clock.now().month);
    final month = (await money.expenses(from: monthStart, category: ExpenseCategory.feed)).data!;
    expect((await repo.summary()).data!.costThisMonth, month.fold<int>(0, (s, e) => s + e.amount));
  });
}
