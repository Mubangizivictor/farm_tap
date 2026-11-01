import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/farmtap_platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const phoneSize = Size(390, 844);
const desktopSize = Size(1440, 900);
const tabletSize = Size(1194, 834);

/// Wraps [home] in a themed, localised MaterialApp at [size] (logical px).
Future<void> pumpFarmTap(
  WidgetTester tester,
  Widget home, {
  Size size = phoneSize,
  Brightness brightness = Brightness.light,
  double textScale = 1,
  bool disableAnimations = false,
  bool web = false,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: FarmTapTheme.light,
      darkTheme: FarmTapTheme.dark,
      themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      builder: (context, child) => FarmTapPlatform(
        isWeb: web,
        child: MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale), disableAnimations: disableAnimations),
          child: child!,
        ),
      ),
      home: home,
    ),
  );
  await tester.pump();
}
