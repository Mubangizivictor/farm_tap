import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/tone.dart';
import 'package:flutter/material.dart';

/// Small pill: "Milking", "Treated", "Pregnant", "+6%". Colour always comes
/// with a word (and optionally an icon), never colour alone.
class StatusBadge extends StatelessWidget {
  const new({required this.label, super.key, this.tone = FarmTapTone.neutral, this.icon});

  final String label;
  final FarmTapTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = tone.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.container, borderRadius: context.radii.badge),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.space.md, vertical: context.space.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: context.sizes.iconXs, color: colors.onContainer),
              context.space.gapXs,
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelMedium?.copyWith(
                  color: colors.onContainer,
                  fontWeight: FarmTapWeights.semiBold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
