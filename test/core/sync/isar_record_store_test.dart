import 'dart:io';

import 'package:farm_tap/core/sync/data/isar/isar_record_store.dart';
import 'package:farm_tap/core/sync/data/memory_record_store.dart';
import 'package:farm_tap/core/sync/domain/merge_policy.dart';
import 'package:farm_tap/core/sync/domain/sync_record.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import '../../helpers/isar_core.dart';

const tenant = 'farm-rwemera';
final t0 = DateTime(2026, 11, 7, 6, 52);

SyncRecord rec(String collection, String id, {int version = 1, Map<String, Object?>? body, DateTime? at}) => SyncRecord(
  collection: collection,
  id: id,
  tenantId: tenant,
  body: body ?? {'litres': 9.5},
  createdAt: t0,
  updatedAt: at ?? t0,
  createdBy: 'staff-amos',
  updatedBy: 'staff-amos',
  deviceId: 'phone-a',
  version: version,
);

void main() {
  late Directory dir;
  late Isar isar;
  late IsarRecordStore store;
  var available = false;

  setUpAll(() async => available = await loadIsarCoreForTests());

  setUp(() async {
    if (!available) return;
    dir = await Directory.systemTemp.createTemp('farmtap_isar');
    isar = await Isar.open(syncSchemas, directory: dir.path, name: 'test${dir.path.hashCode}');
    store = IsarRecordStore(isar);
  });

  tearDown(() async {
    if (!available) return;
    await isar.close(deleteFromDisk: true);
    await dir.delete(recursive: true);
  });

  test('records and the outbox survive closing and reopening the database', () async {
    if (!available) return markTestSkipped('Isar core not available');
    await store.write(rec('milkRecords', 'm1'), auditAction: 'create');
    final name = isar.name;
    await isar.close();
    isar = await Isar.open(syncSchemas, directory: dir.path, name: name);
    store = IsarRecordStore(isar);
    expect((await store.get('milkRecords', 'm1'))!.body['litres'], 9.5);
    final outbox = await store.outbox();
    expect(outbox.map((e) => e.collection), ['milkRecords', auditCollection]);
  });

  test('same rules as the memory store: send, newer edit, retry, merge', () async {
    if (!available) return markTestSkipped('Isar core not available');
    await store.write(rec('animals', 'a1', body: {'name': 'Bihogo'}));
    await store.write(rec('animals', 'a1', version: 2, body: {'name': 'Bihogo II'}));
    await store.markSent('animals', 'a1', 1);
    expect((await store.outbox()).single.version, 2);
    await store.markRetry((await store.outbox()).single.copyWith(attempts: 8, failed: true));
    expect((await store.counts()).failed, 1);
    expect(await store.due(t0), isEmpty);
    expect(await store.retryFailed(), 1);
    expect(await store.due(t0), hasLength(1));
    await store.markSent('animals', 'a1', 2);
    expect((await store.counts()).synced, 1);

    await store.write(rec('animals', 'a2', version: 2, body: {'name': 'Mine'}));
    final conflicts = await store.applyRemote([
      rec('animals', 'a2', version: 2, body: {'name': 'Theirs'}, at: t0.add(const Duration(minutes: 1))),
    ], const MergePolicy());
    expect(conflicts, hasLength(1));
    expect((await store.get('animals', 'a2'))!.body['name'], 'Theirs');
    expect((await store.all(tenant, auditCollection)).single.body['action'], 'conflict');

    await store.setCursor(tenant, 'animals', '42');
    expect(await store.cursor(tenant, 'animals'), '42');
  });
}
