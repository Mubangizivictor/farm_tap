import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/sectors/cattle/health/domain/health_repository.dart';
import 'package:farm_tap/sectors/cattle/milk/domain/milk_models.dart';
import 'package:farm_tap/sectors/cattle/milk/domain/milk_repository.dart';

/// UI phase: the F01-F10 sample numbers. Recording a cow marks her done.
/// Withdrawal ("not for sale") comes from the shared treatment records.
class FakeMilkRepository implements MilkRepository {
  new(this.clock, this.treatments) {
    final today = DateTime(clock.now().year, clock.now().month, clock.now().day);
    _cows = [
      MilkCow(
        id: 'animal-FT-014',
        name: 'Bihogo',
        tag: 'FT-014',
        avatarIndex: 1,
        breed: 'Friesian cross',
        ageYears: 5,
        lastLitres: 9.2,
        recordedLitres: 9.5,
        recordedAt: today.add(const Duration(hours: 6, minutes: 12)),
      ),
      const MilkCow(
        id: 'animal-FT-022',
        name: 'Kasheshe',
        tag: 'FT-022',
        avatarIndex: 2,
        breed: 'Ankole',
        ageYears: 7,
        lastLitres: 5,
      ),
      const MilkCow(
        id: 'animal-FT-031',
        name: 'Kyasiimire',
        tag: 'FT-031',
        avatarIndex: 3,
        breed: 'Jersey cross',
        ageYears: 4,
        lastLitres: 4.5,
      ),
      MilkCow(
        id: 'animal-FT-008',
        name: 'Ngabire',
        tag: 'FT-008',
        avatarIndex: 4,
        breed: 'Friesian',
        ageYears: 6,
        lastLitres: 8.1,
        recordedLitres: 8.8,
        recordedAt: today.add(const Duration(hours: 6, minutes: 15)),
      ),
      const MilkCow(
        id: 'animal-FT-045',
        name: 'Rwemera',
        tag: 'FT-045',
        avatarIndex: 5,
        breed: 'Ankole cross',
        ageYears: 3,
      ),
      MilkCow(
        id: 'animal-FT-027',
        name: 'Nyinamwiza',
        tag: 'FT-027',
        avatarIndex: 1,
        breed: 'Jersey',
        ageYears: 5,
        lastLitres: 7.1,
        recordedLitres: 7.4,
        recordedAt: today.add(const Duration(hours: 6, minutes: 19)),
      ),
      const MilkCow(
        id: 'animal-FT-033',
        name: 'Kahara',
        tag: 'FT-033',
        avatarIndex: 3,
        breed: 'Ankole',
        ageYears: 4,
        lastLitres: 6,
      ),
    ];
    _seedRecords(today);
  }

  final Clock clock;
  final TreatmentRepository treatments;
  late List<MilkCow> _cows;
  final List<MilkRecord> _records = [];
  var _nextRecord = 1;

  /// Herdsman records the morning milking, the milk clerk the evening.
  static const _morningBy = 'staff-ta';
  static const _eveningBy = 'staff-aj';
  static const _milkingCows = 41;

  /// Earlier this month every milking cow was recorded at both sessions;
  /// this morning 34 so far (the 31 others plus the 3 sample cows).
  void _seedRecords(DateTime today) {
    void add(DateTime at, MilkSession s, String by, {String? cowId, double litres = 7}) => _records.add(
      MilkRecord(id: 'milk-${_nextRecord++}', cowId: cowId, session: s, litres: litres, at: at, recordedBy: by),
    );
    for (var d = today.day - 1; d >= 1; d--) {
      final day = today.subtract(Duration(days: d));
      for (var i = 0; i < _milkingCows; i++) {
        add(day.add(const Duration(hours: 6)), MilkSession.morning, _morningBy, cowId: 'cow-$i');
        add(day.add(const Duration(hours: 17)), MilkSession.evening, _eveningBy, cowId: 'cow-$i');
      }
    }
    for (var i = 0; i < _otherRecorded; i++) {
      add(today.add(const Duration(hours: 6)), MilkSession.morning, _morningBy, cowId: 'cow-$i');
    }
    for (final c in _cows.where((c) => c.recordedAt != null)) {
      add(c.recordedAt!, MilkSession.morning, _morningBy, cowId: c.id, litres: c.recordedLitres!);
    }
  }

  // The other 34 of the 41 milking cows (31 already recorded this morning).
  static const _otherRecorded = 31;
  static const _otherCows = 34;
  static const _otherLitres = 142.8;

