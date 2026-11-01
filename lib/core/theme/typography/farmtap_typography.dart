// Typography. Font family and text scale come from FarmTapDesign.
// Use: context.text.titleLarge (Material styles) or
//      context.textStyles.keypadDigit (FarmTap-specific styles).
// Never set fontSize, fontFamily or text colour in widgets.
import 'package:farm_tap/core/theme/farmtap_design.dart';
import 'package:flutter/material.dart';

/// Font weights. Use these names, not FontWeight.w600 etc.
abstract final class FarmTapWeights {
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
}

abstract final class FarmTapTypography {
  /// Base font sizes before FarmTapDesign.textScale. Slightly larger than
  /// Material defaults for low-literacy readability.
  static TextTheme textTheme(FarmTapDesign d, ColorScheme cs) {
    TextStyle s(double size, FontWeight w, double h) => TextStyle(
      fontFamily: d.fontFamily,
      fontSize: size * d.textScale,
      fontWeight: w,
      height: h,
      color: cs.onSurface,
    );
    return TextTheme(
      displayLarge: s(52, FarmTapWeights.bold, 1.1),
      displayMedium: s(44, FarmTapWeights.bold, 1.1),
      displaySmall: s(38, FarmTapWeights.bold, 1.15),
      headlineLarge: s(32, FarmTapWeights.bold, 1.2),
      headlineMedium: s(28, FarmTapWeights.bold, 1.2),
      headlineSmall: s(24, FarmTapWeights.semiBold, 1.25),
      titleLarge: s(22, FarmTapWeights.semiBold, 1.3),
      titleMedium: s(18, FarmTapWeights.semiBold, 1.35),
      titleSmall: s(16, FarmTapWeights.semiBold, 1.35),
      bodyLarge: s(18, FarmTapWeights.regular, 1.45),
      bodyMedium: s(16, FarmTapWeights.regular, 1.45),
      bodySmall: s(14, FarmTapWeights.regular, 1.4).copyWith(color: cs.onSurfaceVariant),
      labelLarge: s(17, FarmTapWeights.semiBold, 1.2),
      labelMedium: s(15, FarmTapWeights.medium, 1.2),
      labelSmall: s(13, FarmTapWeights.medium, 1.2).copyWith(color: cs.onSurfaceVariant),
    );
  }
}

/// FarmTap-specific text styles that Material's TextTheme doesn't cover.
@immutable
class FarmTapTextStyles extends ThemeExtension<FarmTapTextStyles> {
  const new({
    required this.keypadDigit,
    required this.keypadDisplay,
    required this.readBackValue,
    required this.readBackLabel,
    required this.metricValue,
    required this.metricLabel,
    required this.sectionLabel,
    required this.tagNumber,
    required this.button,
    required this.buttonLarge,
    required this.hero,
    required this.micro,
  });

  factory from(FarmTapDesign d, ColorScheme cs) {
    TextStyle s(double size, FontWeight w, {double h = 1.2, Color? c, double ls = 0}) => TextStyle(
      fontFamily: d.fontFamily,
      fontSize: size * d.textScale,
      fontWeight: w,
      height: h,
      letterSpacing: ls,
      color: c ?? cs.onSurface,
    );
    return FarmTapTextStyles(
      keypadDigit: s(32, FarmTapWeights.semiBold),
      keypadDisplay: s(48, FarmTapWeights.bold, h: 1.1),
      readBackValue: s(36, FarmTapWeights.bold, h: 1.15),
      readBackLabel: s(18, FarmTapWeights.medium, c: cs.onSurfaceVariant),
      metricValue: s(32, FarmTapWeights.bold, h: 1.1),
      metricLabel: s(14, FarmTapWeights.medium, c: cs.onSurfaceVariant),
      sectionLabel: s(13, FarmTapWeights.semiBold, c: cs.onSurfaceVariant, ls: 0.6),
      tagNumber: s(20, FarmTapWeights.bold, ls: 0.5),
      button: s(17, FarmTapWeights.semiBold),
      buttonLarge: s(20, FarmTapWeights.semiBold),
      hero: s(44, FarmTapWeights.bold, h: 1.1),
      micro: s(12, FarmTapWeights.medium, c: cs.onSurfaceVariant),
    );
  }

