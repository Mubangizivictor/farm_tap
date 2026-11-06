// FarmTap AI engine, core (decision 0025). Pure Dart, no Firebase, no
// network. A hand port of shared/aiCore.ts: same rules, same numbers, so the
// phone and the web app give the same answer from the same records.
//
// Dates: records hold local Kampala time with no zone
// ("2026-11-03T14:40:19.123"). The engine never converts zones: it reads
// the day and, where hours matter, the clock time, in one local frame.
import 'dart:math' as math;

/// One stored record, as both apps write it (the fields the engine needs).
class Rec {
  const new({required this.id, required this.body, this.isDeleted = false, this.createdAt, this.createdBy});

  /// Reads a record from the JSON shape used by the parity fixtures.
  factory fromJson(Map<String, Object?> j) => Rec(
    id: '${j['id']}',
    isDeleted: j['isDeleted'] == true,
    createdAt: j['createdAt'] as String?,
    createdBy: j['createdBy'] as String?,
    body: (j['body'] as Map?)?.cast<String, Object?>() ?? const {},
  );

  final String id;
  final bool isDeleted;
  final String? createdAt;
  final String? createdBy;
  final Map<String, Object?> body;

  String? str(String k) => body[k] is String ? body[k]! as String : null;
  double? numOrNull(String k) {
    final v = body[k];
    return v is num ? v.toDouble() : null;
  }

  bool? flag(String k) => body[k] is bool ? body[k]! as bool : null;
}

/// How an answer was made. Shown on every card, so a sum is never called "AI".
enum Method { calculated, statistical, rules, model, experimental }

const methodLabel = <Method, String>{
  Method.calculated: 'Calculated from your records',
  Method.statistical: 'Statistical estimate',
  Method.rules: 'Rule-based guide',
  Method.model: 'AI model',
  Method.experimental: 'Experimental',
};

enum Severity { critical, high, medium, low }

int severityRank(Severity s) => s.index;

class AiModuleInfo {
  const new(this.key, this.label, this.hint);
  final String key;
  final String label;
  final String hint;
}

const aiModules = <AiModuleInfo>[
  AiModuleInfo('assistant', 'Farm Assistant', 'Ask questions about your farm records'),
  AiModuleInfo('vet', 'Veterinary Assistant', 'Symptoms, warning signs and when to call the vet'),
  AiModuleInfo('screening', 'Photo Check', 'Take a photo, get possible causes'),
  AiModuleInfo('milk', 'Milk Intelligence', 'Daily milk, cows dropping, unusual days, losses'),
  AiModuleInfo('quality', 'Milk Quality and Expiry', 'Batches, cooling, temperatures, rejections'),
  AiModuleInfo('predictions', 'Production Predictions', 'Next 7 and 30 days of milk'),
  AiModuleInfo('feed', 'Feed Intelligence', 'Feed left, run-out dates, cost per litre'),
  AiModuleInfo('breeding', 'Breeding Intelligence', 'Heats, checks, calving, open cows'),
  AiModuleInfo('health', 'Animal Health Monitoring', 'Repeat illness, vaccinations, follow-ups'),
  AiModuleInfo('finance', 'Financial Intelligence', 'Cost per litre, unusual spending, cash estimate'),
  AiModuleInfo('inventory', 'Inventory Intelligence', 'Feed and drug stock, reorder'),
  AiModuleInfo('reports', 'Smart Farm Reports', 'Ask for a report in your own words'),
  AiModuleInfo('risks', 'Farm Risk Detection', 'Every risk, by how serious it is'),
  AiModuleInfo('recommendations', 'AI Recommendations', "Today's insights"),
  AiModuleInfo('alerts', 'AI Alerts Centre', 'Acknowledge and resolve alerts'),
];

// ---------------------------------------------------------------- Dates

const _dayMs = 86400000;
String _pad(int n) => n.toString().padLeft(2, '0');
final _dayRe = RegExp(r'^\d{4}-\d{2}-\d{2}');

/// yyyy-mm-dd of an ISO date or date-time (its own local day).
String? dayOf(Object? iso) => iso is String && _dayRe.hasMatch(iso) ? iso.substring(0, 10) : null;

final _msRe = RegExp(r'^(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}):(\d{2})(?::(\d{2}))?)?');

