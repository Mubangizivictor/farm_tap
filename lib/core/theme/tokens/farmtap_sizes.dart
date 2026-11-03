// Component size tokens, scaled by FarmTapDesign.sizeScale.
// Use: context.sizes.buttonHeight, context.sizes.iconLg, context.sizes.borderThin
// Values follow docs/UI_REBUILD_PROMPT.md section 4 (all in dp).
import 'dart:ui' show lerpDouble;

import 'package:farm_tap/core/theme/farmtap_design.dart';
import 'package:flutter/material.dart';

@immutable
class FarmTapSizes extends ThemeExtension<FarmTapSizes> {
  const new({required this.scale});

  factory from(FarmTapDesign design) => FarmTapSizes(scale: design.sizeScale);

  final double scale;

  // ---- Touch targets (decision 0013: visuals are compact, hit areas stay >= 48) ----
  double get touchTarget => 48 * scale;

  /// iOS back-swipe strip on the left edge (as Cupertino's gesture).
  double get backSwipeEdge => 20 * scale;

  double get buttonHeight => 48 * scale;
  double get buttonHeightLarge => 52 * scale;
  double get buttonMinWidth => 64 * scale;
  double get inputHeight => 48 * scale;
  double get searchHeight => 44 * scale;
  double get fab => 48 * scale;

  /// Two buttons sit side by side at this width, else they stack.
  double get buttonPairMinWidth => 380 * scale;

  // ---- Icons ----
  double get iconXs => 14 * scale;
  double get iconSm => 18 * scale;
  double get iconMd => 20 * scale;
  double get iconBanner => 20 * scale;
  double get iconLg => 22 * scale;
  double get iconBackspace => 24 * scale;
  double get iconXl => 32 * scale;
  double get iconHero => 48 * scale;

  // ---- Avatars (person and cow) ----
  double get avatarXs => 32 * scale;
  double get avatarSm => 36 * scale;
  double get avatarMd => 40 * scale;
  double get avatarMl => 44 * scale;
  double get avatarLg => 52 * scale;
  double get avatarXl => 64 * scale;
  double get avatarReadBack => 72 * scale;
  double get avatarHero => 80 * scale;

  /// Ring around staff avatars and read-back avatars.
  double get avatarRing => 2 * scale;

  /// Initials text is this fraction of the avatar size.
  double get initialsFraction => 0.36;

  // ---- Icon bubbles (icon is [bubbleIconFraction] of the bubble) ----
  double get bubbleSm => 32 * scale;
  double get bubbleMd => 36 * scale;
  double get bubbleLg => 40 * scale;
  double get bubbleXl => 52 * scale;
  double get bubbleIconFraction => 0.52;

  // ---- Small atoms ----
  double get badgeHeight => 22 * scale;

  /// Material draws its checkbox 18 dp; scale it to the spec's 24 dp box.
  double get materialCheckbox => 18 * scale;
  double get checkbox => 22 * scale;
  double get chipHeight => 34 * scale;
  double get segmentedHeight => 40 * scale;
  double get dot => 8 * scale;
  double get dotActiveWidth => 22 * scale;
  double get notificationDot => 4 * scale;

  // ---- Tiles, rows, tables ----
  double get listTile => 52 * scale;
  double get listTileDense => 48 * scale;
  double get actionTile => 56 * scale;
  double get actionTileWithSubtitle => 60 * scale;
  double get optionRow => 64 * scale;
  double get tableHeader => 40 * scale;
  double get tableRow => 48 * scale;
  double get timelineItem => 60 * scale;

  // ---- Grids (minimum item widths for ResponsiveGrid) ----
  double get gridMetric => 150 * scale;
  double get gridAction => 140 * scale;
  double get gridPaired => 380 * scale;

  // ---- Animations ----
  double get animationSm => 96 * scale;
  double get animationSheet => 112 * scale;
  double get animationMd => 140 * scale;
  double get animationCelebration => 180 * scale;

