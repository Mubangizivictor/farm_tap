import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/tone.dart';
import 'package:flutter/material.dart';

/// Icon in a soft coloured circle. Sizes: 40 metrics/timeline, 44 list tiles,
/// 52 action tiles/options, 64 dialogs. The icon is 52% of the bubble, filled.
class IconBubble extends StatelessWidget {
  const new({required this.icon, super.key, this.tone = FarmTapTone.primary, this.size});

  final IconData icon;
  final FarmTapTone tone;

  /// Defaults to `context.sizes.bubbleMd` (44).
  final double? size;

  @override
  Widget build(BuildContext context) {
    final colors = tone.of(context);
    final dimension = size ?? context.sizes.bubbleMd;
    return Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(color: colors.container, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: ExcludeSemantics(
        child: Icon(icon, fill: 1, color: colors.onContainer, size: dimension * context.sizes.bubbleIconFraction),
      ),
    );
  }
}
