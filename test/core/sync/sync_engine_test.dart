import 'dart:math';

import 'package:farm_tap/core/sync/connectivity_monitor.dart';
import 'package:farm_tap/core/sync/data/fake/fake_remote_store.dart';
import 'package:farm_tap/core/sync/data/memory_record_store.dart';
import 'package:farm_tap/core/sync/domain/merge_policy.dart';
import 'package:farm_tap/core/sync/domain/remote_store.dart';
import 'package:farm_tap/core/sync/domain/retry_backoff.dart';
import 'package:farm_tap/core/sync/domain/sync_record.dart';
import 'package:farm_tap/core/sync/sync_engine.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestClock extends Clock {
  DateTime at = DateTime(2026, 11, 7, 6, 52);
  @override
  DateTime now() => at;
}

const tenant = 'farm-rwemera';

SyncRecord milk(String id, double litres, {DateTime? at, int version = 1, String device = 'phone-a'}) {
  final t = at ?? DateTime(2026, 11, 7, 6, 52);
  return SyncRecord(
    collection: 'milkRecords',
    id: id,
    tenantId: tenant,
    body: {'litres': litres, 'session': 'am'},
    createdAt: t,
    updatedAt: t,
    createdBy: 'staff-amos',
    updatedBy: 'staff-amos',
    deviceId: device,
    version: version,
  );
}

SyncRecord animal(String id, String name, {required DateTime at, int version = 1, String device = 'phone-a'}) =>
    SyncRecord(
      collection: 'animals',
      id: id,
      tenantId: tenant,
      body: {'name': name},
      createdAt: at,
      updatedAt: at,
      createdBy: 'owner',
      updatedBy: 'owner',
      deviceId: device,
      version: version,
    );

