import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/sectors/cattle/breeding/domain/breeding_models.dart';
import 'package:farm_tap/sectors/cattle/breeding/domain/breeding_repository.dart';
import 'package:farm_tap/sectors/cattle/feeding/domain/feeding_models.dart';
import 'package:farm_tap/sectors/cattle/feeding/domain/feeding_repository.dart';
import 'package:farm_tap/sectors/cattle/health/domain/health_models.dart';
import 'package:farm_tap/sectors/cattle/health/domain/health_repository.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/herd_repository.dart';
import 'package:farm_tap/sectors/cattle/home/domain/home_models.dart';
import 'package:farm_tap/sectors/cattle/home/domain/home_repository.dart';
import 'package:farm_tap/sectors/cattle/milk/domain/milk_models.dart';
import 'package:farm_tap/sectors/cattle/milk/domain/milk_repository.dart';
import 'package:farm_tap/sectors/cattle/workers/domain/workers_models.dart';
import 'package:farm_tap/sectors/cattle/workers/domain/workers_repository.dart';

/// D01-D03. With [herd] and [milk] (real-data mode) every number comes from
/// the farm's records; without them (the demo) milk and head counts are the
/// mockup sample numbers, dated relative to the clock.
class FakeHomeRepository implements HomeRepository {
  new(
    this.clock,
    this.treatments, {
    required this.breeding,
    required this.feed,
    required this.workers,
    this.herd,
    this.milk,
  });

  /// Real-data mode: head counts.
  final HerdRepository? herd;

  /// Real-data mode: litres and drops.
  final MilkRepository? milk;

  bool get _real => herd != null && milk != null;

  final Clock clock;

  /// Under treatment, not-for-sale counts and alerts come from here.
  final TreatmentRepository treatments;

  /// Calving alerts come from the breeding records.
  final BreedingRepository breeding;

  /// Low-stock alerts come from the feed records.
  final FeedRepository feed;

  /// Who is in, clock-in times and a worker's tasks come from here.
  final WorkersRepository workers;

  Future<List<TreatmentRecord>> _all() async => (await treatments.treatments()).data ?? const [];

