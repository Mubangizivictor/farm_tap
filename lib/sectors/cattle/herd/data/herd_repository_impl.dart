import 'package:farm_tap/core/error/failure.dart';
import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/tenancy/tenant_provider.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/core/utils/id_generator.dart';
import 'package:farm_tap/sectors/cattle/herd/data/models/animal_model.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/entities/animal.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/herd_models.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/herd_repository.dart';
import 'package:isar_community/isar.dart';

class HerdRepositoryImpl implements HerdRepository {
  new({required this.isar, required this.idGenerator, required this.clock, required this.tenantProvider});

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
    return isar.animalModels.where().filter().isDeletedEqualTo(false).watch(fireImmediately: true).map((models) {
      try {
        final entities = models.map((m) => m.toEntity()).toList();
        return Result.success(entities);
      } on Exception catch (e) {
        return Result.failure(CacheFailure(e.toString()));
      }
    });
  }

  // Herd views and records beyond add/watch come with the backend phase
  // (useFakeData = true until then).
  static const _later = UnexpectedFailure('Not available until the backend phase');

  @override
  Future<Result<List<HerdRow>>> rows() async => const Result.failure(_later);

  @override
  Future<Result<HerdCounts>> counts() async => const Result.failure(_later);

  @override
  Future<Result<AnimalDetail?>> detail(String animalId) async => const Result.failure(_later);

  @override
  Future<Result<Animal?>> findByTag(String tag) async => const Result.failure(_later);

  @override
  List<String> get groups => const [];

  @override
  List<String> get breeds => const [];

  @override
  Future<Result<String>> nextTag() async => const Result.failure(_later);

  @override
  Future<Result<void>> recordDeath(String animalId, {String? cause}) async => const Result.failure(_later);

  @override
  Future<Result<Animal>> recordCalving(String motherId, {required DateTime at}) async => const Result.failure(_later);
}
