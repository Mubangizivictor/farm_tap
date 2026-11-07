// Builds the light and dark ThemeData from FarmTapDesign + tokens.
// You should not need to edit this file to restyle the app:
//   sizes, spacing, corners, font, text size -> farmtap_design.dart
//   colours                                  -> tokens/farmtap_palette.dart
//                                               colors/farmtap_color_schemes.dart
//                                               colors/farmtap_semantic_colors.dart
//   a component's look                       -> components/farmtap_component_themes.dart
//
// Usage in MaterialApp:
//   theme: FarmTapTheme.light,
//   darkTheme: FarmTapTheme.dark,
//   themeMode: ThemeMode.system,
import 'package:farm_tap/core/theme/colors/farmtap_color_schemes.dart';
import 'package:farm_tap/core/theme/colors/farmtap_semantic_colors.dart';
import 'package:farm_tap/core/theme/components/farmtap_component_themes.dart';
import 'package:farm_tap/core/theme/farmtap_design.dart';
import 'package:farm_tap/core/theme/tokens/farmtap_motion.dart';
import 'package:farm_tap/core/theme/tokens/farmtap_radii.dart';
import 'package:farm_tap/core/theme/tokens/farmtap_sizes.dart';
import 'package:farm_tap/core/theme/tokens/farmtap_spacing.dart';
import 'package:farm_tap/core/theme/typography/farmtap_typography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

abstract final class FarmTapTheme {
  static ThemeData get light => build(Brightness.light);
  static ThemeData get dark => build(Brightness.dark);

  static ThemeData build(Brightness brightness, {FarmTapDesign design = FarmTapDesign.current}) {
    final isDark = brightness == Brightness.dark;
    final colors = isDark ? FarmTapColorSchemes.dark : FarmTapColorSchemes.light;
    final status = isDark ? FarmTapSemanticColors.dark : FarmTapSemanticColors.light;
    final text = FarmTapTypography.textTheme(design, colors);
    final textStyles = FarmTapTextStyles.from(design, colors);
    final space = FarmTapSpacing.from(design);
    final radii = FarmTapRadii.from(design);
    final sizes = FarmTapSizes.from(design);
    const motion = FarmTapMotion();

    final t = FarmTapTokens(
      colors: colors,
      status: status,
      text: text,
      textStyles: textStyles,
      space: space,
      radii: radii,
      sizes: sizes,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colors,
      fontFamily: design.fontFamily,
      textTheme: text,
      primaryTextTheme: text.apply(bodyColor: colors.onPrimary, displayColor: colors.onPrimary),
      scaffoldBackgroundColor: colors.surface,
      canvasColor: colors.surface,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      // iOS / macOS: Cupertino slide with the edge swipe-back gesture.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      extensions: <ThemeExtension<dynamic>>[status, textStyles, space, radii, sizes, motion],
      // Components
      appBarTheme: FarmTapComponentThemes.appBar(t),
      navigationBarTheme: FarmTapComponentThemes.navigationBar(t),
      filledButtonTheme: FarmTapComponentThemes.filledButton(t),
      elevatedButtonTheme: FarmTapComponentThemes.elevatedButton(t),
      outlinedButtonTheme: FarmTapComponentThemes.outlinedButton(t),
      textButtonTheme: FarmTapComponentThemes.textButton(t),
      iconButtonTheme: FarmTapComponentThemes.iconButton(t),
      floatingActionButtonTheme: FarmTapComponentThemes.fab(t),
      inputDecorationTheme: FarmTapComponentThemes.input(t),
      cardTheme: FarmTapComponentThemes.card(t),
      listTileTheme: FarmTapComponentThemes.listTile(t),
      dialogTheme: FarmTapComponentThemes.dialog(t),
      bottomSheetTheme: FarmTapComponentThemes.bottomSheet(t),
      snackBarTheme: FarmTapComponentThemes.snackBar(t),
      chipTheme: FarmTapComponentThemes.chip(t),
      segmentedButtonTheme: FarmTapComponentThemes.segmentedButton(t),
      tabBarTheme: FarmTapComponentThemes.tabBar(t),
      tooltipTheme: FarmTapComponentThemes.tooltip(t),
      dividerTheme: FarmTapComponentThemes.divider(t),
      progressIndicatorTheme: FarmTapComponentThemes.progress(t),
      checkboxTheme: FarmTapComponentThemes.checkbox(t),
      iconTheme: FarmTapComponentThemes.icon(t),
      primaryIconTheme: FarmTapComponentThemes.primaryIcon(t),
    );
  }
}
