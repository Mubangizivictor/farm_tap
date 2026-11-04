import 'dart:async';

import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/media/photo_store.dart';
import 'package:farm_tap/core/money/domain/money_models.dart';
import 'package:farm_tap/core/money/domain/money_repository.dart';
import 'package:farm_tap/core/sync/record_journal.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/sectors/cattle/breeding/domain/breeding_repository.dart';
import 'package:farm_tap/sectors/cattle/health/domain/health_models.dart';
import 'package:farm_tap/sectors/cattle/health/domain/health_repository.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/entities/animal.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/herd_models.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/herd_repository.dart';
import 'package:farm_tap/sectors/cattle/milk/domain/milk_models.dart';
import 'package:farm_tap/sectors/cattle/milk/domain/milk_repository.dart';

/// Real-data herd (decision 0014): animals saved on this phone or pulled from
/// the farm's other phones. Counts, milk and the timeline are calculated from
/// the records; nothing is sample data.
class LocalHerdRepository implements HerdRepository {
  new({
    required this.journal,
    required this.clock,
    required this.treatments,
    required this.breeding,
    required this.milk,
    this.money,
  });

  /// Where the price of a sold animal is recorded as income.
  final MoneyRepository Function()? money;

  final RecordJournal journal;
  final Clock clock;
  final TreatmentRepository treatments;
  final BreedingRepository breeding;
  final MilkRepository Function() milk;
  final _controller = StreamController<Result<List<Animal>>>.broadcast();

  static const _collection = 'animals';

  Future<List<Animal>> _all() async => [
    for (final r in await journal.store.all(journal.tenantId(), _collection, includeDeleted: true))
      Animal(
        id: r.id,
        tenantId: r.tenantId,
        tagNumber: r.body['tagNumber']! as String,
        name: r.body['name'] as String? ?? '',
        sex: AnimalSex.values.byName(r.body['sex']! as String),
        breed: r.body['breed'] as String? ?? '',
        dateOfBirth: DateTime.parse(r.body['dateOfBirth']! as String),
        status: AnimalStatus.values.asNameMap()[r.body['status']] ?? AnimalStatus.active,
        govIdTag: r.body['govIdTag'] as String?,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
        createdBy: r.createdBy,
        updatedBy: r.updatedBy,
        deviceId: r.deviceId,
        syncStatus: SyncStatus.values.byName(r.syncStatus.name),
        isDeleted:
            r.isDeleted || r.body['status'] == AnimalStatus.deceased.name || r.body['status'] == AnimalStatus.sold.name,
        dairyStatus: DairyStatus.values.asNameMap()[r.body['dairyStatus']] ?? DairyStatus.milking,
        avatarIndex: r.body['avatarIndex'] as int? ?? 1 + r.id.hashCode.abs() % 6,
        group: r.body['group'] as String?,
        motherTag: r.body['motherTag'] as String?,
        photo: r.body['photo'] as String?,
      ),
  ];

  Future<List<Animal>> _alive() async {
    final all = await _all();
    _remember(all);
    return [
      for (final a in all)
        if (!a.isDeleted) a,
    ];
  }

  static Map<String, Object?> _body(Animal a) => {
    'tagNumber': a.tagNumber,
    'name': a.name,
    'sex': a.sex.name,
    'breed': a.breed,
    'dateOfBirth': a.dateOfBirth.toIso8601String(),
    'status': a.status.name,
    'govIdTag': a.govIdTag,
    'dairyStatus': a.dairyStatus.name,
    'avatarIndex': a.avatarIndex,
    'group': a.group,
    'motherTag': a.motherTag,
    'photo': a.photo,
  };

  Future<void> _changed() async => _controller.add(Result.success(List.unmodifiable(await _alive())));

  @override
  Future<Result<void>> addAnimal(Animal animal) async {
    await journal.add(_collection, _body(animal), id: animal.id);
    await _changed();
    return const Result.success(null);
  }

  @override
  Stream<Result<List<Animal>>> watchAnimals() async* {
    yield Result.success(List.unmodifiable(await _alive()));
    yield* _controller.stream;
  }

  /// A milking cow under withdrawal shows as Treated.
  Future<Animal> _current(Animal a) async {
    final r = (await treatments.withdrawalFor(a.id, clock.now())).data;
    if (r == null || a.dairyStatus == DairyStatus.dry || a.sex == AnimalSex.male) return a;
    return Animal(
      id: a.id,
      tenantId: a.tenantId,
      tagNumber: a.tagNumber,
      name: a.name,
      sex: a.sex,
      breed: a.breed,
      dateOfBirth: a.dateOfBirth,
      status: a.status,
      govIdTag: a.govIdTag,
      createdAt: a.createdAt,
      updatedAt: a.updatedAt,
      createdBy: a.createdBy,
      updatedBy: a.updatedBy,
      deviceId: a.deviceId,
      syncStatus: a.syncStatus,
      isDeleted: a.isDeleted,
      dairyStatus: DairyStatus.treated,
      avatarIndex: a.avatarIndex,
      group: a.group,
      motherTag: a.motherTag,
      photo: a.photo,
    );
  }

