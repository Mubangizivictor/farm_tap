import 'dart:math';

import 'package:farm_tap/core/auth/domain/password_strength.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rules: 8+ with capital, small letter and number', () {
    expect(PasswordRules.meetsRules('short1A'), isFalse);
    expect(PasswordRules.meetsRules('alllowercase1'), isFalse);
    expect(PasswordRules.meetsRules('Milkcow1'), isTrue);
    expect(PasswordRules.strength('milk'), PasswordStrength.weak);
    expect(PasswordRules.strength('Milkcow1'), PasswordStrength.fair);
    expect(PasswordRules.strength('Milkcow1-Rain'), PasswordStrength.strong);
  });

  test('a suggested password always passes and reads well', () {
    for (var i = 0; i < 50; i++) {
      final p = PasswordRules.suggest(Random(i));
      expect(PasswordRules.meetsRules(p), isTrue, reason: p);
      expect(p, matches(RegExp(r'^[A-Z][a-z]+-[A-Z][a-z]+-\d{4}[!#%*?]$')));
    }
  });
}