  /// The cow with her withdrawal (if any) from the treatment records.
  Future<MilkCow> _withTreatment(MilkCow c) async {
    final r = (await treatments.withdrawalFor(c.id, clock.now())).data;
    return c.copyWith(
      treatment: r == null ? null : MilkWithdrawal(drug: r.drug.shortName, given: r.given, until: r.safeFrom),
    );
  }

  Future<List<MilkCow>> _cowsNow() async => [for (final c in _cows) await _withTreatment(c)];

  @override
  Future<Result<MilkSessionSummary>> session(MilkSession session) async {
    final cows = await _cowsNow();
    final mine = cows.fold<double>(0, (s, c) => s + (c.recordedLitres ?? 0));
    final morning = session == MilkSession.morning;
    return Result.success(
      MilkSessionSummary(
        session: session,
        litres: morning ? _otherLitres + mine : 0,
        recordedCount: morning ? _otherRecorded + cows.where((c) => c.recorded).length : 0,
        totalCows: _otherCows + cows.length,
        cows: morning ? cows : [for (final c in cows) c.copyWith(treatment: c.treatment, clearRecord: true)],
      ),
    );
  }

  @override
  Future<Result<MilkCow?>> cow(String cowId) async {
    final c = _cows.where((c) => c.id == cowId).firstOrNull;
    return Result.success(c == null ? null : await _withTreatment(c));
  }

  @override
  Future<Result<void>> recordCow(
    String cowId,
    MilkSession session,
    double litres, {
    required bool notForSale,
    required String recordedBy,
  }) async {
    _records.add(
      MilkRecord(
        id: 'milk-${_nextRecord++}',
        cowId: cowId,
        session: session,
        litres: litres,
        at: clock.now(),
        recordedBy: recordedBy,
        notForSale: notForSale,
      ),
    );
    _cows = [
      for (final c in _cows)
        if (c.id == cowId) c.copyWith(recordedLitres: litres, recordedAt: clock.now()) else c,
    ];
    return const Result.success(null);
  }

  @override
  Future<Result<void>> recordTotal(MilkSession session, double litres, {required String recordedBy}) async {
    _records.add(
      MilkRecord(
        id: 'milk-${_nextRecord++}',
        session: session,
        litres: litres,
        at: clock.now(),
        recordedBy: recordedBy,
      ),
    );
    return const Result.success(null);
  }

  @override
  Future<Result<int>> recordCount(String recordedBy, {required DateTime from}) async =>
      Result.success(_records.where((r) => r.recordedBy == recordedBy && !r.at.isBefore(from)).length);

  @override
  Future<Result<List<MilkUseLine>>> use() async {
    final blocked = [
      for (final c in await _cowsNow())
        if (c.treatment != null) c.name,
    ];
    return Result.success([
      const MilkUseLine(kind: MilkUseKind.sold, litres: 280, detail: 'Kashari Milk Centre'),
      const MilkUseLine(kind: MilkUseKind.home, litres: 12),
      const MilkUseLine(kind: MilkUseKind.calves, litres: 15),
      MilkUseLine(kind: MilkUseKind.notForSale, litres: blocked.isEmpty ? 0 : 5, detail: blocked.join(', ')),
      const MilkUseLine(kind: MilkUseKind.spoiled, litres: 0),
    ]);
  }

  @override
  Future<Result<void>> saveUse(List<MilkUseLine> lines) async => const Result.success(null);

  @override
  Future<Result<MilkSalesSummary>> sales() async => const Result.success(
    MilkSalesSummary(
      soldThisWeek: 1960,
      owed: 412000,
      buyersOwing: 2,
      sales: [
        MilkSale(buyer: 'Kashari Milk Centre', litres: 280, pricePerLitre: 1100, paid: true),
        MilkSale(buyer: 'Mbarara Dairy Shop', litres: 40, pricePerLitre: 1400, paid: false, kind: BuyerKind.shop),
        MilkSale(buyer: 'Neighbours', litres: 12, pricePerLitre: 1500, paid: true, kind: BuyerKind.neighbours),
      ],
    ),
  );

  @override
  Future<Result<MilkTrend>> trend(TrendRange range) async {
    final points = <double>[296, 300, 293, 302, 305, 301, 298, 304, 306, 303, 307, 312];
    return Result.success(
      MilkTrend(
        range: range,
        total: 8742,
        changePercent: 4,
        points: points,
        labels: [for (var i = 1; i <= points.length; i++) '$i'],
        target: 310,
        top: [
          CowTrend(cow: _cows[0], average: 18.1, changePercent: 8),
          CowTrend(cow: _cows[3], average: 16, changePercent: 3),
        ],
        dropping: [CowTrend(cow: _cows[3], average: 10.4, changePercent: -22, today: 8.1)],
      ),
    );
  }
}
