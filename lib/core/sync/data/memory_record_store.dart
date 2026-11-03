import 'dart:async';

import 'package:farm_tap/core/sync/domain/local_record_store.dart';
import 'package:farm_tap/core/sync/domain/merge_policy.dart';
import 'package:farm_tap/core/sync/domain/sync_record.dart';

/// Audit entries are records too, so they reach the cloud through the same
/// outbox (ROADMAP 8: `auditLog/{id}`).
const auditCollection = 'auditLog';

/// Builds the audit record for a write or a kept conflict. The id is fixed by
/// record + version, so writing it twice never makes two entries.
SyncRecord auditFor(
  SyncRecord record, {
  required String action,
  Map<String, Object?>? before,
  bool needsReview = false,
  SyncRecord? winner,
}) => SyncRecord(
  collection: auditCollection,
  id: '${record.collection}.${record.id}.v${record.version}.$action',
  tenantId: record.tenantId,
  body: {
    'action': action,
    'path': record.key,
    'actor': record.updatedBy,
    'before': before,
    'after': record.isDeleted ? null : record.body,
    if (winner != null) 'keptVersion': winner.toJson(),
    'needsReview': needsReview,
  },
  createdAt: record.updatedAt,
  updatedAt: record.updatedAt,
  createdBy: record.updatedBy,
  updatedBy: record.updatedBy,
  deviceId: record.deviceId,
);

/// In-memory [LocalRecordStore]: tests and the demo build. Same rules as the
/// Isar store; every method changes all maps together before notifying.
class MemoryRecordStore implements LocalRecordStore {
  final _records = <String, SyncRecord>{};
  final _outbox = <String, OutboxEntry>{};
  final _order = <String>[];
  final _cursors = <String, String?>{};
  final _changes = StreamController<void>.broadcast();

  @override
  Future<void> write(SyncRecord record, {String? auditAction}) async {
    final before = _records[record.key];
    _put(record.copyWith(syncStatus: SyncStatus.pending));
    if (auditAction != null && record.collection != auditCollection) {
      _put(auditFor(record, action: auditAction, before: before?.body).copyWith(syncStatus: SyncStatus.pending));
    }
    _changes.add(null);
  }

  void _put(SyncRecord record) {
    _records[record.key] = record;
    _outbox[record.key] = OutboxEntry(collection: record.collection, id: record.id, version: record.version);
    _order
      ..remove(record.key)
      ..add(record.key);
  }

  @override
  Future<SyncRecord?> get(String collection, String id) async => _records[recordKey(collection, id)];

  @override
  Stream<List<SyncRecord>> watch(String tenantId, String collection) async* {
    yield await all(tenantId, collection);
    await for (final _ in _changes.stream) {
      yield await all(tenantId, collection);
    }
  }

  @override
  Future<List<SyncRecord>> all(String tenantId, String collection, {bool includeDeleted = false}) async => [
    for (final r in _records.values)
      if (r.tenantId == tenantId && r.collection == collection && (includeDeleted || !r.isDeleted)) r,
  ];

  @override
  Future<List<OutboxEntry>> due(DateTime now, {int limit = 20}) async =>
      [for (final k in _order) ?_outbox[k]].where((e) => e.isDue(now)).take(limit).toList();

  @override
  Future<List<OutboxEntry>> outbox() async => [for (final k in _order) ?_outbox[k]];

  @override
  Future<void> markSent(String collection, String id, int version) async {
    final key = recordKey(collection, id);
    final entry = _outbox[key];
    if (entry == null || entry.version != version) return; // newer edit waits
    _outbox.remove(key);
    _order.remove(key);
    final r = _records[key];
    if (r != null && r.version == version) _records[key] = r.copyWith(syncStatus: SyncStatus.synced);
    _changes.add(null);
  }

  @override
  Future<void> markRetry(OutboxEntry entry) async {
    final current = _outbox[entry.key];
    if (current == null || current.version != entry.version) return;
    _outbox[entry.key] = entry;
    if (entry.failed) {
      final r = _records[entry.key];
      if (r != null) _records[entry.key] = r.copyWith(syncStatus: SyncStatus.failed);
    }
    _changes.add(null);
  }

  @override
  Future<int> retryFailed() async {
    var n = 0;
    for (final e in _outbox.values.toList()) {
      if (!e.failed) continue;
      _outbox[e.key] = OutboxEntry(collection: e.collection, id: e.id, version: e.version);
      final r = _records[e.key];
      if (r != null) _records[e.key] = r.copyWith(syncStatus: SyncStatus.pending);
      n++;
    }
    if (n > 0) _changes.add(null);
    return n;
  }

  @override
  Future<List<SyncConflict>> applyRemote(List<SyncRecord> records, MergePolicy policy) async {
    final conflicts = <SyncConflict>[];
    for (final remote in records) {
      final local = _records[remote.key];
      final outcome = policy.resolve(local, remote, hasUnsentEdit: _outbox.containsKey(remote.key));
      if (outcome.winner == MergeWinner.local) continue;
      if (outcome.conflict && local != null) {
        conflicts.add(SyncConflict(local: local, remote: remote, needsReview: outcome.needsReview));
        _outbox.remove(remote.key);
        _order.remove(remote.key);
        _put(auditFor(local, action: 'conflict', needsReview: outcome.needsReview, winner: remote));
      }
      _records[remote.key] = remote.copyWith(syncStatus: SyncStatus.synced);
    }
    if (records.isNotEmpty) _changes.add(null);
    return conflicts;
  }

  @override
  Future<String?> cursor(String tenantId, String collection) async => _cursors['$tenantId/$collection'];

  @override
  Future<void> setCursor(String tenantId, String collection, String? cursor) async =>
      _cursors['$tenantId/$collection'] = cursor;

  @override
  Future<OutboxCounts> counts() async {
    final failed = _outbox.values.where((e) => e.failed).length;
    return OutboxCounts(
      synced: _records.values.where((r) => r.syncStatus == SyncStatus.synced).length,
      waiting: _outbox.length - failed,
      failed: failed,
    );
  }

  @override
  Stream<void> changes() => _changes.stream;
}
