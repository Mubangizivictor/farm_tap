import 'package:equatable/equatable.dart';
import 'package:farm_tap/core/error/failure.dart';
import 'package:farm_tap/core/error/result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum AuthActionStatus { idle, busy, failed, done }

class AuthActionState extends Equatable {
  const new({this.status = AuthActionStatus.idle, this.failure});

  final AuthActionStatus status;
  final Failure? failure;

  bool get busy => status == AuthActionStatus.busy;

  @override
  List<Object?> get props => [status, failure];
}

/// Runs one account action at a time (sign in, sign up, reset, resend) and
/// reports busy / failed / done to the page. Shared by A02-A06.
class AuthActionCubit extends Cubit<AuthActionState> {
  new() : super(const AuthActionState());

  Future<Result<T>?> run<T>(Future<Result<T>> Function() action) async {
    if (state.busy) return null;
    emit(const AuthActionState(status: AuthActionStatus.busy));
    final result = await action();
    if (isClosed) return result;
    emit(
      result.isSuccess
          ? const AuthActionState(status: AuthActionStatus.done)
          : AuthActionState(status: AuthActionStatus.failed, failure: result.failure),
    );
    return result;
  }
}
