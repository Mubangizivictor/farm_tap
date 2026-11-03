// Multi-step flows (ROUTES.md): onboarding steps go forward with Continue and
// back to the previous step; finishing opens Home with the new farm.
import 'dart:async';

import 'package:farm_tap/app/router/app_router.dart';
import 'package:farm_tap/app/router/routes.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/nfc/card_reader.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/core/utils/formats.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/fake_deps.dart';

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
  setUp(() => CardReader.instance = TestCardReader());
  tearDown(() => CardReader.instance = NoCardReader());

  testWidgets('onboarding: Continue goes forward, back returns, Start opens Home', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 1200)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final deps = await fakeDependencies(signedIn: true);
    final session = deps.session;
    final router = buildRouter(deps, initialLocation: AppRoutes.setupLanguage);
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

  testWidgets('milk: F02 -> F03 back to F02; save resets to F02 with the next cow', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final deps = await fakeDependencies(signedIn: true, farm: true);
    final router = buildRouter(deps, initialLocation: AppRoutes.milkRecord);
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
    expect(_location(router), AppRoutes.milkRecord);

    await tester.tap(find.text('Kahara'));
    await _settle(tester);
    expect(_location(router), '/milk/record/animal-FT-033');
    await tester.tap(find.byTooltip('Back').last);
    await _settle(tester);
    expect(_location(router), AppRoutes.milkRecord);

    await tester.tap(find.text('Kahara'));
    await _settle(tester);
    for (final k in ['9', '.', '5']) {
      await tester.tap(find.text(k).last);
      await tester.pump();
    }
    await tester.tap(find.text('Next'));
    await _settle(tester);
    expect(find.text('9.5 litres'), findsOneWidget);
    await tester.tap(find.text('Yes, save'));
    await _settle(tester);
    expect(find.textContaining('Saved! 9.5 L from Kahara'), findsOneWidget);
    // Auto-advance after 2 s to the next unrecorded cow.
    await tester.pump(const Duration(seconds: 3));
    await _settle(tester);
    expect(_location(router), startsWith('/milk/record/animal-'));
    await tester.tap(find.byTooltip('Back').last);
    await _settle(tester);
    expect(_location(router), AppRoutes.milkRecord);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('centre delivery: G02 -> G03 back to G02; save resets to G02 with Undo', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final deps = await fakeDependencies(signedIn: true, farm: true, centre: true);
    final router = buildRouter(deps, initialLocation: AppRoutes.collect);
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
    expect(_location(router), AppRoutes.collect);
    expect(find.text("Tap the farmer's card"), findsOneWidget);

    // The farmer taps card 0142 on the phone.
    (CardReader.instance as TestCardReader).tap('0142');
    await _settle(tester);
    expect(_location(router), '/collect/farmer-0142');
    expect(find.text('Card OK'), findsOneWidget);
    await tester.tap(find.byTooltip('Back').last);
    await _settle(tester);
    expect(_location(router), AppRoutes.collect);

    (CardReader.instance as TestCardReader).tap('0142');
    await _settle(tester);
    for (final k in ['3', '8']) {
      await tester.tap(find.text(k).last);
      await tester.pump();
    }
    await tester.tap(find.text('Next'));
    await _settle(tester);
    expect(find.text('38.0 litres'), findsOneWidget);
    await tester.tap(find.text('Yes, save'));
    await _settle(tester);
    expect(_location(router), AppRoutes.collect);
    expect(find.text('Tap the next card'), findsOneWidget);
    expect(find.text('Saved 38.0 L for Muhwezi Robert'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await _settle(tester);
    expect(find.text('Delivery removed'), findsOneWidget);
    expect(find.text("Tap the farmer's card"), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('health: H01 -> H02 save with read-back -> Done returns to H01; H06 lists withdrawals', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final deps = await fakeDependencies(signedIn: true, farm: true);
    final router = buildRouter(deps, initialLocation: AppRoutes.health);
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
    expect(find.text('Sick list'), findsOneWidget);

    await tester.tap(find.text('Treatment'));
    await _settle(tester);
    expect(_location(router), AppRoutes.healthTreatment);
    await tester.tap(find.text('Fever'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await _settle(tester);
    expect(find.text('Is this correct?'), findsOneWidget);
    await tester.tap(find.text('Yes, save'));
    await _settle(tester);
    expect(find.text('Treatment saved'), findsOneWidget);
    // Buttons appear once the celebration has played.
    await tester.pump(const Duration(seconds: 4));
    await tester.tap(find.text('Done'));
    await _settle(tester);
    expect(_location(router), AppRoutes.health);

    unawaited(router.push(AppRoutes.healthWithdrawal));
    await _settle(tester);
    // H06 shows each cow's safe-from date straight from her record.
    final f = FarmTapFormat('en');
    for (final r in (await deps.treatments.withdrawals(DateTime.now())).data!) {
      expect(find.text('${f.weekdayShort(r.safeFrom)} ${r.safeFrom.day}'), findsWidgets, reason: r.animalName);
    }
    await tester.pumpWidget(const SizedBox());
  });
}
