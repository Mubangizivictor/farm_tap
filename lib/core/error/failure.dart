import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const new([this.message = '']);
  final String message;

  @override
  List<Object?> get props => [message];
}

class CacheFailure extends Failure {
  const new([super.message]);
}

class NetworkFailure extends Failure {
  const new([super.message]);
}

class ValidationFailure extends Failure {
  const new([super.message]);
}

class PermissionFailure extends Failure {
  const new([super.message]);
}

class UnexpectedFailure extends Failure {
  const new([super.message]);
}
