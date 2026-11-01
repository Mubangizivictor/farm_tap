// "Now" comes only from the injected Clock (core/utils/clock.dart), so the
// UI phase shows the mockups' date and real builds use Africa/Kampala time.
import 'dart:io';

import 'package:farm_tap/core/utils/clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no DateTime.now() in lib/ outside core/utils/clock.dart', () {
    final pattern = RegExp(r'DateTime\s*\.\s*(now|timestamp)\s*\(');
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (path == 'lib/core/utils/clock.dart' || path.contains('/generated/')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final code = lines[i].split('//').first;
        if (pattern.hasMatch(code)) offenders.add('$path:${i + 1}: ${lines[i].trim()}');
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'Use the injected Clock (context.clock / Clock in repositories):\n${offenders.join('\n')}',
    );
  });

  test('FakeClock is the mockups\' Sat 7 Nov 2026, 8:41 am', () {
    final clock = FakeClock();
    expect(clock.now(), DateTime(2026, 11, 7, 8, 41));
    expect(clock.today(), DateTime(2026, 11, 7));
    expect(clock.now().weekday, DateTime.saturday);
  });

  test('SystemClock reads Kampala time (UTC+3)', () {
    final kampala = SystemClock().now();
    final utc = DateTime.timestamp();
    expect(kampala.difference(DateTime(utc.year, utc.month, utc.day, utc.hour, utc.minute)).inMinutes, closeTo(180, 2));
  });
}
