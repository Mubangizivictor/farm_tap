import 'package:farm_tap/core/sync/domain/merge_policy.dart';
import 'package:farm_tap/core/sync/domain/sync_record.dart';

/// Counts for the sync badge and D04.
class OutboxCounts {
  const new({this.synced = 0, this.waiting = 0, this.failed = 0});

  final int synced;
  final int waiting;
  final int failed;
}

/// The phone's own database: the source of truth (ROADMAP 5.1). Isar in the
/// app, in memory in tests.
///
/// Every write saves the record, its outbox entry and its audit entry in one
/// transaction, so a crash or a flat battery never loses one without the
/// others.
abstract class LocalRecordStore {
  /// Saves a new record or a new version of one and queues it for sending.
  /// The record's version must already be bumped by the caller.
  Future<void> write(SyncRecord record, {String? auditAction});

  Future<SyncRecord?> get(String collection, String id);

  /// Live, not-deleted records of a collection for one farm.
  Stream<List<SyncRecord>> watch(String tenantId, String collection);

  Future<List<SyncRecord>> all(String tenantId, String collection, {bool includeDeleted = false});

  /// Outbox entries ready to send now, oldest first.
  Future<List<OutboxEntry>> due(DateTime now, {int limit = 20});

  Future<List<OutboxEntry>> outbox();

  /// The cloud has [version] of the record. Clears the outbox entry only if
  /// no newer local edit was made while sending.
  Future<void> markSent(String collection, String id, int version);

  Future<void> markRetry(OutboxEntry entry);

  /// "Sync now": failed entries become due again. Returns how many.
  Future<int> retryFailed();

  /// Merges records pulled from the cloud. Returns the conflicts it kept.
  Future<List<SyncConflict>> applyRemote(List<SyncRecord> records, MergePolicy policy);

  Future<String?> cursor(String tenantId, String collection);

  Future<void> setCursor(String tenantId, String collection, String? cursor);

  Future<OutboxCounts> counts();

  /// Fires after every change (write, send, merge).
  Stream<void> changes();
}
