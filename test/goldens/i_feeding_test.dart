// Section I — feeding (I01-I03), 8 goldens per screen + small screens.
// flutter test --update-goldens test/goldens/i_feeding_test.dart
import 'package:farm_tap/sectors/cattle/feeding/data/fake/fake_feed_repository.dart';
import 'package:farm_tap/sectors/cattle/feeding/presentation/pages/feeding_pages.dart';
import 'package:farm_tap/sectors/cattle/health/data/fake/fake_treatment_repository.dart';
import 'package:farm_tap/sectors/cattle/milk/data/fake/fake_milk_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_deps.dart';
import '../helpers/screen_golden.dart';
import '../helpers/shell_wrap.dart';

void main() {
  final clock = FixedClock();
  FakeFeedRepository repo() => FakeFeedRepository(clock, FakeMilkRepository(clock, FakeTreatmentRepository(clock)));

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  screenGoldens(
    'I01_feed_stock',
    (_) => inShell(FeedStockPage(repo: repo(), onRecord: () {}), current: '/feeding'),
  );

  screenGoldens(
    'I02_record_feeding',
    (_) => inShell(
      RecordFeedingPage(repo: repo(), onSaved: () {}, initialAmount: '1.5'),
      current: '/feeding',
      parent: '/feeding',
    ),
    act: (tester, _) => settle(tester),
  );

  screenGoldens(
    'I03_feed_purchase_sheet',
    (_) => inShell(FeedStockPage(repo: repo(), onRecord: () {}, openBuy: true), current: '/feeding'),
    act: (tester, _) => settle(tester),
  );
}
