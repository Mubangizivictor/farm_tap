// Trial days left, grace and read-only are calculated from the stored dates
// against the injected clock (ROADMAP 3.2), never stored. The same numbers
// feed the D01 banner, the sidebar trial card and (Section M) M01/M04/M05.
import 'package:farm_tap/app/router/app_router.dart';
import 'package:farm_tap/app/router/routes.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/onboarding/data/fake/fake_onboarding_repository.dart';
import 'package:farm_tap/core/onboarding/domain/farm_setup.dart';
import 'package:farm_tap/core/tenancy/domain/farm_membership.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_deps.dart';

void main() {
  final trial = Subscription(trialStartedAt: DateTime(2026, 11, 2), trialEndsAt: DateTime(2026, 11, 16));

  test('a new farm (B10) gets its own trial: today + 14 days', () async {
    final clock = FakeClock(DateTime(2026, 11, 7, 8, 41));
    final repo = FakeOnboardingRepository(clock);
    final farm = (await repo.createFarm(const FarmSetup(farmName: 'New Farm'))).data!;
    expect(farm.subscription.trialEndsAt, DateTime(2026, 11, 21));
    expect(farm.subscription.trialDaysLeft(clock.today()), 14);
  });

  group('Subscription', () {
    test('trial: days left = trialEndsAt - today', () {
      expect(trial.trialDaysLeft(DateTime(2026, 11, 7, 8, 41)), 9);
      expect(trial.trialDaysUsed(DateTime(2026, 11, 7)), 5);
      expect(trial.trialLength, 14);
      expect(trial.trialDaysLeft(DateTime(2026, 11, 15, 23, 59)), 1);
      expect(trial.state(DateTime(2026, 11, 15)), SubscriptionState.trial);
    });

    test('trial ends unpaid -> read-only, no grace', () {
      expect(trial.state(DateTime(2026, 11, 16)), SubscriptionState.readOnly);
      expect(trial.readOnly(DateTime(2026, 11, 17)), isTrue);
      expect(trial.trialBanner(DateTime(2026, 11, 17)), isNull);
    });

    test('overdue payment: 7 days grace, then read-only', () {
      final paid = Subscription(trialEndsAt: DateTime(2026, 11, 21), paidUntil: DateTime(2026, 12, 21));
      expect(paid.state(DateTime(2026, 12, 20)), SubscriptionState.active);
      expect(paid.state(DateTime(2026, 12, 21)), SubscriptionState.grace);
      expect(paid.graceDaysLeft(DateTime(2026, 12, 21)), 7);
      expect(paid.state(DateTime(2026, 12, 27)), SubscriptionState.grace);
      expect(paid.state(DateTime(2026, 12, 28)), SubscriptionState.readOnly);
    });
  });

  // Same as running with --dart-define=DEMO_DATE=<date>.
  Future<(String?, bool)> homeAt(WidgetTester tester, DateTime demoDate) async {
    tester.view
      ..physicalSize = const Size(390, 1200)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final clock = FakeClock(demoDate);
    final deps = await fakeDependencies(signedIn: true, farm: true, clock: clock);
    final router = buildRouter(deps, initialLocation: AppRoutes.home);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ClockScope(
        clock: clock,
        child: MaterialApp.router(
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
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final banner = find.textContaining('Free trial');
    final text = banner.evaluate().isEmpty ? null : (banner.evaluate().first.widget as Text).data;
    final readOnly = deps.session.readOnly;
    await tester.pumpWidget(const SizedBox());
    return (text, readOnly);
  }

  testWidgets('Sat 7 Nov: the D01 banner shows 9 days left', (tester) async {
    final (banner, readOnly) = await homeAt(tester, DateTime(2026, 11, 7, 8, 41));
    expect(banner, 'Free trial: 9 days left');
    expect(readOnly, isFalse);
  });

  testWidgets('DEMO_DATE=2026-11-15: the banner says 1 day left', (tester) async {
    final (banner, readOnly) = await homeAt(tester, DateTime(2026, 11, 15, 8, 41));
    expect(banner, 'Free trial: 1 day left');
    expect(readOnly, isFalse);
    // Section M adds: M04 trial-ending popup shows on day 13 and 14.
  });

  testWidgets('DEMO_DATE=2026-11-17: the farm is read-only, no trial banner', (tester) async {
    final (banner, readOnly) = await homeAt(tester, DateTime(2026, 11, 17, 8, 41));
    expect(banner, isNull);
    expect(readOnly, isTrue);
    // Section M adds: M05 read-only screen with locked record buttons.
  });
}
