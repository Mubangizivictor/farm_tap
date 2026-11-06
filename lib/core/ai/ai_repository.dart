// The phone side of AI Intelligence (decision 0025, phone phase 2): reads the
// farm's records saved on this phone (works offline), hands them to the
// engine, and saves the few things AI adds (alert actions, milk batches,
// temperatures, vet check results, a use log, shelf-life rules). Nothing
// here talks to an AI service.
import 'package:farm_tap/core/ai/ai_access.dart';
import 'package:farm_tap/core/ai/ai_core.dart';
import 'package:farm_tap/core/ai/ai_data.dart';
import 'package:farm_tap/core/ai/ai_risk.dart';
import 'package:farm_tap/core/sync/domain/sync_record.dart';
import 'package:farm_tap/core/sync/record_journal.dart';
import 'package:farm_tap/core/utils/clock.dart';

/// What the engine reads, loaded once for a screen.
class AiFarm {
  AiFarm({
    required this.data,
    required this.states,
    required this.shelfRules,
    required this.role,
    AiConfig? config,
    this.photoUsedToday = 0,
    this.chatUsedToday = 0,
  }) : config = config ?? defaultAiConfig;

  final FarmData data;
  final Map<String, AlertState> states;
  final List<ShelfRule> shelfRules;

  /// owner, manager, clerk or worker (see [aiRoleOf]).
  final String role;

  /// Platform switches from platform/config.ai (the defaults when offline).
  final AiConfig config;

  /// Photo checks this farm has saved today (the soft daily limit).
  final int photoUsedToday;

  /// Online chat answers this farm has had today (the soft daily limit).
  final int chatUsedToday;

  bool get seesMoneyNow => seesMoney(role);

  /// All findings this person may see, ranked, acknowledged ones marked.
  List<FindingWithState> findings() => allFindings(data, role: role, cfg: config, states: states);

  List<FindingWithState> findingsFor(String module) => findings().where((f) => f.finding.module == module).toList();

  bool moduleVisible(String key) => moduleOn(key, config, role);
}

/// Farm role for AI display: the unlocked worker's role, else the account's.
/// [staffRole] and [farmRole] are enum names (manager, herdsman, clerk,
/// worker, vet; owner, manager, clerk, worker).
String aiRoleOf({String? staffRole, String? farmRole}) {
  if (staffRole != null) {
    return switch (staffRole) {
      'manager' => 'manager',
      'clerk' => 'clerk',
      _ => 'worker',
    };
  }
  return switch (farmRole) {
    'owner' => 'owner',
    'manager' => 'manager',
    'clerk' => 'clerk',
    _ => 'worker',
  };
}

/// Alert ids are used as document ids; Firestore forbids "/" in them.
String stateKey(String alertId) => (alertId.length > 200 ? alertId.substring(0, 200) : alertId).replaceAll('/', '_');

class AiRepository {
  new({required this.journal, required this.clock, this.platformAi});

  final RecordJournal journal;
  final Clock clock;

  /// Reads platform/config.ai (online); null or a failure means the defaults.
  final Future<Object?> Function()? platformAi;

  AiConfig? _cfg;
  DateTime? _cfgAt;

  /// The platform AI switches, asked at most every 5 minutes. Offline or
  /// slow: the last known value, else the defaults.
  Future<AiConfig> platformConfig() async {
    final at = _cfgAt;
    final known = _cfg;
    if (known != null && at != null && clock.now().difference(at) < const Duration(minutes: 5)) return known;
    final f = platformAi;
    if (f != null) {
      try {
        _cfg = aiConfigFrom(await f().timeout(const Duration(seconds: 4)));
        _cfgAt = clock.now();
      } on Object {
        // Keep the last known value.
      }
    }
    return _cfg ?? defaultAiConfig;
  }

  String _iso(DateTime d) {
    final k = d.isUtc ? d.add(const Duration(hours: 3)) : d;
    final s = k.toIso8601String();
    return s.endsWith('Z') ? s.substring(0, s.length - 1) : s;
  }

  /// Local Kampala time as the engine reads it.
  String get nowIso => _iso(clock.now());

  Rec _rec(SyncRecord r) =>
      Rec(id: r.id, isDeleted: r.isDeleted, createdAt: _iso(r.createdAt), createdBy: r.createdBy, body: r.body);

  Future<List<Rec>> _load(String collection) async {
    try {
      return [for (final r in await journal.load(collection)) _rec(r)];
    } on Object {
      // A broken collection must never stop the others.
      return const [];
    }
  }

