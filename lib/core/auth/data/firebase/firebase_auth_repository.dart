import 'dart:async';

import 'package:farm_tap/core/auth/domain/auth_repository.dart';
import 'package:farm_tap/core/auth/domain/entities/account_user.dart';
import 'package:farm_tap/core/error/failure.dart';
import 'package:farm_tap/core/error/result.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Firebase Auth: Google, Apple, email (binding rule 4; no phone sign-in).
///
/// Offline: Firebase keeps the signed-in account on the phone, so the farm
/// phone opens signed in with no network. Only the first sign-in, sign-up and
/// password reset need the internet.
class FirebaseAuthRepository implements AuthRepository {
  new([FirebaseAuth? auth]) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Failure message when the person closed the sign-in sheet.
  static const cancelled = 'cancelled';

  static AccountUser? _map(User? u) => u == null
      ? null
      : AccountUser(id: u.uid, name: u.displayName ?? '', email: u.email ?? '', emailVerified: u.emailVerified);

  @override
  Stream<AccountUser?> get userChanges => _auth.userChanges().map(_map);

  @override
  AccountUser? get currentUser => _map(_auth.currentUser);

  Future<Result<AccountUser>> _run(Future<UserCredential> Function() action) async {
    try {
      final cred = await action();
      return Result.success(_map(cred.user)!);
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign-in failed: ${e.code} ${e.message}');
      return Result.failure(_failure(e.code));
    } on PlatformException catch (e) {
      debugPrint('Sign-in failed: ${e.code} ${e.message}');
      return Result.failure(_failure(e.code));
    } on Object catch (e) {
      debugPrint('Sign-in failed: $e');
      return Result.failure(UnexpectedFailure('$e'));
    }
  }

  static Failure _failure(String code) => switch (code) {
    'network-request-failed' => NetworkFailure(code),
    'wrong-password' || 'invalid-credential' || 'user-not-found' || 'invalid-email' => ValidationFailure(code),
    'email-already-in-use' || 'weak-password' => ValidationFailure(code),
    'user-disabled' || 'operation-not-allowed' => PermissionFailure(code),
    // The person closed the Apple / Google sheet: not an error.
    'canceled' ||
    'cancelled' ||
    'web-context-canceled' ||
    'web-context-cancelled' ||
    'sign_in_canceled' => const ValidationFailure(cancelled),
    'account-exists-with-different-credential' => ValidationFailure(code),
    _ => UnexpectedFailure(code),
  };

  @override
  Future<Result<AccountUser>> signInWithGoogle() => _run(() => _auth.signInWithProvider(GoogleAuthProvider()));

  @override
  Future<Result<AccountUser>> signInWithApple() => _run(
    () => _auth.signInWithProvider(
      AppleAuthProvider()
        ..addScope('email')
        ..addScope('name'),
    ),
  );

  @override
  Future<Result<AccountUser>> signInWithEmail({required String email, required String password}) =>
      _run(() => _auth.signInWithEmailAndPassword(email: email.trim(), password: password));

  @override
  Future<Result<AccountUser>> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) => _run(() async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    await cred.user?.updateDisplayName(name.trim());
    await cred.user?.sendEmailVerification();
    await cred.user?.reload();
    return cred;
  });

  @override
  Future<Result<void>> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      // A05 never says whether the email exists; only a network problem shows.
      if (e.code == 'network-request-failed') return Result.failure(NetworkFailure(e.code));
    }
    return const Result.success(null);
  }

  @override
  Future<Result<void>> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
      return const Result.success(null);
    } on FirebaseAuthException catch (e) {
      return Result.failure(_failure(e.code));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    await _auth.signOut();
    return const Result.success(null);
  }
}
