// The app's only source of "now" (AGENTS.md: no DateTime.now() elsewhere;
// test/core/utils/clock_guard_test.dart enforces it). Farms run on
// Africa/Kampala time whatever the phone's zone.
import 'package:flutter/widgets.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

abstract class Clock {
  const new();

  /// Wall-clock time in Kampala (a plain DateTime with Kampala's fields).
  DateTime now();

  /// Midnight of [now].
  DateTime today() {
    final n = now();
    return DateTime(n.year, n.month, n.day);
  }
}

/// Real time in Africa/Kampala (timezone package; the full database, as
/// Kampala is an alias of Nairobi and missing from the default set).
class SystemClock extends Clock {
  new() {
    if (!_loaded) {
      tzdata.initializeTimeZones();
      _loaded = true;
    }
  }

  static bool _loaded = false;
  static final tz.Location _kampala = tz.getLocation('Africa/Kampala');

  @override
  DateTime now() {
    final t = tz.TZDateTime.now(_kampala);
    return DateTime(t.year, t.month, t.day, t.hour, t.minute, t.second, t.millisecond);
  }
}

/// UI phase (useFakeData): the mockups' Sat 7 Nov 2026, 8:41 am, so sample
/// data (treatments, sessions, pay days) always reads as designed.
/// `--dart-define=DEMO_DATE=2026-11-07T08:41` picks another moment.
class FakeClock extends Clock {
  new([DateTime? at]) : _at = at ?? demoDate;

  final DateTime _at;

  static DateTime get demoDate =>
      DateTime.tryParse(const String.fromEnvironment('DEMO_DATE')) ?? DateTime(2026, 11, 7, 8, 41);

  @override
  DateTime now() => _at;
}

/// Hands the injected clock to widgets: `context.clock.now()`.
class ClockScope extends InheritedWidget {
  const new({required this.clock, required super.child, super.key});

  final Clock clock;

  /// Outside a scope (isolated widget tests) the demo clock is used.
  static Clock of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ClockScope>()?.clock ?? _fallback;

  static final Clock _fallback = FakeClock();

  @override
  bool updateShouldNotify(ClockScope old) => old.clock != clock;
}

extension ClockContext on BuildContext {
  Clock get clock => ClockScope.of(this);
}
