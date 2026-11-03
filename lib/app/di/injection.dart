import 'dart:async';

import 'package:farm_tap/app/flavor.dart';
import 'package:farm_tap/app/session/session_controller.dart';
import 'package:farm_tap/core/audit/audit_logger.dart';
import 'package:farm_tap/core/auth/data/fake/fake_auth_repository.dart';
import 'package:farm_tap/core/auth/domain/auth_repository.dart';
import 'package:farm_tap/core/database/isar_service.dart';
import 'package:farm_tap/core/money/data/fake/fake_money_repository.dart';
import 'package:farm_tap/core/money/domain/money_repository.dart';
import 'package:farm_tap/core/onboarding/data/fake/fake_onboarding_repository.dart';
import 'package:farm_tap/core/onboarding/domain/onboarding_repository.dart';
import 'package:farm_tap/core/people/data/fake/fake_staff_access_repository.dart';
import 'package:farm_tap/core/people/domain/staff_access_repository.dart';
import 'package:farm_tap/core/people/domain/staff_directory.dart';
import 'package:farm_tap/core/sync/connectivity_monitor.dart';
import 'package:farm_tap/core/sync/data/fake/fake_remote_store.dart';
import 'package:farm_tap/core/sync/data/isar/isar_record_store.dart';
import 'package:farm_tap/core/sync/data/memory_record_store.dart';
import 'package:farm_tap/core/sync/domain/local_record_store.dart';
import 'package:farm_tap/core/sync/domain/merge_policy.dart';
import 'package:farm_tap/core/sync/domain/remote_store.dart';
import 'package:farm_tap/core/sync/sync_engine.dart';
import 'package:farm_tap/core/sync/sync_service.dart';
import 'package:farm_tap/core/tenancy/data/fake/fake_farm_membership_repository.dart';
import 'package:farm_tap/core/tenancy/domain/farm_membership_repository.dart';
import 'package:farm_tap/core/tenancy/tenant_provider.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/core/utils/id_generator.dart';
import 'package:farm_tap/core/utils/logger.dart';
import 'package:farm_tap/core/utils/trusted_clock.dart';
import 'package:farm_tap/sectors/cattle/breeding/data/fake/fake_breeding_repository.dart';
import 'package:farm_tap/sectors/cattle/breeding/domain/breeding_repository.dart';
import 'package:farm_tap/sectors/cattle/collection_centre/data/fake/fake_centre_repository.dart';
import 'package:farm_tap/sectors/cattle/collection_centre/domain/centre_repository.dart';
import 'package:farm_tap/sectors/cattle/feeding/data/fake/fake_feed_repository.dart';
import 'package:farm_tap/sectors/cattle/feeding/domain/feeding_repository.dart';
import 'package:farm_tap/sectors/cattle/health/data/fake/fake_treatment_repository.dart';
import 'package:farm_tap/sectors/cattle/health/domain/health_repository.dart';
import 'package:farm_tap/sectors/cattle/herd/data/fake/fake_herd_repository.dart';
import 'package:farm_tap/sectors/cattle/herd/data/herd_repository_impl.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/herd_repository.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/usecases/add_animal.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/usecases/watch_animals.dart';
import 'package:farm_tap/sectors/cattle/herd/presentation/bloc/herd_bloc.dart';
import 'package:farm_tap/sectors/cattle/home/data/fake/fake_home_repository.dart';
import 'package:farm_tap/sectors/cattle/home/domain/home_repository.dart';
import 'package:farm_tap/sectors/cattle/milk/data/fake/fake_milk_repository.dart';
import 'package:farm_tap/sectors/cattle/milk/domain/milk_repository.dart';
import 'package:farm_tap/sectors/cattle/money/data/fake/fake_farm_money_repository.dart';
import 'package:farm_tap/sectors/cattle/money/domain/farm_money_repository.dart';
import 'package:farm_tap/sectors/cattle/owner_reports/data/fake/fake_daily_report_repository.dart';
import 'package:farm_tap/sectors/cattle/owner_reports/domain/daily_report.dart';
import 'package:farm_tap/sectors/cattle/workers/data/fake/fake_workers_repository.dart';
import 'package:farm_tap/sectors/cattle/workers/domain/workers_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GetIt getIt = GetIt.instance;

/// UI phase: in-memory fake repositories with the sample data from the
/// mockups. No Isar writes, no Firebase. Set to false in the backend phase.
const bool useFakeData = true;

