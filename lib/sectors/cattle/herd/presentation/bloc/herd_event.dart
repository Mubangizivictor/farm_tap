import 'package:equatable/equatable.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/entities/animal.dart';

sealed class HerdEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class WatchAnimalsRequested extends HerdEvent {
  const new();
}

class AnimalsUpdated extends HerdEvent {
  const new(this.animals);
  final List<Animal> animals;

  @override
  List<Object?> get props => [animals];
}

class AddAnimalRequested extends HerdEvent {
  const new(this.animal);
  final Animal animal;

  @override
  List<Object?> get props => [animal];
}
