import 'dart:async';

import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/money/domain/money_models.dart';
import 'package:farm_tap/core/money/domain/money_repository.dart';
import 'package:farm_tap/core/sync/record_journal.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/sectors/cattle/breeding/domain/breeding_models.dart';
import 'package:farm_tap/sectors/cattle/breeding/domain/breeding_repository.dart';

/// UI phase: 9 confirmed pregnancies (Kyasiimire, Kahara, Bihogo calve within
/// 30 days of Sat 7 Nov), 2 services due a pregnancy check and a heifer that
/// showed heat yesterday. Every date is calculated with [BreedingRules].
class FakeBreedingRepository implements BreedingRepository {
  new(this.clock, this.money, {this.journal}) {
    final now = clock.now();
    final today = DateTime(now.year, now.month, now.day);
    // Served so that she calves on [due].
    DateTime servedFor(DateTime due) => due.subtract(const Duration(days: BreedingRules.gestationDays));
    final pregnant = <(String, DateTime, String)>[
      ('FT-031', today.add(const Duration(days: 6)), 'Jersey 1180'),
      ('FT-033', today.add(const Duration(days: 21)), 'Friesian 4421'),
      ('FT-014', today.add(const Duration(days: 27)), 'Friesian 4421'),
      ('FT-008', DateTime(2027, 1, 18), 'Friesian 4421'),
      ('FT-027', DateTime(2027, 2, 2), 'Jersey 1180'),
      ('FT-019', DateTime(2027, 2, 25), 'Friesian 4421'),
      ('FT-037', DateTime(2027, 3, 12), 'Jersey 1180'),
      ('FT-041', DateTime(2027, 4, 9), 'Friesian 4421'),
      ('FT-052', DateTime(2027, 5, 30), 'Jersey 1180'),
    ];
    for (final (tag, due, straw) in pregnant) {
      final s = _service(tag, ServiceKind.ai, servedFor(due), straw: straw);
      _checks.add(
        PregnancyCheck(
          id: 'check-${_next++}',
          serviceId: s.id,
          pregnant: true,
          at: s.checkFrom.add(const Duration(days: 2)),
          by: _vet,
        ),
      );
    }
    // Due a pregnancy check (56 days after service).
    _service('FT-022', ServiceKind.ai, today.subtract(const Duration(days: 56)), straw: 'Friesian 4421');
    _service('FT-039', ServiceKind.ai, today.subtract(const Duration(days: 59)), straw: 'Jersey 1180');
    // Heat seen yesterday evening: serve today.
    _service('FT-045', ServiceKind.heat, today.subtract(const Duration(hours: 6)));
  }

  static const _vet = 'Dr. Kamugisha Ivan';
  static const _technician = 'Twinomujuni Amos';
  static const aiCost = 35000;

  static const _animals = [
    BreedingAnimal(id: 'animal-FT-031', name: 'Kyasiimire', tag: 'FT-031', avatarIndex: 3),
    BreedingAnimal(id: 'animal-FT-033', name: 'Kahara', tag: 'FT-033', avatarIndex: 3),
    BreedingAnimal(id: 'animal-FT-014', name: 'Bihogo', tag: 'FT-014', avatarIndex: 1),
    BreedingAnimal(id: 'animal-FT-008', name: 'Ngabire', tag: 'FT-008', avatarIndex: 4),
    BreedingAnimal(id: 'animal-FT-027', name: 'Nyinamwiza', tag: 'FT-027', avatarIndex: 1),
    BreedingAnimal(id: 'animal-FT-019', name: 'Kaaka', tag: 'FT-019', avatarIndex: 6),
    BreedingAnimal(id: 'animal-FT-037', name: 'Kabagyenyi', tag: 'FT-037', avatarIndex: 2),
    BreedingAnimal(id: 'animal-FT-041', name: 'Mbabazi', tag: 'FT-041', avatarIndex: 4),
    BreedingAnimal(id: 'animal-FT-052', name: 'Tushabe', tag: 'FT-052', avatarIndex: 5),
    BreedingAnimal(id: 'animal-FT-022', name: 'Kasheshe', tag: 'FT-022', avatarIndex: 2),
    BreedingAnimal(id: 'animal-FT-039', name: 'Nyakato', tag: 'FT-039', avatarIndex: 6),
    BreedingAnimal(id: 'animal-FT-045', name: 'Rwemera', tag: 'FT-045', avatarIndex: 5, heifer: true),
  ];

  final Clock clock;

  /// Saves records on the phone for sync (decision 0014); null in tests.
  final RecordJournal? journal;
  final MoneyRepository money;
  final List<ServiceRecord> _services = [];
  final List<PregnancyCheck> _checks = [];
  final List<CalvingRecord> _calvings = [];
  var _next = 1;

