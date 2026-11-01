// Loads the real Outfit and Material Icons fonts so golden screenshots show
// real text and icons instead of the default "Ahem" blocks.
import 'dart:async';
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
