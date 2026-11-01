import 'package:farm_tap/core/auth/domain/entities/account_user.dart';
import 'package:farm_tap/core/error/result.dart';

/// Account sign-in: Google, Apple or email only (ROADMAP binding rule 12).
/// No phone-number sign-in or OTP.
abstract interface class AuthRepository {
  Stream<AccountUser?> get userChanges;
  AccountUser? get currentUser;

  Future<Result<AccountUser>> signInWithGoogle();
  Future<Result<AccountUser>> signInWithApple();
  Future<Result<AccountUser>> signInWithEmail({required String email, required String password});
  Future<Result<AccountUser>> signUpWithEmail({required String name, required String email, required String password});

  /// Always succeeds from the user's point of view (A05 never reveals
  /// whether the email exists).
  Future<Result<void>> sendPasswordReset(String email);
  Future<Result<void>> sendEmailVerification();
  Future<Result<void>> signOut();
}
