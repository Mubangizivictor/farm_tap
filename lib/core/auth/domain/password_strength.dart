import 'dart:math';

enum PasswordStrength { weak, fair, good, strong }

/// Sign-up password rules: at least 8 characters with a capital letter, a
/// small letter and a number.
abstract final class PasswordRules {
  static const minLength = 8;

  static bool meetsRules(String p) =>
      p.length >= minLength &&
      p.contains(RegExp('[A-Z]')) &&
      p.contains(RegExp('[a-z]')) &&
      p.contains(RegExp('[0-9]'));

  static PasswordStrength strength(String p) {
    if (!meetsRules(p)) return PasswordStrength.weak;
    var score = 0;
    if (p.length >= 12) score++;
    if (p.length >= 16) score++;
    if (p.contains(RegExp('[^A-Za-z0-9]'))) score++;
    return switch (score) {
      0 => PasswordStrength.fair,
      1 => PasswordStrength.good,
      _ => PasswordStrength.strong,
    };
  }

  static const _words = [
    'Cow', 'Milk', 'Grass', 'Calf', 'Rain', 'Hill', 'Barn', 'Maize', 'River', 'Sun', //
    'Bull', 'Heifer', 'Ankole', 'Kraal', 'Field', 'Cream', 'Bean', 'Goat', 'Farm', 'Dairy',
  ];

  /// Easy to read aloud and type, e.g. "Rain-Heifer-4821!".
  static String suggest([Random? random]) {
    final r = random ?? Random.secure();
    String word() => _words[r.nextInt(_words.length)];
    final digits = (1000 + r.nextInt(9000)).toString();
    const marks = '!#%*?';
    return '${word()}-${word()}-$digits${marks[r.nextInt(marks.length)]}';
  }
}
