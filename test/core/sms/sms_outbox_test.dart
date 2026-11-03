import 'package:farm_tap/core/sms/sms_outbox.dart';
import 'package:farm_tap/core/sync/data/memory_record_store.dart';
import 'package:farm_tap/core/sync/record_journal.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/core/utils/id_generator.dart';
import 'package:farm_tap/sectors/cattle/collection_centre/data/fake/fake_centre_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a delivery queues an SMS receipt to the farmer; Undo withdraws it', () async {
    final clock = FakeClock();
    final store = MemoryRecordStore();
    final journal = RecordJournal(
      store: store,
      clock: clock,
      ids: UuidGenerator(),
      deviceId: 'phone-a',
      tenantId: () => 'centre-1',
      actor: () => 'clerk-uid',
    );
    final centre = FakeCentreRepository(clock, journal: journal, sms: SmsOutbox(journal), withSamples: false);
    final farmer = (await centre.addFarmer(
      name: 'Muhwezi Robert',
      phone: '+256 772 451 908',
      village: 'Kashari',
    )).data!;

    final d = (await centre.recordDelivery(farmer.id, 38)).data!;
    final queued = await journal.load(SmsOutbox.collection);
    expect(queued, hasLength(1));
    expect(queued.single.body['to'], '+256772451908');
    expect(queued.single.body['status'], 'queued');
    expect(queued.single.body['text'], contains('38.0 L'));

    await centre.undoDelivery(d.id);
    expect(await journal.load(SmsOutbox.collection), isEmpty);
    expect((await store.get(SmsOutbox.collection, queued.single.id))!.isDeleted, isTrue);
  });
}
