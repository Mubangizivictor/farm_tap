// Pure logic behind the milk / delivery keypad, so it is easy to test.
// "9" + "." + "5" -> "9.5". One decimal place, no leading zeros, max length.
class DecimalEntry {
  const new({this.text = '', this.maxIntegerDigits = 3, this.maxDecimals = 1});

  final String text;
  final int maxIntegerDigits;
  final int maxDecimals;

  bool get isEmpty => text.isEmpty;

  /// Value as a number; empty or just "." is 0.
  double get value => double.tryParse(text) ?? 0;

  /// What to show on the display ("0" when nothing typed yet).
  String get display => text.isEmpty ? '0' : text;

  DecimalEntry press(String key) {
    if (key == '.') {
      if (maxDecimals == 0 || text.contains('.')) return this;
      return _copy(text.isEmpty ? '0.' : '$text.');
    }
    final dot = text.indexOf('.');
    if (dot >= 0) {
      if (text.length - dot - 1 >= maxDecimals) return this;
      return _copy('$text$key');
    }
    if (text == '0') return _copy(key);
    if (text.length >= maxIntegerDigits) return this;
    return _copy('$text$key');
  }

  DecimalEntry backspace() => text.isEmpty ? this : _copy(text.substring(0, text.length - 1));

  DecimalEntry _copy(String t) => DecimalEntry(text: t, maxIntegerDigits: maxIntegerDigits, maxDecimals: maxDecimals);
}
