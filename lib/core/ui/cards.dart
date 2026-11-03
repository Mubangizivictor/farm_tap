import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/animation_view.dart';
import 'package:farm_tap/core/ui/buttons.dart';
import 'package:farm_tap/core/ui/icon_bubble.dart';
import 'package:farm_tap/core/ui/status_badge.dart';
import 'package:farm_tap/core/ui/tone.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Card: radius 16, padding 16, card colour, 1 dp outlineVariant border, no
/// shadow. [children] are stacked with a 12 gap.
class FarmTapCard extends StatelessWidget {
  const new({super.key, this.child, this.children, this.padding, this.onTap})
    : assert(child != null || children != null, 'child or children');

  final Widget? child;
  final List<Widget>? children;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final items = children;
    final content =
        child ??
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < items!.length; i++) ...[if (i > 0) context.space.gapMd, items[i]],
          ],
        );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding ?? context.space.card, child: content),
      ),
    );
  }
}

/// Header row inside a card: title (titleMedium) + optional action
/// (labelMedium, primary).
class CardHeader extends StatelessWidget {
  const new({required this.title, super.key, this.actionLabel, this.onAction, this.trailing});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Shown instead of the action (e.g. a trend badge).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: context.text.titleMedium)),
        ?trailing,
        if (actionLabel != null) TextAction(label: actionLabel!, onPressed: onAction, small: true),
      ],
    );
  }
}

/// Uppercase section label ("QUICK ACTIONS"), 24 tall, optional action right.
class SectionLabel extends StatelessWidget {
  const new(this.label, {super.key, this.actionLabel, this.onAction});

