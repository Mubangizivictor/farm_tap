import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/sync/record_journal.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/sectors/cattle/health/domain/health_repository.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/entities/animal.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/herd_repository.dart';
import 'package:farm_tap/sectors/cattle/milk/domain/milk_models.dart';
import 'package:farm_tap/sectors/cattle/milk/domain/milk_repository.dart';

/// Real-data milk (decision 0014): every total is added up from the milk
/// records saved on this phone or pulled from the farm's other phones.
class LocalMilkRepository implements MilkRepository {
  new({required this.journal, required this.clock, required this.treatments, required this.herd});

  final RecordJournal journal;
  final Clock clock;
  final TreatmentRepository treatments;
  final HerdRepository Function() herd;

  static const _records = 'milkRecords';
  static const _sales = 'milkSales';
  static const _use = 'milkUse';

  /// Adult females that are not dry (a heifer counts once she is milked).
  Future<List<Animal>> _milkers() async {
    final animals = (await herd().watchAnimals().first).data ?? const <Animal>[];
    return [
      for (final a in animals)
        if (!a.isDeleted &&
            a.sex == AnimalSex.female &&
            a.dairyStatus != DairyStatus.dry &&
            a.dairyStatus != DairyStatus.calf)
          a,
    ];
  }

  Future<List<MilkRecord>> _all() async => [
    for (final r in await journal.store.all(journal.tenantId(), _records))
      MilkRecord(
        id: r.id,
        cowId: r.body['animalId'] as String?,
        session: MilkSession.values.byName(r.body['session']! as String),
        litres: (r.body['litres']! as num).toDouble(),
        at: r.createdAt,
        recordedBy: r.body['recordedBy'] as String? ?? r.createdBy,
        notForSale: r.body['notForSale'] as bool? ?? false,
      ),
  ]..sort((a, b) => a.at.compareTo(b.at));

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  Future<MilkCow> _cow(Animal a, MilkSession session, List<MilkRecord> all) async {
    final today = clock.today();
    final mine = [
      for (final r in all)
        if (r.cowId == a.id && r.session == session) r,
    ];
    final now = mine.where((r) => _sameDay(r.at, today)).lastOrNull;
    final before = mine.where((r) => r.at.isBefore(today)).lastOrNull;
    final w = (await treatments.withdrawalFor(a.id, clock.now())).data;
    return MilkCow(
      id: a.id,
      name: a.name.isEmpty ? a.tagNumber : a.name,
      tag: a.tagNumber,
      avatarIndex: a.avatarIndex,
      breed: a.breed,
      ageYears: a.ageYears(today),
      lastLitres: before?.litres,
      recordedLitres: now?.litres,
      recordedAt: now?.at,
      treatment: w == null ? null : MilkWithdrawal(drug: w.drug.shortName, given: w.given, until: w.safeFrom),
    );
  }

  @override
  Future<Result<MilkSessionSummary>> session(MilkSession session) async {
    final all = await _all();
    final cows = [for (final a in await _milkers()) await _cow(a, session, all)];
    final today = clock.today();
    final litres = all
        .where((r) => r.session == session && _sameDay(r.at, today))
        .fold<double>(0, (t, r) => t + r.litres);
    return Result.success(
      MilkSessionSummary(
        session: session,
        litres: litres,
        cows: cows,
        recordedCount: cows.where((c) => c.recorded).length,
        totalCows: cows.length,
      ),
    );
  }

  @override
  Future<Result<MilkCow?>> cow(String cowId) async {
    final a = (await _milkers()).where((a) => a.id == cowId).firstOrNull;
    if (a == null) return const Result.success(null);
    final session = clock.now().hour < 12 ? MilkSession.morning : MilkSession.evening;
    return Result.success(await _cow(a, session, await _all()));
  }

  @override
  Future<Result<void>> recordCow(
    String cowId,
    MilkSession session,
    double litres, {
    required bool notForSale,
    required String recordedBy,
  }) async {
    await journal.add(_records, {
      'animalId': cowId,
      'session': session.name,
      'litres': litres,
      'notForSale': notForSale,
      'recordedBy': recordedBy,
    });
    return const Result.success(null);
  }

  @override
  Future<Result<void>> recordTotal(MilkSession session, double litres, {required String recordedBy}) async {
    await journal.add(_records, {
      'animalId': null,
      'session': session.name,
      'litres': litres,
      'recordedBy': recordedBy,
    });
    return const Result.success(null);
  }

  @override
  Future<Result<List<MilkRecord>>> records({required DateTime from}) async => Result.success([
    for (final r in await _all())
      if (!r.at.isBefore(from)) r,
  ]);

  @override
  Future<Result<int>> recordCount(String recordedBy, {required DateTime from}) async =>
      Result.success((await _all()).where((r) => r.recordedBy == recordedBy && !r.at.isBefore(from)).length);

