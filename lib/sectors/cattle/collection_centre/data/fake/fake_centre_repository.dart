import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/sectors/cattle/collection_centre/domain/centre_models.dart';
import 'package:farm_tap/sectors/cattle/collection_centre/domain/centre_repository.dart';

/// UI phase: Kashari Milk Centre with the G01-G13 sample numbers. A few
/// farmers are listed in full; the rest only count towards the totals.
class FakeCentreRepository implements CentreRepository {
  new(this.clock) {
    final now = clock.now();
    _day = DateTime(now.year, now.month, now.day);
    _farmers = [
      const CentreFarmer(
        id: 'farmer-0142',
        name: 'Muhwezi Robert',
        card: '0142',
        village: 'Rwanyamahembe',
        phone: '+256 772 451 908',
        network: MobileNetwork.mtn,
        todayLitres: 42.5,
        periodLitres: 510,
        owed: 538200,
        usualLow: 38,
        usualHigh: 45,
      ),
      const CentreFarmer(
        id: 'farmer-0087',
        name: 'Kyomugisha Annet',
        card: '0087',
        village: 'Kashari',
        phone: '+256 701 220 334',
        network: MobileNetwork.airtel,
        todayLitres: 18,
        periodLitres: 216,
        owed: 217800,
        usualLow: 15,
        usualHigh: 20,
      ),
      const CentreFarmer(
        id: 'farmer-0113',
        name: 'Tumusiime Jonan',
        card: '0113',
        village: 'Rubaya',
        phone: '+256 782 118 456',
        network: MobileNetwork.mtn,
        todayLitres: 26.5,
        periodLitres: 318,
        owed: 349800,
        usualLow: 24,
        usualHigh: 30,
      ),
      const CentreFarmer(
        id: 'farmer-0151',
        name: 'Atuhaire Grace',
        card: '0151',
        village: 'Bubaare',
        phone: '+256 775 309 112',
        network: MobileNetwork.mtn,
        todayLitres: 12,
        periodLitres: 144,
        owed: 158400,
        usualLow: 10,
        usualHigh: 14,
      ),
      const CentreFarmer(
        id: 'farmer-0099',
        name: 'Byaruhanga Moses',
        card: '0099',
        village: 'Rwanyamahembe',
        phone: '+256 704 551 870',
        network: MobileNetwork.airtel,
        todayLitres: 35,
        periodLitres: 420,
        owed: 462000,
        usualLow: 32,
        usualHigh: 38,
      ),
      const CentreFarmer(
        id: 'farmer-0128',
        name: 'Ninsiima Prossy',
        card: '0128',
        village: 'Kashari',
        phone: '+256 772 640 218',
        network: MobileNetwork.mtn,
        todayLitres: 22,
        periodLitres: 264,
        owed: 278400,
        usualLow: 20,
        usualHigh: 25,
      ),
      const CentreFarmer(
        id: 'farmer-0064',
        name: 'Kansiime Peace',
        card: '0064',
        village: 'Bubaare',
        phone: '+256 783 902 117',
        network: MobileNetwork.mtn,
        periodLitres: 96,
        owed: 105600,
        usualLow: 8,
        usualHigh: 12,
      ),
      const CentreFarmer(
        id: 'farmer-new-1',
        name: 'Mugisha Brian',
        village: 'Rubaya',
        phone: '+256 709 334 551',
        network: MobileNetwork.airtel,
        periodLitres: 40,
        owed: 44000,
        usualLow: 5,
        usualHigh: 10,
      ),
    ];
    _deliveries = [
      _delivery('d-1', _farmers[1], 18, 6, 41),
      _delivery('d-2', _farmers[4], 35, 6, 47),
      _delivery('d-3', _farmers[2], 26.5, 6, 49),
      _delivery('d-4', _farmers[0], 42.5, 6, 52),
    ];
  }

  final Clock clock;
  late final DateTime _day;
  late List<CentreFarmer> _farmers;
  late List<Delivery> _deliveries;
  int _next = 5;
  bool _closed = false;

