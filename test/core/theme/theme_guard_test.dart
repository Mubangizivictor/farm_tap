// Fails the build if any widget code hard-codes colours, font sizes, fonts,
// corner radii, spacing numbers or animation durations.
// Everything must come from the theme (context.colors, context.space, ...).
// Only lib/core/theme/ is allowed to contain raw values.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no hard-coded styling outside lib/core/theme', () {
    final rules = <String, RegExp>{
      'hex colour – use context.colors / context.status': RegExp(r'Color\(\s*0x'),
      'Color.fromARGB/RGBO – use context.colors / context.status': RegExp(r'Color\.from(ARGB|RGBO)\('),
      'Colors.* – use context.colors / context.status': RegExp(r'\bColors\.(?!transparent\b)\w+'),
      'fontSize – use context.text / context.textStyles': RegExp(r'\bfontSize\s*:'),
      'fontFamily – set only in FarmTapDesign': RegExp(r'\bfontFamily\s*:'),
      'FontWeight.wNNN – use FarmTapWeights': RegExp(r'FontWeight\.w\d00'),
      'BorderRadius number – use context.radii': RegExp(r'BorderRadius\.circular\(\s*\d'),
      'EdgeInsets number – use context.space': RegExp(r'EdgeInsets\.(all|symmetric|only|fromLTRB)\([^)]*\b[1-9]\d*(\.\d+)?\b'),
      'SizedBox number – use context.space.gapX / context.sizes': RegExp(r'SizedBox\([^)]*\b(height|width)\s*:\s*[1-9]'),
      'Duration literal – use context.motion': RegExp(r'Duration\(\s*(milliseconds|seconds)\s*:'),
    };

    final violations = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) {
      final p = f.path.replaceAll(r'\', '/');
      return !p.startsWith('lib/core/theme/') &&
          !p.endsWith('.g.dart') &&
          !p.endsWith('.freezed.dart') &&
          !p.contains('/l10n/generated/');
    });

    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;
        if (line.contains('theme-guard: ignore')) continue; // rare, justified exceptions only
        rules.forEach((message, pattern) {
          if (pattern.hasMatch(line)) {
            violations.add('${file.path}:${i + 1}  $message\n    ${line.trim()}');
          }
        });
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Hard-coded styling found. Use theme tokens instead:\n${violations.join('\n')}',
    );
  });
}
