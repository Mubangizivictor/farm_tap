import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/tone.dart';
import 'package:flutter/material.dart';

/// Small pill: "Milking", "Treated", "Pregnant", "+6%". 26 tall, labelSmall,
/// optional 16 dp filled icon. Colour always comes with a word.
/// Animal status -> tone: Milking success, Treated danger, Pregnant info,
/// Heifer neutral, Dry warning.
class StatusBadge extends StatelessWidget {
  const new({required this.label, super.key, this.tone = FarmTapTone.neutral, this.icon});

  final String label;
  final FarmTapTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = tone.of(context);
    return Container(
      height: context.sizes.badgeHeight,
      padding: EdgeInsets.symmetric(horizontal: context.space.keyGap),
      decoration: BoxDecoration(color: colors.container, borderRadius: context.radii.badge),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, fill: 1, size: context.sizes.iconXs, color: colors.onContainer),
            context.space.gapXs,
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall?.copyWith(color: colors.onContainer),
            ),
          ),
        ],
      ),
    );
  }
}
