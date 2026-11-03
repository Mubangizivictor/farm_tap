import 'dart:async';
import 'dart:convert';

import 'package:farm_tap/core/sync/data/isar/sync_models.dart';
import 'package:farm_tap/core/sync/data/memory_record_store.dart' show auditCollection, auditFor;
import 'package:farm_tap/core/sync/domain/local_record_store.dart';
import 'package:farm_tap/core/sync/domain/merge_policy.dart';
import 'package:farm_tap/core/sync/domain/sync_record.dart';
import 'package:isar_community/isar.dart';

/// Schemas this store needs in `Isar.open`.
const List<CollectionSchema<dynamic>> syncSchemas = [LocalRecordModelSchema, OutboxModelSchema, SyncCursorModelSchema];

/// [LocalRecordStore] on Isar: survives restarts, crashes and a flat
/// battery. Record, outbox entry and audit entry are written in one
/// transaction (decision 0014 §2).
class IsarRecordStore implements LocalRecordStore {
  new(this.isar);

  final Isar isar;

  IsarCollection<LocalRecordModel> get _records => isar.localRecordModels;
  IsarCollection<OutboxModel> get _outbox => isar.outboxModels;

  @override
  Future<void> write(SyncRecord record, {String? auditAction}) => isar.writeTxn(() async {
    final before = await _records.getByKey(record.key);
    await _put(record.copyWith(syncStatus: SyncStatus.pending));
    if (auditAction != null && record.collection != auditCollection) {
      final audit = auditFor(record, action: auditAction, before: before == null ? null : _decode(before.bodyJson));
      await _put(audit.copyWith(syncStatus: SyncStatus.pending));
    }
  });

  /// Inside a transaction: saves the record and (re)queues it.
  Future<void> _put(SyncRecord record) async {
    await _records.putByKey(_toModel(record));
    final last = await _outbox.where().sortBySeqDesc().findFirst();
    final existing = await _outbox.getByKey(record.key);
    await _outbox.putByKey(
      OutboxModel()
        ..key = record.key
        ..collection = record.collection
        ..recordId = record.id
        ..version = record.version
        ..attempts = 0
        ..failed = false
        // Keep its place in line if it was already waiting.
        ..seq = existing?.seq ?? (last?.seq ?? 0) + 1,
    );
  }

  @override
  Future<SyncRecord?> get(String collection, String id) async {
    final m = await _records.getByKey(recordKey(collection, id));
    return m == null ? null : _toRecord(m);
  }

  @override
  Stream<List<SyncRecord>> watch(String tenantId, String collection) => _records
      .where()
      .tenantIdCollectionEqualTo(tenantId, collection)
      .filter()
      .isDeletedEqualTo(false)
      .watch(fireImmediately: true)
      .map((models) => models.map(_toRecord).toList());

  @override
  Future<List<SyncRecord>> all(String tenantId, String collection, {bool includeDeleted = false}) async {
    final q = _records.where().tenantIdCollectionEqualTo(tenantId, collection);
    final models = includeDeleted ? await q.findAll() : await q.filter().isDeletedEqualTo(false).findAll();
    return models.map(_toRecord).toList();
  }

  @override
  Future<List<OutboxEntry>> due(DateTime now, {int limit = 20}) async {
    final models = await _outbox
        .filter()
        .failedEqualTo(false)
        .group((q) => q.nextAttemptAtIsNull().or().nextAttemptAtLessThan(now, include: true))
        .sortBySeq()
        .limit(limit)
        .findAll();
    return models.map(_toEntry).toList();
  }

  @override
  Future<List<OutboxEntry>> outbox() async => (await _outbox.where().sortBySeq().findAll()).map(_toEntry).toList();

  @override
  Future<void> markSent(String collection, String id, int version) => isar.writeTxn(() async {
    final key = recordKey(collection, id);
    final entry = await _outbox.getByKey(key);
    if (entry == null || entry.version != version) return; // a newer edit waits
    await _outbox.deleteByKey(key);
    final r = await _records.getByKey(key);
    if (r != null && r.version == version) {
      r.syncStatus = SyncStatus.synced;
      await _records.putByKey(r);
    }
  });

  @override
  Future<void> markRetry(OutboxEntry entry) => isar.writeTxn(() async {
    final current = await _outbox.getByKey(entry.key);
    if (current == null || current.version != entry.version) return;
    current
      ..attempts = entry.attempts
      ..nextAttemptAt = entry.nextAttemptAt
      ..lastError = entry.lastError
      ..failed = entry.failed;
    await _outbox.putByKey(current);
    if (entry.failed) {
      final r = await _records.getByKey(entry.key);
      if (r != null) {
        r.syncStatus = SyncStatus.failed;
        await _records.putByKey(r);
      }
    }
  });

