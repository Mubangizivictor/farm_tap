import 'package:farm_tap/app/flavor.dart';
import 'package:farm_tap/app/router/app_router.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/l10n/nyn_delegates.dart';
import 'package:farm_tap/core/theme/farmtap_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class FarmTapApp extends StatelessWidget {
  const new({required this.config, super.key});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: config.appName,
      theme: FarmTapTheme.light,
      darkTheme: FarmTapTheme.dark,
      routerConfig: appRouter,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        RunyankoreMaterialLocalizationsDelegate(),
        RunyankoreCupertinoLocalizationsDelegate(),
      ],
      supportedLocales: const [Locale('en'), Locale('nyn')],
      debugShowCheckedModeBanner: false,
    );
  }
}
