import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farm_tap/app/flavor.dart';
import 'package:farm_tap/app/session/session_controller.dart';
import 'package:farm_tap/core/audit/audit_logger.dart';
import 'package:farm_tap/core/auth/data/fake/fake_auth_repository.dart';
import 'package:farm_tap/core/auth/data/firebase/firebase_auth_repository.dart';
import 'package:farm_tap/core/auth/domain/auth_repository.dart';
import 'package:farm_tap/core/database/isar_service.dart';
import 'package:farm_tap/core/media/photo_store.dart';
import 'package:farm_tap/core/money/data/fake/fake_money_repository.dart';
import 'package:farm_tap/core/money/domain/money_repository.dart';
import 'package:farm_tap/core/onboarding/data/fake/fake_onboarding_repository.dart';
import 'package:farm_tap/core/onboarding/data/firebase/firestore_onboarding_repository.dart';
import 'package:farm_tap/core/onboarding/domain/onboarding_repository.dart';
import 'package:farm_tap/core/people/data/fake/fake_staff_access_repository.dart';
import 'package:farm_tap/core/people/domain/staff_access_repository.dart';
import 'package:farm_tap/core/people/domain/staff_directory.dart';
import 'package:farm_tap/core/people/domain/staff_member.dart';
import 'package:farm_tap/core/sms/sms_outbox.dart';
import 'package:farm_tap/core/sync/connectivity_monitor.dart';
import 'package:farm_tap/core/sync/data/fake/fake_remote_store.dart';
import 'package:farm_tap/core/sync/data/firestore_remote_store.dart';
import 'package:farm_tap/core/sync/data/isar/isar_record_store.dart';
import 'package:farm_tap/core/sync/data/memory_record_store.dart';
import 'package:farm_tap/core/sync/domain/local_record_store.dart';
import 'package:farm_tap/core/sync/domain/merge_policy.dart';
import 'package:farm_tap/core/sync/domain/remote_store.dart';
import 'package:farm_tap/core/sync/record_journal.dart';
import 'package:farm_tap/core/sync/sync_engine.dart';
import 'package:farm_tap/core/sync/sync_service.dart';
import 'package:farm_tap/core/tenancy/data/fake/fake_farm_membership_repository.dart';
import 'package:farm_tap/core/tenancy/data/firebase/firestore_farm_membership_repository.dart';
import 'package:farm_tap/core/tenancy/domain/farm_membership_repository.dart';
import 'package:farm_tap/core/tenancy/tenant_provider.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/core/utils/id_generator.dart';
import 'package:farm_tap/core/utils/logger.dart';
import 'package:farm_tap/core/utils/trusted_clock.dart';
import 'package:farm_tap/firebase_options.dart';
import 'package:farm_tap/sectors/cattle/breeding/data/fake/fake_breeding_repository.dart';
import 'package:farm_tap/sectors/cattle/breeding/domain/breeding_repository.dart';
import 'package:farm_tap/sectors/cattle/collection_centre/data/fake/fake_centre_repository.dart';
import 'package:farm_tap/sectors/cattle/collection_centre/domain/centre_repository.dart';
import 'package:farm_tap/sectors/cattle/feeding/data/fake/fake_feed_repository.dart';
import 'package:farm_tap/sectors/cattle/feeding/domain/feeding_repository.dart';
import 'package:farm_tap/sectors/cattle/health/data/fake/fake_treatment_repository.dart';
import 'package:farm_tap/sectors/cattle/health/data/local/local_treatment_repository.dart';
import 'package:farm_tap/sectors/cattle/health/domain/health_repository.dart';
import 'package:farm_tap/sectors/cattle/herd/data/fake/fake_herd_repository.dart';
import 'package:farm_tap/sectors/cattle/herd/data/local/local_herd_repository.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/herd_repository.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/usecases/add_animal.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/usecases/watch_animals.dart';
import 'package:farm_tap/sectors/cattle/herd/presentation/bloc/herd_bloc.dart';
import 'package:farm_tap/sectors/cattle/home/data/fake/fake_home_repository.dart';
import 'package:farm_tap/sectors/cattle/home/domain/home_repository.dart';
import 'package:farm_tap/sectors/cattle/milk/data/fake/fake_milk_repository.dart';
import 'package:farm_tap/sectors/cattle/milk/data/local/local_milk_repository.dart';
import 'package:farm_tap/sectors/cattle/milk/domain/milk_repository.dart';
import 'package:farm_tap/sectors/cattle/money/data/fake/fake_farm_money_repository.dart';
import 'package:farm_tap/sectors/cattle/money/domain/farm_money_repository.dart';
import 'package:farm_tap/sectors/cattle/owner_reports/data/fake/fake_daily_report_repository.dart';
import 'package:farm_tap/sectors/cattle/owner_reports/domain/daily_report.dart';
import 'package:farm_tap/sectors/cattle/workers/data/fake/fake_workers_repository.dart';
import 'package:farm_tap/sectors/cattle/workers/domain/workers_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GetIt getIt = GetIt.instance;