  DateTime get _today {
    final n = clock.now();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  Future<Result<HomeSummary>> summary() async {
    final now = clock.now();
    final records = await _all();
    final staffToday = (await workers.today()).data ?? const <StaffToday>[];
    final List<double> litres;
    var cows = 48;
    var milking = 41;
    var dry = 7;
    if (_real) {
      litres = (await milk!.trend(TrendRange.week)).data?.points ?? List.filled(7, 0);
      final c = (await herd!.counts()).data;
      milking = (c?.milking ?? 0) + (c?.pregnant ?? 0);
      dry = c?.dry ?? 0;
      cows = milking + dry + (c?.heifers ?? 0);
    } else {
      litres = const [296.0, 300.0, 293.0, 302.0, 305.0, 301.0, 312.0];
    }
    final yesterday = litres.length > 1 ? litres[litres.length - 2] : 0.0;
    return Result.success(
      HomeSummary(
        milkToday: litres.last,
        milkTrendPercent: _real ? (yesterday == 0 ? 0 : ((litres.last - yesterday) / yesterday * 100).round()) : 6,
        cows: cows,
        milking: milking,
        dry: dry,
        underTreatment: records.where((r) => r.active(now)).length,
        notForSale: records.where((r) => r.inWithdrawal(now)).length,
        workersIn: staffToday.where((s) => s.onShift && s.isIn).length,
        workersTotal: staffToday.where((s) => s.onShift).length,
        week: [
          for (var i = 0; i < litres.length; i++)
            DayLitres(_today.subtract(Duration(days: litres.length - 1 - i)), litres[i]),
        ],
      ),
    );
  }

  @override
  Future<Result<List<Attention>>> attention() async => Result.success([
    // Milked cows under withdrawal (a dry cow's milk is not sold anyway).
    for (final r in await _all())
      if (r.inWithdrawal(clock.now()) && !r.animalDry)
        MilkNotForSale(animal: r.animalName, drug: r.drug.shortName, safeFrom: r.safeFrom),
    if (_real)
      for (final c in (await milk!.trend(TrendRange.week)).data?.dropping ?? const <CowTrend>[])
        if (c.today != null)
          MilkDropped(animal: c.cow.name, percent: -c.changePercent, today: c.today!, average: c.average),
    for (final p in (await breeding.summary()).data?.calvingSoon ?? const <Pregnancy>[])
      if (p.daysToCalving(clock.now()) <= 7) CalvingDue(animal: p.animal.name, due: p.due),
    for (final st in (await feed.summary()).data?.stock ?? const <FeedStock>[])
      if (st.reorder) StockLow(item: _feedNames[st.feed]!, bagsLeft: st.left.round(), daysLeft: st.daysLeft!),
    if (!_real) ...[
      RecordEdited(person: 'Ahimbisibwe Joy', morning: true, at: _today.add(const Duration(hours: 7, minutes: 42))),
      const TrialEnding(daysLeft: 9),
    ],
  ]);

  @override
  Future<Result<WorkerDay>> workerDay(String staffId) async {
    final me = ((await workers.today()).data ?? const <StaffToday>[]).where((s) => s.staff.id == staffId).firstOrNull;
    final tomorrow = _today.add(const Duration(days: 1));
    final tasks = ((await workers.tasks()).data ?? const <FarmTask>[]).where(
      (t) => t.staffId == staffId && t.due.isBefore(tomorrow) && (!t.done || !t.doneAt!.isBefore(_today)),
    );
    return Result.success(
      WorkerDay(
        clockedInAt: me?.record?.inAt,
        morningSession: true,
        feedingGroupsLeft: _real ? await _groupsLeftToFeed() : 2,
        treatmentsDue: _real ? await _treatmentsDue() : 1,
        dippingDue: _real ? await _nextDipping() : _today.add(const Duration(days: 6)),
        tasks: [for (final t in tasks) WorkerTask(id: t.id, title: t.title, when: _capitalise(t.when), done: t.done)],
      ),
    );
  }

  /// Groups the farm has (from the herd) not yet fed today.
  Future<int> _groupsLeftToFeed() async {
    final c = (await herd!.counts()).data;
    if (c == null) return 0;
    final has = {
      if (c.milking + c.pregnant > 0) FeedGroup.milkingCows,
      if (c.dry > 0) FeedGroup.dryCows,
      if (c.heifers > 0) FeedGroup.heifers,
      if (c.calves > 0) FeedGroup.calves,
    };
    final fed = (await feed.groupsFedOn(_today)).data ?? const <FeedGroup>{};
    return has.difference(fed).length;
  }

  /// Courses still running with no dose given today, plus health jobs due
  /// today or late.
  Future<int> _treatmentsDue() async {
    final now = clock.now();
    final records = await _all();
    final givenToday = {
      for (final r in records)
        if (!r.given.isBefore(_today)) r.animalId,
    };
    final running = {
      for (final r in records)
        if (r.active(now) && !givenToday.contains(r.animalId)) r.animalId,
    };
    final tomorrow = _today.add(const Duration(days: 1));
    final jobs = ((await treatments.schedule()).data ?? const <HealthTask>[]).where((t) => t.due.isBefore(tomorrow));
    return running.length + jobs.length;
  }

  Future<DateTime?> _nextDipping() async {
    final due = [
      for (final t in (await treatments.schedule()).data ?? const <HealthTask>[])
        if (t.kind == HealthTaskKind.dipping && !t.due.isBefore(_today)) t.due,
    ]..sort();
    return due.firstOrNull;
  }

  @override
  Future<Result<void>> setTaskDone(String taskId, {required bool done}) => workers.setTaskDone(taskId, done: done);
}

// Alert text is English in the UI phase (as the other sample alerts).
const Map<FeedKind, String> _feedNames = {
  FeedKind.dairyMeal: 'Dairy meal',
  FeedKind.maizeBran: 'Maize bran',
  FeedKind.mineralLick: 'Mineral lick',
  FeedKind.silage: 'Silage',
  FeedKind.napierGrass: 'Napier grass',
  FeedKind.hay: 'Hay',
  FeedKind.cottonSeedCake: 'Cotton seed cake',
  FeedKind.brewersWaste: "Brewers' waste",
};

String _capitalise(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
