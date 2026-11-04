import 'dart:async';

import 'package:farm_tap/core/sync/domain/sync_record.dart';
import 'package:farm_tap/core/sync/record_journal.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/sectors/cattle/operations/domain/operations_models.dart';
import 'package:flutter/foundation.dart';

/// Contacts, duty roster, time away, feeds store and vaccinations
/// (decision 0024), saved through the phone's record journal so they sync
/// with the web app. Pages listen to it; it reloads after every sync
/// (restoreSavedRecords) and after every change made here.
class OperationsRepository extends ChangeNotifier implements Restorable {
  new({required this.journal, required this.clock});

  final RecordJournal journal;
  final Clock clock;

  static const collections = ['contacts', 'duties', 'absences', 'feedTypes', 'vaccinations'];

  List<FarmContact> contacts = const [];
  List<Duty> duties = const [];
  List<Absence> absences = const [];
  List<FeedType> feedTypes = const [];
  List<Vaccination> vaccinations = const [];
  List<SyncRecord> _moves = const [];
  List<SyncRecord> _uses = const [];
  bool loaded = false;

  @override
  Future<void> restore() async {
    Future<List<SyncRecord>> load(String c) async {
      try {
        return (await journal.load(c)).where((r) => !r.isDeleted).toList();
      } on Object {
        return const [];
      }
    }

    final r = await Future.wait([
      load('contacts'),
      load('duties'),
      load('absences'),
      load('feedTypes'),
      load('vaccinations'),
      load('stockMovements'),
      load('feedUsage'),
    ]);
    contacts = [for (final x in r[0]) FarmContact.fromBody(x.id, x.body)]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    duties = [for (final x in r[1]) Duty.fromBody(x.id, x.body)];
    absences = [for (final x in r[2]) Absence.fromBody(x.id, x.body)]..sort((a, b) => b.from.compareTo(a.from));
    feedTypes = [for (final x in r[3]) FeedType.fromBody(x.id, x.body)]..sort((a, b) => a.name.compareTo(b.name));
    vaccinations = [for (final x in r[4]) Vaccination.fromBody(x.id, x.body)]
      ..sort((a, b) => b.given.compareTo(a.given));
    _moves = r[5];
    _uses = r[6];
    loaded = true;
    notifyListeners();
  }

  Future<void> _after(Future<void> change) async {
    await change;
    await restore();
  }

  // Contacts
  Future<void> saveContact(FarmContact c) => _after(
    c.id.isEmpty ? journal.add('contacts', c.toBody()).then((_) {}) : journal.put('contacts', c.id, c.toBody()),
  );
  Future<void> removeContact(String id) => _after(journal.remove('contacts', id));
  FarmContact? contact(String? id) => contacts.where((c) => c.id == id).firstOrNull;

  // Duties
  Future<void> saveDuty(Duty d) =>
      _after(d.id.isEmpty ? journal.add('duties', d.toBody()).then((_) {}) : journal.put('duties', d.id, d.toBody()));
  Future<void> removeDuty(String id) => _after(journal.remove('duties', id));
  Future<void> addAbsence(Absence a) => _after(journal.add('absences', a.toBody()).then((_) {}));
  Future<void> removeAbsence(String id) => _after(journal.remove('absences', id));

  /// Duties that run on [day], each with who works it.
  List<({Duty duty, String? staffId, bool covering})> dutiesOn(DateTime day) => [
    for (final d in duties.where((d) => d.on(day)))
      (duty: d, staffId: whoWorks(d, day, absences).staffId, covering: whoWorks(d, day, absences).covering),
  ];

  bool isAway(String staffId, DateTime day) => absences.any((a) => a.staffId == staffId && a.covers(day));

  // Feeds store
  Future<void> saveFeedType(FeedType t) => _after(
    t.id.isEmpty ? journal.add('feedTypes', t.toBody()).then((_) {}) : journal.put('feedTypes', t.id, t.toBody()),
  );
  Future<void> removeFeedType(String id) => _after(journal.remove('feedTypes', id));

  /// Counts what is in the store now (a 'count' stock movement).
  Future<void> countFeed(String feed, double amount) => _after(
    journal
        .add('stockMovements', {'kind': 'count', 'feed': feed, 'amount': amount, 'at': clock.now().toIso8601String()})
        .then((_) {}),
  );

  DateTime _at(SyncRecord r) => DateTime.tryParse('${r.body['at'] ?? ''}') ?? r.createdAt;
  double _amt(SyncRecord r) => (r.body['amount'] is num) ? (r.body['amount']! as num).toDouble() : 0;

  /// Same sum as the web (feedStock): last count, plus purchases, minus feedings since.
  FeedStock stockOf(FeedType t) {
    final mine = _moves.where((m) => m.body['feed'] == t.id).toList();
    final counts = mine.where((m) => m.body['kind'] == 'count').toList()..sort((a, b) => _at(b).compareTo(_at(a)));
    final last = counts.firstOrNull;
    final from = last == null ? DateTime(2000) : _at(last);
    var left = last == null ? 0.0 : _amt(last);
    DateTime? bought;
    for (final m in mine.where((m) => m.body['kind'] == 'purchase')) {
      if (_at(m).isAfter(from)) left += _amt(m);
      if (bought == null || _at(m).isAfter(bought)) bought = _at(m);
    }
    final fed = _uses.where((u) => u.body['feed'] == t.id).toList();
    for (final u in fed) {
      if (_at(u).isAfter(from)) left -= _amt(u);
    }
    final weekAgo = clock.now().subtract(const Duration(days: 7)); // theme-guard: ignore
    final perDay = fed.where((u) => !_at(u).isBefore(weekAgo)).fold<double>(0, (s, u) => s + _amt(u)) / 7;
    return FeedStock(type: t, amount: (left * 100).roundToDouble() / 100, lastBought: bought, dailyUse: perDay);
  }

  List<FeedStock> get stock => [for (final t in feedTypes) stockOf(t)];

  // Vaccinations
  /// Saves a vaccination and, when it cost money, its vet expense (linked by
  /// sourceId, like the web).
  Future<void> addVaccination(Vaccination v, {String payMethod = 'cash'}) => _after(() async {
    final id = await journal.add('vaccinations', v.toBody());
    final cost = v.cost ?? 0;
    if (cost > 0) {
      await journal.add('expenses', {
        'category': 'vet',
        'amount': cost,
        'at': v.given.toIso8601String(),
        'note': '${v.vaccine} · ${v.animalIds.isEmpty ? 'whole herd' : '${v.animalIds.length} animals'}',
        'sourceId': id,
        'sourceType': 'vaccination',
        'supplierId': v.vetId,
        'payMethod': payMethod,
        'photo': null,
      });
    }
  }());

  /// Removes it and the expense it made.
  Future<void> removeVaccination(String id) => _after(() async {
    await journal.remove('vaccinations', id);
    for (final e in await journal.load('expenses')) {
      if (!e.isDeleted && e.body['sourceId'] == id) await journal.remove('expenses', e.id);
    }
  }());

  /// The next dose of each vaccine (latest record per vaccine with a due date).
  List<Vaccination> get upcoming {
    final latest = <String, Vaccination>{};
    for (final v in vaccinations) {
      if (v.nextDue == null) continue;
      final cur = latest[v.vaccine];
      if (cur == null || v.nextDue!.isAfter(cur.nextDue!)) latest[v.vaccine] = v;
    }
    return latest.values.toList()..sort((a, b) => a.nextDue!.compareTo(b.nextDue!));
  }
}
