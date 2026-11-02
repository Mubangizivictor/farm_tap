// Section D — home (D01-D06), 8 goldens per screen + small screens.
// flutter test --update-goldens test/goldens/d_home_test.dart
import 'package:farm_tap/core/people/data/fake/fake_staff_access_repository.dart';
import 'package:farm_tap/core/sync/presentation/sync_status_sheet.dart';
import 'package:farm_tap/core/sync/sync_service.dart';
import 'package:farm_tap/sectors/cattle/health/data/fake/fake_treatment_repository.dart';
import 'package:farm_tap/sectors/cattle/home/presentation/pages/alerts_page.dart';
import 'package:farm_tap/sectors/cattle/home/presentation/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_deps.dart';
import '../helpers/screen_golden.dart';
import '../helpers/shell_wrap.dart';

void main() {
  final clock = FixedClock();
  final today = clock.now();

  Widget owner({bool online = true}) => inShell(
    HomePage(
      repo: fakeHome(clock, FakeTreatmentRepository(clock)),
      farmName: 'Rwemera Dairy Farm',
      ownerName: 'Muhwezi Robert',
      trialDaysLeft: demoTrialDaysLeft(),
      today: today,
      onOpen: (_) {},
    ),
    online: online,
  );

  /// Opens an overlay from inside the page (so it has a Navigator).
  Future<void> fromPage(WidgetTester tester, Future<void> Function(BuildContext) open) async {
    final context = tester.element(find.byType(HomePage));
    open(context).ignore();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  screenGoldens('D01_home_owner', (_) => owner());

  screenGoldens(
    'D02_home_worker',
    (_) => inShell(
      HomePage(
        repo: fakeHome(clock, FakeTreatmentRepository(clock)),
        farmName: 'Rwemera Dairy Farm',
        ownerName: 'Muhwezi Robert',
        staff: FakeStaffAccessRepository.sample[1],
        today: today,
        onOpen: (_) {},
        onLock: () {},
      ),
      profileName: 'Twinomujuni Amos',
    ),
  );

  screenGoldens(
    'D03_alerts',
    (_) => inShell(
      AlertsPage(repo: fakeHome(clock, FakeTreatmentRepository(clock)), today: today),
      parent: '/home',
    ),
  );

  screenGoldens(
    'D04_sync_status_sheet',
    (_) => owner(),
    act: (tester, _) =>
        fromPage(tester, (c) => showSyncStatusSheet(c, FakeSyncService(const SyncSnapshot(synced: 1284, waiting: 3)))),
  );

  screenGoldens('D05_home_offline', (_) => owner(online: false));

  screenGoldens(
    'D06_notification_permission',
    (_) => owner(),
    act: (tester, _) => fromPage(tester, showRemindersDialog),
  );
}
