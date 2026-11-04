import 'dart:math';

import 'package:farm_tap/core/error/failure.dart';
import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/people/data/local_card_registry.dart';
import 'package:farm_tap/core/people/domain/card_registry.dart';
import 'package:farm_tap/core/people/domain/photo_store.dart';
import 'package:farm_tap/core/sms/sms_outbox.dart';
import 'package:farm_tap/core/sync/record_journal.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/core/utils/formats.dart';
import 'package:farm_tap/sectors/cattle/collection_centre/domain/centre_models.dart';
import 'package:farm_tap/sectors/cattle/collection_centre/domain/centre_repository.dart';
import 'package:intl/date_symbol_data_local.dart';

/// UI phase: Kashari Milk Centre with the G01-G13 sample numbers. A few
/// farmers are listed in full; the rest only count towards the totals.
/// With [withSamples] false (real data) the centre starts with no farmers and
/// every total comes from its own records.
class FakeCentreRepository implements CentreRepository, Restorable {
  new(this.clock, {this.journal, this.sms, this.withSamples = true, this.verifyPin, LocalCardRegistry? cards})
    : cards = cards ?? LocalCardRegistry(now: clock.now, journal: journal) {
    final now = clock.now();
    _day = DateTime(now.year, now.month, now.day);
    if (!withSamples) {
      _deductions = {};
      _farmers = [];
      _deliveries = [];
      return;
    }
    _farmers = [
      const CentreFarmer(
        id: 'farmer-0142',
        name: 'Muhwezi Robert',
        card: '0142',
        village: 'Rwanyamahembe',
        phone: '+256 772 451 908',
        network: MobileNetwork.mtn,
        todayLitres: 42.5,
        periodLitres: 512,
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
        usualLow: 5,
        usualHigh: 10,
      ),
    ];
    _deductions = {
      'farmer-0142': [
        Deduction(kind: DeductionKind.advance, amount: 20000, date: DateTime(_day.year, _day.month, 2)),
        const Deduction(kind: DeductionKind.feedsOnCredit, amount: 5000),
      ],
      'farmer-0087': [const Deduction(kind: DeductionKind.feedsOnCredit, amount: 19800)],
      'farmer-0128': [Deduction(kind: DeductionKind.advance, amount: 12000, date: DateTime(_day.year, _day.month, 5))],
    };
    // Owed is derived from the same period litres and deductions the
    // statement and payment sheet use, so every screen agrees.
    _farmers = [for (final x in _farmers) x.withOwed(x.periodLitres * _price - _deducted(x.id))];
    _deliveries = [
      _delivery('d-1', _farmers[1], 18, 6, 41),
      _delivery('d-2', _farmers[4], 35, 6, 47),
      _delivery('d-3', _farmers[2], 26.5, 6, 49),
      _delivery('d-4', _farmers[0], 42.5, 6, 52),
    ];
    // The sample farmers' cards join the farm's card register.
    this.cards.seed([
      for (final f in _farmers)
        if (f.card != null)
          IdCardRecord(
            number: f.card!,
            holderId: f.id,
            holderKind: CardHolderKind.farmer,
            holderName: f.name,
            status: CardStatus.active,
          ),
    ]);
  }

  /// Every card on the farm or centre (staff and farmers share it).
  final LocalCardRegistry cards;

  final Clock clock;

  /// False in real-data mode.
  final bool withSamples;

  /// Saves records on the phone for sync (decision 0014); null in tests.
  final RecordJournal? journal;

  /// Where SMS receipts to farmers are queued (none in demo builds).
  final SmsOutbox? sms;

  /// Real data: checks the manager PIN that closes a session.
  final Future<bool> Function(String pin)? verifyPin;
  late final DateTime _day;
  late final Map<String, List<Deduction>> _deductions;
  double _price = defaultPrice;
  static const double defaultPrice = 1100;