  /// The farm's records for [role]. Money is read only for owners and managers.
  Future<AiFarm> load({required String role}) async {
    final money = seesMoney(role);
    final r = await Future.wait([
      _load('animals'),
      _load('milkRecords'),
      _load('treatments'),
      _load('vaccinations'),
      _load('breedingEvents'),
      _load('feedUsage'),
      _load('stockMovements'),
      _load('feedTypes'),
      _load('stockItems'),
      if (money) _load('expenses') else Future.value(const <Rec>[]),
      if (money) _load('income') else Future.value(const <Rec>[]),
      if (money) _load('milkSales') else Future.value(const <Rec>[]),
      _load('deliveries'),
      _load('milkBatches'),
      _load('storageReadings'),
      _load('aiAlertStates'),
      _load('settings'),
      _load('healthAssessments'),
      _load('aiLog'),
    ]);
    final cfg = await platformConfig();
    final today = nowIso.substring(0, 10);
    final photoToday = r[17].where((x) => x.body['kind'] == 'photo' && '${x.body['at']}'.startsWith(today)).length;
    final chatToday = r[18]
        .where((x) => x.body['feature'] == 'chat' && x.body['ok'] == true && '${x.body['at']}'.startsWith(today))
        .length;
    final shelf = shelfRulesFrom(r[16].where((x) => x.id == 'aiMilk').firstOrNull?.body['rules']);
    final data = FarmData(
      now: nowIso,
      animals: r[0],
      milk: r[1],
      treatments: r[2],
      vaccinations: r[3],
      breeding: r[4],
      feedUses: r[5],
      stockMoves: r[6],
      feedTypes: r[7],
      stockItems: r[8],
      expenses: r[9],
      income: r[10],
      milkSales: r[11],
      deliveries: r[12],
      milkBatches: r[13],
      storageReadings: r[14],
      shelfRules: shelf,
    );
    final states = <String, AlertState>{};
    for (final s in r[15]) {
      final st = s.str('status');
      if (st == 'acknowledged' || st == 'resolved') {
        states[s.id] = AlertState(status: st!, note: s.str('note'), byName: s.str('byName'), at: s.str('at'));
      }
    }
    return AiFarm(
      data: data,
      states: states,
      shelfRules: shelf,
      role: role,
      config: cfg,
      photoUsedToday: photoToday,
      chatUsedToday: chatToday,
    );
  }

  // ------------------------------------------------------------ Writes

  /// Acknowledge or resolve an alert (the record id is the alert id).
  Future<void> setAlertState(String alertId, String status, String byName) =>
      journal.put('aiAlertStates', stateKey(alertId), {'status': status, 'byName': byName, 'at': nowIso, 'note': null});

  /// A milk batch kept on the farm before it leaves.
  Future<String> addBatch({
    required double litres,
    required DateTime collectedAt,
    required bool cooled,
    String? place,
    String? note,
  }) => journal.add('milkBatches', {
    'litres': litres,
    'collectedAt': _iso(collectedAt),
    'product': 'rawMilk',
    'cooled': cooled,
    'place': (place?.trim().isEmpty ?? true) ? null : place!.trim(),
    'status': 'stored',
    'closedAt': null,
    'note': note,
  });

  /// Mark a batch sold, used or thrown away.
  Future<void> closeBatch(String id, String status) async {
    final old = await journal.store.get('milkBatches', id);
    if (old == null) return;
    await journal.put('milkBatches', id, {...old.body, 'status': status, 'closedAt': nowIso});
  }

  /// One temperature reading for a batch or a place (append-only).
  Future<void> addReading({required double tempC, String? batchId, String? place}) => journal.add('storageReadings', {
    'batchId': batchId,
    'place': (place?.trim().isEmpty ?? true) ? null : place!.trim(),
    'tempC': tempC,
    'at': nowIso,
  });

  /// Shelf-life rules the farm checked (owners and managers).
  Future<void> saveShelfRules(List<ShelfRule> rules) => journal.put('settings', 'aiMilk', {
    'rules': [
      for (final r in rules)
        {
          'product': r.product,
          'label': r.label,
          'cooledHours': r.cooledHours,
          'warmHours': r.warmHours,
          'maxTempC': r.maxTempC,
        },
    ],
  });

  /// A vet-guide or screening result, kept for the vet (append-only).
  Future<void> saveAssessment(Map<String, Object?> body) => journal.add('healthAssessments', {...body, 'at': nowIso});

  /// A saved photo check (append-only). Holds the words of the result, never
  /// the picture.
  Future<void> savePhotoAssessment(Map<String, Object?> body) => journal.add('healthAssessments', body);

  /// One line in the AI use log: which feature, whether it worked, how long
  /// and how the answer was made. Never the question, answer or any figure.
  /// Fire and forget.
  Future<void> log(String feature, {required bool ok, required int ms, required Method method}) async {
    try {
      await journal.add('aiLog', {
        'feature': feature.length > 32 ? feature.substring(0, 32) : feature,
        'ok': ok,
        'ms': ms,
        'method': method.name,
        'at': nowIso,
      });
    } on Object {
      // The log must never stop the farmer.
    }
  }
}

/// Shelf-life rules from the farm's settings, kept inside sensible limits.
List<ShelfRule> shelfRulesFrom(Object? v) {
  if (v is! List) return defaultShelfRules;
  double clamp(Object? x, double lo, double hi, double d) =>
      x is num && x.isFinite && x >= lo && x <= hi ? x.toDouble() : d;
  final ok = [
    for (final x in v.whereType<Map<Object?, Object?>>())
      ShelfRule(
        product: '${x['product'] ?? 'rawMilk'}',
        label: '${x['label'] ?? 'Raw milk'}',
        cooledHours: clamp(x['cooledHours'], 1, 24 * 14, 48),
        warmHours: clamp(x['warmHours'], 0.5, 48, 3),
        maxTempC: clamp(x['maxTempC'], -5, 15, 4),
      ),
  ];
  return ok.isEmpty ? defaultShelfRules : ok;
}
