import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farm_tap/core/auth/domain/entities/account_user.dart';
import 'package:farm_tap/core/error/failure.dart';
import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/onboarding/data/fake/fake_onboarding_repository.dart';
import 'package:farm_tap/core/onboarding/domain/farm_setup.dart';
import 'package:farm_tap/core/onboarding/domain/onboarding_repository.dart';
import 'package:farm_tap/core/tenancy/domain/farm_membership.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/core/utils/id_generator.dart';

/// B01–B10 on Firestore. Creating the farm needs the internet once (like
/// the first sign-in); everything after works offline.
class FirestoreOnboardingRepository implements OnboardingRepository {
  new({required this.db, required this.clock, required this.ids, required this.uid, this.account});

  final FirebaseFirestore db;
  final Clock clock;
  final IdGenerator ids;
  final String? Function() uid;

  /// Who signed up (name and email for the admin panel's tenant list).
  final AccountUser? Function()? account;

  static const _wait = Duration(seconds: 10); // theme-guard: ignore (network timing, not UI)

  @override
  List<String> get districts => FakeOnboardingRepository(clock).districts;

  @override
  DateTime trialEndsOn() {
    final t = clock.today();
    return DateTime(t.year, t.month, t.day + 14);
  }

  @override
  Future<Result<FarmMembership>> createFarm(FarmSetup setup) async {
    final me = uid();
    if (me == null) return const Result.failure(PermissionFailure('signed-out'));
    final id = ids.generate();
    final role = setup.role == SetupRole.owner ? PlaceRole.owner : PlaceRole.manager;
    final start = clock.today();
    final end = trialEndsOn();
    final centre = setup.dairyType == DairyType.centre;
    try {
      final tenant = db.collection('tenants').doc(id);
      // In order: the rules check the farm exists before the membership.
      await tenant.set({
        'ownerUid': me,
        'name': setup.farmName.trim(),
        'type': centre ? 'centre' : (setup.dairyType == DairyType.both ? 'both' : 'farm'),
        'sector': setup.sector.name,
        'district': setup.district,
        'place': setup.district ?? '',
        'village': setup.village,
        'herdSizeRange': setup.herdSize?.name,
        'contacts': {
          'whatsapp': setup.whatsapp,
          'sms': setup.smsSameAsWhatsapp ? setup.whatsapp : setup.sms,
          'dailyReport': setup.dailyReport,
          'smsAlerts': setup.smsAlerts,
        },
        'settings': {'language': setup.languageCode},
        'subscription': {'trialStartedAt': Timestamp.fromDate(start), 'trialEndsAt': Timestamp.fromDate(end)},
        'createdAt': FieldValue.serverTimestamp(),
        'owner': {'uid': me, 'name': account?.call()?.name ?? '', 'email': account?.call()?.email ?? ''},
        // Victorbee reviews every new farm in the admin panel; the farm
        // works on its trial meanwhile. Only the server changes this.
        'review': {'status': 'pending'},
      });
      await tenant.collection('members').doc(me).set({'role': role.name});
      await db.collection('users').doc(me).set({
        'memberships': FieldValue.arrayUnion([
          {'tenantId': id, 'role': role.name},
        ]),
        'language': setup.languageCode,
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      return Result.failure(e.code == 'unavailable' ? NetworkFailure(e.code) : UnexpectedFailure(e.code));
    }
    return Result.success(
      FarmMembership(
        tenantId: id,
        name: setup.farmName.trim(),
        place: setup.district ?? '',
        kind: centre ? PlaceKind.collectionCentre : PlaceKind.dairyFarm,
        role: role,
        subscription: Subscription(trialStartedAt: start, trialEndsAt: end),
      ),
    );
  }

  @override
  Future<Result<void>> joinWaitlist({required Sector sector, required String name, required String whatsapp}) async {
    try {
      // Offline: Firestore keeps sending it while the app is open; the user
      // does not wait on a weak signal.
      await db
          .collection('waitlist')
          .add({
            'sector': sector.name,
            'name': name,
            'whatsapp': whatsapp,
            'uid': uid(),
            'createdAt': FieldValue.serverTimestamp(),
          })
          .timeout(_wait, onTimeout: () => db.collection('waitlist').doc());
      return const Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(NetworkFailure(e.code));
    }
  }
}
