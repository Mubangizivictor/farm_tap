// FarmTap asset paths. Use these constants instead of typing paths.
// Pick light/dark with FarmTapAssets.byBrightness(context, light, dark)
// or FarmTapAnimations.x.of(context) for character animations.
import 'package:flutter/material.dart';

abstract final class FarmTapAssets {
  static const _b = 'assets/branding';
  static const _s = 'assets/branding/svg';
  static const _a = 'assets/animations';

  // Logo mark only (no words) — 96 logical px
  static const logoMarkLight = '$_b/logo_mark_light.png';
  static const logoMarkDark = '$_b/logo_mark_dark.png';
  static const logoMarkWhite = '$_b/logo_mark_white.png';

  // App bar logo (mark + words, horizontal) — 32 logical px tall
  static const appBarLogoLight = '$_b/app_bar_logo_light.png';
  static const appBarLogoDark = '$_b/app_bar_logo_dark.png';
  static const appBarLogoOnGreen = '$_b/app_bar_logo_on_green.png';

  // Sign-in / welcome / about logo (mark above words) — 200 logical px wide
  static const signInLogoLight = '$_b/sign_in_logo_light.png';
  static const signInLogoDark = '$_b/sign_in_logo_dark.png';

  // Words only — 40 logical px tall
  static const wordmarkLight = '$_b/wordmark_light.png';
  static const wordmarkDark = '$_b/wordmark_dark.png';

  // SVG versions (use with flutter_svg)
  static const logoMarkLightSvg = '$_s/logo_mark_light.svg';
  static const logoMarkDarkSvg = '$_s/logo_mark_dark.svg';
  static const appBarLogoLightSvg = '$_s/app_bar_logo_light.svg';
  static const appBarLogoDarkSvg = '$_s/app_bar_logo_dark.svg';
  static const signInLogoLightSvg = '$_s/sign_in_logo_light.svg';
  static const signInLogoDarkSvg = '$_s/sign_in_logo_dark.svg';

  // Brand animations
  static const loadingLightGif = '$_a/loading_light.gif';
  static const loadingDarkGif = '$_a/loading_dark.gif';
  static const loadingLightWebp = '$_a/loading_light.webp';
  static const loadingDarkWebp = '$_a/loading_dark.webp';
  static const splashAnimationLightGif = '$_a/splash_animation_light.gif';
  static const splashAnimationDarkGif = '$_a/splash_animation_dark.gif';
  static const splashAnimationLightWebp = '$_a/splash_animation_light.webp';
  static const splashAnimationDarkWebp = '$_a/splash_animation_dark.webp';

  static String byBrightness(BuildContext context, String light, String dark) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// One character animation with light/dark and WebP/GIF variants.
/// WebP (transparent) is the default; GIF is a fallback with a solid background.
@immutable
class FarmTapAnimation {
  const FarmTapAnimation(this.base);

  /// e.g. 'assets/animations/anim_milk_saved'
  final String base;

  String get lightWebp => '${base}_light.webp';
  String get darkWebp => '${base}_dark.webp';
  String get lightGif => '${base}_light.gif';
  String get darkGif => '${base}_dark.gif';

  /// Transparent WebP matching the current theme.
  String of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkWebp : lightWebp;

  /// GIF matching the current theme (solid cream/night background).
  String gifOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkGif : lightGif;
}

/// Character animations (see docs/UX_SPEC.md section 5 for where each is used).
abstract final class FarmTapAnimations {
  static const _a = 'assets/animations';
  static const milkSaved = FarmTapAnimation('$_a/anim_milk_saved');
  static const milking = FarmTapAnimation('$_a/anim_milking');
  static const calfBorn = FarmTapAnimation('$_a/anim_calf_born');
  static const cowGrazing = FarmTapAnimation('$_a/anim_cow_grazing');
  static const treatmentSaved = FarmTapAnimation('$_a/anim_treatment_saved');
  static const feeding = FarmTapAnimation('$_a/anim_feeding');
  static const paymentReceived = FarmTapAnimation('$_a/anim_payment_received');
  static const tapCard = FarmTapAnimation('$_a/anim_tap_card');
  static const smsSent = FarmTapAnimation('$_a/anim_sms_sent');
  static const attendance = FarmTapAnimation('$_a/anim_attendance');
  static const celebration = FarmTapAnimation('$_a/anim_celebration');
  static const emptyHerd = FarmTapAnimation('$_a/anim_empty_herd');
  static const offlineSaved = FarmTapAnimation('$_a/anim_offline_saved');
  static const syncDone = FarmTapAnimation('$_a/anim_sync_done');
  static const errorConfused = FarmTapAnimation('$_a/anim_error_confused');
  static const locked = FarmTapAnimation('$_a/anim_locked');
  static const pregnant = FarmTapAnimation('$_a/anim_pregnant');
  static const waitlist = FarmTapAnimation('$_a/anim_waitlist');
  static const welcome = FarmTapAnimation('$_a/anim_welcome');
}
