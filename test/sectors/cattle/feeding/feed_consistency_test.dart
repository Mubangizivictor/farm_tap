// Feed numbers come from the count, purchase and feeding records only.
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
  late FakeFeedRepository repo;

  setUp(() {
    milk = FakeMilkRepository(clock, FakeTreatmentRepository(clock));
    repo = FakeFeedRepository(clock, milk);
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
    expect(s.costPerLitre, 211);
  });

  test('a purchase adds stock and cost; a feeding takes stock away', () async {
    await repo.addPurchase(feed: FeedKind.dairyMeal, amount: 10, pricePerUnit: 52000);
    expect((await row(FeedKind.dairyMeal)).left, 12);
    expect((await repo.summary()).data!.costThisMonth, 1844000 + 520000);
    await repo.recordFeeding(feed: FeedKind.dairyMeal, group: FeedGroup.milkingCows, amount: 1.5);
    expect((await row(FeedKind.dairyMeal)).left, 10.5);
  });
}
