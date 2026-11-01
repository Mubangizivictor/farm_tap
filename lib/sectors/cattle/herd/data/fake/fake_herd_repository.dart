import 'dart:async';

import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/tenancy/tenant_provider.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/entities/animal.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/herd_repository.dart';

/// In-memory herd for the UI phase (useFakeData = true), seeded with the
/// sample cows from the mockups. The Isar repository (HerdRepositoryImpl)
/// replaces it in the backend phase without touching the UI.
class FakeHerdRepository implements HerdRepository {
  new({required this.clock, required this.tenantProvider}) {
    _animals = [for (final s in _seed) _animal(s)];
  }

  final Clock clock;
  final TenantProvider tenantProvider;
  late List<Animal> _animals;
  final _controller = StreamController<Result<List<Animal>>>.broadcast();

  @override
  Future<Result<void>> addAnimal(Animal animal) async {
    _animals = [..._animals, animal];
    _controller.add(Result.success(List.unmodifiable(_animals)));
    return const Result.success(null);
  }

  @override
  Stream<Result<List<Animal>>> watchAnimals() async* {
    yield Result.success(List.unmodifiable(_animals));
    yield* _controller.stream;
  }

  Animal _animal(_SeedCow s) {
    final now = clock.now();
    return Animal(
      id: 'animal-${s.tag}',
      tenantId: tenantProvider.currentTenantId,
      tagNumber: s.tag,
      name: s.name,
      sex: AnimalSex.female,
      breed: s.breed,
      dateOfBirth: DateTime(now.year - s.ageYears, now.month),
      status: AnimalStatus.active,
      createdAt: now,
      updatedAt: now,
      createdBy: 'seed',
      updatedBy: 'seed',
      deviceId: 'fake-device',
      syncStatus: SyncStatus.synced,
    );
  }
}

class _SeedCow {
  const new(this.tag, this.name, this.breed, this.ageYears);

  final String tag;
  final String name;
  final String breed;
  final int ageYears;
}

const _seed = [
  _SeedCow('FT-014', 'Bihogo', 'Friesian cross', 5),
  _SeedCow('FT-022', 'Kasheshe', 'Ankole', 7),
  _SeedCow('FT-031', 'Kyasiimire', 'Jersey cross', 4),
  _SeedCow('FT-008', 'Ngabire', 'Friesian', 6),
  _SeedCow('FT-045', 'Rwemera', 'Ankole cross', 3),
  _SeedCow('FT-019', 'Kaaka', 'Friesian cross', 8),
  _SeedCow('FT-027', 'Nyinamwiza', 'Jersey', 5),
  _SeedCow('FT-033', 'Kahara', 'Ankole', 4),
];
