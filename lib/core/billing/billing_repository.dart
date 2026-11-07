// Paying for FarmTap on the phone (decisions 0023, 0024): plans and payment
// options from the control panel, starting and checking a Mobile Money or
// card payment through FarmTap's server, a by-hand payment claim, and the
// farm's numbered receipts and invoices. The same data the web app uses.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:farm_tap/core/sync/record_journal.dart';
import 'package:firebase_auth/firebase_auth.dart';

String _s(Object? v, [String d = '']) => v is String ? v : d;
int _i(Object? v, [int d = 0]) => v is num ? v.round() : d;
bool _b(Object? v, {required bool d}) => v is bool ? v : d;
DateTime? _date(Object? v) => v is Timestamp ? v.toDate() : (v is String ? DateTime.tryParse(v) : null);

class PlanOption extends Equatable {
  const new({
    required this.id,
    required this.name,
    required this.priceUgx,
    required this.months,
    this.description = '',
    this.highlights = const [],
    this.badge = '',
    this.sort = 0,
    this.features = const {},
  });

  factory fromDoc(String id, Map<String, Object?> d) {
    final rawFeatures = d['features'];
    final Map<String, bool> featureMap = {};
    if (rawFeatures is Map) {
      for (final entry in rawFeatures.entries) {
        if (entry.key is String && entry.value is bool) {
          featureMap[entry.key as String] = entry.value as bool;
        }
      }
    }
    return PlanOption(
      id: id,
      name: _s(d['name'], 'Plan'),
      priceUgx: _i(d['priceUgx']),
      months: _i(d['months'], 1).clamp(1, 36),
      description: _s(d['description']),
      highlights: [
        for (final h in (d['highlights'] as List?) ?? const [])
          if (h is String && h.trim().isNotEmpty) h,
      ],
      badge: _s(d['badge']),
      sort: _i(d['sort']),
      features: featureMap,
    );
  }

  final String id;
  final String name;
  final int priceUgx;
  final int months;
  final String description;
  final List<String> highlights;
  final String badge;
  final int sort;
  /// Feature switches from the plan (key = feature key, value = on/off).
  /// Empty map = all features default to the platform config defaults.
  final Map<String, bool> features;

  int get perMonth => (priceUgx / months).round();

  @override
  List<Object?> get props => [id, name, priceUgx, months, description, highlights, badge, sort, features];
}

/// The same sample plans as the web, until the control panel has its own.
const samplePlans = [
  PlanOption(id: 'monthly', name: 'Monthly', priceUgx: 70000, months: 1, description: 'Pay month by month.', sort: 1),
  PlanOption(
    id: 'quarterly',
    name: '3 months',
    priceUgx: 195000,
    months: 3,
    description: 'Save on three months.',
    badge: 'Most popular',
    sort: 2,
  ),
  PlanOption(
    id: 'yearly',
    name: 'Yearly',
    priceUgx: 700000,
    months: 12,
    description: 'Two months free.',
    badge: 'Best value',
    sort: 3,
  ),
];

class PayGateway extends Equatable {
  const new({
    required this.id,
    required this.name,
    this.enabled = false,
    this.api = false,
    this.payCode = '',
    this.accountName = '',
    this.instructions = '',
  });

  factory fromMap(Map<String, Object?> g) {
    final id = _s(g['id']);
    return PayGateway(
      id: id,
      name: _s(g['name'], 'Payment'),
      enabled: _b(g['enabled'], d: false),
      api: _b(g['api'], d: ['mtn', 'airtel', 'card'].contains(id)),
      payCode: _s(g['payCode']),
      accountName: _s(g['accountName']),
      instructions: _s(g['instructions']),
    );
  }

  final String id;
  final String name;
  final bool enabled;

  /// The server talks to the network itself (else: pay by hand, send the ID).
  final bool api;
  final String payCode;
  final String accountName;
  final String instructions;

  bool get mobile => id == 'mtn' || id == 'airtel';

