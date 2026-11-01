import 'package:farm_tap/app/router/app_dependencies.dart';
import 'package:farm_tap/app/session/session_controller.dart';
import 'package:farm_tap/core/auth/data/fake/fake_auth_repository.dart';
import 'package:farm_tap/core/onboarding/data/fake/fake_onboarding_repository.dart';
import 'package:farm_tap/core/people/data/fake/fake_staff_access_repository.dart';
import 'package:farm_tap/core/sync/sync_service.dart';
import 'package:farm_tap/core/tenancy/data/fake/fake_farm_membership_repository.dart';
import 'package:farm_tap/core/tenancy/tenant_provider.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/sectors/cattle/home/data/fake/fake_home_repository.dart';

/// The mockups' "today": Saturday 7 Nov 2026, 6:52 am.
class FixedClock implements Clock {
  @override
  DateTime now() => DateTime(2026, 11, 7, 6, 52);
}

/// App dependencies built from fakes; optionally signed in with a farm open.
Future<AppDependencies> fakeDependencies({bool signedIn = false, bool farm = false}) async {
  final auth = FakeAuthRepository();
  if (signedIn) await auth.signInWithGoogle();
  final session = SessionController(auth: auth);
  if (farm) session.openFarm(FakeFarmMembershipRepository.places.first);
  final clock = SystemClock();
  return AppDependencies(
    session: session,
    places: FakeFarmMembershipRepository(InMemoryTenantProvider()),
    onboarding: FakeOnboardingRepository(clock),
    staffAccess: FakeStaffAccessRepository(),
    sync: FakeSyncService(),
    home: FakeHomeRepository(clock),
  );
}
