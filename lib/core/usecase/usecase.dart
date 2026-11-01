import 'package:equatable/equatable.dart';
import 'package:farm_tap/core/error/result.dart';

abstract class UseCase<T, Params> {
  Future<Result<T>> call(Params params);
}

class NoParams extends Equatable {
  @override
  List<Object?> get props => [];
}