  @override
  List<Object?> get props => [id, name, enabled, api, payCode, accountName, instructions];
}

class PayOptions {
  const new({required this.plans, required this.gateways, this.supportPhone = '+256793128137', this.manualNote = ''});

  final List<PlanOption> plans;
  final List<PayGateway> gateways;
  final String supportPhone;
  final String manualNote;
}

enum PayStatus { pending, paid, failed, cancelled, expired }

PayStatus payStatusOf(Object? v) => PayStatus.values.firstWhere((s) => s.name == v, orElse: () => PayStatus.pending);

class PayResult {
  const new({required this.status, this.paymentId, this.redirectUrl, this.message, this.paidUntil});

  final PayStatus status;
  final String? paymentId;
  final String? redirectUrl;
  final String? message;
  final DateTime? paidUntil;
}

/// A payment that did not start or failed, with words a farmer understands.
class PayProblem implements Exception {
  const new(this.message);
  final String message;
  @override
  String toString() => message;
}

/// One numbered receipt / invoice / refund note (billingDocs).
class BillingDocument extends Equatable {
  const new({
    required this.id,
    required this.seq,
    required this.receiptNo,
    required this.invoiceNo,
    required this.kind,
    required this.farmName,
    required this.totalUgx,
    required this.method,
    required this.paidAt,
    this.refundNo,
    this.farmPlace = '',
    this.billedTo = '',
    this.billedEmail = '',
    this.reference = '',
    this.items = const [],
    this.periodFrom,
    this.periodTo,
    this.refundOf,
    this.note = '',
  });

  factory fromDoc(String id, Map<String, Object?> d) => BillingDocument(
    id: id,
    seq: _i(d['seq']),
    receiptNo: _s(d['receiptNo']),
    invoiceNo: _s(d['invoiceNo']),
    refundNo: d['refundNo'] is String ? d['refundNo']! as String : null,
    kind: _s(d['kind'], 'payment'),
    farmName: _s(d['farmName']),
    farmPlace: _s(d['farmPlace']),
    billedTo: _s(d['billedTo']),
    billedEmail: _s(d['billedEmail']),
    totalUgx: _i(d['totalUgx']),
    method: _s(d['method']),
    reference: _s(d['reference']),
    paidAt: _date(d['paidAt']) ?? _date(d['issuedAt']) ?? DateTime(2026),
    periodFrom: _date(d['periodFrom']),
    periodTo: _date(d['periodTo']),
    refundOf: d['refundOf'] is String ? d['refundOf']! as String : null,
    note: _s(d['note']),
    items: [
      for (final x in (d['items'] as List?) ?? const [])
        if (x is Map)
          (
            description: _s(x['description']),
            qty: _i(x['qty'], 1),
            unitUgx: _i(x['unitUgx']),
            amountUgx: _i(x['amountUgx']),
          ),
    ],
  );

  final String id;
  final int seq;
  final String receiptNo;
  final String invoiceNo;
  final String? refundNo;

  /// payment | refund
  final String kind;
  final String farmName;
  final String farmPlace;
  final String billedTo;
  final String billedEmail;
  final int totalUgx;
  final String method;
  final String reference;
  final DateTime paidAt;
  final DateTime? periodFrom;
  final DateTime? periodTo;
  final String? refundOf;
  final String note;
  final List<({String description, int qty, int unitUgx, int amountUgx})> items;

  bool get isRefund => kind == 'refund';

  @override
  List<Object?> get props => [id, seq, receiptNo, kind, totalUgx];
}

/// Company details, logo, stamp and signature for the PDFs.
class BillingBrand {
  const new({
    this.company = 'Victorbee Technologies',
    this.address = 'Mbarara, Uganda',
    this.phone = '+256793128137',
    this.email = '',
    this.website = 'farmtap.victorbee.com',
    this.tin = '',
    this.signatoryName = 'Victor Mubangizi',
    this.signatoryTitle = 'Chief Executive Officer',
    this.logo,
    this.stamp,
    this.signature,
  });

