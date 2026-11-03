import 'dart:async';

import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/money/domain/money_models.dart';
import 'package:farm_tap/core/money/domain/money_repository.dart';
import 'package:farm_tap/core/sync/record_journal.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/sectors/cattle/feeding/domain/feeding_models.dart';
import 'package:farm_tap/sectors/cattle/feeding/domain/feeding_repository.dart';
import 'package:farm_tap/sectors/cattle/milk/domain/milk_models.dart';
import 'package:farm_tap/sectors/cattle/milk/domain/milk_repository.dart';

/// UI phase: an opening count on the last day of the month before, this
/// month's purchases and a week of daily feedings. On Sat 7 Nov that leaves
/// dairy meal 2 bags (0.7 a day -> about 3 days), maize bran 14, mineral
/// lick 6 blocks, silage 3 t; UGX 1,844,000 bought / 8,742 L = UGX 211 a litre.
/// Each purchase records its expense in [money]; the month's feed cost is
/// read back from there (the same expenses L01/L02 show).
class FakeFeedRepository implements FeedRepository {
  new(this.clock, this.milk, this.money, {this.journal}) {
    final now = clock.now();
    final today = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(today.year, today.month);
    final opening = monthStart.subtract(const Duration(days: 1));
    _counts = [
      FeedCount(feed: FeedKind.dairyMeal, amount: 1.9, at: opening),
      FeedCount(feed: FeedKind.maizeBran, amount: 1, at: opening),
      FeedCount(feed: FeedKind.mineralLick, amount: 1.4, at: opening),
      FeedCount(feed: FeedKind.silage, amount: 750, at: opening),
    ];
    _purchases = [
      FeedPurchase(
        id: 'buy-1',
        feed: FeedKind.maizeBran,
        amount: 20,
        pricePerUnit: 22000,
        at: monthStart,
        supplier: _agroVet,
      ),
      FeedPurchase(
        id: 'buy-2',
        feed: FeedKind.silage,
        amount: 4000,
        pricePerUnit: 259000,
        at: monthStart,
        supplier: _silageSupplier,
      ),
      FeedPurchase(
        id: 'buy-3',
        feed: FeedKind.dairyMeal,
        amount: 5,
        pricePerUnit: 52000,
        at: monthStart.add(const Duration(days: 1)),
        supplier: _agroVet,
      ),
      FeedPurchase(
        id: 'buy-4',
        feed: FeedKind.mineralLick,
        amount: 6,
        pricePerUnit: 18000,
        at: monthStart.add(const Duration(days: 1)),
        supplier: _agroVet,
      ),
    ];
    for (final p in _purchases) {
      unawaited(_recordExpense(p));
    }
    // One feeding per feed for each of the 7 full days before today.
    const daily = {FeedKind.dairyMeal: 0.7, FeedKind.maizeBran: 1.0, FeedKind.mineralLick: 0.2, FeedKind.silage: 250.0};
    _feedings = [
      for (var d = 1; d <= rateDays; d++)
        for (final e in daily.entries)
          FeedingRecord(
            id: 'feed-${e.key.name}-$d',
            feed: e.key,
            group: FeedGroup.milkingCows,
            amount: e.value,
            at: today.subtract(Duration(days: d)).add(const Duration(hours: 7)),
          ),
    ];
  }

  static const _agroVet = 'Mbarara Agro Vet';
  static const _silageSupplier = 'Kashari Silage Group';

  /// The daily rate is the average of the last [rateDays] full days.
  static const rateDays = 7;

  final Clock clock;

  /// Saves records on the phone for sync (decision 0014); null in tests.
  final RecordJournal? journal;
  final MilkRepository milk;
  final MoneyRepository money;
  late List<FeedCount> _counts;
  late List<FeedPurchase> _purchases;
  late List<FeedingRecord> _feedings;
  var _next = 100;

  @override
  Future<Result<FeedSummary>> summary() async {
    final now = clock.now();
    final today = DateTime(now.year, now.month, now.day);
    final rateFrom = today.subtract(const Duration(days: rateDays));
    final monthStart = DateTime(today.year, today.month);
    final stock = [
      for (final feed in FeedKind.values)
        FeedStock(
          feed: feed,
          left: _round(_in(feed) - _out(feed)),
          perDay: _round(
            _feedings
                    .where((r) => r.feed == feed && !r.at.isBefore(rateFrom) && r.at.isBefore(today))
                    .fold<double>(0, (s, r) => s + r.amount) /
                rateDays,
          ),
        ),
    ];
    final expenses = (await money.expenses(from: monthStart, category: ExpenseCategory.feed)).data ?? const [];
    final cost = expenses.fold<int>(0, (s, e) => s + e.amount);
    final litres = (await milk.trend(TrendRange.month)).data?.total ?? 0;
    return Result.success(
      FeedSummary(stock: stock, costThisMonth: cost, costPerLitre: litres > 0 ? (cost / litres).round() : null),
    );
  }

  double _in(FeedKind feed) =>
      _counts.where((c) => c.feed == feed).fold<double>(0, (s, c) => s + c.amount) +
      _purchases.where((p) => p.feed == feed).fold<double>(0, (s, p) => s + p.amount);

  double _out(FeedKind feed) => _feedings.where((r) => r.feed == feed).fold<double>(0, (s, r) => s + r.amount);

  // Sums of 0.7 drift (6.9 - 4.9 = 2.0000000000000004).
  static double _round(double v) => (v * 1000).roundToDouble() / 1000;

  @override
  Future<Result<FeedingRecord>> recordFeeding({
    required FeedKind feed,
    required FeedGroup group,
    required double amount,
  }) async {
    final record = FeedingRecord(
      id: journal?.newId() ?? 'feed-${_next++}',
      feed: feed,
      group: group,
      amount: amount,
      at: clock.now(),
    );
    _feedings = [..._feedings, record];
    await journal?.add('feedUsage', {
      'feed': feed.name,
      'group': group.name,
      'amount': amount,
      'at': record.at.toIso8601String(),
    }, id: record.id);
    return Result.success(record);
  }

  @override
  Future<Result<FeedPurchase>> addPurchase({
    required FeedKind feed,
    required double amount,
    required int pricePerUnit,
    String? supplier,
  }) async {
    final p = FeedPurchase(
      id: journal?.newId() ?? 'buy-${_next++}',
      feed: feed,
      amount: amount,
      pricePerUnit: pricePerUnit,
      at: clock.now(),
      supplier: supplier,
    );
    _purchases = [..._purchases, p];
    await journal?.add('stockMovements', {
      'kind': 'purchase',
      'feed': feed.name,
      'amount': amount,
      'pricePerUnit': pricePerUnit,
      'supplier': supplier,
      'at': p.at.toIso8601String(),
    }, id: p.id);
    await _recordExpense(p);
    return Result.success(p);
  }

  Future<void> _recordExpense(FeedPurchase p) =>
      money.addExpense(category: ExpenseCategory.feed, amount: p.total, at: p.at, note: p.supplier, sourceId: p.id);

  @override
  Future<Result<double>> usedOn(DateTime day, FeedKind feed) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return Result.success(
      _round(
        _feedings
            .where((r) => r.feed == feed && !r.at.isBefore(start) && r.at.isBefore(end))
            .fold<double>(0, (s, r) => s + r.amount),
      ),
    );
  }

  @override
  List<String> get suppliers => const [_agroVet, _silageSupplier];
}
