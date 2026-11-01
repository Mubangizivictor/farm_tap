// Short, named access to every token from any widget:
//
//   context.colors.primary          Material colour roles (light/dark automatic)
//   context.status.success          FarmTap semantic colours
//   context.text.titleLarge         Material text styles
//   context.textStyles.keypadDigit  FarmTap text styles
//   context.space.lg / gapMd        spacing
//   context.radii.card              corners
//   context.sizes.buttonHeight      sizes
//   context.motion.normal           animation timing
//   context.isDark                  current brightness
//
// Widgets must use these, never raw numbers or colours.
import 'package:farm_tap/core/theme/colors/farmtap_semantic_colors.dart';
import 'package:farm_tap/core/theme/tokens/farmtap_motion.dart';
import 'package:farm_tap/core/theme/tokens/farmtap_radii.dart';
import 'package:farm_tap/core/theme/tokens/farmtap_sizes.dart';
import 'package:farm_tap/core/theme/tokens/farmtap_spacing.dart';
import 'package:farm_tap/core/theme/typography/farmtap_typography.dart';
import 'package:flutter/material.dart';

extension FarmTapThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => theme.colorScheme;
  TextTheme get text => theme.textTheme;
  bool get isDark => theme.brightness == Brightness.dark;

  FarmTapSemanticColors get status => theme.extension<FarmTapSemanticColors>()!;
  FarmTapTextStyles get textStyles => theme.extension<FarmTapTextStyles>()!;
  FarmTapSpacing get space => theme.extension<FarmTapSpacing>()!;
  FarmTapRadii get radii => theme.extension<FarmTapRadii>()!;
  FarmTapSizes get sizes => theme.extension<FarmTapSizes>()!;
  FarmTapMotion get motion => theme.extension<FarmTapMotion>()!;
}