  /// Today's saved split, else everything as sold except milk not for sale.
  @override
  Future<Result<List<MilkUseLine>>> use() async {
    final today = clock.today();
    final saved =
        (await journal.store.all(
            journal.tenantId(),
            _use,
          )).where((r) => r.body['day'] == today.toIso8601String()).toList()
          ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    if (saved.isNotEmpty) {
      return Result.success([
        for (final l in saved.last.body['lines']! as List)
          MilkUseLine(
            kind: MilkUseKind.values.byName((l as Map)['kind']! as String),
            litres: (l['litres']! as num).toDouble(),
            detail: l['detail'] as String?,
          ),
      ]);
    }
    final todays = (await _all()).where((r) => _sameDay(r.at, today));
    final total = todays.fold<double>(0, (t, r) => t + r.litres);
    final blocked = todays.where((r) => r.notForSale).fold<double>(0, (t, r) => t + r.litres);
    final names = [
      for (final c in (await session(MilkSession.morning)).data?.cows ?? const <MilkCow>[])
        if (c.treatment != null) c.name,
    ];
    return Result.success([
      MilkUseLine(kind: MilkUseKind.sold, litres: total - blocked),
      const MilkUseLine(kind: MilkUseKind.home, litres: 0),
      const MilkUseLine(kind: MilkUseKind.calves, litres: 0),
      MilkUseLine(kind: MilkUseKind.notForSale, litres: blocked, detail: names.join(', ')),
      const MilkUseLine(kind: MilkUseKind.spoiled, litres: 0),
    ]);
  }

  @override
  Future<Result<void>> saveUse(List<MilkUseLine> lines) async {
    await journal.add(_use, {
      'day': clock.today().toIso8601String(),
      'lines': [
        for (final l in lines) {'kind': l.kind.name, 'litres': l.litres, 'detail': l.detail},
      ],
    });
    return const Result.success(null);
  }

  Future<List<MilkSale>> _allSales() async => [
    for (final r in await journal.store.all(journal.tenantId(), _sales))
      MilkSale(
        buyer: r.body['buyer']! as String,
        litres: (r.body['litres']! as num).toDouble(),
        pricePerLitre: r.body['pricePerLitre']! as int,
        paid: r.body['paid'] as bool? ?? false,
        kind: BuyerKind.values.asNameMap()[r.body['kind']] ?? BuyerKind.centre,
        at: r.createdAt,
      ),
  ]..sort((a, b) => a.at!.compareTo(b.at!));

  @override
  Future<Result<MilkSalesSummary>> sales() async {
    final all = await _allSales();
    final weekStart = clock.today().subtract(const Duration(days: 6));
    final unpaid = all.where((x) => !x.paid);
    final latest = <String, MilkSale>{for (final x in all) x.buyer: x};
    return Result.success(
      MilkSalesSummary(
        soldThisWeek: all.where((x) => !x.at!.isBefore(weekStart)).fold(0, (t, x) => t + x.litres),
        owed: unpaid.fold(0, (t, x) => t + x.amount),
        buyersOwing: unpaid.map((x) => x.buyer).toSet().length,
        sales: latest.values.toList(),
      ),
    );
  }

  @override
  Future<Result<List<MilkSale>>> salesSince(DateTime from) async => Result.success([
    for (final x in await _allSales())
      if (!x.at!.isBefore(from)) x,
  ]);

  @override
  Future<Result<MilkTrend>> trend(TrendRange range) async {
    final all = await _all();
    final today = clock.today();
    // Buckets: 7 days, 30 days, or 12 months, oldest first.
    final (count, start) = switch (range) {
      TrendRange.week => (7, today.subtract(const Duration(days: 6))),
      TrendRange.month => (30, today.subtract(const Duration(days: 29))),
      TrendRange.year => (12, DateTime(today.year, today.month - 11)),
    };
    int bucket(DateTime at) => range == TrendRange.year
        ? (at.year - start.year) * 12 + at.month - start.month
        : DateTime(at.year, at.month, at.day).difference(start).inDays;
    final points = List<double>.filled(count, 0);
    for (final r in all) {
      final i = bucket(r.at);
      if (i >= 0 && i < count) points[i] += r.litres;
    }
    final total = points.fold<double>(0, (t, p) => t + p);
    final prevStart = range == TrendRange.year
        ? DateTime(start.year - 1, start.month)
        : start.subtract(Duration(days: count));
    final previous = all
        .where((r) => !r.at.isBefore(prevStart) && r.at.isBefore(start))
        .fold<double>(0, (t, r) => t + r.litres);
    String label(int i) => range == TrendRange.year
        ? '${DateTime(start.year, start.month + i).month}'
        : '${start.add(Duration(days: i)).day}';
    final labels = [for (var i = 0; i < count; i++) label(i)];

    // Per cow: average a day over the range against the range before.
    final cows = <CowTrend>[];
    for (final a in await _milkers()) {
      double sum(DateTime from, DateTime to) => all
          .where((r) => r.cowId == a.id && !r.at.isBefore(from) && r.at.isBefore(to))
          .fold<double>(0, (t, r) => t + r.litres);
      final days = range == TrendRange.year ? 365 : count;
      final end = today.add(const Duration(days: 1));
      final now = sum(start, end);
      if (now == 0) continue;
      final before = sum(prevStart, start);
      final todayLitres = sum(today, end);
      cows.add(
        CowTrend(
          cow: await _cow(a, MilkSession.morning, all),
          average: now / days,
          changePercent: before == 0 ? 0 : ((now - before) / before * 100).round(),
          today: todayLitres == 0 ? null : todayLitres,
        ),
      );
    }
    cows.sort((a, b) => b.average.compareTo(a.average));
    return Result.success(
      MilkTrend(
        range: range,
        total: total,
        changePercent: previous == 0 ? 0 : ((total - previous) / previous * 100).round(),
        points: points,
        labels: labels,
        top: cows.take(3).toList(),
        dropping: [
          for (final c in cows)
            if (c.changePercent <= -15) c,
        ],
      ),
    );
  }
}
