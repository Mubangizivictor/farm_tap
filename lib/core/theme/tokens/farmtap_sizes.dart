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

  // ---- Large avatars, animations (added for the UI kit) ----
  double get avatarXl => 96 * scale;
  double get avatarHero => 128 * scale;
  double get animationSm => 120 * scale;
  double get animationMd => 180 * scale;
  double get animationLg => 240 * scale;

  // ---- PIN and keypad (added for the UI kit) ----
  double get pinDot => 20 * scale;
  double get shakeDistance => 10 * scale;
  double get keypadMaxWidth => 360 * scale;
  double get keypadDisplayHeight => 96 * scale;

  // ---- Adaptive shell (added for the UI kit; see UX_SPEC section 1) ----
  double get railWidth => 96 * scale;
  double get sidebarWidth => 264 * scale;
  double get contentMaxWidth => 1120 * scale;
  double get dialogMaxWidth => 560 * scale;
  double get toastWidth => 420 * scale;
  double get searchFieldWidth => 360 * scale;
  double get chartHeight => 200 * scale;
  double get progressBar => 8 * scale;
  double get cardPreviewWidth => 320 * scale;

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
