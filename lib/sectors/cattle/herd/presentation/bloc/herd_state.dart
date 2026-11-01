import 'package:equatable/equatable.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/entities/animal.dart';

enum HerdBlocStatus { initial, loading, success, failure }

class HerdState extends Equatable {
  const new({
    this.status = HerdBlocStatus.initial,
    this.animals = const [],
    this.errorMessage,
  });

  final HerdBlocStatus status;
  final List<Animal> animals;
  final String? errorMessage;

  HerdState copyWith({
    HerdBlocStatus? status,
    List<Animal>? animals,
    String? errorMessage,
  }) {
    return HerdState(
      status: status ?? this.status,
      animals: animals ?? this.animals,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, animals, errorMessage];
}