/// The demo build: in-memory repositories with the mockup sample data, no
/// Firebase. Run it with `--dart-define=FARMTAP_DEMO=true`. The normal build
/// signs in with Firebase and starts every farm empty (decision 0014).
const bool demoBuild = bool.fromEnvironment('FARMTAP_DEMO');

bool _demo = demoBuild;

/// True in the demo build and in widget/golden tests.
bool get useFakeData => _demo;

/// [demo] defaults to the build setting; tests pass true.
Future<void> configureDependencies(Flavor flavor, {bool demo = demoBuild}) async {
  _demo = demo;
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
      ..registerLazySingleton<TreatmentRepository>(
        () => FakeTreatmentRepository(getIt<Clock>(), journal: getIt<RecordJournal>()),
      )
      ..registerLazySingleton<MilkRepository>(
        () => FakeMilkRepository(getIt<Clock>(), getIt<TreatmentRepository>(), journal: getIt<RecordJournal>()),
      )
      ..registerLazySingleton<HerdRepository>(
        () => FakeHerdRepository(
          clock: getIt<Clock>(),
          tenantProvider: tenants,
          treatments: getIt<TreatmentRepository>(),
          breeding: getIt<BreedingRepository>(),
          journal: getIt<RecordJournal>(),
        ),
      );
  } else {
    // Backend phase (decision 0014): Firebase project farm-tap-1dd15.
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    final db = FirebaseFirestore.instance;
    FirestoreRemoteStore.configure(db);
    final prefs = await SharedPreferences.getInstance();
    final auth = FirebaseAuthRepository();
    String? uid() => auth.currentUser?.id;
    final isarService = IsarService();
    await isarService.init();
    getIt
      ..registerSingleton<IsarService>(isarService)
      ..registerSingleton<LocalRecordStore>(IsarRecordStore(isarService.isar))
      ..registerSingleton<RemoteStore>(FirestoreRemoteStore(db))
      ..registerSingleton<AuthRepository>(auth)
      ..registerLazySingleton<FarmMembershipRepository>(
        () => FirestoreFarmMembershipRepository(db: db, uid: uid, prefs: prefs, tenants: tenants),
      )
      ..registerLazySingleton<OnboardingRepository>(
        () => FirestoreOnboardingRepository(
          db: db,
          clock: getIt<Clock>(),
          ids: getIt<IdGenerator>(),
          uid: uid,
          account: () => auth.currentUser,
        ),
      )
      // Real data: calculated from the farm's records, no samples.
      ..registerLazySingleton<TreatmentRepository>(
        () => LocalTreatmentRepository(
          journal: getIt<RecordJournal>(),
          clock: getIt<Clock>(),
          herd: getIt.call<HerdRepository>,
          me: _me,
          money: getIt.call<MoneyRepository>,
        ),
      )
      ..registerLazySingleton<MilkRepository>(
        () => LocalMilkRepository(
          journal: getIt<RecordJournal>(),
          clock: getIt<Clock>(),
          treatments: getIt<TreatmentRepository>(),
          herd: getIt.call<HerdRepository>,
        ),
      )
      ..registerLazySingleton<HerdRepository>(
        () => LocalHerdRepository(
          journal: getIt<RecordJournal>(),
          clock: getIt<Clock>(),
          treatments: getIt<TreatmentRepository>(),
          breeding: getIt<BreedingRepository>(),
          milk: getIt.call<MilkRepository>,
          money: getIt.call<MoneyRepository>,
        ),
      );
  }

  // Shared by both builds: the demo starts them with the mockup samples; the
  // Firebase build starts them empty and fills them from the farm's records.
  final samples = useFakeData;
  getIt
    ..registerLazySingleton<FakeStaffAccessRepository>(
      () => FakeStaffAccessRepository(
        today: getIt<Clock>().today,
        now: getIt<Clock>().now,
        journal: getIt<RecordJournal>(),
        withSamples: samples,
      ),
    )
    ..registerLazySingleton<StaffAccessRepository>(getIt.call<FakeStaffAccessRepository>)
    ..registerLazySingleton<StaffDirectory>(getIt.call<FakeStaffAccessRepository>)
    ..registerLazySingleton<HomeRepository>(
      () => FakeHomeRepository(
        getIt<Clock>(),
        getIt<TreatmentRepository>(),
        breeding: getIt<BreedingRepository>(),
        feed: getIt<FeedRepository>(),
        workers: getIt<WorkersRepository>(),
        herd: samples ? null : getIt<HerdRepository>(),
        milk: samples ? null : getIt<MilkRepository>(),
      ),
    )
    ..registerLazySingleton<CentreRepository>(
      () => FakeCentreRepository(
        getIt<Clock>(),
        journal: getIt<RecordJournal>(),
        sms: samples ? null : SmsOutbox(getIt<RecordJournal>()),
        withSamples: samples,
        verifyPin: samples ? null : _managerPinOk,
      ),
    )
    ..registerLazySingleton<MoneyRepository>(
      () => FakeMoneyRepository(getIt<Clock>(), journal: getIt<RecordJournal>(), withSamples: samples),
    )
    ..registerLazySingleton<WorkersRepository>(
      () => FakeWorkersRepository(
        getIt<Clock>(),
        getIt<StaffDirectory>(),
        getIt<MoneyRepository>(),
        getIt<MilkRepository>(),
        journal: getIt<RecordJournal>(),
        withSamples: samples,
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
        journal: getIt<RecordJournal>(),
        withSamples: samples,
      ),
    )
    ..registerLazySingleton<BreedingRepository>(
      () => FakeBreedingRepository(
        getIt<Clock>(),
        getIt<MoneyRepository>(),
        journal: getIt<RecordJournal>(),
        herd: samples ? null : getIt.call<HerdRepository>,
        me: samples ? null : _me,
      ),
    )
    ..registerLazySingleton<FeedRepository>(
      () => FakeFeedRepository(
        getIt<Clock>(),
        getIt<MilkRepository>(),
        getIt<MoneyRepository>(),
        journal: getIt<RecordJournal>(),
        withSamples: samples,
      ),
    );

  await _configureOffline(tenants);

  getIt.registerLazySingleton(
    () => SessionController(auth: getIt<AuthRepository>(), clock: getIt<Clock>(), trialClock: getIt<TrustedClock>()),
  );
  if (!useFakeData) {
    // No farm is open until the person picks or creates one.
    tenants.currentTenantId = '';
    _followOpenFarm(tenants);
  }

  // Herd use cases and bloc
  getIt
    ..registerLazySingleton(() => AddAnimal(getIt<HerdRepository>()))
    ..registerLazySingleton(() => WatchAnimals(getIt<HerdRepository>()))
    ..registerFactory(() => HerdBloc(watchAnimals: getIt<WatchAnimals>(), addAnimal: getIt<AddAnimal>()));
}