  final String company;
  final String address;
  final String phone;
  final String email;
  final String website;
  final String tin;
  final String signatoryName;
  final String signatoryTitle;

  /// PNG or JPEG bytes from the control panel.
  final List<int>? logo;
  final List<int>? stamp;
  final List<int>? signature;
}

const methodNames = {
  'mtn': 'MTN Mobile Money',
  'airtel': 'Airtel Money',
  'card': 'Card',
  'bank': 'Bank transfer',
  'cash': 'Cash',
};

abstract interface class BillingRepository {
  Future<PayOptions> options();

  /// Starts a Mobile Money prompt or card checkout on FarmTap's server.
  Future<PayResult> start({
    required String tenantId,
    required PlanOption plan,
    required int periods,
    required String method,
    String? phone,
  });

  Future<PayResult> check({required String tenantId, required String paymentId});

  /// Paid by hand (bank, pay code): the transaction ID goes to FarmTap.
  Future<void> claim({
    required PlanOption plan,
    required int periods,
    required String method,
    required String reference,
  });

  Future<List<BillingDocument>> documents(String tenantId);
  Future<BillingBrand> brand();

  /// The farm's current subscription dates (after a payment).
  Future<({DateTime? trialEndsAt, DateTime? paidUntil})> subscription(String tenantId);
}

/// Ugandan mobile number as the networks want it: 2567XXXXXXXX.
String? msisdn(String phone) {
  var d = phone.replaceAll(RegExp(r'\D'), '');
  if (d.startsWith('0')) d = '256${d.substring(1)}';
  if (d.length == 9 && d.startsWith('7')) d = '256$d';
  return RegExp(r'^2567\d{8}$').hasMatch(d) ? d : null;
}

/// The network a number is on (MTN 076-079, Airtel 070, 074-075).
String? networkOf(String phone) {
  final m = msisdn(phone);
  if (m == null) return null;
  final p = m.substring(3, 5);
  if (['76', '77', '78', '79'].contains(p)) return 'mtn';
  if (['70', '74', '75'].contains(p)) return 'airtel';
  return null;
}

/// The live app: Firestore and the payment functions (europe-west1).
class FirebaseBillingRepository implements BillingRepository {
  new({required this.journal, this.projectId = 'farm-tap-1dd15', this.region = 'europe-west1', this.db, this.auth});

  final RecordJournal journal;
  final String projectId;
  final String region;
  final FirebaseFirestore? db;
  final FirebaseAuth? auth;

  FirebaseFirestore get _db => db ?? FirebaseFirestore.instance;

  @override
  Future<PayOptions> options() async {
    final plans = await _db.collection('plans').get();
    final cfg = (await _db.doc('platform/config').get()).data() ?? const <String, Object?>{};
    final list = [
      for (final d in plans.docs)
        if (d.data()['active'] != false) PlanOption.fromDoc(d.id, d.data()),
    ]..sort((a, b) => a.sort.compareTo(b.sort));
    final pay = (cfg['payments'] as Map?)?.cast<String, Object?>() ?? const {};
    final gws = [
      for (final g in (pay['gateways'] as List?) ?? const [])
        if (g is Map && g['hidden'] != true) PayGateway.fromMap(g.cast<String, Object?>()),
    ];
    final sup = (cfg['support'] as Map?)?.cast<String, Object?>() ?? const {};
    return PayOptions(
      plans: list.isEmpty ? samplePlans : list,
      gateways: [...gws.where((g) => g.enabled), ...gws.where((g) => !g.enabled)],
      supportPhone: _s(sup['whatsapp'], _s(sup['phone'], '+256793128137')),
      manualNote: _s(pay['manualNote']),
    );
  }

