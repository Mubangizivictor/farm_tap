import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farm_tap/core/error/failure.dart';
import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/tenancy/domain/farm_membership.dart';
import 'package:farm_tap/core/tenancy/domain/farm_membership_repository.dart';
import 'package:farm_tap/core/tenancy/tenant_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The account's farms (A07) from Firestore, kept on the phone so the farm
/// list, the trial dates and read-only work with no network (decision 0014).
///
/// `users/{uid}.memberships` lists the farms; each farm's role comes from
/// `tenants/{t}/members/{uid}`, which the security rules trust.
class FirestoreFarmMembershipRepository implements FarmMembershipRepository {
  new({required this.db, required this.uid, required this.prefs, required this.tenants});

  final FirebaseFirestore db;
  final String? Function() uid;
  final SharedPreferences prefs;
  final InMemoryTenantProvider tenants;

  String _cacheKey(String uid) => 'places.$uid';

  @override
  Future<Result<List<FarmMembership>>> myPlaces() async {
    final me = uid();
    if (me == null) return const Result.failure(PermissionFailure('signed-out'));
    try {
      final places = await _fetch(me);
      await prefs.setString(_cacheKey(me), jsonEncode([for (final p in places) _toJson(p)]));
      return Result.success(places);
    } on Object {
      final cached = prefs.getString(_cacheKey(me));
      if (cached == null) return const Result.failure(NetworkFailure('no-places-offline'));
      final list = (jsonDecode(cached) as List).cast<Map<String, dynamic>>();
      return Result.success([for (final m in list) _fromJson(m)]);
    }
  }

  Future<List<FarmMembership>> _fetch(String me) async {
    const server = GetOptions(source: Source.server);
    final user = await db.collection('users').doc(me).get(server);
    final ids = ((user.data()?['memberships'] as List?) ?? const [])
        .map((m) => (m as Map)['tenantId'] as String)
        .toSet();
    final places = <FarmMembership>[];
    for (final id in ids) {
      final tenant = await db.collection('tenants').doc(id).get(server);
      final member = await db.collection('tenants').doc(id).collection('members').doc(me).get(server);
      if (!tenant.exists || !member.exists) continue;
      places.add(_fromTenant(id, tenant.data()!, member.data()!['role'] as String));
    }
    return places;
  }

  @override
  Future<Result<void>> open(String tenantId) async {
    tenants.currentTenantId = tenantId;
    await prefs.setString('places.open', tenantId);
    return const Result.success(null);
  }

  static FarmMembership _fromTenant(String id, Map<String, dynamic> t, String role) {
    final sub = (t['subscription'] as Map?) ?? const {};
    DateTime? date(Object? v) => v is Timestamp ? v.toDate() : null;
    return FarmMembership(
      tenantId: id,
      name: t['name'] as String? ?? '',
      place: t['place'] as String? ?? '',
      kind: t['type'] == 'centre' ? PlaceKind.collectionCentre : PlaceKind.dairyFarm,
      role: PlaceRole.values.asNameMap()[role] ?? PlaceRole.worker,
      subscription: Subscription(
        trialStartedAt: date(sub['trialStartedAt']),
        trialEndsAt: date(sub['trialEndsAt']),
        paidUntil: date(sub['paidUntil']),
      ),
      avatarIndex: t['avatarIndex'] as int? ?? 1,
    );
  }

  static Map<String, Object?> _toJson(FarmMembership p) => {
    'tenantId': p.tenantId,
    'name': p.name,
    'place': p.place,
    'kind': p.kind.name,
    'role': p.role.name,
    'trialStartedAt': p.subscription.trialStartedAt?.toIso8601String(),
    'trialEndsAt': p.subscription.trialEndsAt?.toIso8601String(),
    'paidUntil': p.subscription.paidUntil?.toIso8601String(),
    'avatarIndex': p.avatarIndex,
  };

  static FarmMembership _fromJson(Map<String, dynamic> m) {
    DateTime? date(Object? v) => v is String ? DateTime.tryParse(v) : null;
    return FarmMembership(
      tenantId: m['tenantId'] as String,
      name: m['name'] as String,
      place: m['place'] as String,
      kind: PlaceKind.values.byName(m['kind'] as String),
      role: PlaceRole.values.byName(m['role'] as String),
      subscription: Subscription(
        trialStartedAt: date(m['trialStartedAt']),
        trialEndsAt: date(m['trialEndsAt']),
        paidUntil: date(m['paidUntil']),
      ),
      avatarIndex: m['avatarIndex'] as int? ?? 1,
    );
  }
}
