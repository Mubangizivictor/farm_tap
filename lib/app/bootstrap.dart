import 'dart:async';

import 'package:farm_tap/app/app.dart';
import 'package:farm_tap/app/di/injection.dart';
import 'package:farm_tap/app/flavor.dart';
import 'package:farm_tap/core/sound/sound_service.dart';
import 'package:farm_tap/core/utils/logger.dart';
import 'package:flutter/widgets.dart';

Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();

  Flavor.current = flavor;
  final config = AppConfig.forFlavor(flavor);

  SoundService.instance = JustAudioSoundService();
  await configureDependencies(flavor);

  final logger = getIt<AppLogger>();

  FlutterError.onError = (details) {
    logger.e(details.exceptionAsString(), details.exception, details.stack);
  };

  runApp(FarmTapApp(config: config));
}
