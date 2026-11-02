// Breeding numbers come from heat, service and check records only; herd
// counts and home alerts read the same records.
import 'package:farm_tap/core/money/data/fake/fake_money_repository.dart';
import 'package:farm_tap/core/money/domain/money_models.dart';
import 'package:farm_tap/core/tenancy/tenant_provider.dart';
import 'package:farm_tap/sectors/cattle/breeding/data/fake/fake_breeding_repository.dart';
import 'package:farm_tap/sectors/cattle/breeding/domain/breeding_models.dart';
import 'package:farm_tap/sectors/cattle/health/data/fake/fake_treatment_repository.dart';
import 'package:farm_tap/sectors/cattle/herd/data/fake/fake_herd_repository.dart';
import 'package:farm_tap/sectors/cattle/home/domain/home_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_deps.dart';

void main() {
  final clock = FixedClock();
  late FakeMoneyRepository money;
  late FakeBreedingRepository repo;

  setUp(() {
    money = FakeMoneyRepository(clock);
    repo = FakeBreedingRepository(clock, money);
  });

  test('J01 sample: 9 pregnant, 3 calving in 30 days, 2 checks, 1 to serve', () async {
    final s = (await repo.summary()).data!;
    expect(s.pregnancies.length, 9);
    expect(s.calvingSoon.map((p) => (p.animal.name, p.daysToCalving(clock.now()))), [
      ('Kyasiimire', 6),
      ('Kahara', 21),
      ('Bihogo', 27),
    ]);
    expect(s.checksDue, 2);
    expect(s.tasks.last.kind, BreedingTaskKind.serve);
    expect(s.tasks.last.record.animal.name, 'Rwemera');
  });

  test('rules: Kyasiimire served 6 Feb calves 13 Nov, dry off 60 days before', () async {
    final k = (await repo.summary()).data!.pregnancies.first;
    expect(k.service.at, DateTime(2026, 2, 6));
    expect(k.due, DateTime(2026, 11, 13));
    expect(k.dryOffFrom, DateTime(2026, 9, 14));
  });

  test('J02 AI on 7 Nov: check 2 Jan, calving 14 Aug 2027, cost is a breeding expense', () async {
    final s = (await repo.recordService(
      animalId: 'animal-FT-045',
      kind: ServiceKind.ai,
      at: clock.now(),
      straw: 'Friesian 4421',
      cost: 35000,
    )).data!;
    expect(s.checkFrom, DateTime(2027, 1, 2));
    expect(s.expectedCalving, DateTime(2027, 8, 14));
    final e = (await money.expenses(category: ExpenseCategory.breeding)).data!;
    expect(e.where((x) => x.sourceId == s.id).single.amount, 35000);
    // Served: no longer a heat to serve.
    expect((await repo.summary()).data!.tasks.any((t) => t.kind == BreedingTaskKind.serve), isFalse);
  });

  test('J03: a positive check adds a pregnancy and clears the to-do', () async {
    final before = (await repo.summary()).data!;
    final task = before.tasks.first;
    await repo.recordCheck(serviceId: task.record.id, pregnant: true, by: 'Dr. Kamugisha Ivan');
    final after = (await repo.summary()).data!;
    expect(after.pregnancies.length, 10);
    expect(after.checksDue, 1);
  });

  test('herd pregnant count and home calving alert read breeding', () async {
    final treatments = FakeTreatmentRepository(clock);
    final herd = fakeHerd(clock, InMemoryTenantProvider(), treatments);
    expect((await herd.counts()).data!.pregnant, 9);
    final alerts = (await fakeHome(clock, treatments).attention()).data!;
    final calving = alerts.whereType<CalvingDue>().single;
    expect((calving.animal, calving.due), ('Kyasiimire', DateTime(2026, 11, 13)));
    final low = alerts.whereType<StockLow>().single;
    expect((low.item, low.bagsLeft, low.daysLeft), ('Dairy meal', 2, 3));
  });

  test('E07 calving (herd) ends the pregnancy in breeding and herd counts', () async {
    final breeding = FakeBreedingRepository(clock, FakeMoneyRepository(clock));
    final herd = FakeHerdRepository(
      clock: clock,
      tenantProvider: InMemoryTenantProvider(),
      treatments: FakeTreatmentRepository(clock),
      breeding: breeding,
    );
    final calf = (await herd.recordCalving('animal-FT-031', at: clock.now())).data!;
    expect(calf.motherTag, 'FT-031');
    final s = (await breeding.summary()).data!;
    expect(s.pregnancies.any((p) => p.animal.name == 'Kyasiimire'), isFalse);
    expect((await herd.counts()).data!.pregnant, 8);
  });
}
