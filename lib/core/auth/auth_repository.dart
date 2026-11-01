import 'package:farm_tap/core/error/result.dart';

abstract class AuthRepository {
  Future<Result<bool>> signIn(String phone, String pin);
  Future<Result<void>> signOut();
  Stream<bool> get authStateChanges;
}

class FakeAuthRepository implements AuthRepository {
  @override
  Future<Result<bool>> signIn(String phone, String pin) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return const Result.success(true);
  }

  @override
  Future<Result<void>> signOut() async {
    return const Result.success(null);
  }

  @override
  Stream<bool> get authStateChanges => Stream.value(true);
}
