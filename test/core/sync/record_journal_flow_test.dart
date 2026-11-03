import 'package:farm_tap/core/people/data/fake/fake_staff_access_repository.dart';
import 'package:farm_tap/core/people/domain/staff_member.dart';
import 'package:farm_tap/core/sync/connectivity_monitor.dart';
import 'package:farm_tap/core/sync/data/fake/fake_remote_store.dart';
import 'package:farm_tap/core/sync/data/memory_record_store.dart';
import 'package:farm_tap/core/sync/domain/sync_record.dart';
import 'package:farm_tap/core/sync/record_journal.dart';
import 'package:farm_tap/core/sync/sync_engine.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/core/utils/id_generator.dart';
import 'package:farm_tap/sectors/cattle/collection_centre/data/fake/fake_centre_repository.dart';
import 'package:farm_tap/sectors/cattle/health/data/fake/fake_treatment_repository.dart';
import 'package:farm_tap/sectors/cattle/milk/data/fake/fake_milk_repository.dart';
import 'package:farm_tap/sectors/cattle/milk/domain/milk_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Decision 0014 end to end: a screen's save goes onto the phone, waits
/// while offline, and reaches the cloud when the network returns.
void main() {
  const tenant = 'farm-rwemera';
  late MemoryRecordStore store;
  late FakeRemoteStore remote;
  late ManualConnectivity net;
  late SyncEngine engine;
  late RecordJournal journal;
  final clock = FakeClock();

  setUp(() {
    store = MemoryRecordStore();
    remote = FakeRemoteStore();
    net = ManualConnectivity(online: false);
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
      connectivity: net,
      clock: clock,
      tenants: () => [tenant],
      collections: const ['milkRecords', 'deliveries', 'staff', auditCollection],
      debounce: const Duration(days: 1),
      periodic: const Duration(days: 1),
    );
  });

  tearDown(() => engine.dispose());

  test('milk recorded offline waits on the phone, then reaches the cloud', () async {
    final milk = FakeMilkRepository(clock, FakeTreatmentRepository(clock), journal: journal);
    await milk.recordCow('animal-FT-022', MilkSession.morning, 9.5, notForSale: false, recordedBy: 'staff-ta');
    final saved = await store.all(tenant, 'milkRecords');
    expect(saved.single.body['litres'], 9.5);
    expect(saved.single.createdBy, 'staff-ta');
    expect(saved.single.deviceId, 'phone-a');
    expect(saved.single.id, matches(RegExp(r'^[0-9a-f-]{36}$')));
    await engine.sync();
    expect(remote.records, isEmpty);
    expect((await store.counts()).waiting, 2); // record + audit

    net.set(online: true);
    await engine.sync();
    expect(remote.records.where((r) => r.collection == 'milkRecords').single.body['litres'], 9.5);
    expect((await store.counts()).waiting, 0);
  });

  test('Undo on a delivery is a soft delete that also syncs', () async {
    net.set(online: true);
    final centre = FakeCentreRepository(clock, journal: journal);
    final d = (await centre.recordDelivery('farmer-0142', 12)).data!;
    await centre.undoDelivery(d.id);
    await engine.sync();
    final cloud = remote.records.where((r) => r.collection == 'deliveries').single;
    expect(cloud.isDeleted, isTrue);
    expect(cloud.version, 2);
    expect(cloud.body['litres'], 12);
  });

  test('a new worker syncs with a PIN hash, never the PIN', () async {
    final staff = FakeStaffAccessRepository(journal: journal);
    final s = (await staff.addStaff(name: 'Kato', role: StaffRole.worker, pin: '4821')).data!;
    final rec = (await store.get('staff', s.id))!;
    expect(rec.body['pinHash'], startsWith(r'pbkdf2-sha256$'));
    expect(rec.toJson().toString(), isNot(contains('4821')));
    expect(rec.syncStatus, SyncStatus.pending);
  });
}
