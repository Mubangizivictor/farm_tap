import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/onboarding/domain/farm_setup.dart';
import 'package:farm_tap/core/tenancy/domain/farm_membership.dart';

abstract interface class OnboardingRepository {
  /// Districts offered on B06 (Western Uganda first).
  List<String> get districts;

  /// Creates the farm and starts the 14-day trial (B10).
  Future<Result<FarmMembership>> createFarm(FarmSetup setup);

  /// Day the free trial ends for a farm created now.
  DateTime trialEndsOn();

  /// Coming-soon sectors (B03): no payment, message when it opens.
  Future<Result<void>> joinWaitlist({required Sector sector, required String name, required String whatsapp});
}
