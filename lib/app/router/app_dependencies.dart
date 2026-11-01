import 'package:farm_tap/app/di/injection.dart';
import 'package:farm_tap/app/session/session_controller.dart';
import 'package:farm_tap/core/onboarding/domain/onboarding_repository.dart';
import 'package:farm_tap/core/people/domain/staff_access_repository.dart';
import 'package:farm_tap/core/sync/sync_service.dart';
import 'package:farm_tap/core/tenancy/domain/farm_membership_repository.dart';
import 'package:farm_tap/sectors/cattle/home/domain/home_repository.dart';

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
  });

  factory fromGetIt() => AppDependencies(
    session: getIt<SessionController>(),
    places: getIt<FarmMembershipRepository>(),
    onboarding: getIt<OnboardingRepository>(),
    staffAccess: getIt<StaffAccessRepository>(),
    sync: getIt<SyncService>(),
    home: getIt<HomeRepository>(),
  );

  final SessionController session;
  final FarmMembershipRepository places;
  final OnboardingRepository onboarding;
  final StaffAccessRepository staffAccess;
  final SyncService sync;
  final HomeRepository home;
}
