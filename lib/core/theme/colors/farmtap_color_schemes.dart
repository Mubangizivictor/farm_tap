// Which palette colour plays which role, for light and dark mode.
// To change e.g. the primary colour everywhere, change it here (or in the palette).
// Widgets read these as context.colors.primary, context.colors.surface, etc.
import 'package:farm_tap/core/theme/tokens/farmtap_palette.dart';
import 'package:flutter/material.dart';

abstract final class FarmTapColorSchemes {
  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    // Brand
    primary: FarmTapPalette.green700,
    onPrimary: FarmTapPalette.white,
    primaryContainer: FarmTapPalette.green100,
    onPrimaryContainer: FarmTapPalette.green900,
    secondary: FarmTapPalette.gold500,
    onSecondary: FarmTapPalette.gold950,
    secondaryContainer: FarmTapPalette.gold100,
    onSecondaryContainer: FarmTapPalette.gold900,
    tertiary: FarmTapPalette.blue600,
    onTertiary: FarmTapPalette.white,
    tertiaryContainer: FarmTapPalette.blue50,
    onTertiaryContainer: FarmTapPalette.blue990,
    // Error
    error: FarmTapPalette.danger600,
    onError: FarmTapPalette.white,
    errorContainer: FarmTapPalette.danger50,
    onErrorContainer: FarmTapPalette.danger950,
    // Surfaces
    surface: FarmTapPalette.cream,
    onSurface: FarmTapPalette.ink,
    surfaceDim: FarmTapPalette.sand500,
    surfaceBright: FarmTapPalette.cream,
    surfaceContainerLowest: FarmTapPalette.white,
    surfaceContainerLow: FarmTapPalette.sand100,
    surfaceContainer: FarmTapPalette.sand200,
    surfaceContainerHigh: FarmTapPalette.sand300,
    surfaceContainerHighest: FarmTapPalette.sand400,
    onSurfaceVariant: FarmTapPalette.stone700,
    outline: FarmTapPalette.stone500,
    outlineVariant: FarmTapPalette.stone300,
    // Misc
    shadow: FarmTapPalette.black,
    scrim: FarmTapPalette.black,
    inverseSurface: FarmTapPalette.inkSoft,
    onInverseSurface: FarmTapPalette.mistSoft,
    inversePrimary: FarmTapPalette.green400,
    surfaceTint: FarmTapPalette.green700,
  );

  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    // Brand
    primary: FarmTapPalette.green400,
    onPrimary: FarmTapPalette.green950,
    primaryContainer: FarmTapPalette.green800,
    onPrimaryContainer: FarmTapPalette.green10,
    secondary: FarmTapPalette.gold300,
    onSecondary: FarmTapPalette.gold925,
    secondaryContainer: FarmTapPalette.gold800,
    onSecondaryContainer: FarmTapPalette.gold150,
    tertiary: FarmTapPalette.blue300,
    onTertiary: FarmTapPalette.blue950,
    tertiaryContainer: FarmTapPalette.blue800,
    onTertiaryContainer: FarmTapPalette.blue50,
    // Error
    error: FarmTapPalette.danger300,
    onError: FarmTapPalette.danger900,
    errorContainer: FarmTapPalette.danger800,
    onErrorContainer: FarmTapPalette.danger50,
    // Surfaces
    surface: FarmTapPalette.night,
    onSurface: FarmTapPalette.mist,
    surfaceDim: FarmTapPalette.night,
    surfaceBright: FarmTapPalette.night500,
    surfaceContainerLowest: FarmTapPalette.night0,
    surfaceContainerLow: FarmTapPalette.night100,
    surfaceContainer: FarmTapPalette.night200,
    surfaceContainerHigh: FarmTapPalette.night300,
    surfaceContainerHighest: FarmTapPalette.night400,
    onSurfaceVariant: FarmTapPalette.slate300,
    outline: FarmTapPalette.slate500,
    outlineVariant: FarmTapPalette.slate700,
    // Misc
    shadow: FarmTapPalette.black,
    scrim: FarmTapPalette.black,
    inverseSurface: FarmTapPalette.mist,
    onInverseSurface: FarmTapPalette.mistDim,
    inversePrimary: FarmTapPalette.green700,
    surfaceTint: FarmTapPalette.green400,
  );
}