  // Farmers, litres and rejections not listed one by one.
  static const _totalFarmers = 128;
  static const _noCard = 4;
  static const _otherDelivered = 59;
  static const _otherLitres = 1162;
  static const _otherRejected = 2;
  static const managerPin = '1234';

  Delivery _delivery(String id, CentreFarmer f, double litres, int h, int m, {QualityTest test = QualityTest.passed}) =>
      Delivery(
        id: id,
        farmerId: f.id,
        farmerName: f.name,
        card: f.card ?? '',
        litres: litres,
        at: _day.add(Duration(hours: h, minutes: m)),
        session: CentreSession.morning,
        test: test,
      );

  @override
  Future<Result<CentreDay>> today() async {
    final accepted = _deliveries.where((d) => !d.rejected);
    final mine = accepted.fold<double>(0, (s, d) => s + d.litres);
    return Result.success(
      CentreDay(
        session: clock.now().hour < 12 ? CentreSession.morning : CentreSession.evening,
        openSince: _day.add(const Duration(hours: 6)),
        litres: _otherLitres + mine,
        farmers: _otherDelivered + accepted.map((d) => d.farmerId).toSet().length,
        rejected: _otherRejected + _deliveries.where((d) => d.rejected).length,
        latest: _deliveries.reversed.toList(),
        litresByHour: const [146, 312, 486, 298, 142],
        hourLabels: const ['6am', '7am', '8am', '9am', '10am'],
        closed: _closed,
      ),
    );
  }

  @override
  Future<Result<List<CentreFarmer>>> farmers() async => Result.success(List.unmodifiable(_farmers));

  @override
  Future<Result<FarmerCounts>> counts() async {
    final delivered = _otherDelivered + _farmers.where((f) => f.deliveredToday).length - 2;
    return Result.success(
      FarmerCounts(
        total: _totalFarmers,
        deliveredToday: delivered,
        notToday: _totalFarmers - delivered,
        noCard: _noCard,
      ),
    );
  }

  @override
  Future<Result<CentreFarmer?>> farmer(String id) async =>
      Result.success(_farmers.where((f) => f.id == id).firstOrNull);

  @override
  Future<Result<CentreFarmer?>> farmerByCard(String card) async =>
      Result.success(_farmers.where((f) => f.card == card.padLeft(4, '0')).firstOrNull);

  @override
  Future<Result<CentreFarmer>> addFarmer({
    required String name,
    required String phone,
    required String village,
    String? card,
  }) async {
    final farmer = CentreFarmer(
      id: 'farmer-${_next++}',
      name: name,
      card: card == null || card.isEmpty ? null : card.padLeft(4, '0'),
      village: village,
      phone: phone,
      network: phone.contains(' 70') || phone.contains(' 75') ? MobileNetwork.airtel : MobileNetwork.mtn,
      periodLitres: 0,
      usualLow: 0,
      usualHigh: 0,
    );
    _farmers = [..._farmers, farmer];
    return Result.success(farmer);
  }

  @override
  Future<Result<Delivery>> recordDelivery(
    String farmerId,
    double litres, {
    QualityTest test = QualityTest.passed,
  }) async {
    final f = _farmers.firstWhere((f) => f.id == farmerId);
    final now = clock.now();
    final d = Delivery(
      id: 'd-${_next++}',
      farmerId: f.id,
      farmerName: f.name,
      card: f.card ?? '',
      litres: litres,
      at: now,
      session: now.hour < 12 ? CentreSession.morning : CentreSession.evening,
      test: test,
    );
    _deliveries = [..._deliveries, d];
    _farmers = [
      for (final x in _farmers)
        if (x.id == farmerId) x.withToday((x.todayLitres ?? 0) + litres) else x,
    ];
    return Result.success(d);
  }

  @override
  Future<Result<void>> undoDelivery(String deliveryId) async {
    final d = _deliveries.where((d) => d.id == deliveryId).firstOrNull;
    if (d == null) return const Result.success(null);
    _deliveries = [..._deliveries]..remove(d);
    _farmers = [
      for (final x in _farmers)
        if (x.id == d.farmerId) _less(x, d.litres) else x,
    ];
    return const Result.success(null);
  }

