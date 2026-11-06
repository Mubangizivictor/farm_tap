import 'package:farm_tap/core/error/failure.dart';
import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/money/domain/money_models.dart';
import 'package:farm_tap/core/money/domain/money_repository.dart';
import 'package:farm_tap/core/sync/record_journal.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/sectors/cattle/health/data/fake/fake_treatment_repository.dart';
import 'package:farm_tap/sectors/cattle/health/domain/health_models.dart';
import 'package:farm_tap/sectors/cattle/health/domain/health_repository.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/entities/animal.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/herd_repository.dart';

/// Real-data treatments (decision 0014): everything comes from the records
/// saved on this phone (and pulled from other phones). No sample data.
class LocalTreatmentRepository implements TreatmentRepository {
  new({required this.journal, required this.clock, required this.herd, required this.me, this.money});

  /// Where bought drugs are recorded as a vet expense.
  final MoneyRepository Function()? money;

  final RecordJournal journal;
  final Clock clock;
  final HerdRepository Function() herd;

  /// The person using the phone: always offered as "Given by".
  final String Function() me;
  final _givenBy = <String>{};

  /// Common drugs offered from day one, with their usual withdrawal days.
  /// Stock starts at 0 until the farm records some.
  static final List<Drug> starterDrugs = [
    for (final d in [
      FakeTreatmentRepository.penStrep,
      FakeTreatmentRepository.oxy,
      FakeTreatmentRepository.albendazole,
      FakeTreatmentRepository.acaricide,
    ])
      Drug(
        id: d.id,
        name: d.name,
        shortName: d.shortName,
        withdrawalDays: d.withdrawalDays,
        stock: 0,
        unit: d.unit,
        reorderAt: d.reorderAt,
      ),
  ];

  Future<List<Drug>> _drugs() async {
    final saved = [
      for (final r in await journal.load('stockItems'))
        if (r.body['kind'] == 'drug')
          Drug(
            id: r.id,
            name: r.body['name'] as String? ?? '',
            shortName: (r.body['name'] as String? ?? '').split(' ').first,
            withdrawalDays: r.body['withdrawalDays'] as int? ?? 0,
            stock: (r.body['stock'] as num? ?? 0).toDouble(),
            unit: DrugUnit.values.asNameMap()[r.body['unit']] ?? DrugUnit.bottles,
            reorderAt: (r.body['reorderAt'] as num?)?.toDouble(),
          ),
    ];
    final ids = {for (final d in saved) d.id};
    return [...saved, ...starterDrugs.where((d) => !ids.contains(d.id))];
  }

  Future<List<TreatmentRecord>> _all() async {
    final drugs = {for (final d in await _drugs()) d.id: d};
    final out = <TreatmentRecord>[];
    for (final r in await journal.load('treatments')) {
      final b = r.body;
      final drug = drugs[b['drugId']];
      if (drug == null) continue;
      out.add(
        TreatmentRecord(
          id: r.id,
          animalId: b['animalId']! as String,
          animalName: b['animalName'] as String? ?? '',
          tag: b['tag'] as String? ?? '',
          avatarIndex: b['avatarIndex'] as int? ?? 1,
          condition: Condition.values.byName(b['condition']! as String),
          drug: Drug(
            id: drug.id,
            name: drug.name,
            shortName: drug.shortName,
            // The withdrawal at the time of treatment wins over later edits.
            withdrawalDays: b['withdrawalDays'] as int? ?? drug.withdrawalDays,
            stock: drug.stock,
            unit: drug.unit,
          ),
          given: DateTime.parse(b['given']! as String),
          courseDays: b['courseDays'] as int? ?? 1,
          animalDry: b['animalDry'] as bool? ?? false,
          dose: b['dose'] as String?,
          route: DrugRoute.values.byName(b['route'] as String? ?? DrugRoute.injection.name),
          givenBy: b['givenBy'] as String?,
          photo: b['photo'] as String?,
          note: b['note'] as String?,
        ),
      );
    }
    _givenBy.addAll([for (final r in out) ?r.givenBy]);
    return out..sort((a, b) => b.given.compareTo(a.given));
  }

  @override
  Future<Result<List<TreatmentRecord>>> treatments() async => Result.success(await _all());

  @override
  Future<Result<List<TreatmentRecord>>> withdrawals(DateTime now) async {
    // One open course per animal: its newest treatment counts.
    final seen = <String>{};
    final out = <TreatmentRecord>[];
    for (final r in await _all()) {
      if (!seen.add(r.animalId)) continue;
      if (r.inWithdrawal(now)) out.add(r);
    }
    return Result.success(out..sort((a, b) => a.safeFrom.compareTo(b.safeFrom)));
  }

  @override
  Future<Result<TreatmentRecord?>> withdrawalFor(String animalId, DateTime now) async {
    final latest = (await _all()).where((r) => r.animalId == animalId).firstOrNull;
    return Result.success(latest != null && latest.inWithdrawal(now) ? latest : null);
  }

