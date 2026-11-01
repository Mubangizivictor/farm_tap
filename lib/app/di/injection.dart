import 'package:farm_tap/app/flavor.dart';
import 'package:farm_tap/core/audit/audit_logger.dart';
import 'package:farm_tap/core/auth/auth_repository.dart';
import 'package:farm_tap/core/database/isar_service.dart';
import 'package:farm_tap/core/sync/sync_service.dart';
import 'package:farm_tap/core/tenancy/tenant_provider.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/core/utils/id_generator.dart';
import 'package:farm_tap/core/utils/logger.dart';
import 'package:farm_tap/sectors/cattle/herd/data/herd_repository_impl.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/herd_repository.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/usecases/add_animal.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/usecases/watch_animals.dart';
import 'package:farm_tap/sectors/cattle/herd/presentation/bloc/herd_bloc.dart';
import 'package:get_it/get_it.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies(Flavor flavor) async {
  // Core Utils
  getIt
    ..registerLazySingleton<AppLogger>(LoggerImpl.new)
    ..registerLazySingleton<Clock>(SystemClock.new)
    ..registerLazySingleton<IdGenerator>(UuidGenerator.new);

  // Database
  final isarService = IsarService();
  await isarService.init();
  getIt
    ..registerSingleton<IsarService>(isarService)
    // Core Services (Interfaces & Fake/Dev Impls)
    ..registerLazySingleton<AuthRepository>(FakeAuthRepository.new)
    ..registerLazySingleton<TenantProvider>(InMemoryTenantProvider.new)
    ..registerLazySingleton<SyncService>(NoOpSyncService.new)
    ..registerLazySingleton<AuditLogger>(LocalAuditLogger.new);

  // Features - Herd
  getIt.registerLazySingleton<HerdRepository>(
    () => HerdRepositoryImpl(
      isar: getIt<IsarService>().isar,
      idGenerator: getIt<IdGenerator>(),
      clock: getIt<Clock>(),
      tenantProvider: getIt<TenantProvider>(),
    ),
  );

  // Use Cases
  getIt
    ..registerLazySingleton(() => AddAnimal(getIt<HerdRepository>()))
    ..registerLazySingleton(() => WatchAnimals(getIt<HerdRepository>()));

  // Blocs
  getIt.registerFactory(() => HerdBloc(watchAnimals: getIt<WatchAnimals>(), addAnimal: getIt<AddAnimal>()));
}
