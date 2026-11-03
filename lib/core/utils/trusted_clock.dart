import 'package:farm_tap/core/utils/clock.dart';

/// The clock for the trial and read-only checks (decision 0014 §7).
///
/// Turning the phone's date back must not give more free days. This clock
/// remembers the latest time it has seen and never goes before it. Records
/// still use the normal clock, so a wrong phone date never moves a milk
/// record into the future.
class TrustedClock extends Clock {
  new(this.inner, {this._lastSeen, this.save});

  final Clock inner;

  /// Persists the latest time (shared preferences in the app).
  final void Function(DateTime latest)? save;
  DateTime? _lastSeen;

  /// Saves at most once a minute.
  static const _saveEvery = Duration(minutes: 1);

  DateTime? get lastSeen => _lastSeen;

  @override
  DateTime now() {
    final n = inner.now();
    final last = _lastSeen;
    if (last != null && n.isBefore(last)) return last;
    if (last == null || n.difference(last) >= _saveEvery) {
      _lastSeen = n;
      save?.call(n);
    }
    return n;
  }
}