/// Longest a first download holds the farm list before opening anyway.
const _farmDownloadLimit = Duration(seconds: 45); // theme-guard: ignore

/// Opening a farm (A07). Its saved records come back; a phone that has
/// never downloaded this farm (a new phone, or the app reinstalled) first
/// pulls everything, so the first screens show the farm, not an empty one.
/// Offline it opens with what the phone has and the download follows.
Future<void> prepareFarmRecords(String tenantId) async {
  final tenants = getIt<TenantProvider>();
  if (tenants is InMemoryTenantProvider) tenants.currentTenantId = tenantId;
  final store = getIt<LocalRecordStore>();
  Future<bool> fresh() async {
    for (final c in syncedCollections) {
      if (await store.cursor(tenantId, c) != null) return false;
    }
    return true;
  }

  if (!useFakeData && await fresh() && getIt<ConnectivityMonitor>().online) {
    final sync = getIt<SyncService>();
    try {
      await sync.sync().timeout(_farmDownloadLimit);
      // A sync already running when the farm opened may not have pulled it.
      if (await fresh()) await sync.sync().timeout(_farmDownloadLimit);
    } on Object {
      // Slow or lost network: open with what is here; sync carries on.
    }
  }
  await restoreSavedRecords();
}

/// Real data: when a farm opens, its records are the ones saved and synced;
/// the sections reload them, and again after each sync brings in records
/// from the farm's other phones.
void _followOpenFarm(InMemoryTenantProvider tenants) {
  final session = getIt<SessionController>();
  final sync = getIt<SyncService>();
  session.addListener(() {
    final id = session.farm?.tenantId;
    if (id == null) {
      // Signed out or back at the farm list: nothing to sync until one opens.
      tenants.currentTenantId = '';
      return;
    }
    if (id == tenants.currentTenantId) return;
    tenants.currentTenantId = id;
    unawaited(restoreSavedRecords().then((_) => sync.sync()));
  });
  // Photos upload under the open farm once Firebase Storage is switched on.
  PhotoStore.instance.tenantId = () => tenants.currentTenantId;
  unawaited(PhotoStore.instance.uploadPending());
  var wasSyncing = false;
  sync.watch().listen((s) {
    if (wasSyncing && !s.syncing && tenants.currentTenantId.isNotEmpty) {
      unawaited(restoreSavedRecords());
      unawaited(PhotoStore.instance.uploadPending());
    }
    wasSyncing = s.syncing;
  });
}

