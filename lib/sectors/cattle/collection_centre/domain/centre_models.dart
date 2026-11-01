// Collection centre (G01-G13): farmers who supply milk, deliveries per
// session, quality tests, fortnightly payments and the dispatch check.

/// Morning or evening intake at the centre.
enum CentreSession { morning, evening }

enum QualityTest { passed, failed, notDone }

enum RejectReason { sour, addedWater, dirty, treatedCow, other }

enum MobileNetwork { mtn, airtel }

enum PayoutStatus { ready, sent, sending, failed }

enum PayMethod { mobileMoney, cashSheet }

/// G06/G07 — a farmer who delivers milk to the centre.
class CentreFarmer {
  const new({
    required this.id,
    required this.name,
    required this.village,
    required this.phone,
    required this.network,
    required this.periodLitres,
    required this.usualLow,
    required this.usualHigh,
    this.card,
    this.todayLitres,
    this.rejectedLitres = 0,
    this.smsReceipts = true,
    this.owed = 0,
  });

  final String id;
  final String name;

  /// Four-digit card number ("0142"); null when no card was issued yet.
  final String? card;
  final String village;

  /// "+256 772 451 908".
  final String phone;
  final MobileNetwork network;
  final double? todayLitres;
  final double periodLitres;
  final double rejectedLitres;
  final int usualLow;
  final int usualHigh;
  final bool smsReceipts;

  /// Net amount due on the next pay day.
  final double owed;

  bool get deliveredToday => todayLitres != null;

  /// "0772 451 908" for payout rows.
  String get localPhone => phone.startsWith('+256 ') ? '0${phone.substring(5)}' : phone;

  CentreFarmer withToday(double? litres, {double addPeriod = 0}) => CentreFarmer(
    id: id,
    name: name,
    card: card,
    village: village,
    phone: phone,
    network: network,
    todayLitres: litres,
    periodLitres: periodLitres + addPeriod,
    rejectedLitres: rejectedLitres,
    usualLow: usualLow,
    usualHigh: usualHigh,
    smsReceipts: smsReceipts,
    owed: owed + addPeriod * 1100,
  );
}

enum FarmerFilter { all, deliveredToday, notToday, noCard }

class FarmerCounts {
  const new({required this.total, required this.deliveredToday, required this.notToday, required this.noCard});

  final int total;
  final int deliveredToday;
  final int notToday;
  final int noCard;
}

/// One can of milk received at the centre.
class Delivery {
  const new({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.card,
    required this.litres,
    required this.at,
    required this.session,
    this.test = QualityTest.notDone,
    this.rejectReason,
  });

  final String id;
  final String farmerId;
  final String farmerName;
  final String card;
  final double litres;
  final DateTime at;
  final CentreSession session;
  final QualityTest test;
  final RejectReason? rejectReason;

  bool get rejected => test == QualityTest.failed;
}

/// G01 — the open session at a glance.
class CentreDay {
  const new({
    required this.session,
    required this.openSince,
    required this.litres,
    required this.farmers,
    required this.rejected,
    required this.latest,
    required this.litresByHour,
    required this.hourLabels,
    this.closed = false,
  });

  final CentreSession session;
  final DateTime openSince;
  final double litres;
  final int farmers;
  final int rejected;

  /// Newest first.
  final List<Delivery> latest;
  final List<double> litresByHour;
  final List<String> hourLabels;
  final bool closed;
}

/// G09/G10 — one farmer's line on the payment sheet.
class PaymentLine {
  const new({
    required this.farmer,
    required this.litres,
    required this.gross,
    required this.deductions,
    this.status = PayoutStatus.ready,
  });

  final CentreFarmer farmer;
  final double litres;
  final double gross;
  final double deductions;
  final PayoutStatus status;

  double get net => gross - deductions;
}

/// G09 — the current pay period.
class PaymentPeriod {
  const new({
    required this.start,
    required this.end,
    required this.payDay,
    required this.pricePerLitre,
    required this.farmers,
    required this.litres,
    required this.amount,
    required this.fees,
    required this.lines,
  });

  final DateTime start;
  final DateTime end;
  final DateTime payDay;
  final double pricePerLitre;
  final int farmers;
  final double litres;

  /// Net to pay all farmers.
  final double amount;

  /// Estimated Mobile Money fees.
  final double fees;
  final List<PaymentLine> lines;

  double get total => amount + fees;
}

enum DeductionKind { advance, feedsOnCredit }

class Deduction {
  const new({required this.kind, required this.amount, this.date});

  final DeductionKind kind;
  final double amount;
  final DateTime? date;
}

/// G07 — statement card.
class FarmerStatement {
  const new({
    required this.start,
    required this.end,
    required this.payDay,
    required this.litres,
    required this.pricePerLitre,
    required this.deductions,
  });

  final DateTime start;
  final DateTime end;
  final DateTime payDay;
  final double litres;
  final double pricePerLitre;
  final List<Deduction> deductions;

  double get gross => litres * pricePerLitre;
  double get net => gross - deductions.fold<double>(0, (s, d) => s + d.amount);
}

/// G11 — what the SMS statements cost.
class SmsPreview {
  const new({
    required this.centreSender,
    required this.sample,
    required this.weekStart,
    required this.weekEnd,
    required this.weekLitres,
    required this.weekAmount,
    required this.payDay,
    required this.sentAt,
    required this.lastDelivery,
    required this.messages,
    required this.smsLeft,
    required this.smsMonthly,
  });

  /// "KASHARI MCC".
  final String centreSender;
  final CentreFarmer sample;
  final DateTime weekStart;
  final DateTime weekEnd;
  final double weekLitres;
  final double weekAmount;
  final DateTime payDay;
  final DateTime sentAt;
  final Delivery lastDelivery;
  final int messages;
  final int smsLeft;
  final int smsMonthly;

  int get extraNeeded => messages > smsLeft ? messages - smsLeft : 0;
}

/// G13 — received vs dispatched for a session.
class Reconciliation {
  const new({
    required this.session,
    required this.received,
    required this.dispatched,
    required this.limitPercent,
    required this.truck,
    required this.buyer,
    required this.driver,
    required this.leftAt,
    required this.temperature,
  });

  final CentreSession session;
  final double received;
  final double dispatched;
  final int limitPercent;
  final String truck;
  final String buyer;
  final String driver;
  final DateTime leftAt;
  final double temperature;

  double get difference => dispatched - received;
  double get percent => received == 0 ? 0 : difference.abs() / received * 100;
  bool get aboveLimit => percent > limitPercent;
}
