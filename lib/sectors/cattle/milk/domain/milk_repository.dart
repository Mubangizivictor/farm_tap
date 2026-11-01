import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/sectors/cattle/milk/domain/milk_models.dart';

abstract interface class MilkRepository {
  Future<Result<MilkSessionSummary>> session(MilkSession session);
  Future<Result<MilkCow?>> cow(String cowId);

  /// Saves one cow's milk for the session (after the read-back).
  Future<Result<void>> recordCow(String cowId, MilkSession session, double litres, {required bool notForSale});

  /// F07 quick mode: one total for the whole herd.
  Future<Result<void>> recordTotal(MilkSession session, double litres);

  Future<Result<List<MilkUseLine>>> use();
  Future<Result<void>> saveUse(List<MilkUseLine> lines);
  Future<Result<MilkSalesSummary>> sales();
  Future<Result<MilkTrend>> trend(TrendRange range);
}