  /// Phones: celebration content sits this far up (Alignment y, -1 = top).
  double get celebrationAlignY => -0.45;
  double get animationLg => 190 * scale;
  double get heroAnimationWidth => 96 * scale;
  double get photoPreview => 128 * scale;

  // ---- Keypad and PIN ----
  double get keypadKey => 56 * scale;
  double get keypadMaxWidth => 380 * scale;
  double get keypadDisplayHeight => 72 * scale;
  double get keypadCaretWidth => 2 * scale;
  double get keypadCaretHeight => 34 * scale;
  double get pinKey => 56 * scale;
  double get pinPadMaxWidth => 300 * scale;
  double get pinDot => 16 * scale;
  double get shakeDistance => 8 * scale;

  // ---- Progress ----
  double get progressBar => 8 * scale;
  double get progressBarThin => 5 * scale;
  double get progressStroke => 3 * scale;

  // ---- Bars and navigation ----
  double get appBarHeight => 56 * scale;
  double get topBarWide => 64 * scale;
  double get navBarHeight => 64 * scale;
  double get navIndicatorWidth => 56 * scale;
  double get navIndicatorHeight => 30 * scale;
  double get railWidth => 80 * scale;
  double get railIndicatorHeight => 32 * scale;
  double get railItemPitch => 64 * scale;
  double get logoMark => 28 * scale;
  double get logoMarkRail => 32 * scale;
  double get logoBox => 44 * scale;
  double get sidebarWidth => 240 * scale;
  double get sidebarItemHeight => 40 * scale;
  double get farmSwitcherHeight => 52 * scale;
  double get trialCardHeight => 72 * scale;
  double get searchPillWidth => 260 * scale;
  double get searchPillHeight => 40 * scale;

  // ---- Layout widths ----
  double get contentMaxWidth => 1120 * scale;

  /// Max width of a centred column (splash, PIN, check email).
  double get centeredMaxWidth => 480 * scale;

  /// Form column on the right of the split auth layout.
  double get authColumnWidth => 460 * scale;
  double get dialogWidth => 400 * scale;
  double get dialogMaxWidth => 560 * scale;
  double get toastWidth => 420 * scale;
  double get toastHeight => 52 * scale;
  double get sheetHandleWidth => 32 * scale;
  double get sheetHandleHeight => 4 * scale;

  /// Brand panel share of the split auth layout.
  double get authPanelFractionWide => 0.42;
  double get authPanelFractionMedium => 0.40;

  /// Logo on sign-in / splash (mark + wordmark), and the welcome animation.
  double get authLogoHeight => 44 * scale;
  double get authIllustration => 170 * scale;

  /// Brand panel: logo inset 32, illustration inset 40.
  double get brandPanelLogoInset => 28 * scale;
  double get brandPanelInset => 32 * scale;

  // ---- Charts ----
  double get chartHeight => 170 * scale;
  double get chartLine => 2 * scale;
  double get chartDot => 5 * scale;
  double get chartBarMaxWidth => 24 * scale;
  double get chartAreaOpacity => 0.14;

  // ---- Previews ----
  double get cardPreviewWidth => 320 * scale;
  double get qrLabel => 72 * scale;
  double get scanFrameStroke => 5 * scale;
  double get scanFrameArm => 46 * scale;
  double get viewfinderAspect => 0.69;
  double get viewfinderAspectWide => 2.1;

  // ---- Branding ----
  /// Logo image (mark + wordmark) height: app bar 38, sidebar 40.
  double get appBarLogoHeight => 30 * scale;
  double get sidebarLogoHeight => 34 * scale;
  double get signInLogoWidth => 170 * scale;
  double get loaderSize => 56 * scale;
  double get splashAnimationWidth => 220 * scale;

  // ---- Borders and strokes ----
  double get borderThin => 1;
  double get borderInput => 1;
  double get borderMedium => 1.5;
  double get borderThick => 2;
  double get focusRing => 2;
  double get divider => 1;

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
