import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/onboarding/domain/farm_setup.dart';
import 'package:farm_tap/core/onboarding/domain/onboarding_repository.dart';
import 'package:farm_tap/core/tenancy/domain/farm_membership.dart';
import 'package:farm_tap/core/utils/clock.dart';

/// UI phase: creates the farm in memory. The sample date in the mockups is
/// Sat 7 Nov 2026, so the trial ends 21 Nov 2026.
class FakeOnboardingRepository implements OnboardingRepository {
  new(this.clock);

  final Clock clock;

  @override
  DateTime trialEndsOn() {
    final now = clock.now();
    return DateTime(now.year, now.month, now.day + freeTrialDays);
  }

  @override
  Future<Result<FarmMembership>> createFarm(FarmSetup setup) async => Result.success(
    FarmMembership(
      tenantId: 'farm-${setup.farmName.toLowerCase().replaceAll(' ', '-')}',
      name: setup.farmName,
      place: setup.district ?? '',
      kind: setup.dairyType == DairyType.centre ? PlaceKind.collectionCentre : PlaceKind.dairyFarm,
      role: setup.role == SetupRole.owner ? PlaceRole.owner : PlaceRole.manager,
      // A new farm's own trial: today + freeTrialDays (never another farm's date).
      subscription: Subscription(trialStartedAt: clock.today(), trialEndsAt: trialEndsOn()),
    ),
  );

  @override
  Future<Result<void>> joinWaitlist({required Sector sector, required String name, required String whatsapp}) async =>
      const Result.success(null);
}
