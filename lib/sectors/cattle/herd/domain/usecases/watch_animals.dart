import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/entities/animal.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/herd_repository.dart';

class WatchAnimals {
  const new(this.repository);

  final HerdRepository repository;

  Stream<Result<List<Animal>>> call() {
    return repository.watchAnimals();
  }
}