  /// Initials inside a person avatar: [base] (titleSmall) at 36% of [avatarSize].
  /// Kept here because it is the one proportional text size in the app.
  static TextStyle initials(TextStyle base, double avatarSize, double fraction) =>
      base.copyWith(fontSize: avatarSize * fraction, height: 1);

  /// Digits on the number keypad.
  final TextStyle keypadDigit;

  /// The number being typed above the keypad (e.g. "24.5").
  final TextStyle keypadDisplay;

  /// Big value on the read-back confirmation ("24 litres").
  final TextStyle readBackValue;

  /// Label on the read-back confirmation ("Muhwezi").
  final TextStyle readBackLabel;

  /// Dashboard numbers (today's milk, head count).
  final TextStyle metricValue;

  /// Dashboard number labels.
  final TextStyle metricLabel;

  /// Small section headings above lists.
  final TextStyle sectionLabel;

  /// Animal ear-tag numbers and farmer card numbers.
  final TextStyle tagNumber;

  /// Standard button text.
  final TextStyle button;

  /// Large primary action text.
  final TextStyle buttonLarge;

  /// Big number in a tinted hero card ("1,284 L").
  final TextStyle hero;

  /// Chart axis labels.
  final TextStyle micro;

  @override
  FarmTapTextStyles copyWith({
    TextStyle? keypadDigit,
    TextStyle? keypadDisplay,
    TextStyle? readBackValue,
    TextStyle? readBackLabel,
    TextStyle? metricValue,
    TextStyle? metricLabel,
    TextStyle? sectionLabel,
    TextStyle? tagNumber,
    TextStyle? button,
    TextStyle? buttonLarge,
    TextStyle? hero,
    TextStyle? micro,
  }) => FarmTapTextStyles(
    keypadDigit: keypadDigit ?? this.keypadDigit,
    keypadDisplay: keypadDisplay ?? this.keypadDisplay,
    readBackValue: readBackValue ?? this.readBackValue,
    readBackLabel: readBackLabel ?? this.readBackLabel,
    metricValue: metricValue ?? this.metricValue,
    metricLabel: metricLabel ?? this.metricLabel,
    sectionLabel: sectionLabel ?? this.sectionLabel,
    tagNumber: tagNumber ?? this.tagNumber,
    button: button ?? this.button,
    buttonLarge: buttonLarge ?? this.buttonLarge,
    hero: hero ?? this.hero,
    micro: micro ?? this.micro,
  );

  @override
  ThemeExtension<FarmTapTextStyles> lerp(covariant ThemeExtension<FarmTapTextStyles>? other, double t) {
    if (other is! FarmTapTextStyles) return this;
    return FarmTapTextStyles(
      keypadDigit: TextStyle.lerp(keypadDigit, other.keypadDigit, t)!,
      keypadDisplay: TextStyle.lerp(keypadDisplay, other.keypadDisplay, t)!,
      readBackValue: TextStyle.lerp(readBackValue, other.readBackValue, t)!,
      readBackLabel: TextStyle.lerp(readBackLabel, other.readBackLabel, t)!,
      metricValue: TextStyle.lerp(metricValue, other.metricValue, t)!,
      metricLabel: TextStyle.lerp(metricLabel, other.metricLabel, t)!,
      sectionLabel: TextStyle.lerp(sectionLabel, other.sectionLabel, t)!,
      tagNumber: TextStyle.lerp(tagNumber, other.tagNumber, t)!,
      button: TextStyle.lerp(button, other.button, t)!,
      buttonLarge: TextStyle.lerp(buttonLarge, other.buttonLarge, t)!,
      hero: TextStyle.lerp(hero, other.hero, t)!,
      micro: TextStyle.lerp(micro, other.micro, t)!,
    );
  }
}
