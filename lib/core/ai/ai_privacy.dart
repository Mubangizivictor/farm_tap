// FarmTap AI engine: what may leave the farm for an optional self-hosted
// language model (decision 0025). Hand port of shared/aiPrivacy.ts. The
// phone does not call a model in this release; the redaction rules are
// kept so a later release sends nothing the web app would not send.
import 'package:farm_tap/core/ai/ai_assistant.dart';

class NameLabel {
  const new(this.value, this.label);
  final String value;
  final String label;
}

final _phone = RegExp(r'(\+?\d[\d\s-]{7,}\d)');
final _email = RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+');

/// Replace each known name with a label like "Animal 3". Longest first.
String redact(String text, List<NameLabel> names) {
  var out = text.replaceAll(_email, '[email]').replaceAll(_phone, '[phone]');
  final list = names.where((n) => n.value.trim().length >= 2).toList()
    ..sort((a, b) => b.value.length.compareTo(a.value.length));
  for (final n in list) {
    out = out.replaceAll(RegExp('\\b${RegExp.escape(n.value.trim())}\\b', caseSensitive: false), n.label);
  }
  return out;
}

List<NameLabel> nameLabels({
  required List<({String? name, String? tagNumber})> animals,
  required List<String> people,
  required List<String> places,
}) {
  final out = <NameLabel>[];
  for (var i = 0; i < animals.length; i++) {
    final a = animals[i];
    if (a.name != null && a.name!.isNotEmpty) out.add(NameLabel(a.name!, 'Animal ${i + 1}'));
    if (a.tagNumber != null && a.tagNumber!.isNotEmpty) out.add(NameLabel(a.tagNumber!, 'Animal ${i + 1}'));
  }
  for (var i = 0; i < people.length; i++) {
    out.add(NameLabel(people[i], 'Person ${i + 1}'));
  }
  for (final p in places) {
    out.add(NameLabel(p, '[place]'));
  }
  return out;
}

/// Put the real names back into the model's reply, on the farm's own device.
String restore(String text, List<NameLabel> names) {
  var out = text;
  final seen = <String>{};
  for (final n in names) {
    if (seen.contains(n.label) || n.label == '[place]') continue;
    seen.add(n.label);
    out = out.replaceAll(RegExp('\\b${RegExp.escape(n.label)}\\b'), n.value);
  }
  return out;
}

/// Numbers in a model's reply that were not in the calculated answer.
List<String> inventedNumbers(String reply, Answer a) {
  final re = RegExp(r'\d[\d,]*(\.\d+)?');
  final known = {for (final m in re.allMatches('${a.text} ${a.bullets.join(' ')}')) m.group(0)!.replaceAll(',', '')};
  final plain = reply.replaceAll(RegExp(r'\b(Animal|Person) \d+\b'), '');
  return [for (final m in re.allMatches(plain)) m.group(0)!.replaceAll(',', '')]
      .where((x) => !known.contains(x))
      .toList();
}
