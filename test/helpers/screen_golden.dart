// Golden screenshots of one screen in all 4 form factors x light/dark, at the
// mockup size minus device chrome, so tool/compare_mockups.py can put them
// next to docs/design/screens/<ff>/<mode>/<ID>_<name>.png.
//
//   screenGoldens('A01_splash', (ff) => const SplashPage());
//
// Writes test/goldens/<ff>/<mode>/A01_splash.png.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

enum GoldenFormFactor {
  phone(Size(390, 788), web: false),
  tablet(Size(1194, 806), web: false),
  webDesktop(Size(1440, 856), web: true),
  webMobile(Size(390, 788), web: true);

  new(this.size, {required this.web});

  final Size size;

  /// Runs in a browser (web mobile shows the hamburger, not the bottom bar).
  final bool web;

  String get folder => switch (this) {
    GoldenFormFactor.phone => 'phone',
    GoldenFormFactor.tablet => 'tablet',
    GoldenFormFactor.webDesktop => 'web_desktop',
    GoldenFormFactor.webMobile => 'web_mobile',
  };
}

/// Registers 8 golden tests for [name] (e.g. "A01_splash").
/// [build] gets the form factor so a test can pick web-only variants.
/// [act] runs after the first frame, e.g. to open the overlay the mockup shows.
void screenGoldens(
  String name,
  Widget Function(GoldenFormFactor ff) build, {
  Future<void> Function(WidgetTester tester, GoldenFormFactor ff)? act,
  Set<GoldenFormFactor> only = const {...GoldenFormFactor.values},
  Duration settle = const Duration(milliseconds: 400),
}) {
  for (final ff in only) {
    for (final brightness in Brightness.values) {
      testWidgets('$name ${ff.folder} ${brightness.name}', (tester) async {
        await pumpFarmTap(tester, build(ff), size: ff.size, brightness: brightness, web: ff.web);
        await tester.pump(settle);
        if (act != null) {
          await act(tester, ff);
          await tester.pump(settle);
        }
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('${ff.folder}/${brightness.name}/$name.png'),
        );
        // Dispose the tree so no timers are left pending.
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
