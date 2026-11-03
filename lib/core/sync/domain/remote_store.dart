import 'package:farm_tap/core/sync/domain/sync_record.dart';

/// What the cloud said about one pushed record.
enum PushAck {
  /// Saved (or already saved: pushes are idempotent by id + version).
  accepted,

  /// Refused for good (e.g. security rules). Retrying will not help.
  rejected,
}

class PushResult {
  const new(this.acks, {this.reasons = const {}});

  /// By [SyncRecord.key]. A missing key counts as a temporary failure.
  final Map<String, PushAck> acks;
  final Map<String, String> reasons;
}

class PullPage {
  const new({required this.records, required this.cursor, required this.hasMore});

  final List<SyncRecord> records;

  /// Opaque position to continue from (server time of the last record).
  final String? cursor;
  final bool hasMore;
}

/// The cloud side of sync. Firestore in Phase 2 (decision 0014); a fake until
/// then. Any network problem is thrown; the engine catches it and retries.
abstract class RemoteStore {
  Future<PushResult> push(String tenantId, List<SyncRecord> records);

  Future<PullPage> pull(String tenantId, String collection, {String? cursor, int limit});
}
