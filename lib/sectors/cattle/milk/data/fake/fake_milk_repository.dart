import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/sectors/cattle/milk/domain/milk_models.dart';
import 'package:farm_tap/sectors/cattle/milk/domain/milk_repository.dart';

/// UI phase: the F01-F10 sample numbers. Recording a cow marks her done.
class FakeMilkRepository implements MilkRepository {
  new(this.clock) {
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
      MilkCow(
        id: 'animal-FT-022',
        name: 'Kasheshe',
        tag: 'FT-022',
        avatarIndex: 2,
        breed: 'Ankole',
        ageYears: 7,
        lastLitres: 5,
        treatment: MilkWithdrawal(
          drug: 'Penicillin',
          given: today.add(const Duration(days: 1)),
          until: today.add(const Duration(days: 5)),
        ),
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
      const MilkCow(
        id: 'animal-FT-019',
        name: 'Kaaka',
        tag: 'FT-019',
        avatarIndex: 6,
        breed: 'Friesian cross',
        ageYears: 8,
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
  }

  final Clock clock;
  late List<MilkCow> _cows;
  // The other 33 of the 41 milking cows (31 already recorded this morning).
  static const _otherRecorded = 31;
  static const _otherCows = 33;
  static const _otherLitres = 142.8;

  @override
  Future<Result<MilkSessionSummary>> session(MilkSession session) async {
    final mine = _cows.fold<double>(0, (s, c) => s + (c.recordedLitres ?? 0));
    return Result.success(
      MilkSessionSummary(
        session: session,
        litres: session == MilkSession.morning ? _otherLitres + mine : 0,
        recordedCount: session == MilkSession.morning ? _otherRecorded + _cows.where((c) => c.recorded).length : 0,
        totalCows: _otherCows + _cows.length,
        cows: session == MilkSession.morning
            ? _cows
            : [
                for (final c in _cows)
                  MilkCow(
                    id: c.id,
                    name: c.name,
                    tag: c.tag,
                    avatarIndex: c.avatarIndex,
                    breed: c.breed,
                    ageYears: c.ageYears,
                    lastLitres: c.lastLitres,
                    treatment: c.treatment,
                  ),
              ],
      ),
    );
  }

  @override
  Future<Result<MilkCow?>> cow(String cowId) async {
    for (final c in _cows) {
      if (c.id == cowId) return Result.success(c);
    }
    return const Result.success(null);
  }

  @override
  Future<Result<void>> recordCow(String cowId, MilkSession session, double litres, {required bool notForSale}) async {
    _cows = [
      for (final c in _cows)
        if (c.id == cowId)
          MilkCow(
            id: c.id,
            name: c.name,
            tag: c.tag,
            avatarIndex: c.avatarIndex,
            breed: c.breed,
            ageYears: c.ageYears,
            lastLitres: c.lastLitres,
            recordedLitres: litres,
            recordedAt: clock.now(),
            treatment: c.treatment,
          )
        else
          c,
    ];
    return const Result.success(null);
  }

  @override
  Future<Result<void>> recordTotal(MilkSession session, double litres) async => const Result.success(null);

  @override
  Future<Result<List<MilkUseLine>>> use() async => const Result.success([
    MilkUseLine(kind: MilkUseKind.sold, litres: 280, detail: 'Kashari Milk Centre'),
    MilkUseLine(kind: MilkUseKind.home, litres: 12),
    MilkUseLine(kind: MilkUseKind.calves, litres: 15),
    MilkUseLine(kind: MilkUseKind.notForSale, litres: 5, detail: 'Kasheshe'),
    MilkUseLine(kind: MilkUseKind.spoiled, litres: 0),
  ]);

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