  CentreFarmer _less(CentreFarmer x, double litres) {
    final left = (x.todayLitres ?? 0) - litres;
    return x.withToday(left <= 0 ? null : left);
  }

  @override
  Future<Result<void>> rejectDelivery(String farmerId, double litres, RejectReason reason, {String? note}) async {
    final f = _farmers.firstWhere((f) => f.id == farmerId);
    final now = clock.now();
    _deliveries = [
      ..._deliveries,
      Delivery(
        id: 'd-${_next++}',
        farmerId: f.id,
        farmerName: f.name,
        card: f.card ?? '',
        litres: litres,
        at: now,
        session: now.hour < 12 ? CentreSession.morning : CentreSession.evening,
        test: QualityTest.failed,
        rejectReason: reason,
      ),
    ];
    return const Result.success(null);
  }

  @override
  Future<Result<bool>> closeSession(String pin) async {
    if (pin != managerPin) return const Result.success(false);
    _closed = true;
    return const Result.success(true);
  }

  DateTime get _start => DateTime(_day.year, _day.month);
  DateTime get _end => DateTime(_day.year, _day.month, 15);
  DateTime get _payDay => DateTime(_day.year, _day.month, 13);

  @override
  Future<Result<PaymentPeriod>> payments() async {
    PaymentLine line(int i, double deductions, [PayoutStatus status = PayoutStatus.ready]) => PaymentLine(
      farmer: _farmers[i],
      litres: _farmers[i].periodLitres,
      gross: _farmers[i].periodLitres * 1100,
      deductions: deductions,
      status: status,
    );
    return Result.success(
      PaymentPeriod(
        start: _start,
        end: _end,
        payDay: _payDay,
        pricePerLitre: 1100,
        farmers: _totalFarmers,
        litres: 16720,
        amount: 18412600,
        fees: 96000,
        lines: [
          line(0, 22800, PayoutStatus.sent),
          line(1, 19800, PayoutStatus.sending),
          line(2, 0, PayoutStatus.failed),
          line(3, 0),
          line(4, 0),
          line(5, 12000),
        ],
      ),
    );
  }

  @override
  Future<Result<FarmerStatement>> statement(String farmerId) async => Result.success(
    FarmerStatement(
      start: _start,
      end: _end,
      payDay: _payDay,
      litres: 512,
      pricePerLitre: 1100,
      deductions: [
        Deduction(kind: DeductionKind.advance, amount: 20000, date: DateTime(_day.year, _day.month, 4)),
        const Deduction(kind: DeductionKind.feedsOnCredit, amount: 5000),
      ],
    ),
  );

  @override
  Future<Result<SmsPreview>> smsPreview() async => Result.success(
    SmsPreview(
      centreSender: 'KASHARI MCC',
      sample: _farmers.first,
      weekStart: _start,
      weekEnd: DateTime(_day.year, _day.month, 7),
      weekLitres: 268,
      weekAmount: 294800,
      payDay: _payDay,
      sentAt: DateTime(_day.year, _day.month, 7, 19),
      lastDelivery: _deliveries.firstWhere((d) => d.farmerId == _farmers.first.id),
      messages: _totalFarmers,
      smsLeft: 172,
      smsMonthly: 300,
    ),
  );

  @override
  Future<Result<void>> sendStatements() async => const Result.success(null);

  @override
  Future<Result<void>> payOut(PayMethod method) async => const Result.success(null);

  @override
  Future<Result<Reconciliation>> reconciliation() async => Result.success(
    Reconciliation(
      session: CentreSession.morning,
      received: 1284,
      dispatched: 1262,
      limitPercent: 1,
      truck: 'UBH 223K',
      buyer: 'Pearl Dairy',
      driver: 'Ssali James',
      leftAt: _day.add(const Duration(hours: 10, minutes: 42)),
      temperature: 4.2,
    ),
  );

  @override
  Future<Result<void>> saveReconciliation(String explanation) async => const Result.success(null);
}
