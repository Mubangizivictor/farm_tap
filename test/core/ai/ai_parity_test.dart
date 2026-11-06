// The phone AI engine must give the same answers as the web engine on the
// same records (decision 0025, phone AI phase 2). Fixtures: farms.json is
// the input, expected.json is what the shared TypeScript engine says. To
// remake them: node tools/ai_parity/make_farms.mjs && node tools/ai_parity/snapshot.mjs
import 'dart:convert';
import 'dart:io';

import 'package:farm_tap/core/ai/ai_data.dart';
import 'package:flutter_test/flutter_test.dart';

import 'parity_snapshot.dart';

void main() {
  final farms = (jsonDecode(File('test/core/ai/fixtures/farms.json').readAsStringSync()) as List)
      .cast<Map<String, Object?>>();
  final expected = jsonDecode(File('test/core/ai/fixtures/expected.json').readAsStringSync()) as Map<String, Object?>;
  final want = (expected['farms']! as List).cast<Object?>();

  for (var i = 0; i < farms.length; i++) {
    test('farm $i: every alert, forecast, answer and report matches the web engine', () {
      final got = snapshot(FarmData.fromJson(farms[i]));
      final problems = diff(want[i], got);
      expect(problems.take(30).toList(), isEmpty, reason: '${problems.length} differences');
    });
  }

  test('vet guide gives the same result as the web engine', () {
    final problems = diff(expected['vet'], vetSnapshot(expected['vetCases']! as List<Object?>));
    expect(problems.take(30).toList(), isEmpty);
  });
}
