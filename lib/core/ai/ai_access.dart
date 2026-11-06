// FarmTap AI engine: who sees what, and the platform switches (decision 0025).
// Display only: Firestore rules still decide what can be read at all.
// Hand port of shared/aiAccess.ts.
import 'package:farm_tap/core/ai/ai_core.dart';

final List<String> _all = aiModules.map((m) => m.key).toList();

/// AI modules each farm role is shown.
final _byRole = <String, List<String>>{
  'owner': _all,
  'manager': _all,
  'clerk': [
    'assistant',
    'vet',
    'screening',
    'milk',
    'quality',
    'predictions',
    'feed',
    'breeding',
    'health',
    'inventory',
    'risks',
    'recommendations',
    'alerts',
  ],
  'worker': ['assistant', 'vet', 'screening', 'milk', 'quality', 'feed', 'health', 'recommendations', 'alerts'],
};

List<String> roleModules(String role) => _byRole[role] ?? _byRole['worker']!;

/// Money modules and money findings are for owners and managers only.
bool seesMoney(String role) => role == 'owner' || role == 'manager';

/// platform/config.ai, edited in the AI Control Centre.
class AiConfig {
  const new({
    required this.enabled,
    required this.modules,
    required this.experimental,
    required this.llmEnabled,
    required this.llmModel,
    required this.llmTimeoutMs,
    required this.insightsCount,
    this.photoEnabled = false,
    this.photoModel = 'gemini-3.8-flash',
    this.photoPerFarmPerDay = 20,
  });
  final bool enabled;
  final Map<String, bool> modules;
  final bool experimental;
  final bool llmEnabled;
  final String llmModel;
  final int llmTimeoutMs;
  final int insightsCount;

  /// Photo analysis with Google Gemini through Firebase AI Logic (decision 0026).
  /// Off until a Super Admin turns it on.
  final bool photoEnabled;
  final String photoModel;
  final int photoPerFarmPerDay;
}

final defaultAiConfig = AiConfig(
  enabled: true,
  modules: {for (final m in aiModules) m.key: true},
  experimental: true,
  llmEnabled: false,
  llmModel: 'qwen3:4b',
  llmTimeoutMs: 20000,
  insightsCount: 5,
);

Map<String, Object?> _obj(Object? v) => v is Map ? v.cast<String, Object?>() : const {};

AiConfig aiConfigFrom(Object? v) {
  final o = _obj(v);
  final m = _obj(o['modules']);
  final l = _obj(o['llm']);
  final d = defaultAiConfig;
  final model = l['model'];
  final timeout = l['timeoutMs'];
  final count = o['insightsCount'];
  final ph = _obj(o['photo']);
  final phModel = ph['model'];
  final phLimit = ph['perFarmPerDay'];
  return AiConfig(
    enabled: o['enabled'] is bool ? o['enabled']! as bool : d.enabled,
    modules: {for (final x in aiModules) x.key: m[x.key] is bool ? m[x.key]! as bool : d.modules[x.key]!},
    experimental: o['experimental'] is bool ? o['experimental']! as bool : d.experimental,
    llmEnabled: l['enabled'] is bool ? l['enabled']! as bool : d.llmEnabled,
    llmModel: model is String && RegExp(r'^[\w.:\-/]{1,64}$').hasMatch(model) ? model : d.llmModel,
    llmTimeoutMs: timeout is num && timeout >= 1000 && timeout <= 120000 ? timeout.toInt() : d.llmTimeoutMs,
    insightsCount: count is num && count >= 1 && count <= 10 ? jsRound(count).toInt() : d.insightsCount,
    photoEnabled: ph['enabled'] is bool ? ph['enabled']! as bool : d.photoEnabled,
    photoModel: phModel is String && RegExp(r'^[\w.\-]{3,64}$').hasMatch(phModel) ? phModel : d.photoModel,
    photoPerFarmPerDay: phLimit is num && phLimit >= 1 && phLimit <= 500 ? jsRound(phLimit).toInt() : d.photoPerFarmPerDay,
  );
}

const experimentalModules = <String>[];

/// Whether a person on a farm sees one module: platform switch, farm switch, role.
bool moduleOn(String key, AiConfig cfg, String role, {bool farmAiOn = true}) {
  if (!cfg.enabled || !farmAiOn || cfg.modules[key] != true) return false;
  if (experimentalModules.contains(key) && !cfg.experimental) return false;
  if ((key == 'finance' || key == 'reports') && !seesMoney(role)) return false;
  return roleModules(role).contains(key);
}
