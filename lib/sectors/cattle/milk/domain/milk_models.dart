import 'package:equatable/equatable.dart';

enum MilkSession { morning, evening }

/// One saved milk entry: a cow's litres (or a quick herd total) for a
/// session. [recordedBy] is the staff id, or "owner", for the audit trail
/// and K02 "Milk records".
class MilkRecord {
  const new({
    required this.id,
    required this.session,
    required this.litres,
    required this.at,
    required this.recordedBy,
    this.cowId,
    this.notForSale = false,
  });

  final String id;

  /// Null for a quick herd total (F07).
  final String? cowId;
  final MilkSession session;
  final double litres;
  final DateTime at;
  final String recordedBy;
  final bool notForSale;
}

/// A cow as the milk screens see it.
class MilkCow extends Equatable {
  const new({
    required this.id,
    required this.name,
    required this.tag,
    required this.avatarIndex,
    this.breed = '',
    this.ageYears = 0,
    this.lastLitres,
    this.recordedLitres,
    this.recordedAt,
    this.treatment,
  });

  final String id;
  final String name;
  final String tag;
  final int avatarIndex;
  final String breed;
  final int ageYears;

  /// Same session last time ("Last time: 9.2 L").
  final double? lastLitres;

  /// This session; null = not recorded yet.
  final double? recordedLitres;
  final DateTime? recordedAt;

  /// Under drug withdrawal: milk is not for sale (red tile, F06 warning).
  final MilkWithdrawal? treatment;

  bool get recorded => recordedLitres != null;

  MilkCow copyWith({
    double? recordedLitres,
    DateTime? recordedAt,
    MilkWithdrawal? treatment,
    bool clearRecord = false,
  }) => MilkCow(
    id: id,
    name: name,
    tag: tag,
    avatarIndex: avatarIndex,
    breed: breed,
    ageYears: ageYears,
    lastLitres: lastLitres,
    recordedLitres: clearRecord ? null : recordedLitres ?? this.recordedLitres,
    recordedAt: clearRecord ? null : recordedAt ?? this.recordedAt,
    treatment: treatment,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    tag,
    avatarIndex,
    breed,
    ageYears,
    lastLitres,
    recordedLitres,
    recordedAt,
    treatment,
  ];
}

class MilkWithdrawal extends Equatable {
  const new({required this.drug, required this.given, required this.until});

  final String drug;
  final DateTime given;
  final DateTime until;

  @override
  List<Object?> get props => [drug, given, until];
}

/// One session (F01).
class MilkSessionSummary extends Equatable {
  const new({
    required this.session,
    required this.litres,
    required this.cows,
    required this.recordedCount,
    required this.totalCows,
  });

  final MilkSession session;
  final double litres;

  /// The cows to show (every milking cow on a small farm).
  final List<MilkCow> cows;

  /// Across the whole herd: "34 of 41 cows".
  final int recordedCount;
  final int totalCows;

  @override
  List<Object?> get props => [session, litres, cows, recordedCount, totalCows];
}

enum MilkUseKind { sold, home, calves, notForSale, spoiled }

class MilkUseLine extends Equatable {
  const new({required this.kind, required this.litres, this.detail});

  final MilkUseKind kind;
  final double litres;

  /// "Kashari Milk Centre", "Kasheshe".
  final String? detail;

  @override
  List<Object?> get props => [kind, litres, detail];
}

class MilkSale extends Equatable {
  const new({
    required this.buyer,
    required this.litres,
    required this.pricePerLitre,
    required this.paid,
    this.kind = BuyerKind.centre,
    this.at,
    this.id = '',
    this.paidAt,
  });

  /// The sale's record id (empty for samples made in code).
  final String id;
  final String buyer;

  /// When the buyer paid (null while unpaid).
  final DateTime? paidAt;

  /// When it was sold (the sales ledger; L01 income).
  final DateTime? at;
  final double litres;
  final int pricePerLitre;
  final bool paid;
  final BuyerKind kind;

  int get amount => (litres * pricePerLitre).round();

  MilkSale copyWith({bool? paid, DateTime? paidAt}) => MilkSale(
    id: id,
    buyer: buyer,
    litres: litres,
    pricePerLitre: pricePerLitre,
    paid: paid ?? this.paid,
    kind: kind,
    at: at,
    paidAt: paid == false ? null : paidAt ?? this.paidAt,
  );

  @override
  List<Object?> get props => [id, buyer, litres, pricePerLitre, paid, kind, at, paidAt];
}

enum BuyerKind { centre, shop, neighbours }

/// F09: this week's sales and what buyers still owe.
class MilkSalesSummary extends Equatable {
  const new({required this.soldThisWeek, required this.owed, required this.buyersOwing, required this.sales});

  final double soldThisWeek;
  final int owed;
  final int buyersOwing;

  /// The last 30 days of sales, newest first, plus any older still unpaid.
  final List<MilkSale> sales;

  @override
  List<Object?> get props => [soldThisWeek, owed, buyersOwing, sales];
}

enum TrendRange { week, month, year }

class MilkTrend extends Equatable {
  const new({
    required this.range,
    required this.total,
    required this.changePercent,
    required this.points,
    required this.labels,
    required this.top,
    required this.dropping,
    this.target,
  });

  final TrendRange range;
  final double total;
  final int changePercent;
  final List<double> points;
  final List<String> labels;
  final double? target;
  final List<CowTrend> top;
  final List<CowTrend> dropping;

  @override
  List<Object?> get props => [range, total, changePercent, points, labels, target, top, dropping];
}

class CowTrend extends Equatable {
  const new({required this.cow, required this.average, required this.changePercent, this.today});

  final MilkCow cow;
  final double average;
  final int changePercent;
  final double? today;

  @override
  List<Object?> get props => [cow, average, changePercent, today];
}
