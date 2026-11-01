import 'package:farm_tap/core/error/failure.dart';
import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/tenancy/tenant_provider.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/core/utils/id_generator.dart';
import 'package:farm_tap/sectors/cattle/herd/data/models/animal_model.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/entities/animal.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/herd_repository.dart';
import 'package:isar/isar.dart';

class HerdRepositoryImpl implements HerdRepository {
  new({
    required this.isar,
    required this.idGenerator,
    required this.clock,
    required this.tenantProvider,
  });

  final Isar isar;
  final IdGenerator idGenerator;
  final Clock clock;
  final TenantProvider tenantProvider;

  @override
  Future<Result<void>> addAnimal(Animal animal) async {
    try {
      final model = AnimalModel.fromEntity(animal);
      await isar.writeTxn(() async {
        await isar.animalModels.put(model);
      });
      return const Result.success(null);
    } on Exception catch (e) {
      return Result.failure(CacheFailure(e.toString()));
    }
  }

  @override
  Stream<Result<List<Animal>>> watchAnimals() {
    return isar.animalModels
        .where()
        .filter()
        .isDeletedEqualTo(false)
        .watch(fireImmediately: true)
        .map((models) {
      try {
        final entities = models.map((m) => m.toEntity()).toList();
        return Result.success(entities);
      } on Exception catch (e) {
        return Result.failure(CacheFailure(e.toString()));
      }
    });
  }
}
