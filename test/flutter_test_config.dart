// Loads the real Outfit, Material Icons and Material Symbols Rounded fonts so golden screenshots show
// real text and icons instead of the default "Ahem" blocks.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadFont('Outfit', [
    'assets/fonts/Outfit/Outfit-Regular.ttf',
    'assets/fonts/Outfit/Outfit-Medium.ttf',
    'assets/fonts/Outfit/Outfit-SemiBold.ttf',
    'assets/fonts/Outfit/Outfit-Bold.ttf',
    'assets/fonts/Outfit/Outfit-ExtraBold.ttf',
  ]);
  await _loadFont('MaterialIcons', [_materialIconsPath()]);
  await _loadFont('packages/material_symbols_icons/MaterialSymbolsRounded', [
    _packageFile('material_symbols_icons', 'fonts/MaterialSymbolsRounded.ttf'),
  ]);
  await testMain();
}

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final p in paths) {
    final bytes = File(p).readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

String _materialIconsPath() {
  final root = Platform.environment['FLUTTER_ROOT'] ?? _flutterRootFromDart();
  return '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
}

String _flutterRootFromDart() {
  // .../flutter/bin/cache/dart-sdk/bin/dart -> .../flutter
  final dart = Platform.resolvedExecutable.split(Platform.pathSeparator);
  return dart.sublist(0, dart.length - 5).join(Platform.pathSeparator);
}

/// Resolves a file inside a dependency's `lib/` via package_config.json.
String _packageFile(String package, String relative) {
  final config = jsonDecode(File('.dart_tool/package_config.json').readAsStringSync()) as Map<String, dynamic>;
  final entry = (config['packages'] as List<dynamic>).cast<Map<String, dynamic>>().firstWhere(
    (p) => p['name'] == package,
  );
  final rootUri = entry['rootUri'] as String;
  final root = Uri.parse(rootUri.endsWith('/') ? rootUri : '$rootUri/');
  final base = root.isAbsolute ? root : Uri.directory('${Directory.current.path}/.dart_tool/').resolveUri(root);
  return base.resolve('lib/$relative').toFilePath();
}
