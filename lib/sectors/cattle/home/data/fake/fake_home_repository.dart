import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/sectors/cattle/breeding/domain/breeding_models.dart';
import 'package:farm_tap/sectors/cattle/breeding/domain/breeding_repository.dart';
import 'package:farm_tap/sectors/cattle/feeding/domain/feeding_models.dart';
import 'package:farm_tap/sectors/cattle/feeding/domain/feeding_repository.dart';
import 'package:farm_tap/sectors/cattle/health/domain/health_models.dart';
import 'package:farm_tap/sectors/cattle/health/domain/health_repository.dart';
import 'package:farm_tap/sectors/cattle/home/domain/home_models.dart';
import 'package:farm_tap/sectors/cattle/home/domain/home_repository.dart';

/// UI phase: the numbers and alerts shown in the D01-D03 mockups, dated
/// relative to the clock.
class FakeHomeRepository implements HomeRepository {
  new(this.clock, this.treatments, {required this.breeding, required this.feed});

  final Clock clock;

  /// Under treatment, not-for-sale counts and alerts come from here.
  final TreatmentRepository treatments;

  /// Calving alerts come from the breeding records.
  final BreedingRepository breeding;

  /// Low-stock alerts come from the feed records.
  final FeedRepository feed;

  Future<List<TreatmentRecord>> _all() async => (await treatments.treatments()).data ?? const [];
  final _done = <String, bool>{'task-heifers': true};

  DateTime get _today {
    final n = clock.now();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  Future<Result<HomeSummary>> summary() async {
    final now = clock.now();
    final records = await _all();
    const litres = [296.0, 300.0, 293.0, 302.0, 305.0, 301.0, 312.0];
    return Result.success(
      HomeSummary(
        milkToday: 312,
        milkTrendPercent: 6,
        cows: 48,
        milking: 41,
        dry: 7,
        underTreatment: records.where((r) => r.active(now)).length,
        notForSale: records.where((r) => r.inWithdrawal(now)).length,
        workersIn: 5,
        workersTotal: 6,
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
    const MilkDropped(animal: 'Ngabire', percent: 22, today: 8.1, average: 10.4),
    for (final p in (await breeding.summary()).data?.calvingSoon ?? const <Pregnancy>[])
      if (p.daysToCalving(clock.now()) <= 7) CalvingDue(animal: p.animal.name, due: p.due),
    for (final st in (await feed.summary()).data?.stock ?? const <FeedStock>[])
      if (st.reorder) StockLow(item: _feedNames[st.feed]!, bagsLeft: st.left.round(), daysLeft: st.daysLeft!),
    RecordEdited(person: 'Ahimbisibwe Joy', morning: true, at: _today.add(const Duration(hours: 7, minutes: 42))),
    const TrialEnding(daysLeft: 9),
  ]);

  @override
  Future<Result<WorkerDay>> workerDay(String staffId) async => Result.success(
    WorkerDay(
      clockedInAt: _today.add(const Duration(hours: 5, minutes: 45)),
      morningSession: true,
      feedingGroupsLeft: 2,
      treatmentsDue: 1,
      dippingDue: _today.add(const Duration(days: 6)),
      tasks: [
        WorkerTask(
          id: 'task-heifers',
          title: 'Move heifers to paddock 3',
          when: 'Before 10:00',
          done: _done['task-heifers'] ?? false,
        ),
        WorkerTask(
          id: 'task-clean',
          title: 'Clean milking area',
          when: 'After evening milking',
          done: _done['task-clean'] ?? false,
        ),
      ],
    ),
  );

  @override
  Future<Result<void>> setTaskDone(String taskId, {required bool done}) async {
    _done[taskId] = done;
    return const Result.success(null);
  }
}

// Alert text is English in the UI phase (as the other sample alerts).
const Map<FeedKind, String> _feedNames = {
  FeedKind.dairyMeal: 'Dairy meal',
  FeedKind.maizeBran: 'Maize bran',
  FeedKind.mineralLick: 'Mineral lick',
  FeedKind.silage: 'Silage',
};
