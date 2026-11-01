// Every Material component's look, built ONLY from tokens.
// Widgets just use FilledButton, TextField, Card... and get this style for free.
// Change a token in farmtap_design.dart / tokens/ and these follow.
import 'package:farm_tap/core/theme/colors/farmtap_semantic_colors.dart';
import 'package:farm_tap/core/theme/tokens/farmtap_radii.dart';
import 'package:farm_tap/core/theme/tokens/farmtap_sizes.dart';
import 'package:farm_tap/core/theme/tokens/farmtap_spacing.dart';
import 'package:farm_tap/core/theme/typography/farmtap_typography.dart';
import 'package:flutter/material.dart';

/// All tokens for one brightness, passed to the component builders.
@immutable
class FarmTapTokens {
  const new({
    required this.colors,
    required this.status,
    required this.text,
    required this.textStyles,
    required this.space,
    required this.radii,
    required this.sizes,
  });

  final ColorScheme colors;
  final FarmTapSemanticColors status;
  final TextTheme text;
  final FarmTapTextStyles textStyles;
  final FarmTapSpacing space;
  final FarmTapRadii radii;
  final FarmTapSizes sizes;
}

abstract final class FarmTapComponentThemes {
  // ---------------- Bars ----------------
  static AppBarTheme appBar(FarmTapTokens t) => AppBarTheme(
    backgroundColor: t.colors.surface,
    foregroundColor: t.colors.onSurface,
    surfaceTintColor: t.colors.surfaceTint,
    elevation: 0,
    scrolledUnderElevation: 1,
    centerTitle: false,
    toolbarHeight: t.sizes.appBarHeight,
    titleTextStyle: t.text.titleLarge,
    iconTheme: IconThemeData(color: t.colors.onSurface, size: t.sizes.iconLg),
    actionsIconTheme: IconThemeData(color: t.colors.onSurface, size: t.sizes.iconLg),
  );

  static NavigationBarThemeData navigationBar(FarmTapTokens t) => NavigationBarThemeData(
    height: t.sizes.navBarHeight,
    backgroundColor: t.colors.surfaceContainer,
    indicatorColor: t.colors.primaryContainer,
    labelTextStyle: WidgetStateProperty.resolveWith(
      (states) => t.text.labelMedium?.copyWith(
        color: states.contains(WidgetState.selected) ? t.colors.onSurface : t.colors.onSurfaceVariant,
      ),
    ),
    iconTheme: WidgetStateProperty.resolveWith(
      (states) => IconThemeData(
        size: t.sizes.iconLg,
        color: states.contains(WidgetState.selected) ? t.colors.onPrimaryContainer : t.colors.onSurfaceVariant,
      ),
    ),
  );

  // ---------------- Buttons ----------------
  static ButtonStyle _base(FarmTapTokens t) => ButtonStyle(
    minimumSize: WidgetStatePropertyAll(t.sizes.buttonMinSize),
    padding: WidgetStatePropertyAll(t.space.button),
    shape: WidgetStatePropertyAll(t.radii.buttonShape),
    textStyle: WidgetStatePropertyAll(t.textStyles.button),
    iconSize: WidgetStatePropertyAll(t.sizes.iconMd),
  );

  static FilledButtonThemeData filledButton(FarmTapTokens t) => FilledButtonThemeData(style: _base(t));

  static ElevatedButtonThemeData elevatedButton(FarmTapTokens t) => ElevatedButtonThemeData(style: _base(t));

