import 'package:farm_tap/app/router/app_dependencies.dart';
import 'package:farm_tap/app/session/session_controller.dart';
import 'package:farm_tap/core/auth/data/fake/fake_auth_repository.dart';
import 'package:farm_tap/core/money/data/fake/fake_money_repository.dart';
import 'package:farm_tap/core/onboarding/data/fake/fake_onboarding_repository.dart';
import 'package:farm_tap/core/people/data/fake/fake_staff_access_repository.dart';
import 'package:farm_tap/core/sync/sync_service.dart';
import 'package:farm_tap/core/tenancy/data/fake/fake_farm_membership_repository.dart';
import 'package:farm_tap/core/tenancy/domain/farm_membership.dart';
import 'package:farm_tap/core/tenancy/tenant_provider.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/sectors/cattle/breeding/data/fake/fake_breeding_repository.dart';
import 'package:farm_tap/sectors/cattle/collection_centre/data/fake/fake_centre_repository.dart';
import 'package:farm_tap/sectors/cattle/feeding/data/fake/fake_feed_repository.dart';
import 'package:farm_tap/sectors/cattle/health/data/fake/fake_treatment_repository.dart';
import 'package:farm_tap/sectors/cattle/herd/data/fake/fake_herd_repository.dart';
import 'package:farm_tap/sectors/cattle/home/data/fake/fake_home_repository.dart';
import 'package:farm_tap/sectors/cattle/milk/data/fake/fake_milk_repository.dart';
import 'package:farm_tap/sectors/cattle/money/data/fake/fake_farm_money_repository.dart';
import 'package:farm_tap/sectors/cattle/owner_reports/data/fake/fake_daily_report_repository.dart';
import 'package:farm_tap/sectors/cattle/workers/data/fake/fake_workers_repository.dart';

/// The mockups' "today": Saturday 7 Nov 2026, 6:52 am.
class FixedClock extends Clock {
  @override
  DateTime now() => DateTime(2026, 11, 7, 6, 52);
}

/// App dependencies built from fakes; optionally signed in with a farm open.
Future<AppDependencies> fakeDependencies({
  bool signedIn = false,
  bool farm = false,
  bool centre = false,
  Clock? clock,
}) async {
  final c = clock ?? FakeClock();
  final auth = FakeAuthRepository();
  if (signedIn) await auth.signInWithGoogle();
  final session = SessionController(auth: auth, clock: c);
  if (farm) {
    session.openFarm(
      FakeFarmMembershipRepository.places.firstWhere((p) => centre == (p.kind == PlaceKind.collectionCentre)),
    );
  }
  final treatments = FakeTreatmentRepository(c);
  final milk = FakeMilkRepository(c, treatments);
  final money = FakeMoneyRepository(c);
  final breeding = FakeBreedingRepository(c, money);
  final feed = FakeFeedRepository(c, milk, money);
  final staff = FakeStaffAccessRepository();
  final workers = FakeWorkersRepository(c, staff, money, milk);
  final farmMoney = FakeFarmMoneyRepository(c, money, milk);
  final home = FakeHomeRepository(c, treatments, breeding: breeding, feed: feed, workers: workers);
  return AppDependencies(
    session: session,
    places: FakeFarmMembershipRepository(InMemoryTenantProvider()),
    onboarding: FakeOnboardingRepository(c),
    staffAccess: staff,
    sync: FakeSyncService(),
    home: home,
    herd: FakeHerdRepository(
      clock: c,
      tenantProvider: InMemoryTenantProvider(),
      treatments: treatments,
      breeding: breeding,
    ),
    milk: milk,
    centre: FakeCentreRepository(c),
    treatments: treatments,
    feed: feed,
    money: money,
    breeding: breeding,
    workers: workers,
    staffDirectory: staff,
    farmMoney: farmMoney,
    dailyReport: FakeDailyReportRepository(
      clock: c,
      farmName: () => session.farm?.name ?? '',
      home: home,
      milk: milk,
      treatments: treatments,
      feed: feed,
      money: farmMoney,
    ),
  );
}

/// Trial days left on the sample farm at the golden date, from the same
/// Subscription calculation the app uses (never a hard-coded number).
int? demoTrialDaysLeft([DateTime? today]) =>
    FakeFarmMembershipRepository.places.first.subscription.trialBanner(today ?? FixedClock().today());

/// Home fake wired to the same sample breeding and feed records the app uses.
FakeHomeRepository fakeHome(Clock clock, FakeTreatmentRepository treatments) {
  final money = FakeMoneyRepository(clock);
  return FakeHomeRepository(
    clock,
    treatments,
    breeding: FakeBreedingRepository(clock, money),
    feed: FakeFeedRepository(clock, FakeMilkRepository(clock, treatments), money),
    workers: FakeWorkersRepository(clock, FakeStaffAccessRepository(), money, FakeMilkRepository(clock, treatments)),
  );
}

/// Herd fake with the sample breeding records (pregnant count).
FakeHerdRepository fakeHerd(Clock clock, TenantProvider tenants, FakeTreatmentRepository treatments) =>
    FakeHerdRepository(
      clock: clock,
      tenantProvider: tenants,
      treatments: treatments,
      breeding: FakeBreedingRepository(clock, FakeMoneyRepository(clock)),
    );
