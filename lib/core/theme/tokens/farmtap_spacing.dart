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

  // ---- Scale (compact, decision 0013) ----
  double get xxs => unit * 0.5; // 2
  double get xs => unit; // 4
  double get sm => unit * 1.5; // 6
  double get md => unit * 2; // 8
  double get lg => unit * 3; // 12
  double get xl => unit * 4; // 16
  double get xxl => unit * 6; // 24
  double get xxxl => unit * 8; // 32

  // ---- Named in-between steps ----
  double get keyGap => unit * 2; // 8: keypad keys, dialog buttons
  double get banner => unit * 3; // 12: banner padding
  double get pinGap => unit * 3.5; // 14: between PIN dots
  double get fabIcon => unit * 4; // 16: FAB icon inset
  double get wideTop => unit * 5; // 20: content top on desktop
  double get authTop => unit * 10; // 40: auth column top on wide screens
  double get chipRun => unit * 1.5; // 6: gap between chips

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
  /// Padding around a whole screen's content (12).
  EdgeInsets get screen => EdgeInsets.all(lg);

  /// Padding inside cards and panels (12).
  EdgeInsets get card => EdgeInsets.all(lg);

  /// Padding inside list items.
  EdgeInsets get listItem => EdgeInsets.symmetric(horizontal: lg, vertical: xs);

  /// Padding inside text fields.
  EdgeInsets get input => EdgeInsets.symmetric(horizontal: lg, vertical: lg);

  /// Padding inside buttons.
  EdgeInsets get button => EdgeInsets.symmetric(horizontal: xl, vertical: md);

  /// Padding inside dialogs and bottom sheets (16).
  EdgeInsets get sheet => EdgeInsets.all(xl);

  /// Padding inside a list card.
  EdgeInsets get listCard => EdgeInsets.symmetric(horizontal: lg, vertical: xs);

  /// Content padding by form factor: compact 12 (top 8), medium 20, wide 24 (top 20).
  EdgeInsets content(FormFactor form) => switch (form) {
    FormFactor.compact => EdgeInsets.fromLTRB(lg, md, lg, lg),
    FormFactor.medium => EdgeInsets.all(unit * 5),
    FormFactor.expanded => EdgeInsets.fromLTRB(xxl, wideTop, xxl, xxl),
  };

  /// Side padding by form factor (12 / 20 / 24).
  double side(FormFactor form) => switch (form) {
    FormFactor.compact => lg,
    FormFactor.medium => unit * 5,
    FormFactor.expanded => xxl,
  };

  /// Gap between items in a vertical list of cards (8).
  double get listGap => md;

  /// Gap between sections on a screen (16).
  double get sectionGap => xl;

  @override
  FarmTapSpacing copyWith({double? unit}) => FarmTapSpacing(unit: unit ?? this.unit);

  @override
  FarmTapSpacing lerp(FarmTapSpacing? other, double t) {
    if (other == null) return this;
    return FarmTapSpacing(unit: lerpDouble(unit, other.unit, t) ?? unit);
  }
}
