import 'dart:async';
import 'dart:math';

import 'package:farm_tap/core/sync/domain/remote_store.dart';
import 'package:farm_tap/core/sync/domain/sync_record.dart';

/// Thrown by [FakeRemoteStore] to act like a dropped 2G connection.
class FakeNetworkError implements Exception {
  const new([this.message = 'connection dropped']);
  final String message;

  @override
  String toString() => 'FakeNetworkError: $message';
}

/// Stands in for Firestore until Phase 2 (decision 0014). Behaves like the
/// real thing where it matters: set-by-id (idempotent), a server sequence as
/// the pull cursor, and, when [dropRate] > 0, calls that fail *after* the
/// server saved the data (the hardest case for duplicates).
class FakeRemoteStore implements RemoteStore {
  new({this.dropRate = 0, Random? random, this.rejectCollections = const {}}) : _random = random ?? Random(7);

  /// Share of calls that fail (0–1).
  double dropRate;
  final Random _random;
  final Set<String> rejectCollections;

  final _docs = <String, _Doc>{};
  var _seq = 0;
  int pushCalls = 0;

  /// Every record the "cloud" holds, for tests.
  List<SyncRecord> get records => [for (final d in _docs.values) d.record];

  final _changes = StreamController<String>.broadcast();

  /// Another phone's edit arriving in the cloud.
  void serverWrite(SyncRecord record) {
    _docs['${record.tenantId}/${record.key}'] = _Doc(record, ++_seq);
    _changes.add('${record.tenantId}/${record.collection}');
  }

  @override
  Stream<void> changes(String tenantId, List<String> collections) =>
      _changes.stream.where((k) => collections.any((c) => k == '$tenantId/$c')).map((_) {});

  @override
  Future<PushResult> push(String tenantId, List<SyncRecord> records) async {
    pushCalls++;
    if (_drop()) throw const FakeNetworkError('before save');
    final acks = <String, PushAck>{};
    final reasons = <String, String>{};
    for (final r in records) {
      if (rejectCollections.contains(r.collection)) {
        acks[r.key] = PushAck.rejected;
        reasons[r.key] = 'permission-denied';
        continue;
      }
      final docKey = '$tenantId/${r.key}';
      final existing = _docs[docKey];
      // Idempotent: the same or an older version changes nothing.
      if (existing == null || r.version > existing.record.version) {
        _docs[docKey] = _Doc(r.copyWith(syncStatus: SyncStatus.synced), ++_seq);
      }
      acks[r.key] = PushAck.accepted;
    }
    if (_drop()) throw const FakeNetworkError('after save, before reply');
    return PushResult(acks, reasons: reasons);
  }

  @override
  Future<PullPage> pull(String tenantId, String collection, {String? cursor, int limit = 100}) async {
    if (_drop()) throw const FakeNetworkError('pull');
    final after = int.tryParse(cursor ?? '') ?? 0;
    final page =
        _docs.entries
            .where((e) => e.key.startsWith('$tenantId/$collection/') && e.value.seq > after)
            .map((e) => e.value)
            .toList()
          ..sort((a, b) => a.seq.compareTo(b.seq));
    final slice = page.take(limit).toList();
    return PullPage(
      records: [for (final d in slice) d.record],
      cursor: slice.isEmpty ? cursor : '${slice.last.seq}',
      hasMore: page.length > slice.length,
    );
  }

  bool _drop() => dropRate > 0 && _random.nextDouble() < dropRate;
}

class _Doc {
  const new(this.record, this.seq);
  final SyncRecord record;
  final int seq;
}
