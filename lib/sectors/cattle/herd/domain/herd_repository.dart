import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/entities/animal.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/herd_models.dart';

abstract class HerdRepository {
  Future<Result<void>> addAnimal(Animal animal);
  Stream<Result<List<Animal>>> watchAnimals();

  /// Herd list rows with today's milk (E01).
  Future<Result<List<HerdRow>>> rows();
  Future<Result<HerdCounts>> counts();
  Future<Result<AnimalDetail?>> detail(String animalId);
  Future<Result<Animal?>> findByTag(String tag);

  /// Paddocks and pens (E02).
  List<String> get groups;

  /// Breeds offered on E04.
  List<String> get breeds;

  /// Next free tag number, e.g. "FT-049".
  Future<Result<String>> nextTag();

  /// E08: the animal moves to "Past animals"; records are kept.
  Future<Result<void>> recordDeath(String animalId, {String? cause});

  /// E07: a calf is added and linked to its mother; returns the calf.
  Future<Result<Animal>> recordCalving(String motherId, {required DateTime at});
}
