import 'package:farm_tap/app/di/injection.dart';
import 'package:farm_tap/app/session/session_controller.dart';
import 'package:farm_tap/core/onboarding/domain/onboarding_repository.dart';
import 'package:farm_tap/core/people/domain/staff_access_repository.dart';
import 'package:farm_tap/core/sync/sync_service.dart';
import 'package:farm_tap/core/tenancy/domain/farm_membership_repository.dart';
import 'package:farm_tap/sectors/cattle/collection_centre/domain/centre_repository.dart';
import 'package:farm_tap/sectors/cattle/health/domain/health_repository.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/herd_repository.dart';
import 'package:farm_tap/sectors/cattle/home/domain/home_repository.dart';
import 'package:farm_tap/sectors/cattle/milk/domain/milk_repository.dart';

/// Everything the router hands to pages (repositories behind domain
/// interfaces). Built from get_it in the app, from fakes in tests.
class AppDependencies {
  const new({
    required this.session,
    required this.places,
    required this.onboarding,
    required this.staffAccess,
    required this.sync,
    required this.home,
    required this.herd,
    required this.milk,
    required this.centre,
    required this.treatments,
  });

  factory fromGetIt() => AppDependencies(
    session: getIt<SessionController>(),
    places: getIt<FarmMembershipRepository>(),
    onboarding: getIt<OnboardingRepository>(),
    staffAccess: getIt<StaffAccessRepository>(),
    sync: getIt<SyncService>(),
    home: getIt<HomeRepository>(),
    herd: getIt<HerdRepository>(),
    milk: getIt<MilkRepository>(),
    centre: getIt<CentreRepository>(),
    treatments: getIt<TreatmentRepository>(),
  );

  final SessionController session;
  final FarmMembershipRepository places;
  final OnboardingRepository onboarding;
  final StaffAccessRepository staffAccess;
  final SyncService sync;
  final HomeRepository home;
  final HerdRepository herd;
  final MilkRepository milk;
  final CentreRepository centre;
  final TreatmentRepository treatments;
}
