import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/icon_bubble.dart';
import 'package:farm_tap/core/ui/tone.dart';
import 'package:flutter/material.dart';

/// Big icon + verb tile for quick actions ("Record milk", "Tap card").
/// When [locked] (read-only after the trial) it shows a lock and ignores taps.
class ActionTile extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    super.key,
    this.tone = FarmTapTone.success,
    this.onTap,
    this.locked = false,
  });

  final IconData icon;
  final String label;
  final FarmTapTone tone;
  final VoidCallback? onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !locked;
    return Opacity(
      opacity: locked ? 0.5 : 1,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: context.space.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconBubble(icon: icon, tone: tone),
                    const Spacer(),
                    if (locked)
                      Icon(Icons.lock_rounded, size: context.sizes.iconSm, color: context.colors.onSurfaceVariant),
                  ],
                ),
                context.space.gapMd,
                Text(label, style: context.text.titleMedium?.copyWith(fontWeight: FarmTapWeights.semiBold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
