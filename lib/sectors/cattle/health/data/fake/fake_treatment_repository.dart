import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/sync/record_journal.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/sectors/cattle/health/domain/health_models.dart';
import 'package:farm_tap/sectors/cattle/health/domain/health_repository.dart';

/// UI phase: the H01-H06 sample treatments. Milk, herd and home fakes read
/// withdrawal from this one store.
class FakeTreatmentRepository implements TreatmentRepository {
  new(this.clock, {this.journal}) {
    final now = clock.now();
    final today = DateTime(now.year, now.month, now.day);
    _records = [
      TreatmentRecord(
        id: 'treat-1',
        animalId: 'animal-FT-022',
        animalName: 'Kasheshe',
        tag: 'FT-022',
        avatarIndex: 2,
        condition: Condition.mastitis,
        drug: penStrep,
        // Penicillin 8 Nov + 4 days withdrawal -> safe from Thu 12 Nov.
        given: today.add(const Duration(days: 1, hours: 9)),
        courseDays: 3,
        dose: '20 ml',
        givenBy: 'Dr. Kamugisha Ivan',
      ),
      TreatmentRecord(
        id: 'treat-2',
        animalId: 'animal-FT-019',
        animalName: 'Kaaka',
        tag: 'FT-019',
        avatarIndex: 6,
        condition: Condition.lame,
        note: 'hoof treatment',
        drug: oxy,
        given: today.subtract(const Duration(days: 2)),
        courseDays: 3,
        animalDry: true,
      ),
      TreatmentRecord(
        id: 'treat-3',
        animalId: 'animal-FT-045',
        animalName: 'Rwemera',
        tag: 'FT-045',
        avatarIndex: 5,
        condition: Condition.wound,
        note: 'spray daily',
        drug: woundSpray,
        given: today.subtract(const Duration(days: 1)),
        courseDays: 5,
        route: DrugRoute.spray,
      ),
    ];
    _schedule = [
      HealthTask(
        kind: HealthTaskKind.dipping,
        title: 'Dipping — whole herd',
        detail: 'Acaricide · Twinomujuni',
        due: today.add(const Duration(days: 6)),
      ),
      HealthTask(
        kind: HealthTaskKind.deworming,
        title: 'Deworming — calves',
        detail: 'Albendazole · 6 calves',
        due: today.add(const Duration(days: 8)),
      ),
      HealthTask(
        kind: HealthTaskKind.vaccination,
        title: 'FMD booster',
        detail: 'All animals · vet visit',
        due: today.add(const Duration(days: 25)),
      ),
      HealthTask(
        kind: HealthTaskKind.vaccination,
        title: 'Lumpy skin vaccination',
        detail: 'Heifers · 6',
        due: today.add(const Duration(days: 30)),
      ),
    ];
  }

  final Clock clock;

  /// Saves records on the phone for sync (decision 0014); null in tests.
  final RecordJournal? journal;
  late List<TreatmentRecord> _records;
  late List<HealthTask> _schedule;
  late List<Drug> _drugList = List.of(_drugs);
  int _next = 4;

  static const penStrep = Drug(
    id: 'drug-penstrep',
    name: 'Penicillin-Streptomycin',
    shortName: 'Penicillin',
    withdrawalDays: 4,
    stock: 6,
    reorderAt: 2,
  );
  static const oxy = Drug(
    id: 'drug-oxy',
    name: 'Oxytetracycline 20%',
    shortName: 'Oxytetracycline',
    withdrawalDays: 8,
    stock: 1,
    reorderAt: 2,
  );
  static const albendazole = Drug(
    id: 'drug-albendazole',
    name: 'Albendazole dewormer',
    shortName: 'Albendazole',
    withdrawalDays: 3,
    stock: 2,
    unit: DrugUnit.litres,
  );
  static const acaricide = Drug(
    id: 'drug-acaricide',
    name: 'Acaricide (dip)',
    shortName: 'Acaricide',
    withdrawalDays: 0,
    stock: 5,
    unit: DrugUnit.litres,
  );
  static const woundSpray = Drug(
    id: 'drug-spray',
    name: 'Wound spray',
    shortName: 'Wound spray',
    withdrawalDays: 0,
    stock: 1,
    inStockList: false,
  );
  static const List<Drug> _drugs = [penStrep, oxy, albendazole, acaricide, woundSpray];

