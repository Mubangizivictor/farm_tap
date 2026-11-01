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

  // ---- Touch targets (low-literacy: bigger than Material defaults) ----
  double get touchTarget => 48 * scale;

  double get buttonHeight => 56 * scale;
  double get buttonHeightLarge => 64 * scale;
  double get buttonMinWidth => 64 * scale;
  double get inputHeight => 60 * scale;
  double get searchHeight => 52 * scale;
  double get fab => 64 * scale;

  /// Two buttons sit side by side at this width, else they stack.
  double get buttonPairMinWidth => 420 * scale;

  // ---- Icons ----
  double get iconXs => 16 * scale;
  double get iconSm => 20 * scale;
  double get iconMd => 24 * scale;
  double get iconBanner => 26 * scale;
  double get iconLg => 28 * scale;
  double get iconBackspace => 30 * scale;
  double get iconXl => 40 * scale;
  double get iconHero => 64 * scale;

  // ---- Avatars (person and cow) ----
  double get avatarXs => 36 * scale;
  double get avatarSm => 40 * scale;
  double get avatarMd => 48 * scale;
  double get avatarMl => 56 * scale;
  double get avatarLg => 64 * scale;
  double get avatarXl => 80 * scale;
  double get avatarReadBack => 88 * scale;
  double get avatarHero => 96 * scale;

  /// Ring around staff avatars and read-back avatars.
  double get avatarRing => 3 * scale;

  /// Initials text is this fraction of the avatar size.
  double get initialsFraction => 0.36;

  // ---- Icon bubbles (icon is [bubbleIconFraction] of the bubble) ----
  double get bubbleSm => 40 * scale;
  double get bubbleMd => 44 * scale;
  double get bubbleLg => 52 * scale;
  double get bubbleXl => 64 * scale;
  double get bubbleIconFraction => 0.52;

  // ---- Small atoms ----
  double get badgeHeight => 26 * scale;

  /// Material draws its checkbox 18 dp; scale it to the spec's 24 dp box.
  double get materialCheckbox => 18 * scale;
  double get checkbox => 24 * scale;
  double get chipHeight => 40 * scale;
  double get segmentedHeight => 48 * scale;
  double get dot => 10 * scale;
  double get dotActiveWidth => 28 * scale;
  double get notificationDot => 5 * scale;

  // ---- Tiles, rows, tables ----
  double get listTile => 56 * scale;
  double get listTileDense => 48 * scale;
  double get actionTile => 110 * scale;
  double get actionTileWithSubtitle => 124 * scale;
  double get optionRow => 84 * scale;
  double get tableHeader => 44 * scale;
  double get tableRow => 60 * scale;
  double get timelineItem => 76 * scale;

  // ---- Grids (minimum item widths for ResponsiveGrid) ----
  double get gridMetric => 160 * scale;
  double get gridAction => 150 * scale;
  double get gridPaired => 420 * scale;

  // ---- Animations ----
  double get animationSm => 120 * scale;
  double get animationSheet => 136 * scale;
  double get animationMd => 180 * scale;
  double get animationCelebration => 230 * scale;
  double get animationLg => 240 * scale;
  double get heroAnimationWidth => 120 * scale;
  double get photoPreview => 160 * scale;

  // ---- Keypad and PIN ----
  double get keypadKey => 64 * scale;
  double get keypadMaxWidth => 420 * scale;
  double get keypadDisplayHeight => 96 * scale;
  double get keypadCaretWidth => 3 * scale;
  double get keypadCaretHeight => 46 * scale;
  double get pinKey => 60 * scale;
  double get pinPadMaxWidth => 340 * scale;
  double get pinDot => 22 * scale;
  double get shakeDistance => 10 * scale;

  // ---- Progress ----
  double get progressBar => 10 * scale;
  double get progressBarThin => 6 * scale;
  double get progressStroke => 4 * scale;

  // ---- Bars and navigation ----
  double get appBarHeight => 64 * scale;
  double get topBarWide => 76 * scale;
  double get navBarHeight => 80 * scale;
  double get navIndicatorWidth => 64 * scale;
  double get navIndicatorHeight => 34 * scale;
  double get railWidth => 96 * scale;
  double get railIndicatorHeight => 36 * scale;
  double get railItemPitch => 76 * scale;
  double get logoMark => 32 * scale;
  double get logoMarkRail => 36 * scale;
  double get logoBox => 52 * scale;
  double get sidebarWidth => 264 * scale;
  double get sidebarItemHeight => 44 * scale;
  double get farmSwitcherHeight => 60 * scale;
  double get trialCardHeight => 82 * scale;
  double get searchPillWidth => 290 * scale;
  double get searchPillHeight => 48 * scale;

  // ---- Layout widths ----
  double get contentMaxWidth => 1120 * scale;

  /// Max width of a centred column (splash, PIN, check email).
  double get centeredMaxWidth => 480 * scale;

  /// Form column on the right of the split auth layout.
  double get authColumnWidth => 460 * scale;
  double get dialogWidth => 400 * scale;
  double get dialogMaxWidth => 560 * scale;
  double get toastWidth => 420 * scale;
  double get toastHeight => 64 * scale;
  double get sheetHandleWidth => 36 * scale;
  double get sheetHandleHeight => 5 * scale;

  /// Brand panel share of the split auth layout.
  double get authPanelFractionWide => 0.42;
  double get authPanelFractionMedium => 0.40;

  /// Logo on sign-in / splash (mark + wordmark), and the welcome animation.
  double get authLogoHeight => 52 * scale;
  double get authIllustration => 200 * scale;

  /// Brand panel: logo inset 32, illustration inset 40.
  double get brandPanelLogoInset => 32 * scale;
  double get brandPanelInset => 40 * scale;

  // ---- Charts ----
  double get chartHeight => 200 * scale;
  double get chartLine => 3 * scale;
  double get chartDot => 7 * scale;
  double get chartBarMaxWidth => 36 * scale;
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
  double get appBarLogoHeight => 38 * scale;
  double get sidebarLogoHeight => 40 * scale;
  double get signInLogoWidth => 200 * scale;
  double get loaderSize => 72 * scale;
  double get splashAnimationWidth => 260 * scale;

  // ---- Borders and strokes ----
  double get borderThin => 1;
  double get borderInput => 1.2;
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
