import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/onboarding/domain/farm_setup.dart';
import 'package:farm_tap/core/tenancy/domain/farm_membership.dart';

/// Failure message when the account already owns as many farms as its plan
/// allows (one, unless on a multi-farm plan; decision 0018).
const farmLimitReached = 'farm-limit';

abstract interface class OnboardingRepository {
  /// Creates the farm and starts the free trial (B10).
  Future<Result<FarmMembership>> createFarm(FarmSetup setup);

  /// Day the free trial ends for a farm created now.
  DateTime trialEndsOn();

  /// Coming-soon sectors (B03): no payment, message when it opens.
  Future<Result<void>> joinWaitlist({required Sector sector, required String name, required String whatsapp});
}
