import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/tenancy/domain/farm_membership.dart';

abstract interface class FarmMembershipRepository {
  /// Farms and centres the signed-in account can open.
  Future<Result<List<FarmMembership>>> myPlaces();

  /// Makes [tenantId] the current tenant.
  Future<Result<void>> open(String tenantId);
}
