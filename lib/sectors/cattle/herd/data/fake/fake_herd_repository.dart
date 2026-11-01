import 'dart:async';

import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/tenancy/tenant_provider.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/entities/animal.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/herd_models.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/herd_repository.dart';

/// In-memory herd for the UI phase (useFakeData = true), seeded with the
/// sample cows from the mockups. The Isar repository (HerdRepositoryImpl)
/// replaces it in the backend phase without touching the UI.
class FakeHerdRepository implements HerdRepository {
  new({required this.clock, required this.tenantProvider}) {
    _animals = [for (final s in _seed) _animal(s)];
    _milk = {for (final s in _seed) 'animal-${s.tag}': s.milk};
  }

  final Clock clock;
  final TenantProvider tenantProvider;
  late List<Animal> _animals;
  late Map<String, double?> _milk;
  var _nextTag = 49;
  final _controller = StreamController<Result<List<Animal>>>.broadcast();

  DateTime get _today {
    final n = clock.now();
    return DateTime(n.year, n.month, n.day);
  }

  List<Animal> get _alive => [
    for (final a in _animals)
      if (!a.isDeleted) a,
  ];

  @override
  Future<Result<void>> addAnimal(Animal animal) async {
    _animals = [..._animals, animal];
    _controller.add(Result.success(List.unmodifiable(_alive)));
    return const Result.success(null);
  }

  @override
  Stream<Result<List<Animal>>> watchAnimals() async* {
    yield Result.success(List.unmodifiable(_alive));
    yield* _controller.stream;
  }

  @override
  Future<Result<List<HerdRow>>> rows() async =>
      Result.success([for (final a in _alive) HerdRow(animal: a, milkToday: _milk[a.id])]);

  @override
  Future<Result<HerdCounts>> counts() async => const Result.success(
    HerdCounts(
      total: 48,
      milking: 41,
      dry: 7,
      treated: 2,
      pregnant: 9,
      heifers: 6,
      calves: 6,
      bulls: 1,
      bornThisMonth: 2,
      boughtThisMonth: 1,
      soldThisMonth: 1,
      diedThisMonth: 0,
    ),
  );

  @override
  Future<Result<Animal?>> findByTag(String tag) async {
    for (final a in _alive) {
      if (a.tagNumber == tag) return Result.success(a);
    }
    return const Result.success(null);
  }

  @override
  Future<Result<AnimalDetail?>> detail(String animalId) async {
    final matches = _animals.where((a) => a.id == animalId);
    if (matches.isEmpty) return const Result.success(null);
    final a = matches.first;
    final treated = a.dairyStatus == DairyStatus.treated;
    final day = _today;
    return Result.success(
      AnimalDetail(
        animal: a,
        avgMilk: treated ? 11.4 : (_milk[a.id] ?? 0) * 0.62,
        daysInMilk: treated ? 142 : 96,
        pregnancyCheckDue: day.subtract(const Duration(days: 5)),
        withdrawal: treated ? Withdrawal(drug: 'Penicillin', until: day.add(const Duration(days: 5))) : null,
        timeline: [
          if (treated)
            TreatmentEvent(
              at: day.add(const Duration(hours: 9)),
              drug: 'Penicillin',
              reason: 'Mastitis',
              vet: 'Dr. Kamugisha',
              safeFrom: day.add(const Duration(days: 5)),
            ),
          MilkEvent(at: day.subtract(const Duration(hours: 6)), morning: 6, evening: 5.2),
          ServiceEvent(
            at: day.subtract(const Duration(days: 36)),
            method: 'AI',
            straw: 'Friesian 4421',
            by: 'Twinomujuni',
          ),
          VaccinationEvent(at: day.subtract(const Duration(days: 50)), name: 'FMD', batch: '22-117'),
        ],
      ),
    );
  }

  @override
  List<String> get groups => const ['Paddock 1', 'Paddock 2', 'Paddock 3', 'Calf pen'];

  @override
  List<String> get breeds => const [
    'Friesian',
    'Friesian cross',
    'Jersey',
    'Jersey cross',
    'Ankole',
    'Ankole cross',
    'Guernsey',
  ];

  @override
  Future<Result<String>> nextTag() async => Result.success('FT-${_nextTag.toString().padLeft(3, '0')}');