  ServiceRecord _service(String tag, ServiceKind kind, DateTime at, {String? straw}) {
    final s = ServiceRecord(
      id: 'service-${_next++}',
      animal: _animals.firstWhere((a) => a.tag == tag),
      kind: kind,
      at: at,
      straw: straw,
      technician: kind == ServiceKind.ai ? _technician : null,
      cost: kind == ServiceKind.ai ? aiCost : null,
    );
    _services.add(s);
    unawaited(_recordExpense(s));
    return s;
  }

  Future<void> _recordExpense(ServiceRecord s) async {
    if (s.cost == null || s.cost == 0) return;
    await money.addExpense(
      category: ExpenseCategory.breeding,
      amount: s.cost!,
      at: s.at,
      note: '${s.animal.name} · ${s.straw ?? s.bull ?? ''}',
      sourceId: s.id,
    );
  }

  /// The animal's latest heat or service.
  ServiceRecord? _latest(String animalId) =>
      (_services.where((s) => s.animal.id == animalId).toList()..sort((a, b) => b.at.compareTo(a.at))).firstOrNull;

  @override
  Future<Result<BreedingSummary>> summary() async {
    final now = clock.now();
    final pregnancies = <Pregnancy>[];
    final tasks = <BreedingTask>[];
    for (final a in _animals) {
      final last = _latest(a.id);
      if (last == null) continue;
      final calved = _calvings.any((c) => c.animalId == a.id && c.at.isAfter(last.at));
      if (calved) continue;
      if (last.kind == ServiceKind.heat) {
        if (now.difference(last.at).inDays < BreedingRules.heatValidDays) {
          tasks.add(BreedingTask(kind: BreedingTaskKind.serve, record: last));
        }
        continue;
      }
      final check = _checks.where((c) => c.serviceId == last.id).firstOrNull;
      if (check == null) {
        if (!now.isBefore(last.checkFrom)) tasks.add(BreedingTask(kind: BreedingTaskKind.check, record: last));
      } else if (check.pregnant) {
        pregnancies.add(Pregnancy(service: last, check: check));
      }
    }
    pregnancies.sort((a, b) => a.due.compareTo(b.due));
    // Checks first (newest service first), then heats to serve.
    tasks.sort((a, b) => a.kind != b.kind ? a.kind.index.compareTo(b.kind.index) : b.record.at.compareTo(a.record.at));
    return Result.success(
      BreedingSummary(
        pregnancies: pregnancies,
        calvingSoon: pregnancies.where((p) => p.daysToCalving(now) <= BreedingRules.calvingSoonDays).toList(),
        tasks: tasks,
      ),
    );
  }

  @override
  Future<Result<List<BreedingAnimal>>> animals() async => const Result.success(_animals);

  @override
  Future<Result<ServiceRecord>> recordService({
    required String animalId,
    required ServiceKind kind,
    required DateTime at,
    String? straw,
    String? bull,
    String? technician,
    int? cost,
  }) async {
    final s = ServiceRecord(
      id: journal?.newId() ?? 'service-${_next++}',
      animal: _animals.firstWhere((a) => a.id == animalId),
      kind: kind,
      at: at,
      straw: straw,
      bull: bull,
      technician: technician,
      cost: cost,
    );
    _services.add(s);
    await journal?.add('breedingEvents', {
      'type': kind == ServiceKind.ai ? 'ai' : 'service',
      'kind': kind.name,
      'animalId': animalId,
      'at': at.toIso8601String(),
      'straw': straw,
      'bull': bull,
      'technician': technician,
      'cost': cost,
    }, id: s.id);
    await _recordExpense(s);
    return Result.success(s);
  }

  @override
  Future<Result<Pregnancy?>> recordCheck({required String serviceId, required bool pregnant, String? by}) async {
    final check = PregnancyCheck(
      id: journal?.newId() ?? 'check-${_next++}',
      serviceId: serviceId,
      pregnant: pregnant,
      at: clock.now(),
      by: by,
    );
    _checks.add(check);
    await journal?.add('breedingEvents', {
      'type': 'pregnancyCheck',
      'serviceId': serviceId,
      'pregnant': pregnant,
      'by': by,
      'at': check.at.toIso8601String(),
    }, id: check.id);
    final service = _services.firstWhere((s) => s.id == serviceId);
    return Result.success(pregnant ? Pregnancy(service: service, check: check) : null);
  }

  @override
  Future<Result<void>> recordCalving(String animalId, {required DateTime at}) async {
    _calvings.add(CalvingRecord(animalId: animalId, at: at));
    await journal?.add('breedingEvents', {'type': 'calving', 'animalId': animalId, 'at': at.toIso8601String()});
    return const Result.success(null);
  }

  @override
  List<String> get technicians => const [_technician, _vet];
}
