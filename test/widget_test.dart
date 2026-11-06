import 'package:farm_tap/app/app.dart';
import 'package:farm_tap/app/di/injection.dart';
import 'package:farm_tap/app/flavor.dart';
import 'package:farm_tap/core/auth/presentation/pages/sign_in_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => configureDependencies(Flavor.dev, demo: true));

  testWidgets('App boots: A01 splash, then A02 sign-in after 2 s', (tester) async {
    await tester.pumpWidget(FarmTapApp(config: AppConfig.forFlavor(Flavor.dev)));
    await tester.pump(const Duration(milliseconds: 2100));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(SignInPage), findsOneWidget);
  });
}