/// The person using the phone: the unlocked staff member, else the
/// signed-in account (its name, else its email). Never empty.
String _me() {
  final session = getIt<SessionController>();
  final user = session.auth.currentUser;
  final name = session.staff?.name ?? user?.name ?? '';
  if (name.isNotEmpty) return name;
  return (user?.email ?? '').isNotEmpty ? user!.email : 'Owner';
}

const _lastSeenKey = 'trustedClock.lastSeen';
const _deviceIdKey = 'device.id';

/// Decision 0014: the phone's record store, the sync engine and the
/// rollback-proof trial clock. The demo build keeps records in memory; the
/// backend build stores them in Isar (registered above).
Future<void> _configureOffline(TenantProvider tenants) async {
  SharedPreferences? prefs;
  if (!useFakeData) prefs = await SharedPreferences.getInstance();
  final lastSeen = DateTime.tryParse(prefs?.getString(_lastSeenKey) ?? '');
  // One id per installed app, on every record it makes (ROADMAP 5.1).
  final storedDeviceId = prefs?.getString(_deviceIdKey);
  final deviceId = storedDeviceId ?? (useFakeData ? 'demo-phone' : getIt<IdGenerator>().generate());
  if (storedDeviceId == null) await prefs?.setString(_deviceIdKey, deviceId);
  getIt.registerSingleton<TrustedClock>(
    TrustedClock(
      getIt<Clock>(),
      lastSeen: lastSeen,
      save: prefs == null ? null : (t) => unawaited(prefs!.setString(_lastSeenKey, t.toIso8601String())),
    ),
  );

  if (!getIt.isRegistered<LocalRecordStore>()) getIt.registerSingleton<LocalRecordStore>(MemoryRecordStore());
  getIt.registerLazySingleton<RecordJournal>(
    () => RecordJournal(
      store: getIt<LocalRecordStore>(),
      clock: getIt<Clock>(),
      ids: getIt<IdGenerator>(),
      deviceId: deviceId,
      tenantId: () => tenants.currentTenantId,
      actor: () {
        final session = getIt<SessionController>();
        return session.staff?.id ?? session.auth.currentUser?.id ?? 'unknown';
      },
    ),
  );
  // Demo build: a pretend cloud, so "Sync now" works without Firebase.
  if (!getIt.isRegistered<RemoteStore>()) getIt.registerSingleton<RemoteStore>(FakeRemoteStore());

  final connectivity = DeviceConnectivity();
  await connectivity.start();
  getIt
    ..registerSingleton<ConnectivityMonitor>(connectivity)
    ..registerSingleton<SyncService>(
      SyncEngine(
        store: getIt<LocalRecordStore>(),
        remote: getIt<RemoteStore>(),
        connectivity: connectivity,
        clock: getIt<Clock>(),
        // Nothing to send or pull until a farm is open.
        tenants: () => [if (tenants.currentTenantId.isNotEmpty) tenants.currentTenantId],
        collections: syncedCollections,
      ),
    );
}

/// Closing a centre session: a manager's PIN, or anyone signed in when the
/// farm has no manager yet (the owner closes it).
Future<bool> _managerPinOk(String pin) async {
  final directory = getIt<StaffDirectory>();
  final staff = (await directory.staff()).data ?? const <StaffMember>[];
  if (!staff.any((s) => s.role == StaffRole.manager)) return true;
  return (await directory.verifyManagerPin(pin)).data ?? false;
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
  'milkUse',
  'milkSalePayments',
  'reconciliations',
];

/// Reloads what was saved on this phone before the first screen shows
/// (decision 0014). Runs offline; a broken record never blocks start-up.
Future<void> restoreSavedRecords() async {
  final repos = <Object>[
    getIt<MoneyRepository>(),
    getIt<StaffAccessRepository>(),
    getIt<BreedingRepository>(),
    getIt<FeedRepository>(),
    getIt<WorkersRepository>(),
    getIt<HerdRepository>(),
    getIt<TreatmentRepository>(),
    getIt<MilkRepository>(),
    getIt<CentreRepository>(),
  ];
  for (final r in repos) {
    if (r is! Restorable) continue;
    try {
      await r.restore();
    } on Object catch (e, s) {
      getIt<AppLogger>().e('restore failed: ${r.runtimeType}', e, s);
    }
  }
}