/// Milliseconds of a local ISO date-time, read in one fixed frame (UTC).
int? msOf(Object? iso) {
  if (iso is! String) return null;
  final m = _msRe.firstMatch(iso);
  if (m == null) return null;
  int g(int i) => m.group(i) == null ? 0 : int.parse(m.group(i)!);
  return DateTime.utc(g(1), g(2), g(3), g(4), g(5), g(6)).millisecondsSinceEpoch;
}

int _dayToMs(String day) => DateTime.utc(
  int.parse(day.substring(0, 4)),
  int.parse(day.substring(5, 7)),
  int.parse(day.substring(8, 10)),
).millisecondsSinceEpoch;

String _isoDay(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${_pad(d.month)}-${_pad(d.day)}';

String addDays(String day, int n) =>
    _isoDay(DateTime.fromMillisecondsSinceEpoch(_dayToMs(day) + n * _dayMs, isUtc: true));

int daysBetween(String from, String to) => jsRound((_dayToMs(to) - _dayToMs(from)) / _dayMs).toInt();

/// 0 = Sunday.
int weekdayOf(String day) => DateTime.fromMillisecondsSinceEpoch(_dayToMs(day), isUtc: true).weekday % 7;

String monthOf(String day) => day.substring(0, 7);

String addMonths(String month, int n) {
  final d = DateTime.utc(int.parse(month.substring(0, 4)), int.parse(month.substring(5, 7)) + n);
  return '${d.year.toString().padLeft(4, '0')}-${_pad(d.month)}';
}

/// Now as local Kampala time in the engine's frame (UTC+3, no daylight saving).
({String day, int ms, String iso}) kampalaNow(DateTime now) {
  final k = now.toUtc().add(const Duration(hours: 3));
  final iso = '${_isoDay(k)}T${_pad(k.hour)}:${_pad(k.minute)}:${_pad(k.second)}';
  return (day: iso.substring(0, 10), ms: msOf(iso)!, iso: iso);
}

/// The day a record belongs to: its own date field, else when it was made.
String? recDay(Rec r, [String? field]) => (field != null ? dayOf(r.body[field]) : null) ?? dayOf(r.createdAt);

List<Rec> alive(List<Rec>? rs) => (rs ?? const <Rec>[]).where((r) => !r.isDeleted).toList();

double num0(Object? v) {
  if (v is num && v.isFinite) return v.toDouble();
  if (v is String && v.trim().isNotEmpty) {
    final n = double.tryParse(v.trim());
    if (n != null && n.isFinite) return n;
  }
  return 0;
}

/// JavaScript Math.round: halves round up (also for negatives).
double jsRound(num x) => (x + 0.5).floorToDouble();

// ---------------------------------------------------------------- Statistics

double sum(Iterable<double> xs) => xs.fold(0, (t, x) => t + x);
double mean(List<double> xs) => xs.isEmpty ? 0 : sum(xs) / xs.length;

double median(List<double> xs) {
  if (xs.isEmpty) return 0;
  final s = [...xs]..sort();
  final m = s.length ~/ 2;
  return s.length.isOdd ? s[m] : (s[m - 1] + s[m]) / 2;
}

/// Median absolute deviation, scaled to match a standard deviation.
double mad(List<double> xs) {
  final m = median(xs);
  return 1.4826 * median(xs.map((x) => (x - m).abs()).toList());
}

/// Robust z-score of x against history. Null when history is too short or flat.
double? robustZ(double x, List<double> history, {int minPoints = 7}) {
  if (history.length < minPoints) return null;
  final m = median(history);
  var s = mad(history);
  if (s < m.abs() * 0.05) s = m.abs() * 0.05;
  if (s == 0) return null;
  return (x - m) / s;
}

class LineFit {
  const new(this.slope, this.intercept, this.residualSd, this.r2, this.n);
  final double slope;
  final double intercept;
  final double residualSd;
  final double r2;
  final int n;
}

/// Weighted least squares line y = a + b*x.
LineFit? fitLine(List<double> xs, List<double> ys, [List<double>? ws]) {
  final n = xs.length;
  if (n < 2 || ys.length != n) return null;
  final w = ws ?? List<double>.filled(n, 1);
  final total = sum(w);
  var mx = 0.0;
  var my = 0.0;
  for (var i = 0; i < n; i++) {
    mx += xs[i] * w[i];
    my += ys[i] * w[i];
  }
  mx /= total;
  my /= total;
  var sxx = 0.0;
  var sxy = 0.0;
  for (var i = 0; i < n; i++) {
    sxx += w[i] * math.pow(xs[i] - mx, 2);
    sxy += w[i] * (xs[i] - mx) * (ys[i] - my);
  }
  final slope = sxx == 0 ? 0.0 : sxy / sxx;
  final intercept = my - slope * mx;
  var sse = 0.0;
  var sst = 0.0;
  for (var i = 0; i < n; i++) {
    sse += w[i] * math.pow(ys[i] - (intercept + slope * xs[i]), 2);
    sst += w[i] * math.pow(ys[i] - my, 2);
  }
  final residualSd = math.sqrt(sse / total) * math.sqrt(n / math.max(1, n - 2));
  return LineFit(slope, intercept, residualSd, sst == 0 ? 1 : math.max(0, 1 - sse / sst), n);
}

/// Percentage change from before to now, rounded; null when before is 0.
int? pctChange(double now, double before) {
  if (before == 0) return null;
  return jsRound(((now - before) / before) * 100).toInt();
}

double round1(double x) => jsRound(x * 10) / 10;

// ---------------------------------------------------------------- Insights

class Link {
  const new(this.label, this.href);
  final String label;
  final String href;
}

/// One finding: an alert, a recommendation or an insight. `id` is stable for
/// the same situation, so an acknowledgement sticks until it changes.
class Finding {
  const new({
    required this.id,
    required this.module,
    required this.severity,
    required this.title,
    required this.why,
    required this.action,
    required this.method,
    this.links = const [],
    this.subjects = const [],
  });
  final String id;
  final String module;
  final Severity severity;
  final String title;
  final String why;
  final String action;
  final Method method;
  final List<Link> links;
  final List<String> subjects;
}

/// Stable sort (Dart's List.sort is not stable; JavaScript's is).
List<T> stableSort<T>(Iterable<T> xs, int Function(T a, T b) cmp) {
  final l = xs.toList();
  final idx = List<int>.generate(l.length, (i) => i)
    ..sort((a, b) {
      final c = cmp(l[a], l[b]);
      return c != 0 ? c : a - b;
    });
  return [for (final i in idx) l[i]];
}

/// An approximation of JavaScript localeCompare for plain text: letters
/// compare ignoring case first, then lower case sorts before upper case.
int localeCompare(String a, String b) {
  final c = a.toLowerCase().compareTo(b.toLowerCase());
  if (c != 0) return c;
  for (var i = 0; i < a.length && i < b.length; i++) {
    if (a[i] != b[i]) return a[i] == a[i].toLowerCase() ? -1 : 1;
  }
  return a.length - b.length;
}

/// Sort by severity, then title; drop repeats of the same id.
List<Finding> rankFindings(List<Finding> fs) {
  final seen = <String>{};
  return stableSort(fs.where((f) => seen.add(f.id)), (a, b) {
    final c = severityRank(a.severity) - severityRank(b.severity);
    return c != 0 ? c : localeCompare(a.title, b.title);
  });
}

// ---------------------------------------------------------------- Formats

String _group(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return (n < 0 ? '-' : '') + b.toString();
}

/// en-US number with up to 3 decimals, like JS toLocaleString.
String _locale(double x) {
  final neg = x < 0;
  final r = (x.abs() * 1000).round() / 1000;
  final whole = r.floor();
  final frac = (r - whole).toStringAsFixed(3).substring(2).replaceFirst(RegExp(r'0+$'), '');
  return '${neg ? '-' : ''}${_group(whole)}${frac.isEmpty ? '' : '.$frac'}';
}

String fmtL(double l) => '${_locale(round1(l))} L';
String fmtUgx(double n) => 'UGX ${_locale(jsRound(n))}';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _wd = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

/// "Thu 12 Nov"
String fmtDay(String day) =>
    '${_wd[weekdayOf(day)]} ${int.parse(day.substring(8, 10))} ${_months[int.parse(day.substring(5, 7)) - 1]}';

/// "Nov 2026"
String fmtMonth(String month) => '${_months[int.parse(month.substring(5, 7)) - 1]} ${month.substring(0, 4)}';

String plural(int n, String one, [String? many]) => '$n ${n == 1 ? one : (many ?? '${one}s')}';

/// A number the way JavaScript prints it in a template string (12 not 12.0).
String jsNum(num v) {
  final d = v.toDouble();
  return d == d.roundToDouble() && d.abs() < 1e15 ? d.toInt().toString() : d.toString();
}

/// First letter upper case.
String cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
