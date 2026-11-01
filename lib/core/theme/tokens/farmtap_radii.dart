// Corner radius tokens, scaled by FarmTapDesign.radiusScale.
// Use: context.radii.card (BorderRadius) or context.radii.md (double).
import 'dart:ui' show lerpDouble;

import 'package:farm_tap/core/theme/farmtap_design.dart';
import 'package:flutter/material.dart';

@immutable
class FarmTapRadii extends ThemeExtension<FarmTapRadii> {
  const new({required this.scale});

  factory from(FarmTapDesign design) => FarmTapRadii(scale: design.radiusScale);

  final double scale;

  // ---- Scale (doubles) ----
  double get xs => 6 * scale;
  double get sm => 10 * scale;
  double get smd => 12 * scale;
  double get md => 14 * scale;
  double get lg => 16 * scale;
  double get lg2 => 18 * scale;
  double get xl => 24 * scale;
  double get xxl => 28 * scale;
  double get pill => 999;

  // ---- Component radii (BorderRadius) ----
  BorderRadius get button => BorderRadius.circular(md);
  BorderRadius get input => BorderRadius.circular(md);
  BorderRadius get card => BorderRadius.circular(lg);
  BorderRadius get chip => BorderRadius.circular(smd);
  BorderRadius get dialog => BorderRadius.circular(xxl);
  BorderRadius get banner => BorderRadius.circular(md);
  BorderRadius get tile => BorderRadius.circular(lg2);
  BorderRadius get keypadDisplay => BorderRadius.circular(lg2);
  BorderRadius get tooltip => BorderRadius.circular(8 * scale);
  BorderRadius get tableHeader => BorderRadius.circular(smd);
  BorderRadius get segmentedThumb => BorderRadius.circular(20 * scale);
  BorderRadius get snackBar => BorderRadius.circular(md);
  BorderRadius get fab => BorderRadius.circular(xl - xs);
  BorderRadius get keypadKey => BorderRadius.circular(lg);
  BorderRadius get image => BorderRadius.circular(sm);
  BorderRadius get badge => BorderRadius.circular(pill);

  /// Top corners only, for bottom sheets.
  BorderRadius get sheet => BorderRadius.vertical(top: Radius.circular(xxl));

  // ---- Shapes ----
  RoundedRectangleBorder get buttonShape => RoundedRectangleBorder(borderRadius: button);
  RoundedRectangleBorder get cardShape => RoundedRectangleBorder(borderRadius: card);
  RoundedRectangleBorder get dialogShape => RoundedRectangleBorder(borderRadius: dialog);
  RoundedRectangleBorder get sheetShape => RoundedRectangleBorder(borderRadius: sheet);

  @override
  FarmTapRadii copyWith({double? scale}) => FarmTapRadii(scale: scale ?? this.scale);

  @override
  FarmTapRadii lerp(FarmTapRadii? other, double t) {
    if (other == null) return this;
    return FarmTapRadii(scale: lerpDouble(scale, other.scale, t) ?? scale);
  }
}
