import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/sectors/cattle/feeding/domain/feeding_models.dart';

/// Feed stock, purchases and feedings.
abstract interface class FeedRepository {
  /// I01: what is left of each feed and this month's cost.
  Future<Result<FeedSummary>> summary();

  Future<Result<FeedingRecord>> recordFeeding({
    required FeedKind feed,
    required FeedGroup group,
    required double amount,
  });

  /// I03: adds stock and records the expense in the money repository.
  Future<Result<FeedPurchase>> addPurchase({
    required FeedKind feed,
    required double amount,
    required int pricePerUnit,
    String? supplier,
  });

  /// I01 "Count stock": what is in the store now (the opening count when
  /// the farm starts using FarmTap). Later purchases and feedings move it.
  Future<Result<void>> countStock(FeedKind feed, double amount);

  /// Groups already fed on [day] (worker home: groups left to feed).
  Future<Result<Set<FeedGroup>>> groupsFedOn(DateTime day);

  /// Amount of [feed] given on [day] (L04 daily report).
  Future<Result<double>> usedOn(DateTime day, FeedKind feed);

  /// Suppliers used before, newest first (I03 default).
  List<String> get suppliers;
}
