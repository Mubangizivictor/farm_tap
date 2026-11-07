import 'dart:async';

import 'package:farm_tap/app/di/injection.dart';
import 'package:farm_tap/app/flavor.dart';
import 'package:farm_tap/app/router/app_dependencies.dart';
import 'package:farm_tap/app/router/app_router.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/settings/app_settings_cubit.dart';
import 'package:farm_tap/core/theme/farmtap_theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

class FarmTapApp extends StatefulWidget {
  const new({required this.config, super.key});

  final AppConfig config;

  @override
  State<FarmTapApp> createState() => _FarmTapAppState();
}

class _FarmTapAppState extends State<FarmTapApp> {
  late final AppDependencies _deps = AppDependencies.fromGetIt();
  late final GoRouter _router = buildRouter(_deps);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClockScope(
      clock: getIt<Clock>(),
      child: BlocProvider(
        create: (_) {
          final settings = AppSettingsCubit();
          unawaited(settings.load());
          return settings;
        },
        child: BlocBuilder<AppSettingsCubit, AppSettings>(
          buildWhen: (a, b) => a.themeMode != b.themeMode,
          builder: (context, settings) => _app(settings.themeMode),
        ),
      ),
    );
  }

  Widget _app(ThemeMode themeMode) {
    return MaterialApp.router(
      title: widget.config.appName,
      locale: const Locale('en'),
      theme: FarmTapTheme.light,
      darkTheme: FarmTapTheme.dark,
      themeMode: themeMode,
      routerConfig: _router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      debugShowCheckedModeBanner: false,
      // Pull down on any page to sync with the server (FarmTap logo, at least 1.5 s).
      builder: (context, child) => FarmTapRefresh(onRefresh: _deps.sync.sync, child: child ?? const SizedBox.shrink()),
    );
  }
}
