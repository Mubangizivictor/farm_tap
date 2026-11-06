import 'package:farm_tap/core/sms/phone_messenger.dart';
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

  RecordJournal journalFor(FakeClock clock) => RecordJournal(
    store: MemoryRecordStore(),
    clock: clock,
    ids: UuidGenerator(),
    deviceId: 'phone-a',
    tenantId: () => 'centre-1',
    actor: () => 'clerk-uid',
  );

  test('Uganda numbers become international, links are encoded', () {
    expect(PhoneMessenger.international('0772 451 908'), '+256772451908');
    expect(PhoneMessenger.international('256772451908'), '+256772451908');
    expect(PhoneMessenger.international('+256 772-451-908'), '+256772451908');
    expect(PhoneMessenger.international('772451908'), '+256772451908');
    expect(PhoneMessenger.international(''), '');
    expect(PhoneMessenger.smsUri('0772451908', 'Hi & bye').toString(), 'sms:+256772451908?body=Hi%20%26%20bye');
    expect(PhoneMessenger.whatsappUri('+256 772 451 908', 'Hi').toString(), 'https://wa.me/256772451908?text=Hi');
  });

  test('sending from the phone opens the app and marks the message sent', () async {
    final clock = FakeClock();
    final journal = journalFor(clock);
    final outbox = SmsOutbox(journal);
    await outbox.queue(to: '0772451908', text: 'FarmTap: 38 L', kind: 'deliveryReceipt', name: 'Robert');
    final waiting = await outbox.waiting();
    expect(waiting.single.name, 'Robert');

    Uri? opened;
    final ok = await outbox.sendFromPhone(
      waiting.single,
      MessageRoute.whatsapp,
      messenger: PhoneMessenger(
        launch: (uri) async {
          opened = uri;
          return true;
        },
      ),
    );
    expect(ok, isTrue);
    expect(opened.toString(), startsWith('https://wa.me/256772451908?text='));
    expect(await outbox.waiting(), isEmpty);
    final all = await outbox.all();
    expect(all.single.status, SmsOutbox.sentFromPhone);
    final record = (await journal.load(SmsOutbox.collection)).single;
    expect(record.body['via'], 'whatsapp');
    expect(record.version, 2);
  });

  test('when no app opens, the message keeps waiting', () async {
    final outbox = SmsOutbox(journalFor(FakeClock()));
    await outbox.queue(to: '0772451908', text: 'x', kind: 'statement');
    final m = (await outbox.waiting()).single;
    final ok = await outbox.sendFromPhone(m, MessageRoute.sms, messenger: PhoneMessenger(launch: (_) async => false));
    expect(ok, isFalse);
    expect(await outbox.waiting(), hasLength(1));
  });

  test('weekly statements are queued for farmers who delivered', () async {
    final clock = FakeClock();
    final journal = journalFor(clock);
    final centre = FakeCentreRepository(clock, journal: journal, sms: SmsOutbox(journal), withSamples: false);
    final robert = (await centre.addFarmer(
      name: 'Muhwezi Robert',
      phone: '+256 772 451 908',
      village: 'Kashari',
    )).data!;
    await centre.addFarmer(name: 'No Milk', phone: '+256 700 000 001', village: 'Kashari');
    await centre.recordDelivery(robert.id, 20);
    final before = (await SmsOutbox(journal).waiting()).length;

    final count = (await centre.sendStatements()).data;
    expect(count, 1);
    final statements = (await SmsOutbox(journal).waiting()).where((m) => m.kind == 'statement').toList();
    expect(statements, hasLength(1));
    expect(statements.single.text, contains('Muhwezi Robert'));
    expect(statements.single.text, contains('20.0 L'));
    expect(statements.single.text, contains('UGX 22,000'));
    expect((await SmsOutbox(journal).waiting()).length, before + 1);
  });
}
