import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/usecase/usecase.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/entities/animal.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/herd_repository.dart';

class AddAnimal implements UseCase<void, Animal> {
  const new(this.repository);

  final HerdRepository repository;

  @override
  Future<Result<void>> call(Animal params) {
    return repository.addAnimal(params);
  }
}