Future<void> configureDependencies(Flavor flavor) async {
  final tenants = InMemoryTenantProvider();

  // Core utils and services
  getIt
    ..registerLazySingleton<AppLogger>(LoggerImpl.new)
    ..registerLazySingleton<Clock>(() => useFakeData ? FakeClock() : SystemClock())
    ..registerLazySingleton<IdGenerator>(UuidGenerator.new)
    ..registerSingleton<TenantProvider>(tenants)
    ..registerLazySingleton<AuditLogger>(LocalAuditLogger.new);

  if (useFakeData) {
    getIt
      ..registerLazySingleton<AuthRepository>(FakeAuthRepository.new)
      ..registerLazySingleton<FarmMembershipRepository>(() => FakeFarmMembershipRepository(tenants))
      ..registerLazySingleton<OnboardingRepository>(() => FakeOnboardingRepository(getIt<Clock>()))
      ..registerLazySingleton<FakeStaffAccessRepository>(() => FakeStaffAccessRepository(today: getIt<Clock>().today, now: getIt<Clock>().now))
      ..registerLazySingleton<StaffAccessRepository>(getIt.call<FakeStaffAccessRepository>)
      ..registerLazySingleton<StaffDirectory>(getIt.call<FakeStaffAccessRepository>)
      ..registerLazySingleton<TreatmentRepository>(() => FakeTreatmentRepository(getIt<Clock>()))
      ..registerLazySingleton<HomeRepository>(
        () => FakeHomeRepository(
          getIt<Clock>(),
          getIt<TreatmentRepository>(),
          breeding: getIt<BreedingRepository>(),
          feed: getIt<FeedRepository>(),
          workers: getIt<WorkersRepository>(),
        ),
      )
      ..registerLazySingleton<MilkRepository>(() => FakeMilkRepository(getIt<Clock>(), getIt<TreatmentRepository>()))
      ..registerLazySingleton<CentreRepository>(() => FakeCentreRepository(getIt<Clock>()))
      ..registerLazySingleton<MoneyRepository>(() => FakeMoneyRepository(getIt<Clock>()))
      ..registerLazySingleton<WorkersRepository>(
        () => FakeWorkersRepository(
          getIt<Clock>(),
          getIt<StaffDirectory>(),
          getIt<MoneyRepository>(),
          getIt<MilkRepository>(),
        ),
      )
      ..registerLazySingleton<FarmMoneyRepository>(
        () => FakeFarmMoneyRepository(getIt<Clock>(), getIt<MoneyRepository>(), getIt<MilkRepository>()),
      )
      ..registerLazySingleton<DailyReportRepository>(
        () => FakeDailyReportRepository(
          clock: getIt<Clock>(),
          farmName: () => getIt<SessionController>().farm?.name ?? '',
          home: getIt<HomeRepository>(),
          milk: getIt<MilkRepository>(),
          treatments: getIt<TreatmentRepository>(),
          feed: getIt<FeedRepository>(),
          money: getIt<FarmMoneyRepository>(),
        ),
      )
      ..registerLazySingleton<BreedingRepository>(
        () => FakeBreedingRepository(getIt<Clock>(), getIt<MoneyRepository>()),
      )
      ..registerLazySingleton<FeedRepository>(
        () => FakeFeedRepository(getIt<Clock>(), getIt<MilkRepository>(), getIt<MoneyRepository>()),
      )
      ..registerLazySingleton<HerdRepository>(
        () => FakeHerdRepository(
          clock: getIt<Clock>(),
          tenantProvider: tenants,
          treatments: getIt<TreatmentRepository>(),
          breeding: getIt<BreedingRepository>(),
        ),
      );
  } else {
    // Backend phase: real Firebase auth / membership repositories go here.
    final isarService = IsarService();
    await isarService.init();
    getIt
      ..registerSingleton<IsarService>(isarService)
      ..registerSingleton<LocalRecordStore>(IsarRecordStore(isarService.isar))
      ..registerLazySingleton<HerdRepository>(
        () => HerdRepositoryImpl(
          isar: isarService.isar,
          idGenerator: getIt<IdGenerator>(),
          clock: getIt<Clock>(),
          tenantProvider: tenants,
        ),
      );
  }

  await _configureOffline(tenants);

  getIt.registerLazySingleton(
    () => SessionController(auth: getIt<AuthRepository>(), clock: getIt<Clock>(), trialClock: getIt<TrustedClock>()),
  );

  // Herd use cases and bloc
  getIt
    ..registerLazySingleton(() => AddAnimal(getIt<HerdRepository>()))
    ..registerLazySingleton(() => WatchAnimals(getIt<HerdRepository>()))
    ..registerFactory(() => HerdBloc(watchAnimals: getIt<WatchAnimals>(), addAnimal: getIt<AddAnimal>()));
}

const _lastSeenKey = 'trustedClock.lastSeen';

/// Decision 0014: the phone's record store, the sync engine and the
/// rollback-proof trial clock. The demo build keeps records in memory; the
/// backend build stores them in Isar (registered above).
Future<void> _configureOffline(TenantProvider tenants) async {
  SharedPreferences? prefs;
  if (!useFakeData) prefs = await SharedPreferences.getInstance();
  final lastSeen = DateTime.tryParse(prefs?.getString(_lastSeenKey) ?? '');
  getIt.registerSingleton<TrustedClock>(
    TrustedClock(
      getIt<Clock>(),
      lastSeen: lastSeen,
      save: prefs == null ? null : (t) => unawaited(prefs!.setString(_lastSeenKey, t.toIso8601String())),
    ),
  );

  if (!getIt.isRegistered<LocalRecordStore>()) getIt.registerSingleton<LocalRecordStore>(MemoryRecordStore());

  final connectivity = DeviceConnectivity();
  await connectivity.start();
  getIt
    ..registerSingleton<ConnectivityMonitor>(connectivity)
    // Phase 2 replaces this with the Firestore adapter.
    ..registerSingleton<RemoteStore>(FakeRemoteStore())
    ..registerSingleton<SyncService>(
      SyncEngine(
        store: getIt<LocalRecordStore>(),
        remote: getIt<RemoteStore>(),
        connectivity: connectivity,
        clock: getIt<Clock>(),
        tenants: () => [tenants.currentTenantId],
        collections: syncedCollections,
      ),
    );
}

/// Every collection the phone pulls (ROADMAP 8, Dairy V1).
const List<String> syncedCollections = [
  ...MergePolicy.defaultAppendOnly,
  'animals',
  'animalGroups',
  'staff',
  'farmers',
  'nfcCards',
  'paymentPeriods',
  'farmerStatements',
  'deductions',
  'stockItems',
  'tasks',
  'reminders',
  'settings',
];
