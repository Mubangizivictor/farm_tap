// ============================================================================
//  FARMTAP DESIGN CONTROL PANEL
//  This is the ONE place to change the look of the whole app.
//  Change a value here -> every screen updates, in light AND dark mode.
//
//  - Colours:      tokens/farmtap_palette.dart (raw colours)
//                  colors/farmtap_color_schemes.dart (which colour is used where)
//  - Everything else (sizes, spacing, corners, text size, font): below.
// ============================================================================
import 'package:flutter/foundation.dart';

@immutable
class FarmTapDesign {
  const new({
    this.fontFamily = 'Outfit',
    this.baseUnit = 4,
    this.sizeScale = 1.0,
    this.textScale = 1.0,
    this.radiusScale = 1.0,
  });

  /// The design used by the app. Edit these values to restyle everything.
  static const FarmTapDesign current = FarmTapDesign();

  /// Font family registered in pubspec.yaml.
  final String fontFamily;

  /// Base spacing unit in logical pixels. All spacing is a multiple of this.
  final double baseUnit;

  /// Multiplies every size token (touch targets, buttons, icons, spacing).
  final double sizeScale;

  /// Multiplies every font size.
  final double textScale;

  /// Multiplies every corner radius.
  final double radiusScale;
}
