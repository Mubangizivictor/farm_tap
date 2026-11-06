// Store screenshots for Google Play and the App Store (decision 0024).
// Not part of the normal test run. Make them with:
//
//   STORE_SHOTS=1 flutter test --update-goldens test/store
//
// Writes docs/store/screenshots/raw/<size>/<n>_<name>.png; then
// `python3 tool/store_frames.py` adds the caption and FarmTap frame.
import 'dart:io';

import 'package:farm_tap/core/billing/billing_repository.dart';
import 'package:farm_tap/core/billing/presentation/subscription_page.dart';
import 'package:farm_tap/core/people/data/fake/fake_staff_access_repository.dart';
import 'package:farm_tap/core/sync/data/memory_record_store.dart';
import 'package:farm_tap/core/sync/record_journal.dart';
import 'package:farm_tap/core/tenancy/domain/farm_membership.dart';
import 'package:farm_tap/core/tenancy/tenant_provider.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/core/utils/id_generator.dart';
import 'package:farm_tap/sectors/cattle/health/data/fake/fake_treatment_repository.dart';
import 'package:farm_tap/sectors/cattle/herd/presentation/pages/herd_list_page.dart';
import 'package:farm_tap/sectors/cattle/home/presentation/pages/home_page.dart';
import 'package:farm_tap/sectors/cattle/milk/data/fake/fake_milk_repository.dart';
import 'package:farm_tap/sectors/cattle/milk/presentation/pages/milk_pages.dart';
import 'package:farm_tap/sectors/cattle/operations/data/operations_repository.dart';
import 'package:farm_tap/sectors/cattle/operations/domain/operations_models.dart';
import 'package:farm_tap/sectors/cattle/operations/presentation/pages/feed_store_page.dart';
import 'package:farm_tap/sectors/cattle/operations/presentation/pages/roster_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_deps.dart';
import '../helpers/pump_app.dart';
import '../helpers/screen_golden.dart';
import '../helpers/shell_wrap.dart';

/// Logical size and pixel ratio of each store size.
const _sizes = {
  // Google Play phone (9:16, 1080 x 1920).
  'play_phone': (Size(360, 640), 3.0),
  // App Store 6.9" iPhone (1320 x 2868).
  'apple_6_9': (Size(440, 956), 3.0),
  // App Store 13" iPad (2064 x 2752).
  'apple_ipad_13': (Size(1032, 1376), 2.0),
};

void main() {
  final skip = !Platform.environment.containsKey('STORE_SHOTS');
  final clock = FixedClock();
  final now = clock.now();

  Future<OperationsRepository> ops() async {
    final journal = RecordJournal(
      store: MemoryRecordStore(),
      clock: clock,
      ids: UuidGenerator(),
      deviceId: 'shots',
      tenantId: () => 'farm-1',
      actor: () => 'owner',
    );
    final r = OperationsRepository(journal: journal, clock: clock);
    for (final (who, stand, act, shift) in [
      ('staff-ta', 'staff-mt', DutyActivity.milking, DutyShift.morning),
      ('staff-mt', 'staff-ta', DutyActivity.feeding, DutyShift.morning),
      ('staff-aj', null, DutyActivity.health, DutyShift.afternoon),
      ('staff-np', 'staff-aj', DutyActivity.milking, DutyShift.evening),
      ('staff-kr', null, DutyActivity.security, DutyShift.night),
    ]) {
      await r.saveDuty(Duty(id: '', activity: act, staffId: who, standInId: stand, shift: shift));
    }
    await r.addAbsence(
      Absence(id: '', staffId: 'staff-np', from: now, to: now.add(const Duration(days: 2)), reason: 'Sick'),
    );
    for (final (name, unit, low, count) in [
      ('Dairy meal', 'kg', 100.0, 420.0),
      ('Maize bran', 'kg', 80.0, 60.0),
      ('Hay', 'bales', 20.0, 140.0),
      ('Mineral lick', 'kg', 5.0, 18.0),
    ]) {
      await r.saveFeedType(FeedType(id: '', name: name, unit: unit, lowAt: low));
      await r.countFeed(r.feedTypes.firstWhere((t) => t.name == name).id, count);
    }
    for (var d = 1; d <= 7; d++) {
      for (final (f, amt) in [('Dairy meal', 45.0), ('Maize bran', 12.0), ('Hay', 6.0)]) {
        await r.journal.add('feedUsage', {
          'feed': r.feedTypes.firstWhere((t) => t.name == f).id,
          'amount': amt,
          'at': now.subtract(Duration(days: d)).toIso8601String(),
        });
      }
    }
    await r.restore();
    return r;
  }

  final screens = <String, Future<Widget> Function()>{
    '1_home': () async => inShell(
      HomePage(
        repo: fakeHome(clock, FakeTreatmentRepository(clock)),
        farmName: 'Rwemera Dairy Farm',
        ownerName: 'Muhwezi Robert',
        trialDaysLeft: demoTrialDaysLeft(),
        today: now,
        onOpen: (_) {},
      ),
    ),
    '2_milk': () async => inShell(
      MilkTodayPage(
        repo: FakeMilkRepository(clock, FakeTreatmentRepository(clock)),
        onRecord: () {},
        onTool: (_) {},
        today: now,
      ),
      current: '/milk',
    ),
    '3_herd': () async => inShell(
      HerdListPage(
        repo: fakeHerd(clock, InMemoryTenantProvider(), FakeTreatmentRepository(clock)),
        onAnimal: (_) {},
        onAdd: () {},
        onScan: () {},
        today: now,
      ),
      current: '/herd',
    ),
    '4_roster': () async => inShell(
      RosterPage(repo: await ops(), staff: FakeStaffAccessRepository(), canEdit: true, myStaffId: 'staff-ta'),
      current: '/more',
      parent: '/more',
    ),
    '5_feeds': () async => inShell(
      FeedStorePage(repo: await ops(), canEdit: true, onRecordFeeding: () {}),
      current: '/more',
      parent: '/more',
    ),
    '6_plan': () async => inShell(
      SubscriptionPage(
        repo: FakeBillingRepository(),
        tenantId: 'farm-1',
        farmName: 'Rwemera Dairy Farm',
        subscription: Subscription(trialStartedAt: DateTime(2026, 10, 31), trialEndsAt: DateTime(2026, 11, 14)),
        canPay: true,
        onPaid: (_) {},
      ),
      current: '/more',
      parent: '/more',
    ),
  };

  for (final MapEntry(key: size, value: (logical, ratio)) in _sizes.entries) {
    for (final MapEntry(key: name, value: build) in screens.entries) {
      testWidgets('$size $name', skip: skip, (tester) async {
        final page = await tester.runAsync(build);
        await pumpFarmTap(
          tester,
          ClockScope(clock: clock, child: page!),
          size: logical,
        );
        tester.view
          ..physicalSize = logical * ratio
          ..devicePixelRatio = ratio;
        await tester.pump();
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
        await tester.pump(const Duration(seconds: 1));
        await precacheImages(tester);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('../../docs/store/screenshots/raw/$size/$name.png'),
        );
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
