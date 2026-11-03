import 'package:farm_tap/core/money/data/fake/fake_money_repository.dart';
import 'package:farm_tap/core/people/data/fake/fake_staff_access_repository.dart';
import 'package:farm_tap/core/people/domain/staff_member.dart';
import 'package:farm_tap/core/sync/data/memory_record_store.dart';
import 'package:farm_tap/core/sync/record_journal.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/core/utils/id_generator.dart';
import 'package:farm_tap/sectors/cattle/breeding/data/fake/fake_breeding_repository.dart';
import 'package:farm_tap/sectors/cattle/collection_centre/data/fake/fake_centre_repository.dart';
import 'package:farm_tap/sectors/cattle/feeding/data/fake/fake_feed_repository.dart';
import 'package:farm_tap/sectors/cattle/health/data/local/local_treatment_repository.dart';
import 'package:farm_tap/sectors/cattle/health/domain/health_models.dart';
import 'package:farm_tap/sectors/cattle/herd/data/local/local_herd_repository.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/entities/animal.dart';
import 'package:farm_tap/sectors/cattle/home/data/fake/fake_home_repository.dart';
import 'package:farm_tap/sectors/cattle/milk/data/local/local_milk_repository.dart';
import 'package:farm_tap/sectors/cattle/milk/domain/milk_models.dart';
import 'package:farm_tap/sectors/cattle/money/data/fake/fake_farm_money_repository.dart';
import 'package:farm_tap/sectors/cattle/owner_reports/data/fake/fake_daily_report_repository.dart';
import 'package:farm_tap/sectors/cattle/workers/data/fake/fake_workers_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Real-data mode: a new farm starts empty and every number comes from the
/// records it saves (decision 0014).
void main() {
  const tenant = 'farm-new';
  final clock = FakeClock();
  late MemoryRecordStore store;
  late RecordJournal journal;
  late LocalHerdRepository herd;
  late LocalMilkRepository milk;
  late LocalTreatmentRepository health;
  late FakeMoneyRepository money;
  late FakeBreedingRepository breeding;

  Animal cow(String id, String tag, {DairyStatus status = DairyStatus.milking, AnimalSex sex = AnimalSex.female}) =>
      Animal(
        id: id,
        tenantId: tenant,
        tagNumber: tag,
        name: 'Cow $tag',
        sex: sex,
        breed: 'Ankole',
        dateOfBirth: DateTime(2021),
        status: AnimalStatus.active,
        createdAt: clock.now(),
        updatedAt: clock.now(),
        createdBy: 'owner',
        updatedBy: 'owner',
        deviceId: 'phone-a',
        syncStatus: SyncStatus.pending,
        dairyStatus: status,
      );

  /// A fresh app on the same phone: everything is read back from the store.
  void open() {
    journal = RecordJournal(
      store: store,
      clock: clock,
      ids: UuidGenerator(),
      deviceId: 'phone-a',
      tenantId: () => tenant,
      actor: () => 'owner-uid',
    );
    money = FakeMoneyRepository(clock, journal: journal, withSamples: false);
    breeding = FakeBreedingRepository(clock, money, journal: journal, herd: () => herd, me: () => 'Victor');
    health = LocalTreatmentRepository(journal: journal, clock: clock, herd: () => herd, me: () => 'Victor');
    milk = LocalMilkRepository(journal: journal, clock: clock, treatments: health, herd: () => herd);
    herd = LocalHerdRepository(
      journal: journal,
      clock: clock,
      treatments: health,
      breeding: breeding,
      milk: () => milk,
    );
  }

  setUp(() {
    store = MemoryRecordStore();
    open();
  });

  test('a new farm has no sample animals or milk', () async {
    expect((await herd.counts()).data!.total, 0);
    final s = (await milk.session(MilkSession.morning)).data!;
    expect(s.totalCows, 0);
    expect(s.litres, 0);
    expect((await milk.trend(TrendRange.week)).data!.total, 0);
    expect((await herd.nextTag()).data, isNotEmpty);
  });

  test('animals and milk are saved, counted, and survive a restart', () async {
    await herd.addAnimal(cow('a1', 'FT-001'));
    await herd.addAnimal(cow('a2', 'FT-002', status: DairyStatus.heifer));
    await herd.addAnimal(cow('a3', 'FT-003', status: DairyStatus.calf));
    await herd.addAnimal(cow('b1', 'FT-004', status: DairyStatus.bull, sex: AnimalSex.male));
    await milk.recordCow('a1', MilkSession.morning, 9.5, notForSale: false, recordedBy: 'owner');
    await milk.recordTotal(MilkSession.evening, 4, recordedBy: 'owner');

    open();
    expect((await herd.counts()).data!.total, 4);
    final s = (await milk.session(MilkSession.morning)).data!;
    expect(s.totalCows, 2, reason: 'the calf and the bull are not milked');
    expect(s.recordedCount, 1);
    expect(s.litres, 9.5);
    expect(s.cows.firstWhere((c) => c.id == 'a1').recordedLitres, 9.5);
    expect((await milk.trend(TrendRange.week)).data!.total, 13.5);
    expect((await milk.records(from: clock.today())).data, hasLength(2));
    expect((await herd.rows()).data, hasLength(4));
    expect((await herd.detail('a1')).data!.timeline, isNotEmpty);
    expect((await store.all(tenant, 'milkRecords')).every((r) => r.createdBy == 'owner-uid'), isTrue);
  });

  test('a treatment puts the cow on withdrawal; her milk is not for sale', () async {
    await herd.addAnimal(cow('a1', 'FT-001'));
    final drug = (await health.drugs()).data!.firstWhere((d) => d.withdrawalDays > 0);
    await health.addTreatment(
      NewTreatment(animalId: 'a1', condition: Condition.mastitis, drugId: drug.id, given: clock.now()),
    );

    open();
    final c = (await milk.session(MilkSession.morning)).data!.cows.single;
    expect(c.treatment, isNotNull);
    expect((await health.withdrawals(clock.now())).data, hasLength(1));
    expect((await herd.counts()).data!.treated, 1);
  });

  test('a death moves the animal to past animals; records are kept', () async {
    await herd.addAnimal(cow('a1', 'FT-001'));
    await herd.recordDeath('a1', cause: 'East Coast Fever');
    open();
    expect((await herd.counts()).data!.total, 0);
    expect(await store.get('animals', 'a1'), isNotNull);
  });

  test('every other section starts empty in real-data mode', () async {
    final staff = FakeStaffAccessRepository(journal: journal, withSamples: false);
    final feed = FakeFeedRepository(clock, milk, money, journal: journal, withSamples: false);
    final workers = FakeWorkersRepository(clock, staff, money, milk, journal: journal, withSamples: false);
    final centre = FakeCentreRepository(clock, journal: journal, withSamples: false);
    final home = FakeHomeRepository(
      clock,
      health,
      breeding: breeding,
      feed: feed,
      workers: workers,
      herd: herd,
      milk: milk,
    );
    final report = FakeDailyReportRepository(
      clock: clock,
      farmName: () => 'New farm',
      home: home,
      milk: milk,
      treatments: health,
      feed: feed,
      money: FakeFarmMoneyRepository(clock, money, milk),
      withSamples: false,
    );

    expect((await staff.staff()).data, isEmpty);
    expect((await staff.nextBlankCard()).data, isNull);
    expect((await money.expenses()).data, isEmpty);
    expect((await feed.summary()).data!.costThisMonth, 0);
    expect(feed.suppliers, isEmpty);
    expect((await workers.today()).data, isEmpty);
    expect((await workers.tasks()).data, isEmpty);
    expect((await breeding.animals()).data, isEmpty);
    expect((await breeding.summary()).data!.pregnancies, isEmpty);
    expect(breeding.technicians, ['Victor']);
    expect((await centre.farmers()).data, isEmpty);
    expect((await centre.today()).data!.litres, 0);
    expect((await centre.payments()).data!.lines, isEmpty);
    final summary = (await home.summary()).data!;
    expect(summary.milkToday, 0);
    expect(summary.cows, 0);
    expect((await home.attention()).data, isEmpty);
    expect((await home.workerDay('nobody')).data!.dippingDue, isNull);
    final r = (await report.today()).data!;
    expect(r.milkLitres, 0);
    expect((await report.settings()).data!.phone, isEmpty);
  });

  test('real-mode records flow into home, breeding, staff and centre', () async {
    await herd.addAnimal(cow('a1', 'FT-001'));
    await milk.recordCow('a1', MilkSession.morning, 8, notForSale: false, recordedBy: 'owner');
    expect((await breeding.animals()).data!.single.id, 'a1');

    final staff = FakeStaffAccessRepository(journal: journal, withSamples: false);
    final amos = (await staff.addStaff(name: 'Amos', role: StaffRole.herdsman, pin: '4821')).data!;
    expect((await staff.verifyPin(amos.id, '1234')).data, isA<PinRejected>(), reason: 'no shared demo PIN');
    final restarted = FakeStaffAccessRepository(journal: journal, withSamples: false);
    await restarted.restore();
    expect((await restarted.verifyPin(amos.id, '4821')).data, isA<PinAccepted>());

    final centre = FakeCentreRepository(clock, journal: journal, withSamples: false);
    final f = (await centre.addFarmer(name: 'Robert', phone: '+256 772 000 111', village: 'Kashari')).data!;
    await centre.recordDelivery(f.id, 20);
    expect((await centre.today()).data!.litres, 20);
    expect((await centre.payments()).data!.lines.single.litres, 20);
    expect((await centre.smsPreview()).data!.weekLitres, 20);

    final feed = FakeFeedRepository(clock, milk, money, journal: journal, withSamples: false);
    final workers = FakeWorkersRepository(clock, staff, money, milk, journal: journal, withSamples: false);
    final home = FakeHomeRepository(
      clock,
      health,
      breeding: breeding,
      feed: feed,
      workers: workers,
      herd: herd,
      milk: milk,
    );
    final summary = (await home.summary()).data!;
    expect(summary.milkToday, 8);
    expect(summary.milking, 1);
    expect(summary.cows, 1);
  });
}
