// Component size tokens, scaled by FarmTapDesign.sizeScale.
// Use: context.sizes.buttonHeight, context.sizes.iconLg, context.sizes.borderThin
import 'dart:ui' show lerpDouble;

import 'package:farm_tap/core/theme/farmtap_design.dart';
import 'package:flutter/material.dart';

@immutable
class FarmTapSizes extends ThemeExtension<FarmTapSizes> {
  const new({required this.scale});

  factory from(FarmTapDesign design) => FarmTapSizes(scale: design.sizeScale);

  final double scale;

  // ---- Touch targets (low-literacy: bigger than Material defaults) ----
  double get touchTarget => 48 * scale;
  double get buttonHeight => 56 * scale;
  double get buttonHeightLarge => 64 * scale;
  double get buttonMinWidth => 64 * scale;
  double get inputHeight => 56 * scale;
  double get keypadKey => 72 * scale;
  double get actionTile => 72 * scale;
  double get fab => 64 * scale;

  // ---- Icons ----
  double get iconXs => 16 * scale;
  double get iconSm => 20 * scale;
  double get iconMd => 24 * scale;
  double get iconLg => 28 * scale;
  double get iconXl => 40 * scale;
  double get iconHero => 64 * scale;

  // ---- Avatars, photos ----
  double get avatarSm => 32 * scale;
  double get avatarMd => 48 * scale;
  double get avatarLg => 72 * scale;
  double get thumbnail => 64 * scale;
  double get photoPreview => 160 * scale;

  // ---- Branding ----
  double get appBarLogoHeight => 32 * scale;
  double get signInLogoWidth => 200 * scale;
  double get loaderSize => 72 * scale;
  double get splashAnimationWidth => 240 * scale;

  // ---- Bars ----
  double get appBarHeight => 64 * scale;
  double get navBarHeight => 76 * scale;

  // ---- Layout ----
  /// Max width of content on tablets / web so lines don't stretch.
  double get maxContentWidth => 640 * scale;

  // ---- Borders and strokes ----
  double get borderThin => 1;
  double get borderMedium => 1.5;
  double get borderThick => 2;
  double get focusRing => 2;
  double get divider => 1;
  double get progressStroke => 4 * scale;

  // ---- Common ready-made sizes ----
  Size get buttonMinSize => Size(buttonMinWidth, buttonHeight);
  Size get buttonLargeMinSize => Size(buttonMinWidth, buttonHeightLarge);
  Size get touchTargetSize => Size.square(touchTarget);

  @override
  FarmTapSizes copyWith({double? scale}) => FarmTapSizes(scale: scale ?? this.scale);

  @override
  FarmTapSizes lerp(FarmTapSizes? other, double t) {
    if (other == null) return this;
    return FarmTapSizes(scale: lerpDouble(scale, other.scale, t) ?? scale);
  }
}
