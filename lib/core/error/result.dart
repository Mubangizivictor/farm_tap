import 'package:farm_tap/core/error/failure.dart';

sealed class Result<T> {
  const new();

  const factory success(T data) = Success<T>;
  const factory failure(Failure failure) = FailureResult<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is FailureResult<T>;

  T? get data => switch (this) {
    Success(data: final d) => d,
    FailureResult() => null,
  };

  Failure? get failure => switch (this) {
    Success() => null,
    FailureResult(failure: final f) => f,
  };
}

class Success<T> extends Result<T> {
  const new(this.data);

  @override
  final T data;
}

class FailureResult<T> extends Result<T> {
  const new(this.failure);

  @override
  final Failure failure;
}