  Future<Map<String, double>> _milkToday() async {
    final records = (await milk().records(from: clock.today())).data ?? const <MilkRecord>[];
    final out = <String, double>{};
    for (final r in records) {
      if (r.cowId case final id?) out[id] = (out[id] ?? 0) + r.litres;
    }
    return out;
  }

  @override
  Future<Result<List<HerdRow>>> rows() async {
    final today = await _milkToday();
    return Result.success([for (final a in await _alive()) HerdRow(animal: await _current(a), milkToday: today[a.id])]);
  }

  @override
  Future<Result<HerdCounts>> counts() async {
    final alive = await _alive();
    final all = await _all();
    final month = DateTime(clock.now().year, clock.now().month);
    int count(DairyStatus s) => alive.where((a) => a.dairyStatus == s).length;
    return Result.success(
      HerdCounts(
        total: alive.length,
        milking: count(DairyStatus.milking) + count(DairyStatus.treated),
        dry: count(DairyStatus.dry),
        treated: ((await treatments.withdrawals(clock.now())).data ?? const <TreatmentRecord>[]).length,
        pregnant: (await breeding.summary()).data?.pregnancies.length ?? 0,
        heifers: count(DairyStatus.heifer),
        calves: count(DairyStatus.calf),
        bulls: count(DairyStatus.bull),
        bornThisMonth: alive.where((a) => !a.dateOfBirth.isBefore(month)).length,
        boughtThisMonth: 0,
        soldThisMonth: all.where((a) => a.status == AnimalStatus.sold && !a.updatedAt.isBefore(month)).length,
        diedThisMonth: all.where((a) => a.status == AnimalStatus.deceased && !a.updatedAt.isBefore(month)).length,
      ),
    );
  }

  @override
  Future<Result<Animal?>> findByTag(String tag) async {
    for (final a in await _alive()) {
      if (a.tagNumber.toLowerCase() == tag.trim().toLowerCase()) return Result.success(await _current(a));
    }
    return const Result.success(null);
  }

  @override
  Future<Result<AnimalDetail?>> detail(String animalId) async {
    final match = (await _all()).where((a) => a.id == animalId).firstOrNull;
    if (match == null) return const Result.success(null);
    final a = await _current(match);
    final now = clock.now();
    final withdrawal = (await treatments.withdrawalFor(a.id, now)).data;

    // Milk per day for this cow, last 30 days.
    final since = clock.today().subtract(const Duration(days: 30));
    final records = ((await milk().records(from: since)).data ?? const <MilkRecord>[]).where((r) => r.cowId == a.id);
    final byDay = <DateTime, (double, double)>{};
    for (final r in records) {
      final day = DateTime(r.at.year, r.at.month, r.at.day);
      final (am, pm) = byDay[day] ?? (0.0, 0.0);
      byDay[day] = r.session == MilkSession.morning ? (am + r.litres, pm) : (am, pm + r.litres);
    }
    final week = clock.today().subtract(const Duration(days: 6));
    final lastWeek = [
      for (final e in byDay.entries)
        if (!e.key.isBefore(week)) e.value.$1 + e.value.$2,
    ];
    final avg = lastWeek.isEmpty ? 0.0 : lastWeek.reduce((x, y) => x + y) / lastWeek.length;

    final treated = ((await treatments.treatments()).data ?? const <TreatmentRecord>[]).where(
      (r) => r.animalId == a.id,
    );
    final calving = a.dairyStatus == DairyStatus.calf ? null : _lastCalving(await _all(), a);
    return Result.success(
      AnimalDetail(
        animal: a,
        avgMilk: avg,
        daysInMilk: calving == null ? 0 : clock.today().difference(calving).inDays,
        withdrawal: withdrawal == null ? null : Withdrawal(drug: withdrawal.drug.shortName, until: withdrawal.safeFrom),
        timeline: [
          for (final r in treated)
            TreatmentEvent(
              at: r.given,
              drug: r.drug.shortName,
              reason: _conditionName(r.condition),
              vet: r.givenBy ?? '',
              safeFrom: r.safeFrom,
            ),
          for (final e in byDay.entries) MilkEvent(at: e.key, morning: e.value.$1, evening: e.value.$2),
        ]..sort((x, y) => y.at.compareTo(x.at)),
      ),
    );
  }

  /// Birth date of her newest calf, if recorded.
  static DateTime? _lastCalving(List<Animal> all, Animal mother) {
    final calves = all.where((c) => c.motherTag == mother.tagNumber).map((c) => c.dateOfBirth).toList()..sort();
    return calves.lastOrNull;
  }

