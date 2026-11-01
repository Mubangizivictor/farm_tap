import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/tenancy/domain/farm_membership.dart';
import 'package:farm_tap/core/tenancy/domain/farm_membership_repository.dart';
import 'package:farm_tap/core/tenancy/tenant_provider.dart';

/// Sample places from the mockups (A07).
class FakeFarmMembershipRepository implements FarmMembershipRepository {
  new(this._tenants);

  final InMemoryTenantProvider _tenants;

  /// Both trials: started Mon 2 Nov 2026, end Mon 16 Nov (9 days left and
  /// 5 of 14 used on the demo date, Sat 7 Nov).
  static final places = [
    FarmMembership(
      tenantId: 'farm-rwemera',
      name: 'Rwemera Dairy Farm',
      place: 'Mbarara',
      kind: PlaceKind.dairyFarm,
      role: PlaceRole.owner,
      subscription: Subscription(trialStartedAt: DateTime(2026, 11, 2), trialEndsAt: DateTime(2026, 11, 16)),
    ),
    FarmMembership(
      tenantId: 'centre-kashari',
      name: 'Kashari Milk Centre',
      place: 'Kashari',
      kind: PlaceKind.collectionCentre,
      role: PlaceRole.manager,
      subscription: Subscription(trialStartedAt: DateTime(2026, 11, 2), trialEndsAt: DateTime(2026, 11, 16)),
    ),
  ];

  @override
  Future<Result<List<FarmMembership>>> myPlaces() async => Result.success(places);

  @override
  Future<Result<void>> open(String tenantId) async {
    _tenants.currentTenantId = tenantId;
    return const Result.success(null);
  }
}
