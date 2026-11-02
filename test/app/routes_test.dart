// Navigation contract (docs/design/ROUTES.md): every non-root route is
// pushed from its parent and the back arrow returns to the parent; a deep
// link's back arrow goes to the parent; iOS edge swipe goes back; guards.
import 'dart:async';

import 'package:farm_tap/app/router/app_router.dart';
import 'package:farm_tap/app/router/routes.dart';
import 'package:farm_tap/app/session/session_controller.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/people/data/fake/fake_staff_access_repository.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/fake_deps.dart';

/// (route, parent, signed in?, farm open?) for every implemented non-root route.
const _routes = <(String, String, bool, bool)>[
  (AppRoutes.emailSignIn, AppRoutes.signIn, false, false),
  (AppRoutes.signUp, AppRoutes.emailSignIn, false, false),
  (AppRoutes.forgotPassword, AppRoutes.emailSignIn, false, false),
  (AppRoutes.setupSector, AppRoutes.setupLanguage, true, false),
  (AppRoutes.setupWaitlistDone, AppRoutes.setupSector, true, false),
  (AppRoutes.setupDairyType, AppRoutes.setupSector, true, false),
  (AppRoutes.setupFarm, AppRoutes.setupDairyType, true, false),
  (AppRoutes.setupContacts, AppRoutes.setupFarm, true, false),
  (AppRoutes.setupRole, AppRoutes.setupContacts, true, false),
  (AppRoutes.setupStaff, AppRoutes.setupRole, true, false),
  (AppRoutes.unlockNumber, AppRoutes.unlock, true, true),
  ('${AppRoutes.unlockPin}?card=0142', AppRoutes.unlock, true, true),
  (AppRoutes.homeAlerts, AppRoutes.home, true, true),
  (AppRoutes.herdAdd, AppRoutes.herd, true, true),
  (AppRoutes.herdScan, AppRoutes.herd, true, true),
  (AppRoutes.herdCount, AppRoutes.herd, true, true),
  (AppRoutes.herdLabels, AppRoutes.herd, true, true),
  ('/herd/animal-FT-022', AppRoutes.herd, true, true),
  (AppRoutes.milkRecord, AppRoutes.milk, true, true),
  ('/milk/record/animal-FT-033', AppRoutes.milkRecord, true, true),
  (AppRoutes.milkTotal, AppRoutes.milk, true, true),
  (AppRoutes.milkUse, AppRoutes.milk, true, true),
  (AppRoutes.milkSales, AppRoutes.milk, true, true),
  (AppRoutes.milkTrends, AppRoutes.milk, true, true),
  ('/collect/farmer-0142', AppRoutes.collect, true, true),
  ('/farmers/farmer-0142', AppRoutes.farmers, true, true),
  (AppRoutes.payFarmers, AppRoutes.pay, true, true),
  (AppRoutes.paySms, AppRoutes.pay, true, true),
  (AppRoutes.centreReconcile, AppRoutes.home, true, true),
  (AppRoutes.healthTreatment, AppRoutes.health, true, true),
  (AppRoutes.healthDrugs, AppRoutes.health, true, true),
  (AppRoutes.healthSchedule, AppRoutes.health, true, true),
  (AppRoutes.healthWithdrawal, AppRoutes.health, true, true),
];

class _Harness {
  new _(this.session, this.router);

  final SessionController session;
  final GoRouter router;

  static Future<_Harness> pump(
    WidgetTester tester, {
    required String start,
    bool signedIn = false,
    bool farm = false,
    Size size = const Size(390, 844),
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final deps = await fakeDependencies(signedIn: signedIn, farm: farm);
    final session = deps.session;
    final router = buildRouter(deps, initialLocation: start);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        debugShowCheckedModeBanner: false,
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
    return _Harness._(session, router);
  }

  /// The top-most route, including imperatively pushed ones.
  String get location {
    final config = router.routerDelegate.currentConfiguration;
    final last = config.last;
    return last is ImperativeRouteMatch ? last.matches.uri.path : config.uri.path;
  }
}

/// Animations loop forever (cartoon WebPs), so pumpAndSettle never ends:
/// pump past page transitions instead.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _tapBack(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Back').last);
  await _settle(tester);
}