  @override
  Future<int> retryFailed() => isar.writeTxn(() async {
    final failed = await _outbox.filter().failedEqualTo(true).findAll();
    for (final e in failed) {
      e
        ..failed = false
        ..attempts = 0
        ..nextAttemptAt = null;
      await _outbox.putByKey(e);
      final r = await _records.getByKey(e.key);
      if (r != null) {
        r.syncStatus = SyncStatus.pending;
        await _records.putByKey(r);
      }
    }
    return failed.length;
  });

  @override
  Future<List<SyncConflict>> applyRemote(List<SyncRecord> records, MergePolicy policy) => isar.writeTxn(() async {
    final conflicts = <SyncConflict>[];
    for (final remote in records) {
      final localModel = await _records.getByKey(remote.key);
      final local = localModel == null ? null : _toRecord(localModel);
      final unsent = await _outbox.getByKey(remote.key) != null;
      final outcome = policy.resolve(local, remote, hasUnsentEdit: unsent);
      if (outcome.winner == MergeWinner.local) continue;
      if (outcome.conflict && local != null) {
        conflicts.add(SyncConflict(local: local, remote: remote, needsReview: outcome.needsReview));
        await _outbox.deleteByKey(remote.key);
        await _put(auditFor(local, action: 'conflict', needsReview: outcome.needsReview, winner: remote));
      }
      await _records.putByKey(_toModel(remote.copyWith(syncStatus: SyncStatus.synced)));
    }
    return conflicts;
  });

  @override
  Future<String?> cursor(String tenantId, String collection) async =>
      (await isar.syncCursorModels.getByKey('$tenantId/$collection'))?.cursor;

  @override
  Future<void> setCursor(String tenantId, String collection, String? cursor) => isar.writeTxn(
    () => isar.syncCursorModels.putByKey(
      SyncCursorModel()
        ..key = '$tenantId/$collection'
        ..cursor = cursor,
    ),
  );

  @override
  Future<OutboxCounts> counts() async {
    final waitingAll = await _outbox.count();
    final failed = await _outbox.filter().failedEqualTo(true).count();
    final synced = await _records.filter().syncStatusEqualTo(SyncStatus.synced).count();
    return OutboxCounts(synced: synced, waiting: waitingAll - failed, failed: failed);
  }

  @override
  Stream<void> changes() {
    late StreamController<void> controller;
    final subs = <StreamSubscription<void>>[];
    controller = StreamController<void>.broadcast(
      onListen: () => subs
        ..add(_records.watchLazy().listen(controller.add))
        ..add(_outbox.watchLazy().listen(controller.add)),
      onCancel: () {
        for (final s in subs) {
          unawaited(s.cancel());
        }
        subs.clear();
      },
    );
    return controller.stream;
  }

  static Map<String, Object?> _decode(String json) => Map<String, Object?>.from(jsonDecode(json) as Map);

  static LocalRecordModel _toModel(SyncRecord r) => LocalRecordModel()
    ..key = r.key
    ..tenantId = r.tenantId
    ..collection = r.collection
    ..recordId = r.id
    ..bodyJson = jsonEncode(r.body)
    ..createdAt = r.createdAt
    ..updatedAt = r.updatedAt
    ..createdBy = r.createdBy
    ..updatedBy = r.updatedBy
    ..deviceId = r.deviceId
    ..version = r.version
    ..isDeleted = r.isDeleted
    ..syncStatus = r.syncStatus;

  static SyncRecord _toRecord(LocalRecordModel m) => SyncRecord(
    collection: m.collection,
    id: m.recordId,
    tenantId: m.tenantId,
    body: _decode(m.bodyJson),
    createdAt: m.createdAt,
    updatedAt: m.updatedAt,
    createdBy: m.createdBy,
    updatedBy: m.updatedBy,
    deviceId: m.deviceId,
    version: m.version,
    isDeleted: m.isDeleted,
    syncStatus: m.syncStatus,
  );

  static OutboxEntry _toEntry(OutboxModel m) => OutboxEntry(
    collection: m.collection,
    id: m.recordId,
    version: m.version,
    attempts: m.attempts,
    nextAttemptAt: m.nextAttemptAt,
    lastError: m.lastError,
    failed: m.failed,
  );
}
