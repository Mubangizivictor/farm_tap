// Treatments are the single source for withdrawal: the herd's Treated badge
// and safe-from date (E03), the milk block (F01, F02, F06, F08), the home
// alert (D01/D03) and the H06 list must all agree with the records.
import 'package:farm_tap/core/tenancy/tenant_provider.dart';
import 'package:farm_tap/sectors/cattle/health/data/fake/fake_treatment_repository.dart';
import 'package:farm_tap/sectors/cattle/herd/data/fake/fake_herd_repository.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/entities/animal.dart';
import 'package:farm_tap/sectors/cattle/home/data/fake/fake_home_repository.dart';
import 'package:farm_tap/sectors/cattle/home/domain/home_models.dart';
import 'package:farm_tap/sectors/cattle/milk/data/fake/fake_milk_repository.dart';
import 'package:farm_tap/sectors/cattle/milk/domain/milk_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_deps.dart';

void main() {
  final clock = FixedClock();
  final now = clock.now();
  late FakeTreatmentRepository treatments;
  late FakeMilkRepository milk;
  late FakeHerdRepository herd;
  late FakeHomeRepository home;

  setUp(() {
    treatments = FakeTreatmentRepository(clock);
    milk = FakeMilkRepository(clock, treatments);
    herd = fakeHerd(clock, InMemoryTenantProvider(), treatments);
    home = fakeHome(clock, treatments);
  });

  test('Kasheshe: Penicillin 8 Nov + 4 days -> safe from Thu 12 Nov', () async {
    final r = (await treatments.withdrawalFor('animal-FT-022', now)).data!;
    expect(r.given.day, 8);
    expect(r.drug.withdrawalDays, 4);
    expect(r.safeFrom, DateTime(2026, 11, 12));
    expect(r.safeFrom.weekday, DateTime.thursday);
  });

  test('every screen reads the same withdrawal', () async {
    final blocked = (await treatments.withdrawals(now)).data!;
    final summary = (await milk.session(MilkSession.morning)).data!;
    final rows = (await herd.rows()).data!;
    final alerts = (await home.attention()).data!.whereType<MilkNotForSale>().toList();
    final use = (await milk.use()).data!.firstWhere((l) => l.kind == MilkUseKind.notForSale);

    // H06 and H01: two cows' milk not for sale.
    expect(blocked.map((r) => r.animalName), containsAll(['Kasheshe', 'Kaaka']));
    expect((await home.summary()).data!.notForSale, blocked.length);
    expect((await herd.counts()).data!.treated, blocked.length);

    for (final r in blocked) {
      // E03: safe-from date and Treated badge (dry cows keep Dry).
      final detail = (await herd.detail(r.animalId)).data!;
      expect(detail.withdrawal!.until, r.safeFrom, reason: r.animalName);
      expect(detail.withdrawal!.daysLeft(now), r.withdrawalDaysLeft(now), reason: r.animalName);
      final row = rows.firstWhere((x) => x.animal.id == r.animalId);
      expect(row.animal.dairyStatus, r.animalDry ? DairyStatus.dry : DairyStatus.treated, reason: r.animalName);

      if (r.animalDry) continue;
      // F02/F06 and F01 "Check these": the milk is blocked until the same date.
      final cow = summary.cows.firstWhere((c) => c.id == r.animalId);
      expect(cow.treatment!.until, r.safeFrom, reason: r.animalName);
      expect((await milk.cow(r.animalId)).data!.treatment!.until, r.safeFrom);
      // F08 not-for-sale line and the home alert.
      expect(use.detail, contains(r.animalName));
      expect(alerts.firstWhere((a) => a.animal == r.animalName).safeFrom, r.safeFrom);
    }

    // No cow is blocked in milk without a record.
    for (final c in summary.cows.where((c) => c.treatment != null)) {
      expect(blocked.any((r) => r.animalId == c.id), isTrue, reason: c.name);
    }
  });
}
