import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farm_tap/core/sync/domain/remote_store.dart';
import 'package:farm_tap/core/sync/domain/sync_record.dart';

/// Firestore side of sync (decision 0014, Phase 2).
///
/// Path: `tenants/{tenantId}/{collection}/{id}`. Each document is the
/// record's JSON plus `serverUpdatedAt` (server time), which the pull
/// orders by. Writes are `set` by the phone-made id, so a retry after a lost
/// reply changes nothing.
///
/// The SDK's own offline cache is turned off: our outbox already keeps every
/// record, and two queues would hide what is really sent.
class FirestoreRemoteStore implements RemoteStore {
  new(this.db, {this.timeout = const Duration(seconds: 45)}); // theme-guard: ignore (network timing, not UI)

  final FirebaseFirestore db;

  /// A write the server has not confirmed in this time counts as failed and
  /// is retried later (safe: writes are idempotent).
  final Duration timeout;

  static const serverTimeField = 'serverUpdatedAt';

  /// Call once at start-up, before any read or write.
  static void configure(FirebaseFirestore db) => db.settings = const Settings(persistenceEnabled: false);

  CollectionReference<Map<String, dynamic>> _col(String tenantId, String collection) =>
      db.collection('tenants').doc(tenantId).collection(collection);

  @override
  Future<PushResult> push(String tenantId, List<SyncRecord> records) async {
    if (records.isEmpty) return const PushResult({});
    try {
      final batch = db.batch();
      for (final r in records) {
        batch.set(_col(tenantId, r.collection).doc(r.id), _toDoc(r));
      }
      await batch.commit().timeout(timeout);
      return PushResult({for (final r in records) r.key: PushAck.accepted});
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied' && e.code != 'invalid-argument') rethrow;
      // One refused record fails the whole batch; send one by one so the
      // others still get through and only the refused one shows as failed.
      return await _pushOneByOne(tenantId, records);
    }
  }

  Future<PushResult> _pushOneByOne(String tenantId, List<SyncRecord> records) async {
    final acks = <String, PushAck>{};
    final reasons = <String, String>{};
    for (final r in records) {
      try {
        await _col(tenantId, r.collection).doc(r.id).set(_toDoc(r)).timeout(timeout);
        acks[r.key] = PushAck.accepted;
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied' && e.code != 'invalid-argument') rethrow;
        acks[r.key] = PushAck.rejected;
        reasons[r.key] = e.code;
      }
    }
    return PushResult(acks, reasons: reasons);
  }

  @override
  Future<PullPage> pull(String tenantId, String collection, {String? cursor, int limit = 100}) async {
    var q = _col(tenantId, collection).orderBy(serverTimeField).orderBy(FieldPath.documentId).limit(limit);
    final after = _Cursor.parse(cursor);
    if (after != null) q = q.startAfter([after.time, after.id]);
    final snap = await q.get(const GetOptions(source: Source.server)).timeout(timeout);
    final records = <SyncRecord>[];
    for (final d in snap.docs) {
      // Our own write still waiting for its server time: next pull gets it.
      if (d.data()[serverTimeField] == null) continue;
      records.add(_fromDoc(d.data()));
    }
    final last = snap.docs.where((d) => d.data()[serverTimeField] != null).lastOrNull;
    return PullPage(
      records: records,
      cursor: last == null ? cursor : _Cursor(last.data()[serverTimeField] as Timestamp, last.id).toString(),
      hasMore: snap.docs.length == limit,
    );
  }

  @override
  Stream<void> changes(String tenantId, List<String> collections) {
    // One small listener per collection on its newest document: a change
    // costs one read, an idle farm costs nothing after the first snapshot.
    final out = StreamController<void>();
    final subs = <StreamSubscription<Object?>>[];
    out
      ..onListen = () {
        for (final c in collections) {
          var first = true;
          subs.add(
            _col(tenantId, c).orderBy(serverTimeField, descending: true).limit(1).snapshots().listen(
              (snap) {
                // The first snapshot is what is already there.
                if (first) {
                  first = false;
                  return;
                }
                if (snap.metadata.hasPendingWrites) return;
                out.add(null);
              },
              // Permission or network trouble on one collection: the
              // periodic pull still covers it.
              onError: (Object _) {},
            ),
          );
        }
      }
      ..onCancel = () async {
        for (final s in subs) {
          await s.cancel();
        }
      };
    return out.stream;
  }

  static Map<String, Object?> _toDoc(SyncRecord r) => {...r.toJson(), serverTimeField: FieldValue.serverTimestamp()};

  static SyncRecord _fromDoc(Map<String, dynamic> data) =>
      SyncRecord.fromJson(Map<String, Object?>.from(data)..remove(serverTimeField));
}

/// Position after the last pulled document: server time + id, so documents
/// with the same time are never skipped between pages.
class _Cursor {
  const new(this.time, this.id);

  final Timestamp time;
  final String id;

  static _Cursor? parse(String? s) {
    if (s == null) return null;
    final parts = s.split('|');
    if (parts.length != 3) return null;
    final sec = int.tryParse(parts[0]);
    final nano = int.tryParse(parts[1]);
    if (sec == null || nano == null) return null;
    return _Cursor(Timestamp(sec, nano), parts[2]);
  }

  @override
  String toString() => '${time.seconds}|${time.nanoseconds}|$id';
}