  /// A callable function over HTTPS (no extra plugin needed).
  Future<Map<String, Object?>> _call(String name, Map<String, Object?> data) async {
    final user = (auth ?? FirebaseAuth.instance).currentUser;
    if (user == null) throw const PayProblem('Sign in again, then try.');
    final token = await user.getIdToken();
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20); // theme-guard: ignore
    try {
      final req = await client.postUrl(Uri.parse('https://$region-$projectId.cloudfunctions.net/$name'));
      req.headers
        ..contentType = ContentType.json
        ..set(HttpHeaders.authorizationHeader, 'Bearer $token');
      req.write(jsonEncode({'data': data}));
      final res = await req.close().timeout(const Duration(seconds: 60)); // theme-guard: ignore
      final text = await res.transform(utf8.decoder).join();
      final body = (jsonDecode(text.isEmpty ? '{}' : text) as Map).cast<String, Object?>();
      if (res.statusCode == 404) {
        throw const PayProblem('Paying in the app is not switched on yet. Pay on WhatsApp for now.');
      }
      final error = body['error'];
      if (error is Map) {
        final msg = _s(error['message']);
        throw PayProblem(
          msg.isEmpty || msg.toLowerCase().contains('firebase')
              ? 'The payment could not start. Try again, or pay on WhatsApp.'
              : msg,
        );
      }
      return ((body['result'] as Map?) ?? const {}).cast<String, Object?>();
    } on PayProblem {
      rethrow;
    } on Object {
      throw const PayProblem('Could not reach FarmTap. Check the internet and try again.');
    } finally {
      client.close();
    }
  }

  @override
  Future<PayResult> start({
    required String tenantId,
    required PlanOption plan,
    required int periods,
    required String method,
    String? phone,
  }) async {
    final r = await _call('startPayment', {
      'tenantId': tenantId,
      'planId': plan.id,
      'periods': periods,
      'method': method,
      'phone': ?phone,
      'returnUrl': 'https://farmtap.victorbee.com/settings/?paid={id}#plan',
    });
    return PayResult(
      status: payStatusOf(r['status']),
      paymentId: r['paymentId'] as String?,
      redirectUrl: r['redirectUrl'] as String?,
      message: r['message'] as String?,
    );
  }

  @override
  Future<PayResult> check({required String tenantId, required String paymentId}) async {
    final r = await _call('checkPayment', {'tenantId': tenantId, 'paymentId': paymentId});
    return PayResult(
      status: payStatusOf(r['status']),
      paymentId: paymentId,
      message: r['message'] as String?,
      paidUntil: _date(r['paidUntil']),
    );
  }

  @override
  Future<void> claim({
    required PlanOption plan,
    required int periods,
    required String method,
    required String reference,
  }) => journal.add('payments', {
    'status': 'submitted',
    'amount': plan.priceUgx * periods,
    'method': method,
    'reference': reference.trim(),
    'planId': plan.id,
    'periods': periods,
  });

  @override
  Future<List<BillingDocument>> documents(String tenantId) async {
    final s = await _db.collection('billingDocs').where('tenantId', isEqualTo: tenantId).get();
    return [for (final d in s.docs) BillingDocument.fromDoc(d.id, d.data())]..sort((a, b) => b.seq.compareTo(a.seq));
  }

  @override
  Future<BillingBrand> brand() async {
    Future<Map<String, Object?>> read(String p) async {
      try {
        return (await _db.doc(p).get()).data() ?? const {};
      } on Object {
        return const {};
      }
    }

    final r = await Future.wait([
      read('platform/config'),
      read('platform/company'),
      read('platformAssets/logo'),
      read('platformAssets/stamp'),
      read('platformAssets/signature'),
    ]);
    List<int>? bytes(Map<String, Object?> a) {
      final u = _s(a['dataUrl']);
      final i = u.indexOf('base64,');
      if (i < 0) return null;
      try {
        return base64Decode(u.substring(i + 7));
      } on Object {
        return null;
      }
    }

    final sup = (r[0]['support'] as Map?)?.cast<String, Object?>() ?? const {};
    final c = r[1];
    const d = BillingBrand();
    return BillingBrand(
      company: _s(c['company'], d.company),
      address: _s(c['address'], d.address),
      website: _s(c['website'], d.website),
      tin: _s(c['tin']),
      signatoryName: _s(c['signatoryName'], d.signatoryName),
      signatoryTitle: _s(c['signatoryTitle'], d.signatoryTitle),
      phone: _s(sup['phone'], d.phone),
      email: _s(sup['email']),
      logo: bytes(r[2]),
      stamp: bytes(r[3]),
      signature: bytes(r[4]),
    );
  }

  @override
  Future<({DateTime? trialEndsAt, DateTime? paidUntil})> subscription(String tenantId) async {
    final t = (await _db.doc('tenants/$tenantId').get()).data() ?? const {};
    final s = (t['subscription'] as Map?)?.cast<String, Object?>() ?? const {};
    return (trialEndsAt: _date(s['trialEndsAt']), paidUntil: _date(s['paidUntil']));
  }
}

