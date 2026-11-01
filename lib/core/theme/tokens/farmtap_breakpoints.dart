// Width classes from UX_SPEC section 1. Always use the available WIDTH of the
// window (MediaQuery / LayoutBuilder), never the device type.
// Use: context.formFactor, context.isCompact, FarmTapBreakpoints.table
import 'package:flutter/widgets.dart';

enum FormFactor { compact, medium, expanded }

abstract final class FarmTapBreakpoints {
  /// Below this: bottom bar, one column, bottom sheets.
  static const double medium = 600;

  /// Records switch from tiles to a table at this width.
  static const double table = 700;

  /// At or above this: sidebar, top bar with search, max content width.
  /// 1280, not 1024, so landscape tablets (1194 dp) keep the rail
  /// (docs/decisions/0012-tablet-rail-breakpoint.md).
  static const double expanded = 1280;

  static FormFactor of(double width) {
    if (width >= expanded) return FormFactor.expanded;
    if (width >= medium) return FormFactor.medium;
    return FormFactor.compact;
  }
}

extension FormFactorContext on BuildContext {
  FormFactor get formFactor => FarmTapBreakpoints.of(MediaQuery.sizeOf(this).width);
  bool get isCompact => formFactor == FormFactor.compact;
  bool get isExpanded => formFactor == FormFactor.expanded;
}