  @override
  Future<Result<List<Drug>>> drugs() async => Result.success(await _drugs());

  @override
  Future<Result<List<TreatableAnimal>>> animals() async {
    final rows = (await herd().rows()).data ?? const [];
    return Result.success([
      for (final row in rows)
        TreatableAnimal(
          id: row.animal.id,
          name: row.animal.name.isEmpty ? row.animal.tagNumber : row.animal.name,
          tag: row.animal.tagNumber,
          avatarIndex: row.animal.avatarIndex,
          dry: row.animal.dairyStatus == DairyStatus.dry,
        ),
    ]);
  }

  @override
  Future<Result<TreatmentRecord>> addTreatment(NewTreatment input) async {
    final animal = ((await animals()).data ?? const <TreatableAnimal>[])
        .where((a) => a.id == input.animalId)
        .firstOrNull;
    final drug = (await _drugs()).where((d) => d.id == input.drugId).firstOrNull;
    if (animal == null || drug == null) return const Result.failure(ValidationFailure('unknown-animal-or-drug'));
    final id = await journal.add('treatments', {
      'animalId': animal.id,
      'animalName': animal.name,
      'tag': animal.tag,
      'avatarIndex': animal.avatarIndex,
      'animalDry': animal.dry,
      'condition': input.condition.name,
      'drugId': drug.id,
      'withdrawalDays': drug.withdrawalDays,
      'given': input.given.toIso8601String(),
      'courseDays': 3,
      'dose': input.dose,
      'route': input.route.name,
      'givenBy': input.givenBy,
      'photo': input.photo,
      'note': input.note,
    });
    return Result.success((await _all()).firstWhere((r) => r.id == id));
  }

  @override
  Future<Result<List<HealthTask>>> schedule() async {
    final out = <HealthTask>[
      for (final r in await journal.load('reminders'))
        if (r.body['kind'] == 'health' && r.body['done'] != true)
          HealthTask(
            id: r.id,
            kind: HealthTaskKind.values.asNameMap()[r.body['taskKind']] ?? HealthTaskKind.vaccination,
            title: r.body['title'] as String? ?? '',
            detail: r.body['detail'] as String? ?? '',
            due: DateTime.parse(r.body['due']! as String),
          ),
    ];
    return Result.success(out..sort((a, b) => a.due.compareTo(b.due)));
  }

  @override
  Future<Result<void>> setTaskDone(String taskId, {required bool done}) async {
    final r = await journal.store.get('reminders', taskId);
    if (r == null) return const Result.success(null);
    await journal.put('reminders', taskId, {...r.body, 'done': done, 'doneAt': clock.now().toIso8601String()});
    return const Result.success(null);
  }

  @override
  Future<Result<void>> addTask(HealthTask task) async {
    await journal.add('reminders', {
      'kind': 'health',
      'taskKind': task.kind.name,
      'title': task.title,
      'detail': task.detail,
      'due': task.due.toIso8601String(),
    });
    return const Result.success(null);
  }

  @override
  Future<Result<Drug>> addDrug({required String name, required double stock, required int withdrawalDays}) async {
    final id = await journal.add('stockItems', {
      'kind': 'drug',
      'name': name,
      'stock': stock,
      'withdrawalDays': withdrawalDays,
    });
    return Result.success(
      Drug(id: id, name: name, shortName: name.split(' ').first, withdrawalDays: withdrawalDays, stock: stock),
    );
  }

  Future<Map<String, Object?>> _drugBody(String drugId) async {
    final saved = await journal.store.get('stockItems', drugId);
    if (saved != null && !saved.isDeleted) return {...saved.body};
    final d = (await _drugs()).firstWhere((d) => d.id == drugId);
    return {
      'kind': 'drug',
      'name': d.name,
      'stock': d.stock,
      'withdrawalDays': d.withdrawalDays,
      'unit': d.unit.name,
      'reorderAt': d.reorderAt,
    };
  }

  @override
  Future<Result<void>> restockDrug(String drugId, {required double amount, int? price}) async {
    final body = await _drugBody(drugId);
    final stock = (body['stock'] as num? ?? 0).toDouble() + amount;
    await journal.put('stockItems', drugId, {...body, 'stock': stock});
    final movement = await journal.add('stockMovements', {
      'kind': 'drugPurchase',
      'drugId': drugId,
      'amount': amount,
      'price': price,
      'at': clock.now().toIso8601String(),
    });
    if (price != null && price > 0) {
      await money?.call().addExpense(
        category: ExpenseCategory.vet,
        amount: price,
        note: body['name'] as String?,
        sourceId: movement,
      );
    }
    return const Result.success(null);
  }

  @override
  Future<Result<void>> setDrugStock(String drugId, double stock) async {
    final body = await _drugBody(drugId);
    await journal.put('stockItems', drugId, {...body, 'stock': stock});
    return const Result.success(null);
  }

  /// The phone's user first, then everyone who treated an animal before.
  @override
  List<String> get vets => [me(), ..._givenBy.where((v) => v != me())];
}
