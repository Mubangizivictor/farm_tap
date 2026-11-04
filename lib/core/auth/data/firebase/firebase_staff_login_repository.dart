import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farm_tap/core/auth/domain/staff_login_repository.dart';
import 'package:farm_tap/core/error/failure.dart';
import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/people/domain/staff_member.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Staff phone + PIN sign-in on the free Firebase plan (decision 0016 §5).
///
/// Each worker gets a Firebase email/password login made from their phone
/// number: `p<phone>v<n>@staff.farmtap.app`. The manager's phone makes it in
/// a second Firebase app so the manager stays signed in, and writes
/// - `users/{uid}` (as the new worker): the farm and "must change PIN",
/// - `tenants/{t}/members/{uid}`: role and staffId (security rules trust it),
/// - `staffLogins/{phone}`: the current login version, read before sign-in.
/// A PIN reset makes login version n+1 and removes the old membership.
class FirebaseStaffLoginRepository implements StaffLoginRepository {
  new({FirebaseAuth? auth, FirebaseFirestore? db})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  static const domain = 'staff.farmtap.app';
  static const _setupApp = 'farmtap-staff-setup';

  static String email(String phone, int version) => 'p${phone}v$version@$domain';

  /// Firebase needs 6+ characters; the phone makes each worker's differ.
  static String password(String pin, String phone) => 'FarmTap-$pin-$phone';

  static bool isStaffEmail(String? email) => email != null && email.endsWith('@$domain');

  /// The phone digits inside a staff login email.
  static String? phoneOf(String? email) {
    if (!isStaffEmail(email)) return null;
    final m = RegExp(r'^p(\d{9})v\d+@').firstMatch(email!);
    return m?.group(1);
  }

  static String _placeRole(StaffRole r) => switch (r) {
    StaffRole.manager => 'manager',
    StaffRole.clerk => 'clerk',
    _ => 'worker',
  };

  DocumentReference<Map<String, dynamic>> _login(String phone) => _db.collection('staffLogins').doc(phone);

  Future<FirebaseApp> _secondApp() async {
    for (final a in Firebase.apps) {
      if (a.name == _setupApp) return a;
    }
    return await Firebase.initializeApp(name: _setupApp, options: Firebase.app().options);
  }

  @override
  Future<Result<void>> createLogin({
    required String tenantId,
    required String staffId,
    required String name,
    required String phone,
    required String pin,
    required StaffRole role,
  }) async {
    final digits = ugPhoneDigits(phone);
    if (digits == null) return const Result.failure(ValidationFailure('phone'));
    try {
      final existing = await _login(digits).get(const GetOptions(source: Source.server));
      final old = existing.data();
      if (old != null && old['tenantId'] != tenantId) {
        return const Result.failure(ValidationFailure(StaffLoginError.otherFarm));
      }
      var version = ((old?['v'] as int?) ?? 0) + 1;
      final app = await _secondApp();
      final auth2 = FirebaseAuth.instanceFor(app: app);
      UserCredential? cred;
      // A half-made earlier try may have used this version: move on.
      for (var tries = 0; cred == null && tries < 3; tries++) {
        try {
          cred = await auth2.createUserWithEmailAndPassword(
            email: email(digits, version),
            password: password(pin, digits),
          );
        } on FirebaseAuthException catch (e) {
          if (e.code != 'email-already-in-use') rethrow;
          version++;
        }
      }
      if (cred == null) return const Result.failure(UnexpectedFailure('staff-login-version'));
      final uid = cred.user!.uid;
      await cred.user!.updateDisplayName(name);
      // Written as the new worker (only they may write their user doc).
      await FirebaseFirestore.instanceFor(app: app).collection('users').doc(uid).set({
        'name': name,
        'memberships': [
          {'tenantId': tenantId},
        ],
        'staffLogin': {'tenantId': tenantId, 'staffId': staffId, 'mustChangePin': true},
      });
      await auth2.signOut();
      final members = _db.collection('tenants').doc(tenantId).collection('members');
      await members.doc(uid).set({
        'role': _placeRole(role),
        'staffId': staffId,
        'name': name,
        'phone': digits,
        'createdAt': FieldValue.serverTimestamp(),
      });
      final oldUid = old?['uid'] as String?;
      if (oldUid != null && oldUid != uid) {
        try {
          await members.doc(oldUid).delete();
        } on Object catch (e) {
          debugPrint('Old staff login not removed: $e');
        }
      }
      await _login(digits).set({'tenantId': tenantId, 'staffId': staffId, 'uid': uid, 'v': version});
      return const Result.success(null);
    } on FirebaseAuthException catch (e) {
      debugPrint('Staff login not made: ${e.code}');
      return Result.failure(_failure(e.code));
    } on FirebaseException catch (e) {
      debugPrint('Staff login not made: ${e.code}');
      return Result.failure(_failure(e.code));
    } on Object catch (e) {
      return Result.failure(UnexpectedFailure('$e'));
    }
  }

  static Failure _failure(String code) => switch (code) {
    'network-request-failed' || 'unavailable' => const NetworkFailure(StaffLoginError.offline),
    'too-many-requests' => const ValidationFailure(StaffLoginError.tooMany),
    'wrong-password' ||
    'invalid-credential' ||
    'user-not-found' ||
    'invalid-email' => const ValidationFailure(StaffLoginError.wrong),
    'permission-denied' => PermissionFailure(code),
    _ => UnexpectedFailure(code),
  };

  @override
  Future<Result<StaffSignIn>> signIn({required String phone, required String pin}) async {
    final digits = ugPhoneDigits(phone);
    if (digits == null) return const Result.failure(ValidationFailure(StaffLoginError.wrong));
    try {
      final login = (await _login(digits).get(const GetOptions(source: Source.server))).data();
      if (login == null) return const Result.failure(ValidationFailure(StaffLoginError.wrong));
      final cred = await _auth.signInWithEmailAndPassword(
        email: email(digits, login['v'] as int? ?? 1),
        password: password(pin, digits),
      );
      final user = await _db.collection('users').doc(cred.user!.uid).get(const GetOptions(source: Source.server));
      final staff = (user.data()?['staffLogin'] as Map?) ?? const {};
      return Result.success(
        StaffSignIn(
          mustChangePin: staff['mustChangePin'] == true,
          tenantId: staff['tenantId'] as String? ?? login['tenantId'] as String,
          staffId: staff['staffId'] as String? ?? login['staffId'] as String,
        ),
      );
    } on FirebaseAuthException catch (e) {
      return Result.failure(_failure(e.code));
    } on FirebaseException catch (e) {
      return Result.failure(_failure(e.code));
    } on Object catch (e) {
      return Result.failure(UnexpectedFailure('$e'));
    }
  }

  @override
  Future<Result<void>> changePin(String newPin) async {
    final user = _auth.currentUser;
    final digits = phoneOf(user?.email);
    if (user == null || digits == null) return const Result.failure(PermissionFailure('not-staff'));
    try {
      await user.updatePassword(password(newPin, digits));
      await _db.collection('users').doc(user.uid).set({
        'staffLogin': {'mustChangePin': false},
      }, SetOptions(merge: true));
      return const Result.success(null);
    } on FirebaseAuthException catch (e) {
      return Result.failure(_failure(e.code));
    } on FirebaseException catch (e) {
      return Result.failure(_failure(e.code));
    }
  }
}
