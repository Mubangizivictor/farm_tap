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
/// [dir] (e.g. 'gallery/') puts the goldens in a sub-folder.
/// [smallScreens] adds overflow checks at 375x667, 360x640 and 1.3x text.
/// [act] runs after the first frame, e.g. to open the overlay the mockup shows.
void screenGoldens(
  String name,
  Widget Function(GoldenFormFactor ff) build, {
  Future<void> Function(WidgetTester tester, GoldenFormFactor ff)? act,
  Set<GoldenFormFactor> only = const {...GoldenFormFactor.values},
  Duration settle = const Duration(milliseconds: 400),
  String dir = '',
  bool smallScreens = true,
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
        await precacheImages(tester);
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('$dir${ff.folder}/${brightness.name}/$name.png'));
        // Dispose the tree so no timers are left pending.
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
  if (!smallScreens) return;
  // Small phones and large text: any RenderFlex overflow fails the test.
  for (final (label, size, scale) in _smallChecks) {
    testWidgets('$name $label', (tester) async {
      await pumpFarmTap(tester, build(GoldenFormFactor.phone), size: size, textScale: scale);
      await tester.pump(settle);
      if (act != null) {
        await act(tester, GoldenFormFactor.phone);
        await tester.pump(settle);
      }
      await precacheImages(tester);
      if (scale == 1) {
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('${dir}small/$label/$name.png'));
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}

const _smallChecks = <(String, Size, double)>[
  ('se_375x667', Size(375, 667), 1),
  ('android_360x640', Size(360, 640), 1),
  ('text_1_3x', Size(390, 788), 1.3),
];

/// Decodes every Image on screen for real (test image loading is async and
/// otherwise never finishes inside the fake clock), then rebuilds.
Future<void> precacheImages(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      final image = element.widget as Image;
      // Animated WebP streams may never report "complete"; the first frame
      // arrives well within this.
      await precacheImage(image.image, element).timeout(const Duration(seconds: 2), onTimeout: () {});
    }
  });
  await tester.pump();
}