void main() {
  group('push from parent, back returns to parent', () {
    for (final (route, parent, signedIn, farm) in _routes) {
      testWidgets(route, (tester) async {
        final h = await _Harness.pump(tester, start: parent, signedIn: signedIn, farm: farm);
        expect(h.location, parent);
        unawaited(h.router.push(route));
        await _settle(tester);
        expect(h.location, Uri.parse(route).path);
        await _tapBack(tester);
        expect(h.location, parent);
      });
    }
  });

  group('deep link: back arrow goes to the parent', () {
    for (final (route, parent, signedIn, farm) in _routes) {
      testWidgets(route, (tester) async {
        final h = await _Harness.pump(tester, start: route, signedIn: signedIn, farm: farm);
        expect(h.location, Uri.parse(route).path);
        await _tapBack(tester);
        expect(h.location, parent);
      });
    }
  });

  testWidgets('iOS: edge swipe goes back', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final h = await _Harness.pump(tester, start: AppRoutes.signIn);
    unawaited(h.router.push(AppRoutes.emailSignIn));
    await _settle(tester);
    // The swipe only starts once the push transition has fully completed.
    await tester.pump(const Duration(seconds: 1));
    await tester.timedDragFrom(const Offset(5, 400), const Offset(300, 0), const Duration(milliseconds: 300));
    await _settle(tester);
    expect(h.location, AppRoutes.signIn);
    debugDefaultTargetPlatformOverride = null;
  });

  group('guards', () {
    testWidgets('signed out -> sign-in', (tester) async {
      final h = await _Harness.pump(tester, start: AppRoutes.herd);
      expect(h.location, AppRoutes.signIn);
    });

    testWidgets('signed in without a farm -> farm picker', (tester) async {
      final h = await _Harness.pump(tester, start: AppRoutes.home, signedIn: true);
      expect(h.location, AppRoutes.farmPicker);
    });

    testWidgets('signed in with a farm -> sign-in redirects home', (tester) async {
      final h = await _Harness.pump(tester, start: AppRoutes.signIn, signedIn: true, farm: true);
      expect(h.location, AppRoutes.home);
    });

    testWidgets('locked farm phone -> unlock', (tester) async {
      final h = await _Harness.pump(tester, start: AppRoutes.farmPicker, signedIn: true, farm: true);
      h.session.lock();
      h.router.go(AppRoutes.herd);
      await _settle(tester);
      expect(h.location, startsWith(AppRoutes.unlock));
    });
  });

  testWidgets('tabs keep their own stack; phone More-sections show back to More', (tester) async {
    final h = await _Harness.pump(tester, start: AppRoutes.more, signedIn: true, farm: true);
    unawaited(h.router.push(AppRoutes.feeding));
    await _settle(tester);
    expect(h.location, AppRoutes.feeding);
    await _tapBack(tester);
    expect(h.location, AppRoutes.more);
  });

  testWidgets('back arrow on a dirty form asks "Discard changes?"', (tester) async {
    final h = await _Harness.pump(tester, start: AppRoutes.feeding, signedIn: true, farm: true);
    unawaited(h.router.push(AppRoutes.feedingRecord));
    await _settle(tester);
    await tester.tap(find.text('5'));
    await _settle(tester);
    await _tapBack(tester);
    expect(find.text('Discard changes?'), findsOneWidget);
    expect(h.location, AppRoutes.feedingRecord);
    await tester.tap(find.text('Discard'));
    await _settle(tester);
    expect(h.location, AppRoutes.feeding);
  });

  group('N01 More: sections push from /more, back returns to More', () {
    for (final (label, location, ready) in [
      ('Feeding', '/feeding', 'Feed cost this month'),
      ('Breeding', '/breeding', 'Expected calvings'),
      ('Workers', '/workers', '6 people'),
      ('Money', '/money', 'Cost per litre'),
      ('Reports', '/reports', 'Monthly farm report'),
      ('Settings', '/settings', 'Coming soon'),
      ('Help & support', '/settings/help', 'Coming soon'),
    ]) {
      testWidgets(label, (tester) async {
        final h = await _Harness.pump(tester, start: AppRoutes.more, signedIn: true, farm: true);
        await tester.ensureVisible(find.text(label).last);
        await tester.tap(find.text(label).last);
        await _settle(tester);
        expect(h.location, location);
        expect(find.text(ready), findsWidgets);
        await _tapBack(tester);
        expect(h.location, AppRoutes.more);
      });
    }
  });

  group('K: workers pages push from /workers and back returns', () {
    for (final (route, ready) in [
      ('/workers/attendance', 'Attendance'),
      ('/workers/tasks', 'Tasks'),
      ('/workers/wages', 'Wages & advances'),
      ('/workers/staff-ta', 'Balance owed'),
      ('/workers/add', 'Save worker'),
      ('/workers/staff-ta/edit', 'Save changes'),
    ]) {
      testWidgets(route, (tester) async {
        final h = await _Harness.pump(tester, start: AppRoutes.workers, signedIn: true, farm: true);
        unawaited(h.router.push(route));
        await _settle(tester);
        expect(h.location, route);
        expect(find.text(ready), findsWidgets);
        await _tapBack(tester);
        expect(h.location, AppRoutes.workers);
      });
    }

    testWidgets('K03 assign card by typed number returns to K02', (tester) async {
      final h = await _Harness.pump(tester, start: AppRoutes.workers, signedIn: true, farm: true);
      unawaited(h.router.push('/workers/staff-np'));
      await _settle(tester);
      unawaited(h.router.push('/workers/staff-np/card'));
      await _settle(tester);
      await tester.tap(find.text('Type card number'));
      await _settle(tester);
      for (final d in ['2', '0', '7']) {
        await tester.tap(find.text(d).last);
        await tester.pump();
      }
      await tester.tap(find.text('Use this card'));
      await _settle(tester);
      expect(h.location, '/workers/staff-np');
      await tester.pump(const Duration(seconds: 4));
    });
  });

  group('ROADMAP 7.4: only owner and manager manage staff', () {
    Future<void> check(WidgetTester tester, {required int staffIndex, required bool allowed}) async {
      final h = await _Harness.pump(tester, start: AppRoutes.workers, signedIn: true, farm: true);
      h.session.unlock(FakeStaffAccessRepository.sample[staffIndex]);
      unawaited(h.router.push('/workers/staff-ta'));
      await _settle(tester);
      expect(find.text('Reset PIN'), allowed ? findsOneWidget : findsNothing);
      expect(find.byTooltip('Edit worker'), allowed ? findsOneWidget : findsNothing);
      await _tapBack(tester);
      expect(find.text('Add worker'), allowed ? findsOneWidget : findsNothing);
    }

    testWidgets('manager (Tom) sees Add / Edit / Reset PIN', (tester) => check(tester, staffIndex: 0, allowed: true));
    testWidgets('herdsman (Amos) does not', (tester) => check(tester, staffIndex: 1, allowed: false));
    testWidgets('worker (Peter) does not', (tester) => check(tester, staffIndex: 3, allowed: false));

    testWidgets('owner (no staff unlocked) sees them', (tester) async {
      final h = await _Harness.pump(tester, start: AppRoutes.workers, signedIn: true, farm: true);
      expect(h.session.staff, isNull);
      expect(find.text('Add worker'), findsOneWidget);
    });
  });

  group('L: money and reports push and back', () {
    for (final (start, route, ready) in [
      ('/money', '/money/expense', 'Category'),
      ('/reports', '/reports/whatsapp', 'Send time'),
    ]) {
      testWidgets(route, (tester) async {
        final h = await _Harness.pump(tester, start: start, signedIn: true, farm: true);
        unawaited(h.router.push(route));
        await _settle(tester);
        expect(find.text(ready), findsWidgets);
        await _tapBack(tester);
        expect(h.location, start);
      });
    }
  });
}