  final String label;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.space.xxl,
      child: Row(
        children: [
          Expanded(child: Text(label, style: context.textStyles.sectionLabel)),
          if (actionLabel != null)
            InkWell(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: context.text.labelMedium?.copyWith(
                  color: context.colors.primary,
                  fontWeight: FarmTapWeights.semiBold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tinted hero card: container colour, no border. Left: label (metricLabel),
/// hero number, sub (bodySmall). Right: an animation 110-130 wide.
class HeroCard extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    super.key,
    this.unit,
    this.sub,
    this.tone = FarmTapTone.primary,
    this.animation,
    this.animationLeading = false,
    this.trailing,
    this.onTap,
  });

  final String label;
  final String value;
  final String? unit;
  final String? sub;
  final FarmTapTone tone;
  final FarmTapAnimation? animation;

  /// Illustration on the left with a smaller headline value and a body-size
  /// sub line (K04 "4 of 5 in / Tap your card to clock in or out").
  final bool animationLeading;

  /// Shown under the sub line (e.g. a progress bar or button).
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = tone.of(context);
    final on = colors.onContainer;
    return Material(
      color: colors.container,
      borderRadius: context.radii.card,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: context.space.card,
          child: Row(
            children: [
              if (animation != null && animationLeading) ...[
                FarmTapAnimationView(animation: animation!, size: context.sizes.heroAnimationWidth),
                context.space.gapLg,
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (label.isNotEmpty) ...[
                      Text(label, style: context.textStyles.metricLabel.copyWith(color: on)),
                      context.space.gapXs,
                    ],
                    // One line: long money values scale down instead of wrapping.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text.rich(
                        TextSpan(
                          text: value,
                          style: (animationLeading ? context.text.headlineMedium! : context.textStyles.hero).copyWith(
                            color: on,
                          ),
                          children: [
                            if (unit != null)
                              TextSpan(
                                text: ' $unit',
                                style: context.text.titleLarge?.copyWith(color: on),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (sub != null) ...[
                      context.space.gapXs,
                      Text(
                        sub!,
                        style: (animationLeading ? context.text.bodyLarge : context.text.bodySmall)?.copyWith(
                          color: on,
                        ),
                      ),
                    ],
                    if (trailing != null) ...[context.space.gapMd, trailing!],
                  ],
                ),
              ),
              if (animation != null && !animationLeading)
                FarmTapAnimationView(animation: animation!, size: context.sizes.heroAnimationWidth),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card holding list rows separated by 1 dp dividers inset 56, with an
/// optional header (title + "See all"). Padding 12.
class ListCard extends StatelessWidget {
  const new({required this.children, super.key, this.title, this.actionLabel, this.onAction, this.trailing});

  final List<Widget> children;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final inset = context.sizes.listTile;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: context.space.listCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null)
              Padding(
                padding: EdgeInsets.only(bottom: context.space.xs),
                child: CardHeader(title: title!, actionLabel: actionLabel, onAction: onAction, trailing: trailing),
              ),
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) Divider(indent: inset, height: context.sizes.divider),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// Number-first card: IconBubble 40, optional trend badge, label, value with
/// unit, optional sub line. Tapping opens its section.
class MetricCard extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
    this.unit,
    this.caption,
    this.trend,
    this.trendUp = true,
    this.tone = FarmTapTone.primary,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;

  /// "L" in "312 L", "/6" in "5 /6".
  final String? unit;
  final String? caption;

  /// "+6%": a success badge with a trending-up icon (danger + down when
  /// [trendUp] is false).
  final String? trend;
  final bool trendUp;
  final FarmTapTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FarmTapCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconBubble(icon: icon, tone: tone, size: context.sizes.bubbleSm),
              const Spacer(),
              if (trend != null)
                StatusBadge(
                  label: trend!,
                  tone: trendUp ? FarmTapTone.success : FarmTapTone.danger,
                  icon: trendUp ? Symbols.trending_up_rounded : Symbols.trending_down_rounded,
                ),
            ],
          ),
          context.space.gapMd,
          Text(label, style: context.textStyles.metricLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
          context.space.gapXxs,
          // One line: long money values ("UGX 1.52M") shrink to fit.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text.rich(
              TextSpan(
                text: value,
                style: context.textStyles.metricValue,
                children: [
                  if (unit != null)
                    TextSpan(
                      text: ' $unit',
                      style: context.text.titleSmall?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                ],
              ),
              maxLines: 1,
            ),
          ),
          if (caption != null) ...[
            context.space.gapXxs,
            Text(caption!, style: context.text.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}

/// List row: min 56; leading (avatar 48 / bubble 44) in a 56 slot; title
/// titleSmall and subtitle bodySmall (2 lines max); optional badge 6 below;
/// trailing value titleSmall + sub bodySmall right-aligned; chevron 24.
class RecordTile extends StatelessWidget {
  const new({
    required this.title,
    super.key,
    this.subtitle,
    this.leading,
    this.badge,
    this.trailing,
    this.trailingValue,
    this.trailingSub,
    this.onTap,
    this.showChevron = true,
    this.dense = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;

  /// Shown 6 below the subtitle (StatusBadge).
  final Widget? badge;

  /// Custom trailing widget (badge, switch).
  final Widget? trailing;
  final String? trailingValue;
  final String? trailingSub;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final slot = context.sizes.listTile;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: dense ? context.sizes.listTileDense : context.sizes.listTile),
        child: Padding(
          // Compact rows (decision 0013): 8 above and below, dense 6.
          padding: EdgeInsets.symmetric(vertical: dense ? context.space.sm : context.space.md),
          child: Row(
            children: [
              if (leading != null)
                SizedBox(
                  width: slot,
                  child: Align(alignment: Alignment.centerLeft, child: leading),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge sits on the title line (decision 0013), wrapping under it when narrow.
                    Wrap(
                      spacing: context.space.md,
                      runSpacing: context.space.xxs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.titleSmall),
                        ?badge,
                      ],
                    ),
                    if (subtitle != null)
                      Text(subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
                  ],
                ),
              ),
              if (trailingValue != null || trailingSub != null) ...[
                context.space.gapSm,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (trailingValue != null) Text(trailingValue!, style: context.text.titleSmall),
                    if (trailingSub != null) Text(trailingSub!, style: context.text.bodySmall),
                  ],
                ),
              ],
              if (trailing != null) ...[context.space.gapSm, trailing!],
              if (onTap != null && showChevron) ...[
                context.space.gapXs,
                Icon(Symbols.chevron_right_rounded, size: context.sizes.iconMd, color: context.colors.onSurfaceVariant),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Quick-action tile (decision 0013): compact row, min 56 (60 with subtitle), bubble 32, label titleSmall, optional subtitle bodySmall.
/// IconBubble 52, label titleSmall, optional subtitle bodySmall.
/// When [locked] (read-only after the trial) it shows a lock and ignores taps.
class ActionTile extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    super.key,
    this.subtitle,
    this.tone = FarmTapTone.primary,
    this.onTap,
    this.locked = false,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final FarmTapTone tone;
  final VoidCallback? onTap;
  final bool locked;

  /// Picked from a set (L02 category): primary border and a check.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !locked;
    final shape = RoundedRectangleBorder(
      borderRadius: context.radii.tile,
      side: selected
          ? BorderSide(color: context.colors.primary, width: context.sizes.borderThick)
          : BorderSide(color: context.colors.outlineVariant, width: context.sizes.borderThin),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      child: Material(
        color: context.status.card,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Container(
            constraints: BoxConstraints(
              minHeight: subtitle == null ? context.sizes.actionTile : context.sizes.actionTileWithSubtitle,
            ),
            padding: EdgeInsets.symmetric(horizontal: context.space.lg, vertical: context.space.md),
            // Decision 0013: compact row tile (bubble, label, subtitle).
            child: Row(
              children: [
                IconBubble(icon: icon, tone: locked ? FarmTapTone.neutral : tone, size: context.sizes.bubbleSm),
                context.space.gapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleSmall?.copyWith(
                          color: locked ? context.colors.onSurfaceVariant : null,
                        ),
                      ),
                      if (subtitle != null)
                        Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
                    ],
                  ),
                ),
                if (selected)
                  Icon(
                    Symbols.check_circle_rounded,
                    fill: 1,
                    size: context.sizes.iconMd,
                    color: context.colors.primary,
                  ),
                if (locked)
                  Icon(
                    Symbols.lock_rounded,
                    fill: 1,
                    size: context.sizes.iconSm,
                    color: context.colors.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Onboarding option: 84 tall, radius 18. Selected = primaryContainer + 2 dp
/// primary border + check_circle 28; unselected = card + radio ring.
/// [comingSoon] adds a gold badge.
class OptionRow extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.selected,
    super.key,
    this.subtitle,
    this.tone = FarmTapTone.primary,
    this.comingSoon = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final FarmTapTone tone;
  final bool comingSoon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    return Semantics(
      selected: selected,
      button: true,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected ? c.primaryContainer : context.status.card,
        shape: RoundedRectangleBorder(
          borderRadius: context.radii.tile,
          side: selected
              ? BorderSide(color: c.primary, width: context.sizes.borderThick)
              : BorderSide(color: c.outlineVariant, width: context.sizes.borderThin),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: BoxConstraints(minHeight: context.sizes.optionRow),
            padding: EdgeInsets.symmetric(horizontal: context.space.lg, vertical: context.space.md),
            child: Row(
              children: [
                IconBubble(icon: icon, tone: tone, size: context.sizes.bubbleLg),
                context.space.gapLg,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: context.text.titleMedium),
                      if (subtitle != null)
                        Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
                    ],
                  ),
                ),
                if (comingSoon) ...[
                  context.space.gapSm,
                  StatusBadge(label: l10n.comingSoon, tone: FarmTapTone.gold),
                  // Keep the check slot so badges line up with the radios.
                  SizedBox(width: context.space.sm + context.sizes.iconLg),
                ] else ...[
                  context.space.gapSm,
                  if (selected)
                    Icon(Symbols.check_circle_rounded, fill: 1, size: context.sizes.iconLg, color: c.primary)
                  else
                    Container(
                      width: context.sizes.iconMd,
                      height: context.sizes.iconMd,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: c.outline, width: context.sizes.borderThick),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TimelineEntry {
  const new({required this.icon, required this.title, this.subtitle, this.time, this.tone = FarmTapTone.primary});

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? time;
  final FarmTapTone tone;
}

/// Vertical timeline: bubbles 40 joined by a 2 dp outlineVariant connector,
/// title titleSmall, sub bodySmall (1 line), time bodySmall right; 76 per item.
class Timeline extends StatelessWidget {
  const new({required this.entries, super.key});

  final List<TimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    final bubble = context.sizes.bubbleSm;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < entries.length; i++)
          SizedBox(
            height: context.sizes.timelineItem,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: bubble,
                  child: Column(
                    children: [
                      IconBubble(icon: entries[i].icon, tone: entries[i].tone, size: bubble),
                      if (i < entries.length - 1)
                        Expanded(
                          child: Container(width: context.sizes.borderThick, color: context.colors.outlineVariant),
                        ),
                    ],
                  ),
                ),
                context.space.gapMd,
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: context.space.xxs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entries[i].title,
                          style: context.text.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (entries[i].subtitle != null)
                          Text(
                            entries[i].subtitle!,
                            style: context.text.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ),
                if (entries[i].time != null)
                  Padding(
                    padding: EdgeInsets.only(top: context.space.xxs, left: context.space.sm),
                    child: Text(entries[i].time!, style: context.text.bodySmall),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// "Litres delivered ........ 512.0 L" line in a summary card (statements,
/// totals, dispatch). [emphasis] makes both sides titleMedium (Total, To pay).
class SummaryRow extends StatelessWidget {
  const new({required this.label, required this.value, super.key, this.emphasis = false, this.valueColor});

  final String label;
  final String value;
  final bool emphasis;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final labelStyle = emphasis
        ? context.text.titleMedium
        : context.text.bodyLarge?.copyWith(color: context.colors.onSurfaceVariant);
    final valueStyle = (emphasis ? context.text.titleMedium : context.text.titleSmall)?.copyWith(color: valueColor);
    return MergeSemantics(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.space.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(child: Text(label, style: labelStyle)),
            context.space.gapMd,
            Text(value, textAlign: TextAlign.end, style: valueStyle),
          ],
        ),
      ),
    );
  }
}