  static const _animals = [
    TreatableAnimal(id: 'animal-FT-022', name: 'Kasheshe', tag: 'FT-022', avatarIndex: 2),
    TreatableAnimal(id: 'animal-FT-014', name: 'Bihogo', tag: 'FT-014', avatarIndex: 1),
    TreatableAnimal(id: 'animal-FT-008', name: 'Ngabire', tag: 'FT-008', avatarIndex: 4),
    TreatableAnimal(id: 'animal-FT-019', name: 'Kaaka', tag: 'FT-019', avatarIndex: 6, dry: true),
    TreatableAnimal(id: 'animal-FT-027', name: 'Nyinamwiza', tag: 'FT-027', avatarIndex: 1),
  ];

  @override
  Future<Result<List<TreatmentRecord>>> treatments() async => Result.success(List.unmodifiable(_records));

  @override
  Future<Result<List<TreatmentRecord>>> withdrawals(DateTime now) async => Result.success(
    [
      for (final r in _records)
        if (r.inWithdrawal(now)) r,
    ]..sort((a, b) => a.safeFrom.compareTo(b.safeFrom)),
  );

  @override
  Future<Result<TreatmentRecord?>> withdrawalFor(String animalId, DateTime now) async =>
      Result.success(_records.where((r) => r.animalId == animalId && r.inWithdrawal(now)).firstOrNull);

  @override
  Future<Result<List<Drug>>> drugs() async => Result.success(List.unmodifiable(_drugList));

  @override
  Future<Result<List<TreatableAnimal>>> animals() async => const Result.success(_animals);

  @override
  Future<Result<TreatmentRecord>> addTreatment(NewTreatment input) async {
    final a = _animals.firstWhere((a) => a.id == input.animalId);
    final record = TreatmentRecord(
      id: journal?.newId() ?? 'treat-${_next++}',
      animalId: a.id,
      animalName: a.name,
      tag: a.tag,
      avatarIndex: a.avatarIndex,
      condition: input.condition,
      drug: _drugList.firstWhere((d) => d.id == input.drugId),
      given: input.given,
      courseDays: 3,
      animalDry: a.dry,
      dose: input.dose,
      route: input.route,
      givenBy: input.givenBy,
    );
    // One open course per animal: the new record replaces the old one.
    _records = [record, ..._records.where((r) => r.animalId != a.id)];
    await journal?.add('treatments', {
      'animalId': a.id,
      'condition': input.condition.name,
      'drugId': input.drugId,
      'withdrawalDays': record.drug.withdrawalDays,
      'given': input.given.toIso8601String(),
      'dose': input.dose,
      'route': input.route.name,
      'givenBy': input.givenBy,
    }, id: record.id);
    return Result.success(record);
  }

  @override
  Future<Result<List<HealthTask>>> schedule() async => Result.success(_schedule);

  @override
  Future<Result<void>> addTask(HealthTask task) async {
    _schedule = [..._schedule, task]..sort((a, b) => a.due.compareTo(b.due));
    await journal?.add('reminders', {'kind': 'health', 'title': task.title, 'due': task.due.toIso8601String()});
    return const Result.success(null);
  }

  @override
  Future<Result<Drug>> addDrug({required String name, required double stock, required int withdrawalDays}) async {
    final drug = Drug(
      id: journal?.newId() ?? 'drug-${_next++}',
      name: name,
      shortName: name.split(' ').first,
      withdrawalDays: withdrawalDays,
      stock: stock,
    );
    _drugList = [..._drugList, drug];
    await journal?.add('stockItems', {
      'kind': 'drug',
      'name': name,
      'stock': stock,
      'withdrawalDays': withdrawalDays,
    }, id: drug.id);
    return Result.success(drug);
  }

  @override
  List<String> get vets => const ['Dr. Kamugisha Ivan', 'Twinomujuni Amos', 'Muhwezi Robert'];
}
