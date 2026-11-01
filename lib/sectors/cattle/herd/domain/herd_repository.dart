import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/entities/animal.dart';

abstract class HerdRepository {
  Future<Result<void>> addAnimal(Animal animal);
  Stream<Result<List<Animal>>> watchAnimals();
}
