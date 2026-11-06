import 'package:farm_tap/core/money/data/fake/fake_money_repository.dart';
import 'package:farm_tap/core/people/data/fake/fake_staff_access_repository.dart';
import 'package:farm_tap/core/sync/connectivity_monitor.dart';
import 'package:farm_tap/core/sync/data/fake/fake_remote_store.dart';
import 'package:farm_tap/core/sync/data/memory_record_store.dart';
import 'package:farm_tap/core/sync/domain/sync_record.dart';
import 'package:farm_tap/core/sync/record_journal.dart';
import 'package:farm_tap/core/sync/sync_engine.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/core/utils/id_generator.dart';
import 'package:farm_tap/sectors/cattle/health/data/fake/fake_treatment_repository.dart';
import 'package:farm_tap/sectors/cattle/milk/data/fake/fake_milk_repository.dart';
import 'package:farm_tap/sectors/cattle/workers/data/fake/fake_workers_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// What the web app writes reaches the phone, and reads right there:
/// soon after it is saved, edits and removals included.
void main() {
  const tenant = 'farm-rwemera';
  final clock = FakeClock();

  SyncRecord web(String collection, String id, Map<String, Object?> body, {int version = 1, bool deleted = false}) {
    final t = clock.now();
    return SyncRecord(
      collection: collection,
      id: id,
      tenantId: tenant,
      body: body,
      createdAt: t,
      updatedAt: t.add(Duration(seconds: version)),
      createdBy: 'owner',
      updatedBy: 'owner',
      deviceId: 'web-abc',
      version: version,
      isDeleted: deleted,
      syncStatus: SyncStatus.synced,
    );
  }

  group('tasks from the web', () {
    final now = DateTime(2026, 11, 4, 9);

    test('the phone shape reads as is', () {
      final t = FakeWorkersRepository.taskFromBody('k1', {
        'title': 'Spray the calves',
        'staffId': 'staff-ta',
        'due': '2026-11-04T18:00:00.000',
        'when': 'before 10:00',
        'doneAt': null,
        'note': 'Use the blue pump',
        'priority': 'high',
      }, now: now);
      expect(t!.title, 'Spray the calves');
      expect(t.staffId, 'staff-ta');
      expect(t.due, DateTime(2026, 11, 4, 18));
      expect(t.doneAt, isNull);
    });

    test('an older web task (assignedTo, dueDate, status) still shows', () {
      final t = FakeWorkersRepository.taskFromBody('k2', {
        'title': 'Old web task',
        'assignedTo': 'staff-kr',
        'dueDate': '2026-11-04T00:00:00.000',
        'status': 'done',
      }, now: now);
      expect(t!.staffId, 'staff-kr');
      expect(t.due, DateTime(2026, 11, 4, 18));
      expect(t.when, '');
      expect(t.doneAt, isNotNull);
    });

    test('a task with no worker or title is skipped, not a crash', () {
      expect(FakeWorkersRepository.taskFromBody('k3', {'title': 'Nobody'}, now: now), isNull);
      expect(FakeWorkersRepository.taskFromBody('k4', {'staffId': 'staff-ta'}, now: now), isNull);
    });
  });

  group('end to end', () {
    late MemoryRecordStore store;
    late FakeRemoteStore remote;
    late SyncEngine engine;
    late RecordJournal journal;
    late FakeWorkersRepository workers;

    setUp(() {
      store = MemoryRecordStore();
      remote = FakeRemoteStore();
      journal = RecordJournal(
        store: store,
        clock: clock,
        ids: UuidGenerator(),
        deviceId: 'phone-a',
        tenantId: () => tenant,
        actor: () => 'staff-ta',
      );
      engine = SyncEngine(
        store: store,
        remote: remote,
        connectivity: ManualConnectivity(),
        clock: clock,
        tenants: () => [tenant],
        collections: const ['tasks', auditCollection],
        debounce: const Duration(days: 1),
        periodic: const Duration(days: 1),
        liveDelay: const Duration(milliseconds: 10),
      );
      workers = FakeWorkersRepository(
        clock,
        FakeStaffAccessRepository(),
        FakeMoneyRepository(clock),
        FakeMilkRepository(clock, FakeTreatmentRepository(clock)),
        journal: journal,
        withSamples: false,
      );
    });

    tearDown(() => engine.dispose());

    Future<List<String>> titles() async => [for (final t in (await workers.tasks()).data!) t.title];

    test('a task saved on the web is pulled within seconds, not at the next 15-minute pull', () async {
      await engine.start();
      remote.serverWrite(
        web('tasks', 'k1', {
          'title': 'Fix the fence',
          'staffId': 'staff-ta',
          'due': '2026-11-06T18:00:00.000',
          'when': '',
          'doneAt': null,
        }),
      );
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await engine.idle();
      expect((await store.all(tenant, 'tasks')).single.id, 'k1');
    });

    test('edited and removed on the web: the phone list follows', () async {
      final body = {
        'title': 'Fix the fence',
        'staffId': 'staff-ta',
        'due': '2026-11-06T18:00:00.000',
        'when': '',
        'doneAt': null,
      };
      remote.serverWrite(web('tasks', 'k1', body));
      await engine.sync();
      await workers.restore();
      expect(await titles(), ['Fix the fence']);

      remote.serverWrite(web('tasks', 'k1', {...body, 'title': 'Fix the paddock B fence'}, version: 2));
      await engine.sync();
      await workers.restore();
      expect(await titles(), ['Fix the paddock B fence']);

      remote.serverWrite(web('tasks', 'k1', {...body, 'title': 'Fix the paddock B fence'}, version: 3, deleted: true));
      await engine.sync();
      await workers.restore();
      expect(await titles(), isEmpty);
    });

    test('ticking a web task on the phone keeps its note and urgency', () async {
      remote.serverWrite(
        web('tasks', 'k1', {
          'title': 'Spray the calves',
          'staffId': 'staff-ta',
          'due': '2026-11-04T18:00:00.000',
          'when': '',
          'doneAt': null,
          'note': 'Use the blue pump',
          'priority': 'high',
        }),
      );
      await engine.sync();
      await workers.restore();
      await workers.setTaskDone('k1', done: true);
      final saved = await store.get('tasks', 'k1');
      expect(saved!.body['note'], 'Use the blue pump');
      expect(saved.body['priority'], 'high');
      expect(saved.body['doneAt'], isNotNull);
      expect(saved.version, 2);
    });
  });
}
