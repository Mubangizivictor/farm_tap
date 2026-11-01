// Multi-step flows (ROUTES.md): onboarding steps go forward with Continue and
// back to the previous step; finishing opens Home with the new farm.
import 'package:farm_tap/app/router/app_router.dart';
import 'package:farm_tap/app/router/routes.dart';
import 'package:farm_tap/app/session/session_controller.dart';
import 'package:farm_tap/core/auth/data/fake/fake_auth_repository.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/onboarding/data/fake/fake_onboarding_repository.dart';
import 'package:farm_tap/core/people/data/fake/fake_staff_access_repository.dart';
import 'package:farm_tap/core/tenancy/data/fake/fake_farm_membership_repository.dart';
import 'package:farm_tap/core/tenancy/tenant_provider.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

String _location(GoRouter router) {
  final config = router.routerDelegate.currentConfiguration;
  final last = config.last;
  return last is ImperativeRouteMatch ? last.matches.uri.path : config.uri.path;
}

void main() {
  testWidgets('onboarding: Continue goes forward, back returns, Start opens Home', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 1200)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final auth = FakeAuthRepository();
    await auth.signInWithGoogle();
    final session = SessionController(auth: auth);
    final router = buildRouter(
      session: session,
      places: FakeFarmMembershipRepository(InMemoryTenantProvider()),
      onboarding: FakeOnboardingRepository(SystemClock()),
      staffAccess: FakeStaffAccessRepository(),
      initialLocation: AppRoutes.setupLanguage,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: FarmTapTheme.light,
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
      ),
    );
    await _settle(tester);

    Future<void> next() async {
      await tester.tap(find.widgetWithText(FarmTapButton, 'Continue'));
      await _settle(tester);
    }

    expect(_location(router), AppRoutes.setupLanguage);
    await next();
    expect(_location(router), AppRoutes.setupSector);
    await next();
    expect(_location(router), AppRoutes.setupDairyType);

    // Back returns to the previous step.
    await tester.tap(find.byTooltip('Back').last);
    await _settle(tester);
    expect(_location(router), AppRoutes.setupSector);
    await next();
    await next();
    expect(_location(router), AppRoutes.setupFarm);

    await tester.enterText(find.byType(TextField).first, 'Rwemera Dairy Farm');
    await next();
    expect(_location(router), AppRoutes.setupContacts);
    await tester.enterText(find.byType(TextField).first, '772451908');
    await next();
    expect(_location(router), AppRoutes.setupRole);
    await next();
    expect(_location(router), AppRoutes.setupStaff);

    await tester.tap(find.text('Skip'));
    await _settle(tester);
    expect(_location(router), AppRoutes.setupDone);
    expect(find.text('Rwemera Dairy Farm'), findsOneWidget);

    await tester.tap(find.text('Start using FarmTap'));
    await _settle(tester);
    expect(_location(router), AppRoutes.home);
    expect(session.farm?.name, 'Rwemera Dairy Farm');
    await tester.pumpWidget(const SizedBox());
  });
}
