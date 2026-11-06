import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/sectors/cattle/milk/domain/milk_models.dart';

abstract interface class MilkRepository {
  /// One session of [day] (today when null).
  Future<Result<MilkSessionSummary>> session(MilkSession session, {DateTime? day});
  Future<Result<MilkCow?>> cow(String cowId);

  /// Saves one cow's milk for the session (after the read-back).
  Future<Result<void>> recordCow(
    String cowId,
    MilkSession session,
    double litres, {
    required bool notForSale,
    required String recordedBy,
  });

  /// F07 quick mode: one total for the whole herd.
  Future<Result<void>> recordTotal(MilkSession session, double litres, {required String recordedBy});

  /// Every saved record since [from] (audit trail; sums by recorder).
  Future<Result<List<MilkRecord>>> records({required DateTime from});

  /// Records saved by [recordedBy] since [from] (K02 "Milk records").
  Future<Result<int>> recordCount(String recordedBy, {required DateTime from});

  Future<Result<List<MilkUseLine>>> use();
  Future<Result<void>> saveUse(List<MilkUseLine> lines);
  Future<Result<MilkSalesSummary>> sales();

  /// F09 "Add sale": milk sold to a centre, shop or neighbour.
  Future<Result<MilkSale>> addSale({
    required String buyer,
    required BuyerKind kind,
    required double litres,
    required int pricePerLitre,
    required bool paid,
  });

  /// Marks a sale paid (or back to unpaid when entered by mistake).
  Future<Result<void>> setSalePaid(String saleId, {required bool paid});

  /// Buyers sold to before, most recent first, with their last price.
  Future<Result<List<MilkSale>>> recentBuyers();

  /// Total litres milked on [day], today when null (F08 "produced").
  Future<Result<double>> litresOn([DateTime? day]);

  /// Every sale since [from] (income for L01 and reports).
  Future<Result<List<MilkSale>>> salesSince(DateTime from);
  Future<Result<MilkTrend>> trend(TrendRange range);
}
