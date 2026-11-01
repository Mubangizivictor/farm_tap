import 'package:farm_tap/app/di/injection.dart';
import 'package:farm_tap/app/flavor.dart';
import 'package:farm_tap/app/router/app_router.dart';
import 'package:farm_tap/app/session/session_controller.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/l10n/nyn_delegates.dart';
import 'package:farm_tap/core/settings/app_settings_cubit.dart';
import 'package:farm_tap/core/tenancy/domain/farm_membership_repository.dart';
import 'package:farm_tap/core/theme/farmtap_theme.dart';
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
  late final GoRouter _router = buildRouter(
    session: getIt<SessionController>(),
    places: getIt<FarmMembershipRepository>(),
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AppSettingsCubit(),
      child: BlocBuilder<AppSettingsCubit, AppSettings>(
        buildWhen: (a, b) => a.languageCode != b.languageCode,
        builder: (context, settings) => _app(Locale(settings.languageCode)),
      ),
    );
  }

  Widget _app(Locale locale) {
    return MaterialApp.router(
      title: widget.config.appName,
      locale: locale,
      theme: FarmTapTheme.light,
      darkTheme: FarmTapTheme.dark,
      routerConfig: _router,
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
