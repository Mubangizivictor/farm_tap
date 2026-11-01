// One vocabulary for success / warning / danger / info / gold / neutral so
// badges, banners, bubbles and tiles all colour the same way.
// Colour is always paired with an icon or word by the widgets that use this.
import 'package:farm_tap/core/theme/theme.dart';
import 'package:flutter/material.dart';

enum FarmTapTone { primary, success, warning, danger, info, gold, neutral }

@immutable
class ToneColors {
  const new({required this.container, required this.onContainer, required this.accent, required this.onAccent});

  /// Soft background (badge, bubble, banner).
  final Color container;
  final Color onContainer;

  /// Strong colour (icons on white, filled chips).
  final Color accent;
  final Color onAccent;
}

extension FarmTapToneColors on FarmTapTone {
  ToneColors of(BuildContext context) {
    final s = context.status;
    final c = context.colors;
    return switch (this) {
      FarmTapTone.primary => ToneColors(
        container: c.primaryContainer,
        onContainer: c.onPrimaryContainer,
        accent: c.primary,
        onAccent: c.onPrimary,
      ),
      FarmTapTone.success => ToneColors(
        container: s.successContainer,
        onContainer: s.onSuccessContainer,
        accent: s.success,
        onAccent: s.onSuccess,
      ),
      FarmTapTone.warning => ToneColors(
        container: s.warningContainer,
        onContainer: s.onWarningContainer,
        accent: s.warning,
        onAccent: s.onWarning,
      ),
      FarmTapTone.danger => ToneColors(
        container: s.dangerContainer,
        onContainer: s.onDangerContainer,
        accent: s.danger,
        onAccent: s.onDanger,
      ),
      FarmTapTone.info => ToneColors(
        container: s.infoContainer,
        onContainer: s.onInfoContainer,
        accent: s.info,
        onAccent: s.onInfo,
      ),
      FarmTapTone.gold => ToneColors(
        container: c.secondaryContainer,
        onContainer: c.onSecondaryContainer,
        accent: s.brandGold,
        onAccent: c.onSecondary,
      ),
      FarmTapTone.neutral => ToneColors(
        container: c.surfaceContainerHigh,
        onContainer: c.onSurfaceVariant,
        accent: c.onSurfaceVariant,
        onAccent: c.surface,
      ),
    };
  }
}
