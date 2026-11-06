import 'dart:math';

/// How long to wait before trying a record again (decision 0014 §3):
/// 30 s, 1 min, 2 min ... capped at 1 h, with jitter so 50 phones at one
/// centre do not all retry in the same second when the mast comes back.
class RetryBackoff {
  const new({
    this.base = const Duration(seconds: 30), // theme-guard: ignore (network timing, not UI)
    this.cap = const Duration(hours: 1),
    this.maxAttempts = 8,
    this._random,
  });

  final Duration base;
  final Duration cap;

  /// After this many failed tries the record shows as "Failed" in D04. It is
  /// still kept and sent again on "Sync now" or when the network returns.
  final int maxAttempts;
  final Random? _random;

  /// Wait after the [attempt]-th failure (1-based).
  Duration delay(int attempt) {
    final exp = attempt < 1 ? 0 : min(attempt - 1, 20);
    final raw = base.inMilliseconds * pow(2, exp);
    final capped = min(raw, cap.inMilliseconds).toInt();
    // Equal jitter: half fixed, half random.
    final half = capped ~/ 2;
    final jitter = half == 0 ? 0 : (_random ?? Random()).nextInt(half + 1);
    return Duration(milliseconds: half + jitter); // theme-guard: ignore (network timing, not UI)
  }

  bool exhausted(int attempts) => attempts >= maxAttempts;
}
