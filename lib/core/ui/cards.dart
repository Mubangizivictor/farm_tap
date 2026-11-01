import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/icon_bubble.dart';
import 'package:farm_tap/core/ui/status_badge.dart';
import 'package:farm_tap/core/ui/tone.dart';
import 'package:flutter/material.dart';

/// Number-first card: "Milk today  312 L  +6%". Tapping opens its section.
class MetricCard extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
    this.unit,
    this.caption,
    this.trend,
    this.tone = FarmTapTone.success,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;

  /// "L" in "312 L", "/6" in "5 /6".
  final String? unit;
  final String? caption;

  /// "+6%": shown as a green badge with a trend arrow.
  final String? trend;
  final FarmTapTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                  if (trend != null)
                    StatusBadge(label: trend!, tone: FarmTapTone.success, icon: Icons.trending_up_rounded),
                ],
              ),
              context.space.gapMd,
              Text(label, style: context.textStyles.metricLabel),
              context.space.gapXs,
              Text.rich(
                TextSpan(
                  text: value,
                  style: context.textStyles.metricValue,
                  children: [
                    if (unit != null)
                      TextSpan(
                        text: ' $unit',
                        style: context.text.titleMedium?.copyWith(color: context.colors.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              if (caption != null) ...[
                context.space.gapXs,
                Text(caption!, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One row of a list: leading (avatar / bubble), title, subtitle, trailing
/// (badge / value). Used by RecordCollection on phones.
class RecordTile extends StatelessWidget {
  const new({
    required this.title,
    super.key,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showChevron = true,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: context.sizes.actionTile),
        child: Padding(
          padding: context.space.listItem,
          child: Row(
            children: [
              if (leading != null) ...[leading!, context.space.gapMd],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleMedium?.copyWith(fontWeight: FarmTapWeights.semiBold),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[context.space.gapSm, trailing!],
              if (onTap != null && showChevron) ...[
                context.space.gapXs,
                Icon(Icons.chevron_right_rounded, color: context.colors.onSurfaceVariant),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