  double _deducted(String farmerId) => (_deductions[farmerId] ?? const []).fold(0, (s, d) => s + d.amount);
  late List<CentreFarmer> _farmers;
  late List<Delivery> _deliveries;
  int _next = 5;
  bool _closed = false;

  // Sample farmers, litres and rejections not listed one by one.
  int get _totalFarmers => withSamples ? 128 : _farmers.length;
  int get _noCard => withSamples ? 4 : _farmers.where((f) => f.card == null).length;
  int get _otherDelivered => withSamples ? 59 : 0;
  double get _otherLitres => withSamples ? 1162 : 0;
  int get _otherRejected => withSamples ? 2 : 0;
  static const managerPin = '1234';

  /// Accepted litres today by hour, 6am to 10am (G01 chart).
  List<double> _byHour() {
    final out = List<double>.filled(5, 0);
    for (final d in _deliveries) {
      final i = d.at.hour - 6;
      if (!d.rejected && !d.at.isBefore(_day) && i >= 0 && i < out.length) out[i] += d.litres;
    }
    return out;
  }

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
        litresByHour: withSamples ? const [146, 312, 486, 298, 142] : _byHour(),
        hourLabels: const ['6am', '7am', '8am', '9am', '10am'],
        closed: _closed,
      ),
    );
  }

  @override
  Future<Result<List<CentreFarmer>>> farmers() async => Result.success(List.unmodifiable(_farmers));

  @override
  Future<Result<FarmerCounts>> counts() async {
    final delivered = _otherDelivered + _farmers.where((f) => f.deliveredToday).length - (withSamples ? 2 : 0);
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
  Future<Result<CentreFarmer?>> farmerByCard(String card) async {
    final record = (await cards.lookup(card)).data;
    if (record != null && record.holderKind == CardHolderKind.farmer) {
      if (!record.active) return const Result.success(null);
      return Result.success(_farmers.where((f) => f.id == record.holderId).firstOrNull);
    }
    // Demo only: a sample farmer whose number a sample worker also has.
    if (!withSamples) return const Result.success(null);
    final n = card.replaceAll(RegExp(r'\D'), '');
    if (n.isEmpty || n.length > 4) return const Result.success(null);
    return Result.success(_farmers.where((f) => f.card == n.padLeft(4, '0')).firstOrNull);
  }

  Map<String, Object?> _farmerBody(CentreFarmer f) => {
    'name': f.name,
    'phone': f.phone,
    'village': f.village,
    'card': f.card,
    'photo': f.photo,
    'photoUrl': f.photoUrl,
    'since': f.since?.toIso8601String(),
  };

  Future<void> _replace(CentreFarmer f) async {
    _farmers = [
      for (final x in _farmers)
        if (x.id == f.id) f else x,
    ];
    await journal?.put('farmers', f.id, _farmerBody(f));
  }

  @override
  Future<Result<CentreFarmer>> assignCard(String farmerId, String? scanned, {bool replace = false}) async {
    final f = _farmers.where((x) => x.id == farmerId).firstOrNull;
    if (f == null) return const Result.failure(ValidationFailure('farmer-unknown'));
    // A sample farmer's card that is not in the register yet.
    if (f.card != null && (await cards.activeCardOf(f.id)).data == null && !replace) {
      return const Result.failure(ValidationFailure(CardIssueError.hasCard));
    }
    final issued = await cards.issue(
      holderId: f.id,
      kind: CardHolderKind.farmer,
      holderName: f.name,
      scanned: scanned,
      replace: replace,
    );
    switch (issued) {
      case FailureResult(:final failure):
        return Result.failure(failure);
      case Success(:final data):
        final updated = f.withCard(data.number);
        await _replace(updated);
        return Result.success(updated);
    }
  }

  @override
  Future<Result<CentreFarmer>> revokeCard(String farmerId, CardStatus why) async {
    final f = _farmers.where((x) => x.id == farmerId).firstOrNull;
    if (f == null) return const Result.failure(ValidationFailure('farmer-unknown'));
    final card = (await cards.activeCardOf(f.id)).data;
    if (card != null) await cards.revoke(card.number, why);
    final updated = f.withCard(null);
    await _replace(updated);
    return Result.success(updated);
  }

  @override
  Future<Result<List<IdCardRecord>>> cardHistory(String farmerId) => cards.historyOf(farmerId);

  @override
  Future<Result<CentreFarmer>> setPhoto(String farmerId, PersonPhoto photo) async {
    final f = _farmers.where((x) => x.id == farmerId).firstOrNull;
    if (f == null) return const Result.failure(ValidationFailure('farmer-unknown'));
    final updated = f.withCard(null, keepCard: true, photo: photo.thumb, photoUrl: photo.url);
    await _replace(updated);
    return Result.success(updated);
  }

  @override
  Future<Result<List<Delivery>>> deliveriesOf(String farmerId, {int limit = 10}) async {
    final mine = _deliveries.where((d) => d.farmerId == farmerId).toList()..sort((a, b) => b.at.compareTo(a.at));
    return Result.success(mine.take(limit).toList());
  }

  @override
  Future<Result<CentreFarmer>> addFarmer({
    required String name,
    required String phone,
    required String village,
    String? card,
  }) async {
    final id = journal?.newId() ?? 'farmer-${_next++}';
    String? number;
    if (card != null && card.isNotEmpty) {
      // One holder per card (decision 0016): refuse a card someone has.
      final issued = await cards.issue(holderId: id, kind: CardHolderKind.farmer, holderName: name, scanned: card);
      if (issued case FailureResult(:final failure)) return Result.failure(failure);
      number = issued.data!.number;
    }
    final farmer = CentreFarmer(
      id: id,
      name: name,
      card: number,
      village: village,
      phone: phone,
      network: CentreFarmer.networkOf(phone),
      periodLitres: 0,
      usualLow: 0,
      usualHigh: 0,
      since: clock.today(),
    );
    _farmers = [..._farmers, farmer];
    await journal?.add('farmers', _farmerBody(farmer), id: farmer.id);
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
      id: journal?.newId() ?? 'd-${_next++}',
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
    await journal?.add('deliveries', _deliveryBody(d), id: d.id);
    if (f.smsReceipts) {
      final at = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      await sms?.queue(
        id: SmsOutbox.receiptId(d.id),
        to: f.phone,
        name: f.name,
        kind: 'deliveryReceipt',
        text: 'FarmTap: received ${litres.toStringAsFixed(1)} L of milk from ${f.name} at $at. Thank you.',
      );
    }
    return Result.success(d);
  }

  @override
  Future<Result<void>> undoDelivery(String deliveryId) async {
    final d = _deliveries.where((d) => d.id == deliveryId).firstOrNull;
    if (d == null) return const Result.success(null);
    _deliveries = [..._deliveries]..remove(d);
    // Undo is a soft delete: the record stays, marked deleted.
    await journal?.remove('deliveries', d.id);
    final f = _farmers.where((x) => x.id == d.farmerId).firstOrNull;
    if (f != null && f.smsReceipts) await sms?.cancel(SmsOutbox.receiptId(d.id));
    _farmers = [
      for (final x in _farmers)
        if (x.id == d.farmerId) _less(x, d.litres) else x,
    ];
    return const Result.success(null);
  }

  @override
  Future<void> restore() async {
    final j = journal;
    if (j == null) return;
    await cards.restore();
    final farmerIds = {for (final f in _farmers) f.id};
    for (final r in await j.load('farmers')) {
      final b = r.body;
      if (farmerIds.contains(r.id)) {
        // Card, photo and details can change after the farmer was added
        // (here, on another phone, or on the web).
        _farmers = [
          for (final x in _farmers)
            if (x.id == r.id)
              x
                  .withCard(b['card'] as String?, photo: b['photo'] as String?, photoUrl: b['photoUrl'] as String?)
                  .withDetails(
                    name: b['name'] as String? ?? x.name,
                    phone: b['phone'] as String? ?? x.phone,
                    village: b['village'] as String? ?? x.village,
                    smsReceipts: b['smsReceipts'] as bool? ?? x.smsReceipts,
                  )
            else
              x,
        ];
        continue;
      }
      final phone = b['phone'] as String? ?? '';
      _farmers = [
        ..._farmers,
        CentreFarmer(
          id: r.id,
          name: b['name'] as String? ?? '',
          card: b['card'] as String?,
          village: b['village'] as String? ?? '',
          phone: phone,
          network: CentreFarmer.networkOf(phone),
          photo: b['photo'] as String?,
          photoUrl: b['photoUrl'] as String?,
          since: DateTime.tryParse(b['since'] as String? ?? ''),
          periodLitres: 0,
          usualLow: 0,
          usualHigh: 0,
          smsReceipts: b['smsReceipts'] as bool? ?? true,
        ),
      ];
    }
    for (final r in await j.load('settings')) {
      if (r.id == _priceDoc) _price = (r.body['pricePerLitre'] as num?)?.toDouble() ?? _price;
    }
    final known = {for (final d in _deliveries) d.id};
    for (final r in await j.loadWithDeleted('deliveries')) {
      if (r.isDeleted) {
        // Undone on another phone or the web: take it off the lists.
        final gone = _deliveries.where((d) => d.id == r.id).firstOrNull;
        if (gone == null) continue;
        _deliveries = [for (final d in _deliveries) if (d.id != r.id) d];
        if (gone.rejectReason == null && !gone.at.isBefore(_day)) {
          _farmers = [
            for (final x in _farmers)
              if (x.id == gone.farmerId) x.withToday(max(0, (x.todayLitres ?? 0) - gone.litres)) else x,
          ];
        }
        continue;
      }
      if (known.contains(r.id)) continue;
      final b = r.body;
      final f = _farmers.where((f) => f.id == b['farmerId']).firstOrNull;
      if (f == null) continue;
      final litres = (b['litres']! as num).toDouble();
      final test = QualityTest.values.byName(b['test']! as String);
      final reason = b['rejectReason'] as String?;
      final d = Delivery(
        id: r.id,
        farmerId: f.id,
        farmerName: f.name,
        card: f.card ?? '',
        litres: litres,
        at: DateTime.parse(b['at']! as String),
        session: CentreSession.values.byName(b['session']! as String),
        test: test,
        rejectReason: reason == null ? null : RejectReason.values.byName(reason),
      );
      _deliveries = [..._deliveries, d];
      if (reason == null && !d.at.isBefore(_day)) {
        _farmers = [
          for (final x in _farmers)
            if (x.id == f.id) x.withToday((x.todayLitres ?? 0) + litres) else x,
        ];
      }
    }
  }

  static const _priceDoc = 'centrePrice';

  @override
  double get pricePerLitre => _price;

  @override
  Future<Result<void>> setPricePerLitre(double ugx) async {
    _price = ugx;
    _farmers = [for (final x in _farmers) x.withOwed(_periodLitres(x) * _price - _deducted(x.id))];
    await journal?.put('settings', _priceDoc, {'pricePerLitre': ugx});
    return const Result.success(null);
  }

  @override
  Future<Result<CentreFarmer>> updateFarmer(
    String farmerId, {
    required String name,
    required String phone,
    required String village,
    required bool smsReceipts,
  }) async {
    final i = _farmers.indexWhere((f) => f.id == farmerId);
    if (i < 0) return const Result.failure(ValidationFailure('no-farmer'));
    final f = _farmers[i].edited(name: name, phone: phone, village: village, sms: smsReceipts);
    _farmers = [..._farmers]..[i] = f;
    final j = journal;
    if (j != null) {
      // Keep fields other screens saved on the record (card, photo).
      final old = (await j.store.get('farmers', farmerId))?.body ?? const <String, Object?>{};
      await j.put('farmers', farmerId, {
        ...old,
        'name': name,
        'phone': phone,
        'village': village,
        'smsReceipts': smsReceipts,
      });
    }
    return Result.success(f);
  }

  static Map<String, Object?> _deliveryBody(Delivery d) => {
    'farmerId': d.farmerId,
    'litres': d.litres,
    'session': d.session.name,
    'test': d.test.name,
    'rejectReason': d.rejectReason?.name,
    'at': d.at.toIso8601String(),
  };

  CentreFarmer _less(CentreFarmer x, double litres) {
    final left = (x.todayLitres ?? 0) - litres;
    return x.withToday(left <= 0 ? null : left);
  }

  @override
  Future<Result<void>> rejectDelivery(String farmerId, double litres, RejectReason reason, {String? note}) async {
    final f = _farmers.firstWhere((f) => f.id == farmerId);
    final now = clock.now();
    final rejected = Delivery(
      id: journal?.newId() ?? 'd-${_next++}',
      farmerId: f.id,
      farmerName: f.name,
      card: f.card ?? '',
      litres: litres,
      at: now,
      session: now.hour < 12 ? CentreSession.morning : CentreSession.evening,
      test: QualityTest.failed,
      rejectReason: reason,
    );
    _deliveries = [..._deliveries, rejected];
    await journal?.add('deliveries', {..._deliveryBody(rejected), 'note': note}, id: rejected.id);
    return const Result.success(null);
  }

  @override
  Future<Result<bool>> closeSession(String pin) async {
    final check = verifyPin;
    final ok = withSamples || check == null ? pin == managerPin : await check(pin);
    if (!ok) return const Result.success(false);
    _closed = true;
    return const Result.success(true);
  }

  /// Accepted litres this pay period (samples carry their own total).
  double _periodLitres(CentreFarmer f) => withSamples
      ? f.periodLitres
      : _deliveries
            .where((d) => d.farmerId == f.id && !d.rejected && !d.at.isBefore(_start) && d.at.isBefore(_end))
            .fold(0, (s, d) => s + d.litres);

  DateTime get _start => DateTime(_day.year, _day.month);
  DateTime get _end => DateTime(_day.year, _day.month, 15);
  DateTime get _payDay => DateTime(_day.year, _day.month, 13);

  @override
  Future<Result<PaymentPeriod>> payments() async {
    PaymentLine line(int i, [PayoutStatus status = PayoutStatus.ready]) => PaymentLine(
      farmer: _farmers[i],
      litres: _periodLitres(_farmers[i]),
      gross: _periodLitres(_farmers[i]) * _price,
      deductions: _deducted(_farmers[i].id),
      status: status,
    );
    if (!withSamples) {
      final lines = [for (var i = 0; i < _farmers.length; i++) line(i)];
      return Result.success(
        PaymentPeriod(
          start: _start,
          end: _end,
          payDay: _payDay,
          pricePerLitre: _price,
          farmers: _farmers.length,
          litres: lines.fold(0, (s, l) => s + l.litres),
          amount: lines.fold(0, (s, l) => s + l.gross - l.deductions),
          fees: 0,
          lines: lines,
        ),
      );
    }
    return Result.success(
      PaymentPeriod(
        start: _start,
        end: _end,
        payDay: _payDay,
        pricePerLitre: _price,
        farmers: _totalFarmers,
        litres: 16720,
        amount: 18412600,
        fees: 96000,
        lines: [
          line(0, PayoutStatus.sent),
          line(1, PayoutStatus.sending),
          line(2, PayoutStatus.failed),
          line(3),
          line(4),
          line(5),
        ],
      ),
    );
  }

  @override
  Future<Result<FarmerStatement>> statement(String farmerId) async {
    final farmer = _farmers.firstWhere((f) => f.id == farmerId);
    return Result.success(
      FarmerStatement(
        start: _start,
        end: _end,
        payDay: _payDay,
        litres: _periodLitres(farmer),
        pricePerLitre: _price,
        deductions: _deductions[farmerId] ?? const [],
      ),
    );
  }

  @override
  Future<Result<SmsPreview>> smsPreview() async {
    if (!withSamples) {
      final last = _deliveries.where((d) => !d.rejected).lastOrNull;
      if (last == null) return const Result.failure(ValidationFailure('no-deliveries'));
      final farmer = _farmers.firstWhere((f) => f.id == last.farmerId);
      final weekStart = _day.subtract(const Duration(days: 6));
      final week = _deliveries.where((d) => d.farmerId == farmer.id && !d.rejected && !d.at.isBefore(weekStart));
      final litres = week.fold<double>(0, (s, d) => s + d.litres);
      return Result.success(
        SmsPreview(
          centreSender: 'FARMTAP',
          sample: farmer,
          weekStart: weekStart,
          weekEnd: _day,
          weekLitres: litres,
          weekAmount: litres * _price,
          payDay: _payDay,
          sentAt: _day.add(const Duration(hours: 19)),
          lastDelivery: last,
          messages: _farmers.length,
          smsLeft: 0,
          smsMonthly: 0,
        ),
      );
    }
    return Result.success(_sampleSms());
  }

  SmsPreview _sampleSms() => SmsPreview(
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
  );

  /// Queues this week's statement for every farmer with a phone number and
  /// SMS receipts on. Returns how many were queued (none in the demo).
  @override
  Future<Result<int>> sendStatements() async {
    final outbox = sms;
    if (outbox == null) return const Result.success(0);
    final weekStart = _day.subtract(const Duration(days: 6));
    await initializeDateFormatting('en');
    final f = FarmTapFormat('en');
    var queued = 0;
    for (final farmer in _farmers) {
      if (!farmer.smsReceipts || farmer.phone.trim().isEmpty) continue;
      final litres = _deliveries
          .where((d) => d.farmerId == farmer.id && !d.rejected && !d.at.isBefore(weekStart))
          .fold<double>(0, (s, d) => s + d.litres);
      if (litres == 0) continue;
      await outbox.queue(
        to: farmer.phone,
        name: farmer.name,
        kind: 'statement',
        text:
            'FarmTap: ${farmer.name}, ${f.period(weekStart, _day)} you delivered ${f.litresValue(litres, trim: false)} L. '
            'Amount so far ${f.money(litres * _price)}. Pay day ${f.day(_payDay)}. Thank you!',
      );
      queued++;
    }
    return Result.success(queued);
  }

  @override
  Future<Result<void>> payOut(PayMethod method) async => const Result.success(null);

  @override
  Future<Result<Reconciliation>> reconciliation() async {
    if (!withSamples) {
      // No dispatch is recorded yet, so received and sent are the same.
      final received = _deliveries
          .where((d) => !d.rejected && !d.at.isBefore(_day))
          .fold<double>(0, (s, d) => s + d.litres);
      return Result.success(
        Reconciliation(
          session: clock.now().hour < 12 ? CentreSession.morning : CentreSession.evening,
          received: received,
          dispatched: received,
          limitPercent: 1,
          truck: '',
          buyer: '',
          driver: '',
          leftAt: clock.now(),
          temperature: 0,
        ),
      );
    }
    return Result.success(_sampleReconciliation());
  }

  Reconciliation _sampleReconciliation() => Reconciliation(
    session: CentreSession.morning,
    received: 1284,
    dispatched: 1262,
    limitPercent: 1,
    truck: 'UBH 223K',
    buyer: 'Pearl Dairy',
    driver: 'Ssali James',
    leftAt: _day.add(const Duration(hours: 10, minutes: 42)),
    temperature: 4.2,
  );

  @override
  Future<Result<void>> saveReconciliation(String explanation) async {
    await journal?.add('reconciliations', {'day': _day.toIso8601String(), 'explanation': explanation});
    return const Result.success(null);
  }
}
