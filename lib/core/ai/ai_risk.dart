// FarmTap AI engine: every finding in one place: risk dashboard, alerts
// centre and "Today's AI farm insights" (decision 0025). Hand port of
// shared/aiRisk.ts.
import 'ai_access.dart';
import 'ai_core.dart';
import 'ai_data.dart';
import 'ai_herd.dart';
import 'ai_milk.dart';
import 'ai_money.dart';
import 'ai_stock.dart';

/// aiAlertStates body: someone acknowledged or resolved an alert (doc id = alert id).
class AlertState {
  const AlertState({required this.status, this.note, this.byName, this.at});
  final String status; // acknowledged | resolved
  final String? note;
  final String? byName;
  final String? at;
}

class FindingWithState {
  const FindingWithState(this.finding, this.state);
  final Finding finding;

  /// new or acknowledged
  final String state;
}

/// All findings the person may see, ranked, with acknowledged ones marked
/// and resolved ones removed. A resolved alert comes back only as a new id
/// (a new day, month or batch), so a fixed problem stays fixed.
List<FindingWithState> allFindings(
  FarmData d, {
  required String role,
  required AiConfig cfg,
  bool farmAiOn = true,
  Map<String, AlertState>? states,
}) {
  bool on(String m) => moduleOn(m, cfg, role, farmAiOn: farmAiOn);
  final fs = <Finding>[];
  void safe(List<Finding> Function() f) {
    try {
      fs.addAll(f());
    } on Object {
      // One broken analysis (odd old record) must not hide every other alert.
    }
  }

  if (on('milk')) safe(() => milkFindings(d));
  if (on('quality')) safe(() => qualityFindings(d));
  if (on('health')) safe(() => healthFindings(d));
  if (on('breeding')) safe(() => breedingFindings(d));
  if (on('feed') || on('inventory')) safe(() => feedFindings(d));
  if (on('inventory')) safe(() => drugFindings(d));
  if (on('finance') && seesMoney(role)) safe(() => financeFindings(d));
  final visible = fs.where((f) => f.module == 'finance' ? seesMoney(role) : true).toList();
  return [
    for (final f in rankFindings(visible))
      if (states?[f.id]?.status != 'resolved')
        FindingWithState(f, states?[f.id]?.status == 'acknowledged' ? 'acknowledged' : 'new'),
  ];
}

Map<Severity, int> countBySeverity(List<Finding> fs) {
  final out = {for (final s in Severity.values) s: 0};
  for (final f in fs) {
    out[f.severity] = out[f.severity]! + 1;
  }
  return out;
}

/// Today's insights: the most serious new findings, then acknowledged ones.
List<FindingWithState> todaysInsights(List<FindingWithState> fs, int n) =>
    [...fs.where((f) => f.state == 'new'), ...fs.where((f) => f.state != 'new')].take(n).toList();

const severityLabel = <Severity, String>{
  Severity.critical: 'Critical',
  Severity.high: 'High',
  Severity.medium: 'Medium',
  Severity.low: 'Low',
};
