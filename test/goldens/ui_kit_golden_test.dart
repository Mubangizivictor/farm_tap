// Screenshots of the shared UI kit (the hidden /dev/gallery page).
// Update with: flutter test --update-goldens test/goldens
import 'package:farm_tap/core/ui/gallery/ui_gallery_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  const sizes = {
    'phone': Size(390, 4300),
    'desktop': Size(1440, 3300),
  };
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
        await tester.pump(const Duration(milliseconds: 300));
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('UI_kit_gallery_${entry.key}_$mode.png'),
        );
        // Dispose the tree so no timers are left pending.
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
