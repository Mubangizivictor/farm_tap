import 'package:farm_tap/sectors/cattle/feeding/data/fake/fake_feed_repository.dart';
import 'package:farm_tap/sectors/cattle/feeding/presentation/pages/feeding_pages.dart';
import 'package:farm_tap/sectors/cattle/health/data/fake/fake_treatment_repository.dart';
import 'package:farm_tap/sectors/cattle/milk/data/fake/fake_milk_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_deps.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/shell_wrap.dart';

void main() {
  final clock = FixedClock();

  testWidgets('I03 buy feed (after read-back) updates I01 stock', (tester) async {
    final repo = FakeFeedRepository(clock, FakeMilkRepository(clock, FakeTreatmentRepository(clock)));
    await pumpFarmTap(tester, inShell(FeedStockPage(repo: repo, onRecord: () {}), current: '/feeding'));
    await tester.pumpAndSettle();
    expect(find.text('2 bags left · about 3 days'), findsOneWidget);
    await tester.tap(find.byTooltip('Buy feed'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save purchase'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, save'));
    await tester.pumpAndSettle();
    expect(find.text('Save purchase'), findsNothing);
    expect(find.text('12 bags'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });
}
