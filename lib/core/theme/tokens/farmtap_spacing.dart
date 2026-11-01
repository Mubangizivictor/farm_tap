// Spacing tokens. All spacing is a multiple of FarmTapDesign.baseUnit
// scaled by FarmTapDesign.sizeScale. Use: context.space.lg, context.space.gapMd
import 'dart:ui' show lerpDouble;

import 'package:farm_tap/core/theme/farmtap_design.dart';
import 'package:farm_tap/core/theme/tokens/farmtap_breakpoints.dart';
import 'package:flutter/material.dart';

@immutable
class FarmTapSpacing extends ThemeExtension<FarmTapSpacing> {
  const new({required this.unit});

  factory from(FarmTapDesign design) => FarmTapSpacing(unit: design.baseUnit * design.sizeScale);

  /// One grid unit (4 by default).
  final double unit;

  // ---- Scale ----
  double get xxs => unit * 0.5; // 2
  double get xs => unit; // 4
  double get sm => unit * 2; // 8
  double get md => unit * 3; // 12
  double get lg => unit * 4; // 16
  double get xl => unit * 6; // 24
  double get xxl => unit * 8; // 32
  double get xxxl => unit * 12; // 48

  // ---- Named in-between steps from the mockups ----
  double get keyGap => unit * 2.5; // 10: keypad keys, dialog buttons
  double get banner => unit * 3.5; // 14: banner padding
  double get pinGap => unit * 4.5; // 18: between PIN dots
  double get fabIcon => unit * 5; // 20: FAB icon inset
  double get wideTop => unit * 7; // 28: content top on desktop
  double get authTop => unit * 14; // 56: auth column top on wide screens
  double get chipRun => unit * 2; // 8: gap between chips (rows 48 apart)

  // ---- Ready-made gaps (work in Row and Column) ----
  SizedBox get gapXxs => SizedBox.square(dimension: xxs);
  SizedBox get gapXs => SizedBox.square(dimension: xs);
  SizedBox get gapSm => SizedBox.square(dimension: sm);
  SizedBox get gapMd => SizedBox.square(dimension: md);
  SizedBox get gapLg => SizedBox.square(dimension: lg);
  SizedBox get gapXl => SizedBox.square(dimension: xl);
  SizedBox get gapXxl => SizedBox.square(dimension: xxl);
  SizedBox get gapXxxl => SizedBox.square(dimension: xxxl);

  // ---- Ready-made paddings ----
  /// Padding around a whole screen's content.
  EdgeInsets get screen => EdgeInsets.all(lg);

  /// Padding inside cards and panels.
  EdgeInsets get card => EdgeInsets.all(lg);

  /// Padding inside list items.
  EdgeInsets get listItem => EdgeInsets.symmetric(horizontal: lg, vertical: sm);

  /// Padding inside text fields.
  EdgeInsets get input => EdgeInsets.symmetric(horizontal: lg + xxs, vertical: lg + xxs);

  /// Padding inside buttons.
  EdgeInsets get button => EdgeInsets.symmetric(horizontal: xl, vertical: md);

  /// Padding inside dialogs and bottom sheets.
  EdgeInsets get sheet => EdgeInsets.all(xl);

  /// Padding inside a list card.
  EdgeInsets get listCard => EdgeInsets.all(md);

  /// Content padding by form factor: compact 16 (top 8), medium 24, wide 32 (top 28).
  EdgeInsets content(FormFactor form) => switch (form) {
    FormFactor.compact => EdgeInsets.fromLTRB(lg, sm, lg, lg),
    FormFactor.medium => EdgeInsets.all(xl),
    FormFactor.expanded => EdgeInsets.fromLTRB(xxl, wideTop, xxl, xxl),
  };

  /// Side padding by form factor (16 / 24 / 32).
  double side(FormFactor form) => switch (form) {
    FormFactor.compact => lg,
    FormFactor.medium => xl,
    FormFactor.expanded => xxl,
  };

  /// Gap between items in a vertical list of cards.
  double get listGap => md;

  /// Gap between sections on a screen.
  double get sectionGap => xl;

  @override
  FarmTapSpacing copyWith({double? unit}) => FarmTapSpacing(unit: unit ?? this.unit);

  @override
  FarmTapSpacing lerp(FarmTapSpacing? other, double t) {
    if (other == null) return this;
    return FarmTapSpacing(unit: lerpDouble(unit, other.unit, t) ?? unit);
  }
}
