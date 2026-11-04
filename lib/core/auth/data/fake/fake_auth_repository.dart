import 'dart:async';

import 'package:farm_tap/core/auth/domain/auth_repository.dart';
import 'package:farm_tap/core/auth/domain/entities/account_user.dart';
import 'package:farm_tap/core/error/failure.dart';
import 'package:farm_tap/core/error/result.dart';

/// In-memory sign-in for the UI phase (useFakeData). Any Google / Apple
/// sign-in succeeds as the sample owner; email sign-in needs a password of
/// at least 8 characters.
class FakeAuthRepository implements AuthRepository {
  final _controller = StreamController<AccountUser?>.broadcast();
  AccountUser? _user;

  static const sampleOwner = AccountUser(
    id: 'user-muhwezi',
    name: 'Muhwezi Robert',
    email: 'muhwezi.robert@gmail.com',
    emailVerified: true,
  );

  @override
  Stream<AccountUser?> get userChanges => _controller.stream;

  @override
  AccountUser? get currentUser => _user;

  Result<AccountUser> _set(AccountUser user) {
    _user = user;
    _controller.add(user);
    return Result.success(user);
  }

  /// A worker signed in with phone + PIN (FakeStaffLoginRepository).
  void signInAs(AccountUser user) => _set(user);

  @override
  Future<Result<AccountUser>> signInWithGoogle() async => _set(sampleOwner);

  @override
  Future<Result<AccountUser>> signInWithApple() async => _set(sampleOwner);

  @override
  Future<Result<AccountUser>> signInWithEmail({required String email, required String password}) async {
    if (password.length < 8) return const Result.failure(ValidationFailure('wrong-password'));
    return _set(AccountUser(id: 'user-$email', name: sampleOwner.name, email: email, emailVerified: true));
  }

  @override
  Future<Result<AccountUser>> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async => _set(AccountUser(id: 'user-$email', name: name, email: email));

  @override
  Future<Result<void>> sendPasswordReset(String email) async => const Result.success(null);

  @override
  Future<Result<void>> sendEmailVerification() async => const Result.success(null);

  @override
  Future<Result<void>> signOut() async {
    _user = null;
    _controller.add(null);
    return const Result.success(null);
  }
}
