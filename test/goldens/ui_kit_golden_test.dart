// Screenshots of the shared UI kit (the hidden /dev/gallery page).
// Update with: flutter test --update-goldens test/goldens
//
// 1. Full-length catalogue: UI_kit_gallery_<phone|tablet|desktop>_<mode>.png
// 2. First screenful (the D01 home replica) in all 4 form factors, compared
//    with the D01 mockup: python3 tool/compare_mockups.py --dir gallery
import 'package:farm_tap/core/ui/gallery/ui_gallery_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';
import '../helpers/screen_golden.dart';

void main() {
  const sizes = {'phone': Size(390, 8200), 'tablet': Size(1194, 6400), 'desktop': Size(1440, 6000)};
  for (final entry in sizes.entries) {
    for (final brightness in Brightness.values) {
      final mode = brightness.name;
      testWidgets('UI kit gallery ${entry.key} $mode', (tester) async {
        await pumpFarmTap(
          tester,
          UiGalleryPage(initialDark: brightness == Brightness.dark),
          size: entry.value,
          brightness: brightness,
        );
        await tester.pump(const Duration(milliseconds: 400));
        await precacheImages(tester);
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('UI_kit_gallery_${entry.key}_$mode.png'));
        // Dispose the tree so no timers are left pending.
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  screenGoldens('D01_home_owner', (_) => const UiGalleryPage(), dir: 'gallery/');
}
