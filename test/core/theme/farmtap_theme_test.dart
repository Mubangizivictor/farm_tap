import 'package:farm_tap/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FarmTapTheme', () {
    for (final brightness in Brightness.values) {
      test('$brightness theme has every FarmTap extension', () {
        final theme = FarmTapTheme.build(brightness);
        expect(theme.brightness, brightness);
        expect(theme.extension<FarmTapSemanticColors>(), isNotNull);
        expect(theme.extension<FarmTapTextStyles>(), isNotNull);
        expect(theme.extension<FarmTapSpacing>(), isNotNull);
        expect(theme.extension<FarmTapRadii>(), isNotNull);
        expect(theme.extension<FarmTapSizes>(), isNotNull);
        expect(theme.extension<FarmTapMotion>(), isNotNull);
      });
    }

    test('changing FarmTapDesign changes every size token', () {
      final normal = FarmTapTheme.build(Brightness.light);
      final bigger = FarmTapTheme.build(
        Brightness.light,
        design: const FarmTapDesign(sizeScale: 1.5, textScale: 1.5, radiusScale: 2),
      );
      final n = normal.extension<FarmTapSizes>()!;
      final b = bigger.extension<FarmTapSizes>()!;
      expect(b.buttonHeight, n.buttonHeight * 1.5);
      expect(bigger.extension<FarmTapSpacing>()!.lg, normal.extension<FarmTapSpacing>()!.lg * 1.5);
      expect(bigger.extension<FarmTapRadii>()!.md, normal.extension<FarmTapRadii>()!.md * 2);
      expect(bigger.textTheme.bodyLarge!.fontSize, normal.textTheme.bodyLarge!.fontSize! * 1.5);
    });

    testWidgets('context extensions resolve in light and dark', (tester) async {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        late BuildContext captured;
        await tester.pumpWidget(
          MaterialApp(
            theme: FarmTapTheme.light,
            darkTheme: FarmTapTheme.dark,
            themeMode: mode,
            home: Builder(
              builder: (c) {
                captured = c;
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(captured.isDark, mode == ThemeMode.dark);
        expect(captured.space.lg, greaterThan(0));
        expect(captured.status.success, isNotNull);
        expect(captured.textStyles.keypadDigit.fontSize, greaterThan(0));
      }
    });
  });
}