  @override
  Future<Result<void>> recordDeath(String animalId, {String? cause}) async {
    _animals = [
      for (final a in _animals)
        if (a.id == animalId) _copy(a, deleted: true) else a,
    ];
    _controller.add(Result.success(List.unmodifiable(_alive)));
    return const Result.success(null);
  }

  @override
  Future<Result<Animal>> recordCalving(String motherId, {required DateTime at}) async {
    final mother = _animals.firstWhere((a) => a.id == motherId);
    _nextTag++;
    final tag = 'FT-${_nextTag.toString().padLeft(3, '0')}';
    final calf = Animal(
      id: 'animal-$tag',
      tenantId: tenantProvider.currentTenantId,
      tagNumber: tag,
      name: '',
      sex: AnimalSex.female,
      breed: mother.breed,
      dateOfBirth: at,
      status: AnimalStatus.active,
      createdAt: at,
      updatedAt: at,
      createdBy: 'staff',
      updatedBy: 'staff',
      deviceId: 'fake-device',
      syncStatus: SyncStatus.pending,
      dairyStatus: DairyStatus.calf,
      group: 'Calf pen',
      motherTag: mother.tagNumber,
    );
    await addAnimal(calf);
    return Result.success(calf);
  }

  Animal _copy(Animal a, {required bool deleted}) => Animal(
    id: a.id,
    tenantId: a.tenantId,
    tagNumber: a.tagNumber,
    name: a.name,
    sex: a.sex,
    breed: a.breed,
    dateOfBirth: a.dateOfBirth,
    status: deleted ? AnimalStatus.deceased : a.status,
    createdAt: a.createdAt,
    updatedAt: clock.now(),
    createdBy: a.createdBy,
    updatedBy: 'staff',
    deviceId: a.deviceId,
    syncStatus: SyncStatus.pending,
    isDeleted: deleted,
    dairyStatus: a.dairyStatus,
    avatarIndex: a.avatarIndex,
    group: a.group,
    motherTag: a.motherTag,
  );

  Animal _animal(_SeedCow s) {
    final now = clock.now();
    return Animal(
      id: 'animal-${s.tag}',
      tenantId: tenantProvider.currentTenantId,
      tagNumber: s.tag,
      name: s.name,
      sex: AnimalSex.female,
      breed: s.breed,
      dateOfBirth: DateTime(now.year - s.ageYears, now.month, now.day),
      status: AnimalStatus.active,
      createdAt: now,
      updatedAt: now,
      createdBy: 'seed',
      updatedBy: 'seed',
      deviceId: 'fake-device',
      syncStatus: SyncStatus.synced,
      dairyStatus: s.status,
      avatarIndex: s.avatar,
      group: s.group,
    );
  }
}

class _SeedCow {
  const new(this.tag, this.name, this.breed, this.ageYears, this.status, this.avatar, this.milk, this.group);

  final String tag;
  final String name;
  final String breed;
  final int ageYears;
  final DairyStatus status;
  final int avatar;
  final double? milk;
  final String group;
}

const _seed = [
  _SeedCow('FT-014', 'Bihogo', 'Friesian cross', 5, DairyStatus.milking, 1, 18.5, 'Paddock 1'),
  _SeedCow('FT-022', 'Kasheshe', 'Ankole', 7, DairyStatus.treated, 2, null, 'Paddock 1'),
  _SeedCow('FT-031', 'Kyasiimire', 'Jersey cross', 4, DairyStatus.pregnant, 3, 9, 'Paddock 2'),
  _SeedCow('FT-008', 'Ngabire', 'Friesian', 6, DairyStatus.milking, 4, 16.2, 'Paddock 1'),
  _SeedCow('FT-045', 'Rwemera', 'Ankole cross', 3, DairyStatus.heifer, 5, null, 'Paddock 3'),
  _SeedCow('FT-019', 'Kaaka', 'Friesian cross', 8, DairyStatus.dry, 6, null, 'Paddock 3'),
  _SeedCow('FT-027', 'Nyinamwiza', 'Jersey', 5, DairyStatus.milking, 1, 14.8, 'Paddock 2'),
  _SeedCow('FT-033', 'Kahara', 'Ankole', 4, DairyStatus.milking, 3, 12.1, 'Paddock 2'),
];