  static String _conditionName(Condition c) => switch (c) {
    Condition.mastitis => 'Mastitis',
    Condition.lame => 'Lame',
    Condition.fever => 'Fever',
    Condition.wound => 'Wound',
    Condition.eye => 'Eye',
    Condition.diarrhoea => 'Diarrhoea',
    Condition.other => 'Other',
  };

  /// Paddocks and pens already used on this farm, plus the usual ones.
  @override
  List<String> get groups => {..._usedGroups, 'Paddock 1', 'Paddock 2', 'Paddock 3', 'Calf pen'}.toList();

  @override
  List<String> get breeds => {
    'Friesian',
    'Friesian cross',
    'Jersey',
    'Jersey cross',
    'Ankole',
    'Ankole cross',
    'Guernsey',
    'Ayrshire',
    'Boran',
    'Zebu',
    ..._usedBreeds,
  }.toList();

  // Filled from the saved animals each time the herd changes.
  Set<String> _usedGroups = {};
  Set<String> _usedBreeds = {};

  void _remember(List<Animal> all) {
    PhotoStore.instance.animalPhotos
      ..clear()
      ..addAll({
        for (final a in all)
          if ((a.photo ?? '').isNotEmpty) a.id: a.photo!,
      });
    _usedGroups = {
      for (final a in all)
        if ((a.group ?? '').isNotEmpty) a.group!,
    };
    _usedBreeds = {
      for (final a in all)
        if (a.breed.isNotEmpty) a.breed,
    };
  }

  @override
  Future<Result<bool>> updateAnimal(Animal animal) async {
    final all = await _all();
    final tag = animal.tagNumber.trim().toLowerCase();
    if (all.any((a) => a.id != animal.id && !a.isDeleted && a.tagNumber.toLowerCase() == tag)) {
      return const Result.success(false);
    }
    final r = await journal.store.get(_collection, animal.id);
    await journal.put(_collection, animal.id, {...?r?.body, ..._body(animal)});
    await _changed();
    return const Result.success(true);
  }

  @override
  Future<Result<void>> recordSale(String animalId, {required int price, String? buyer}) async {
    final r = await journal.store.get(_collection, animalId);
    if (r == null) return const Result.success(null);
    await journal.put(_collection, animalId, {...r.body, 'status': AnimalStatus.sold.name});
    final eventId = await journal.add('animalEvents', {
      'type': 'sold',
      'animalId': animalId,
      'price': price,
      'buyer': buyer,
    });
    if (price > 0) {
      final label = [r.body['tagNumber'], r.body['name']].whereType<String>().where((s) => s.isNotEmpty).join(' ');
      await money?.call().addIncome(
        source: IncomeSource.animalSale,
        amount: price,
        note: [label, if (buyer != null && buyer.isNotEmpty) buyer].join(' · '),
        sourceId: eventId,
      );
    }
    await _changed();
    return const Result.success(null);
  }

  @override
  Future<Result<List<Animal>>> pastAnimals() async => Result.success(
    [
      for (final a in await _all())
        if (a.status == AnimalStatus.sold || a.status == AnimalStatus.deceased) a,
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
  );

  @override
  Future<Result<String>> nextTag() async {
    var max = 0;
    for (final a in await _all()) {
      final n = int.tryParse(a.tagNumber.replaceAll(RegExp('[^0-9]'), ''));
      if (n != null && n > max) max = n;
    }
    return Result.success('FT-${(max + 1).toString().padLeft(3, '0')}');
  }

  @override
  Future<Result<void>> recordDeath(String animalId, {String? cause}) async {
    final r = await journal.store.get(_collection, animalId);
    if (r == null) return const Result.success(null);
    await journal.put(_collection, animalId, {...r.body, 'status': AnimalStatus.deceased.name});
    await journal.add('animalEvents', {'type': 'death', 'animalId': animalId, 'cause': cause});
    await _changed();
    return const Result.success(null);
  }

  @override
  Future<Result<Animal>> recordCalving(String motherId, {required DateTime at}) async {
    final mother = (await _all()).firstWhere((a) => a.id == motherId);
    final tag = (await nextTag()).data!;
    final calf = Animal(
      id: journal.newId(),
      tenantId: journal.tenantId(),
      tagNumber: tag,
      name: '',
      sex: AnimalSex.female,
      breed: mother.breed,
      dateOfBirth: at,
      status: AnimalStatus.active,
      createdAt: at,
      updatedAt: at,
      createdBy: journal.actor(),
      updatedBy: journal.actor(),
      deviceId: journal.deviceId,
      syncStatus: SyncStatus.pending,
      dairyStatus: DairyStatus.calf,
      group: 'Calf pen',
      motherTag: mother.tagNumber,
    );
    await addAnimal(calf);
    // She is milking again after calving.
    final r = await journal.store.get(_collection, motherId);
    if (r != null) await journal.put(_collection, motherId, {...r.body, 'dairyStatus': DairyStatus.milking.name});
    await breeding.recordCalving(motherId, at: at);
    await _changed();
    return Result.success(calf);
  }
}