/// The demo app and tests: sample plans, a payment that goes through after
/// one check, and one sample receipt.
class FakeBillingRepository implements BillingRepository {
  new({this.now});

  final DateTime Function()? now;
  final claims = <Map<String, Object?>>[];
  int _checks = 0;
  DateTime? _paidUntil;

  DateTime get _now => now?.call() ?? DateTime(2026, 11, 7, 8, 41);

  @override
  Future<PayOptions> options() async => const PayOptions(
    plans: samplePlans,
    gateways: [
      PayGateway(id: 'mtn', name: 'MTN Mobile Money', enabled: true, api: true),
      PayGateway(id: 'airtel', name: 'Airtel Money', enabled: true, api: true),
      PayGateway(id: 'card', name: 'Visa or Mastercard', enabled: true, api: true),
      PayGateway(
        id: 'bank',
        name: 'Bank transfer',
        enabled: true,
        accountName: 'Victorbee Technologies',
        payCode: '0123456789',
        instructions: 'Send to the account number and use the farm name as the reference.',
      ),
    ],
  );

  @override
  Future<PayResult> start({
    required String tenantId,
    required PlanOption plan,
    required int periods,
    required String method,
    String? phone,
  }) async {
    _checks = 0;
    return const PayResult(status: PayStatus.pending, paymentId: 'demo-pay');
  }

  @override
  Future<PayResult> check({required String tenantId, required String paymentId}) async {
    _checks++;
    if (_checks < 2) return PayResult(status: PayStatus.pending, paymentId: paymentId);
    _paidUntil = _now.add(const Duration(days: 30));
    return PayResult(status: PayStatus.paid, paymentId: paymentId, paidUntil: _paidUntil);
  }

  @override
  Future<void> claim({
    required PlanOption plan,
    required int periods,
    required String method,
    required String reference,
  }) async => claims.add({'planId': plan.id, 'periods': periods, 'method': method, 'reference': reference});

  @override
  Future<List<BillingDocument>> documents(String tenantId) async => [
    BillingDocument(
      id: 'demo-1',
      seq: 1,
      receiptNo: 'RCT-2026-000001',
      invoiceNo: 'INV-2026-000001',
      kind: 'payment',
      farmName: 'Rwemera Dairy',
      farmPlace: 'Rwanyamahembe, Mbarara',
      billedTo: 'Victor',
      totalUgx: 70000,
      method: 'mtn',
      reference: 'MP261101.1234',
      paidAt: DateTime(2026, 11),
      periodFrom: DateTime(2026, 11),
      periodTo: DateTime(2026, 12),
      items: const [(description: 'FarmTap Monthly plan, 1 month', qty: 1, unitUgx: 70000, amountUgx: 70000)],
    ),
  ];

  @override
  Future<BillingBrand> brand() async => const BillingBrand();

  @override
  Future<({DateTime? trialEndsAt, DateTime? paidUntil})> subscription(String tenantId) async =>
      (trialEndsAt: null, paidUntil: _paidUntil);
}
