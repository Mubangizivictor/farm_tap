import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/tenancy/domain/farm_membership.dart';

abstract interface class FarmMembershipRepository {
  /// Farms and centres the signed-in account can open.
  Future<Result<List<FarmMembership>>> myPlaces();

  /// Makes [tenantId] the current tenant and remembers it on this phone.
  Future<Result<void>> open(String tenantId);

  /// The farm this account opened last on this phone (null on a new phone),
  /// so a returning person goes straight in.
  Future<String?> lastOpened();

  /// How many farms this account may own: [defaultFarmLimit], more only on
  /// a multi-farm plan (decision 0015).
  Future<int> farmLimit();
}
