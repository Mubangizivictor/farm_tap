import 'dart:async';

import 'package:farm_tap/app/app.dart';
import 'package:farm_tap/app/di/injection.dart';
import 'package:farm_tap/app/flavor.dart';
import 'package:farm_tap/core/sound/sound_service.dart';
import 'package:farm_tap/core/sync/sync_engine.dart';
import 'package:farm_tap/core/sync/sync_service.dart';
import 'package:farm_tap/core/utils/logger.dart';
import 'package:flutter/widgets.dart';

Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();

  Flavor.current = flavor;
  final config = AppConfig.forFlavor(flavor);

  SoundService.instance = JustAudioSoundService();
  await configureDependencies(flavor);

  await restoreSavedRecords();

  final logger = getIt<AppLogger>();

  FlutterError.onError = (details) {
    logger.e(details.exceptionAsString(), details.exception, details.stack);
  };

  // Decision 0014: start sending saved records, and again on every return
  // to the app.
  final sync = getIt<SyncService>();
  if (sync is SyncEngine) {
    unawaited(sync.start());
    AppLifecycleListener(onResume: () => unawaited(sync.onResume()));
  }

  runApp(FarmTapApp(config: config));
}
