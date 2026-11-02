// Cattle feeding (I01-I03). Stock counts, purchases and feedings are the
// single source: what is left, the daily rate, days left and the month's
// feed cost are all calculated from them.

enum FeedKind { dairyMeal, maizeBran, mineralLick, silage }

enum FeedUnit { bags, blocks, kg }

enum FeedGroup { milkingCows, dryCows, heifers, calves }

extension FeedKindUnit on FeedKind {
  FeedUnit get unit => switch (this) {
    FeedKind.mineralLick => FeedUnit.blocks,
    FeedKind.silage => FeedUnit.kg,
    _ => FeedUnit.bags,
  };
}

/// Stock counted by hand (the opening count when the farm starts).
class FeedCount {
  const new({required this.feed, required this.amount, required this.at});

  final FeedKind feed;
  final double amount;
  final DateTime at;
}

/// I03: bought feed. Adds stock and is a farm expense.
class FeedPurchase {
  const new({
    required this.id,
    required this.feed,
    required this.amount,
    required this.pricePerUnit,
    required this.at,
    this.supplier,
  });

  final String id;
  final FeedKind feed;

  /// In the feed's unit; silage in kg.
  final double amount;

  /// Per bag / block / tonne (silage).
  final int pricePerUnit;
  final DateTime at;
  final String? supplier;

  int get total => (pricePerUnit * (feed.unit == FeedUnit.kg ? amount / 1000 : amount)).round();
}

/// I02: feed given to one group.
class FeedingRecord {
  const new({required this.id, required this.feed, required this.group, required this.amount, required this.at});

  final String id;
  final FeedKind feed;
  final FeedGroup group;
  final double amount;
  final DateTime at;
}

/// One I01 row, calculated from the records.
class FeedStock {
  const new({required this.feed, required this.left, required this.perDay});

  /// Below this many days of feed the row asks to reorder.
  static const reorderDays = 7;

  final FeedKind feed;
  final double left;
  final double perDay;

  int? get daysLeft => perDay <= 0 ? null : (left / perDay).round();
  bool get reorder => daysLeft != null && daysLeft! < reorderDays;
}

/// I01 header and rows.
class FeedSummary {
  const new({required this.stock, required this.costThisMonth, required this.costPerLitre});

  final List<FeedStock> stock;
  final int costThisMonth;

  /// Feed cost this month / milk this month; null before any milk.
  final int? costPerLitre;
}