  static OutlinedButtonThemeData outlinedButton(FarmTapTokens t) => OutlinedButtonThemeData(
    style: _base(t).copyWith(
      side: WidgetStateProperty.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.disabled) ? t.colors.outlineVariant : t.colors.outline,
          width: t.sizes.borderMedium,
        ),
      ),
    ),
  );

  static TextButtonThemeData textButton(FarmTapTokens t) => TextButtonThemeData(
    style: ButtonStyle(
      minimumSize: WidgetStatePropertyAll(t.sizes.touchTargetSize),
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: t.space.md)),
      shape: WidgetStatePropertyAll(t.radii.buttonShape),
      textStyle: WidgetStatePropertyAll(t.textStyles.button),
    ),
  );

  static IconButtonThemeData iconButton(FarmTapTokens t) => IconButtonThemeData(
    style: ButtonStyle(
      minimumSize: WidgetStatePropertyAll(t.sizes.touchTargetSize),
      iconSize: WidgetStatePropertyAll(t.sizes.iconLg),
    ),
  );

  static FloatingActionButtonThemeData fab(FarmTapTokens t) => FloatingActionButtonThemeData(
    backgroundColor: t.colors.primary,
    foregroundColor: t.colors.onPrimary,
    iconSize: t.sizes.iconLg,
    sizeConstraints: BoxConstraints.tightFor(width: t.sizes.fab, height: t.sizes.fab),
    extendedSizeConstraints: BoxConstraints(minHeight: t.sizes.fab),
    extendedTextStyle: t.textStyles.button,
    shape: RoundedRectangleBorder(borderRadius: t.radii.fab),
  );

  // ---------------- Inputs ----------------
  static InputDecorationTheme input(FarmTapTokens t) {
    OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
      borderRadius: t.radii.input,
      borderSide: BorderSide(color: c, width: w),
    );
    return InputDecorationTheme(
      filled: true,
      fillColor: t.colors.surfaceContainerLowest,
      contentPadding: t.space.input,
      labelStyle: t.text.bodyLarge?.copyWith(color: t.colors.onSurfaceVariant),
      floatingLabelStyle: t.text.bodyMedium?.copyWith(color: t.colors.primary),
      hintStyle: t.text.bodyLarge?.copyWith(color: t.colors.onSurfaceVariant),
      helperStyle: t.text.bodySmall,
      errorStyle: t.text.bodySmall?.copyWith(color: t.colors.error),
      prefixIconColor: t.colors.onSurfaceVariant,
      suffixIconColor: t.colors.onSurfaceVariant,
      border: border(t.colors.outline, t.sizes.borderThin),
      enabledBorder: border(t.colors.outline, t.sizes.borderThin),
      disabledBorder: border(t.colors.outlineVariant, t.sizes.borderThin),
      focusedBorder: border(t.colors.primary, t.sizes.focusRing),
      errorBorder: border(t.colors.error, t.sizes.borderMedium),
      focusedErrorBorder: border(t.colors.error, t.sizes.focusRing),
    );
  }

  // ---------------- Containers ----------------
  static CardThemeData card(FarmTapTokens t) => CardThemeData(
    color: t.colors.surfaceContainerLowest,
    surfaceTintColor: t.colors.surfaceTint,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: t.radii.card,
      side: BorderSide(color: t.colors.outlineVariant, width: t.sizes.borderThin),
    ),
  );

  static ListTileThemeData listTile(FarmTapTokens t) => ListTileThemeData(
    contentPadding: t.space.listItem,
    minVerticalPadding: t.space.md,
    minTileHeight: t.sizes.actionTile,
    horizontalTitleGap: t.space.md,
    titleTextStyle: t.text.titleMedium,
    subtitleTextStyle: t.text.bodyMedium?.copyWith(color: t.colors.onSurfaceVariant),
    leadingAndTrailingTextStyle: t.text.labelLarge,
    iconColor: t.colors.primary,
    shape: RoundedRectangleBorder(borderRadius: t.radii.card),
  );

  static DialogThemeData dialog(FarmTapTokens t) => DialogThemeData(
    backgroundColor: t.colors.surfaceContainerHigh,
    surfaceTintColor: t.colors.surfaceTint,
    shape: t.radii.dialogShape,
    titleTextStyle: t.text.headlineSmall,
    contentTextStyle: t.text.bodyLarge,
    actionsPadding: EdgeInsets.fromLTRB(t.space.xl, 0, t.space.xl, t.space.xl),
  );

  static BottomSheetThemeData bottomSheet(FarmTapTokens t) => BottomSheetThemeData(
    backgroundColor: t.colors.surfaceContainerLow,
    surfaceTintColor: t.colors.surfaceTint,
    modalBackgroundColor: t.colors.surfaceContainerLow,
    shape: t.radii.sheetShape,
    showDragHandle: true,
    dragHandleColor: t.colors.outline,
  );

  static SnackBarThemeData snackBar(FarmTapTokens t) => SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: t.colors.inverseSurface,
    contentTextStyle: t.text.bodyLarge?.copyWith(color: t.colors.onInverseSurface),
    actionTextColor: t.colors.inversePrimary,
    shape: RoundedRectangleBorder(borderRadius: t.radii.snackBar),
    insetPadding: t.space.screen,
  );

  static ChipThemeData chip(FarmTapTokens t) => ChipThemeData(
    labelStyle: t.text.labelMedium,
    padding: EdgeInsets.symmetric(horizontal: t.space.sm, vertical: t.space.xs),
    shape: RoundedRectangleBorder(borderRadius: t.radii.chip),
    side: BorderSide(color: t.colors.outlineVariant, width: t.sizes.borderThin),
    iconTheme: IconThemeData(size: t.sizes.iconSm, color: t.colors.onSurfaceVariant),
  );

  static TooltipThemeData tooltip(FarmTapTokens t) => TooltipThemeData(
    textStyle: t.text.bodyMedium?.copyWith(color: t.colors.onInverseSurface),
    decoration: BoxDecoration(color: t.colors.inverseSurface, borderRadius: t.radii.chip),
    padding: EdgeInsets.symmetric(horizontal: t.space.md, vertical: t.space.sm),
  );

  static DividerThemeData divider(FarmTapTokens t) =>
      DividerThemeData(color: t.colors.outlineVariant, thickness: t.sizes.divider, space: t.sizes.divider);

  static ProgressIndicatorThemeData progress(FarmTapTokens t) => ProgressIndicatorThemeData(
    color: t.colors.primary,
    linearTrackColor: t.colors.primaryContainer,
    circularTrackColor: t.colors.primaryContainer,
  );

  static IconThemeData icon(FarmTapTokens t) => IconThemeData(color: t.colors.onSurface, size: t.sizes.iconMd);

  static IconThemeData primaryIcon(FarmTapTokens t) => IconThemeData(color: t.colors.onPrimary, size: t.sizes.iconMd);
}
