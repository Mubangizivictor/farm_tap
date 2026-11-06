import 'dart:ffi';
import 'dart:io';

import 'package:isar_community/isar.dart';

/// Loads the native Isar core for host tests (macOS / Linux). The first run
/// downloads it to `.dart_tool/isar_core/`; flutter_test blocks HTTP, so the
/// download runs with a real client. Returns false when it cannot be loaded
/// (no network on the first run), and the Isar tests skip.
Future<bool> loadIsarCoreForTests() async {
  final remote = switch (Abi.current()) {
    Abi.macosArm64 || Abi.macosX64 => 'libisar_macos.dylib',
    Abi.linuxX64 => 'libisar_linux_x64.so',
    Abi.linuxArm64 => 'libisar_linux_arm64.so',
    Abi.windowsX64 => 'isar_windows_x64.dll',
    _ => null,
  };
  if (remote == null) return false;
  final file = File('.dart_tool/isar_core/${Isar.version}/$remote');
  try {
    if (!file.existsSync()) {
      await HttpOverrides.runWithHttpOverrides(() async {
        final client = HttpClient()..findProxy = HttpClient.findProxyFromEnvironment;
        try {
          for (final base in _mirrors) {
            final response = await (await client.getUrl(Uri.parse('$base/${Isar.version}/$remote'))).close();
            if (response.statusCode != 200) {
              await response.drain<void>();
              continue;
            }
            file.parent.createSync(recursive: true);
            await response.pipe(file.openWrite());
            return;
          }
          throw const HttpException('Isar core not found');
        } finally {
          client.close();
        }
      }, _RealHttp());
    }
    await Isar.initializeIsarCore(libraries: {Abi.current(): file.absolute.path});
    return true;
  } on Object {
    if (file.existsSync() && file.lengthSync() == 0) file.deleteSync();
    return false;
  }
}

const _mirrors = [
  'https://binaries.isar-community.dev',
  'https://github.com/isar-community/isar-community/releases/download',
];

class _RealHttp extends HttpOverrides {
  // Base class methods create real sockets.
}