void main() {
  late _TestClock clock;
  late MemoryRecordStore store;
  late FakeRemoteStore remote;
  late ManualConnectivity net;
  late SyncEngine engine;

  SyncEngine build({RetryBackoff backoff = const RetryBackoff()}) => SyncEngine(
    store: store,
    remote: remote,
    connectivity: net,
    clock: clock,
    tenants: () => [tenant],
    collections: const ['milkRecords', 'animals', auditCollection],
    backoff: backoff,
    debounce: const Duration(days: 1),
    periodic: const Duration(days: 1),
  );

  setUp(() {
    clock = _TestClock();
    store = MemoryRecordStore();
    remote = FakeRemoteStore();
    net = ManualConnectivity();
    engine = build();
  });

  tearDown(() => engine.dispose());

  test('a write is saved on the phone first, then sent', () async {
    await store.write(milk('m1', 9.5), auditAction: 'create');
    expect((await store.counts()).waiting, 2); // record + audit entry
    await engine.sync();
    expect((await store.counts()).waiting, 0);
    expect((await store.get('milkRecords', 'm1'))!.syncStatus, SyncStatus.synced);
    expect(remote.records.where((r) => r.collection == 'milkRecords'), hasLength(1));
    expect(remote.records.where((r) => r.collection == auditCollection), hasLength(1));
  });

  test('offline: records wait; when the network returns they are sent', () async {
    net.set(online: false);
    await engine.start();
    await store.write(milk('m1', 9.5));
    await store.write(milk('m2', 8.8));
    await engine.sync();
    expect(remote.pushCalls, 0);
    expect(engine.current.waiting, 2);
    expect(engine.current.online, isFalse);
    net.set(online: true);
    await pumpEventQueue();
    await engine.idle();
    expect(engine.current.waiting, 0);
    expect(engine.current.online, isTrue);
    expect(remote.records, hasLength(2));
  });

  test('flaky 2G: 30% of calls drop, every record still arrives exactly once', () async {
    remote = FakeRemoteStore(dropRate: 0.3, random: Random(42));
    engine = build(backoff: RetryBackoff(maxAttempts: 1000, random: Random(1)));
    for (var i = 0; i < 150; i++) {
      await store.write(milk('m$i', 5 + i % 7));
    }
    for (var round = 0; round < 200 && (await store.outbox()).isNotEmpty; round++) {
      await engine.sync();
      clock.at = clock.at.add(const Duration(hours: 2));
    }
    expect(await store.outbox(), isEmpty);
    final ids = remote.records.map((r) => r.id).toList();
    expect(ids, hasLength(150));
    expect(ids.toSet(), hasLength(150));
    final local = await store.all(tenant, 'milkRecords');
    expect(local.every((r) => r.syncStatus == SyncStatus.synced), isTrue);
  });

  test('an edit made while sending stays queued', () async {
    await store.write(animal('a1', 'Bihogo', at: clock.at));
    final sent = (await store.due(clock.now())).single;
    await store.write(animal('a1', 'Bihogo II', at: clock.at.add(const Duration(minutes: 1)), version: 2));
    await store.markSent('animals', 'a1', sent.version);
    final left = await store.outbox();
    expect(left.single.version, 2);
    expect((await store.get('animals', 'a1'))!.syncStatus, SyncStatus.pending);
  });

  test('a refused record shows as failed and comes back on Sync now', () async {
    remote = FakeRemoteStore(rejectCollections: {'animals'});
    engine = build();
    await store.write(animal('a1', 'Bihogo', at: clock.at));
    await engine.sync();
    expect((await store.counts()).failed, 1);
    expect((await store.get('animals', 'a1'))!.syncStatus, SyncStatus.failed);
    remote.rejectCollections.clear();
    await engine.sync();
    expect((await store.counts()).failed, 0);
    expect((await store.get('animals', 'a1'))!.syncStatus, SyncStatus.synced);
  });

  test('after too many network failures a record is failed but never dropped', () async {
    remote = FakeRemoteStore(dropRate: 1);
    engine = build(backoff: RetryBackoff(maxAttempts: 3, random: Random(1)));
    await store.write(milk('m1', 9.5));
    // "Sync now" makes failed records due again, so exactly 3 tries here.
    for (var i = 0; i < 3; i++) {
      await engine.sync();
      clock.at = clock.at.add(const Duration(hours: 2));
    }
    expect((await store.counts()).failed, 1);
    remote.dropRate = 0;
    await engine.sync();
    expect(await store.outbox(), isEmpty);
    expect(remote.records.single.id, 'm1');
  });

  test("pull brings other phones' records, page by page", () async {
    for (var i = 0; i < 250; i++) {
      remote.serverWrite(milk('other-$i', 6, device: 'phone-b').copyWith(syncStatus: SyncStatus.synced));
    }
    await engine.sync();
    expect(await store.all(tenant, 'milkRecords'), hasLength(250));
    expect(await store.cursor(tenant, 'milkRecords'), isNotNull);
  });

  group('merge rules', () {
    const policy = MergePolicy();
    final t = DateTime(2026, 11, 7, 6, 52);

    test('newest edit wins; a lost local edit is kept in the audit log', () async {
      await store.write(animal('a1', 'Local name', at: t, version: 2));
      final conflicts = await store.applyRemote([
        animal('a1', 'Other phone', at: t.add(const Duration(minutes: 5)), version: 2, device: 'phone-b'),
      ], policy);
      expect(conflicts.single.needsReview, isFalse);
      expect((await store.get('animals', 'a1'))!.body['name'], 'Other phone');
      final audit = await store.all(tenant, auditCollection);
      expect(audit.single.body['action'], 'conflict');
    });

    test('an older remote copy never overwrites a newer local edit', () async {
      await store.write(animal('a1', 'Local name', at: t.add(const Duration(minutes: 5)), version: 2));
      await store.applyRemote([animal('a1', 'Old', at: t, device: 'phone-b')], policy);
      expect((await store.get('animals', 'a1'))!.body['name'], 'Local name');
      expect(await store.outbox(), hasLength(1));
    });

    test('milk records are append-only: our unsent record is kept', () {
      final outcome = policy.resolve(milk('m1', 9.5), milk('m1', 9.5), hasUnsentEdit: true);
      expect(outcome.winner, MergeWinner.local);
    });

    test('a lost money or litres edit is flagged for the owner', () {
      final local = milk('s1', 9.5).copyWith();
      final remoteRec = SyncRecord.fromJson({
        ...local.toJson(),
        'collection': 'paymentPeriods',
        'updatedAt': t.add(const Duration(hours: 1)).toIso8601String(),
      });
      final localPeriod = SyncRecord.fromJson({...local.toJson(), 'collection': 'paymentPeriods'});
      final outcome = policy.resolve(localPeriod, remoteRec, hasUnsentEdit: true);
      expect(outcome.winner, MergeWinner.remote);
      expect(outcome.needsReview, isTrue);
    });

    test('same time: every phone picks the same winner', () {
      final a = animal('a1', 'A', at: t);
      final b = animal('a1', 'B', at: t, device: 'phone-b');
      expect(policy.resolve(a, b, hasUnsentEdit: true).winner, MergeWinner.remote);
      expect(policy.resolve(b, a, hasUnsentEdit: true).winner, MergeWinner.local);
    });
  });

  test('backoff grows, is capped at 1 hour and has jitter', () {
    final b = RetryBackoff(random: Random(3));
    expect(b.delay(1).inSeconds, inInclusiveRange(15, 30));
    expect(b.delay(4).inSeconds, inInclusiveRange(120, 240));
    expect(b.delay(30), lessThanOrEqualTo(const Duration(hours: 1)));
    expect(b.delay(30), greaterThanOrEqualTo(const Duration(minutes: 30)));
  });

  test('a push that saved but lost its reply is not duplicated on retry', () async {
    // Drop only the reply: the server saved, the phone thinks it failed.
    remote = _ReplyDropper();
    engine = build(backoff: RetryBackoff(random: Random(1)));
    await store.write(milk('m1', 9.5));
    await engine.sync();
    expect(await store.outbox(), hasLength(1));
    clock.at = clock.at.add(const Duration(hours: 2));
    await engine.sync();
    expect(await store.outbox(), isEmpty);
    expect(remote.records, hasLength(1));
  });
}

class _ReplyDropper extends FakeRemoteStore {
  var _first = true;

  @override
  Future<PushResult> push(String tenantId, List<SyncRecord> records) async {
    final result = await super.push(tenantId, records);
    if (_first) {
      _first = false;
      throw const FakeNetworkError('reply lost');
    }
    return result;
  }
}
