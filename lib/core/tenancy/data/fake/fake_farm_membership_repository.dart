import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/tenancy/domain/farm_membership.dart';
import 'package:farm_tap/core/tenancy/domain/farm_membership_repository.dart';
import 'package:farm_tap/core/tenancy/tenant_provider.dart';

/// Sample places from the mockups (A07).
class FakeFarmMembershipRepository implements FarmMembershipRepository {
  new(this._tenants);

  final InMemoryTenantProvider _tenants;

  static const places = [
    FarmMembership(
      tenantId: 'farm-rwemera',
      name: 'Rwemera Dairy Farm',
      place: 'Mbarara',
      kind: PlaceKind.dairyFarm,
      role: PlaceRole.owner,
      subscription: SubscriptionState.active,
    ),
    FarmMembership(
      tenantId: 'centre-kashari',
      name: 'Kashari Milk Centre',
      place: 'Kashari',
      kind: PlaceKind.collectionCentre,
      role: PlaceRole.manager,
      subscription: SubscriptionState.trial,
      trialDaysLeft: 9,
    ),
  ];

  @override
  Future<Result<List<FarmMembership>>> myPlaces() async => const Result.success(places);

  @override
  Future<Result<void>> open(String tenantId) async {
    _tenants.currentTenantId = tenantId;
    return const Result.success(null);
  }
}
