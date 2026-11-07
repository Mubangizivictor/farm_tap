import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/buttons.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class FilterOption<T> {
  const new({required this.value, required this.label, this.count, this.icon});

  final T value;
  final String label;
  final int? count;
  final IconData? icon;
}

/// One chip: 40 tall, radius 12, padding 16, labelMedium. Selected =
/// secondaryContainer + filled check 20; unselected = c0 + outlineVariant.
class FarmTapChip extends StatelessWidget {
  const new({required this.label, required this.selected, required this.onTap, super.key, this.icon});

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = selected ? c.onSecondaryContainer : c.onSurface;
    final leading = selected ? Symbols.check_rounded : icon;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      // 40 dp chip inside a 48 dp tap area (rows of chips sit 48 apart).
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: context.sizes.touchTarget),
          child: Center(
            widthFactor: 1,
            child: Material(
              color: selected ? c.secondaryContainer : c.surfaceContainerLowest,
              shape: RoundedRectangleBorder(
                borderRadius: context.radii.chip,
                side: selected ? BorderSide.none : BorderSide(color: c.outlineVariant, width: context.sizes.borderThin),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: Container(
                  height: context.sizes.chipHeight,
                  padding: EdgeInsets.symmetric(horizontal: context.space.lg),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (leading != null) ...[
                        Icon(leading, fill: 1, size: context.sizes.iconSm, color: fg),
                        context.space.gapXs,
                      ],
                      Text(label, style: context.text.labelMedium?.copyWith(color: fg)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Row of single-choice chips with optional counts: "All 48", "Milking 41".
/// Scrolls sideways by default; set [wrap] to wrap onto rows 48 apart.
class FilterChips<T> extends StatelessWidget {
  const new({required this.options, required this.selected, required this.onSelected, super.key, this.wrap = false});

  final List<FilterOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    final chips = [
      for (final o in options)
        FarmTapChip(
          label: o.count == null ? o.label : '${o.label} ${o.count}',
          icon: o.icon,
          selected: o.value == selected,
          onTap: () => onSelected(o.value),
        ),
    ];
    final gap = context.space.chipRun;
    if (wrap) {
      return Wrap(spacing: gap, children: chips);
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < chips.length; i++) ...[if (i > 0) SizedBox(width: gap), chips[i]],
        ],
      ),
    );
  }
}

class TabOption<T> {
  const new({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Segmented control: track 48 tall, radius 24, c2; selected thumb inset 4,
/// radius 20, c0 with outlineVariant border; labelMedium centred.
class SegmentedTabs<T> extends StatelessWidget {
  const new({required this.options, required this.selected, required this.onChanged, super.key});

  final List<TabOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: context.sizes.segmentedHeight,
      decoration: BoxDecoration(
        color: c.surfaceContainerHigh,
        borderRadius: context.radii.badge,
        border: Border.all(color: c.outlineVariant, width: context.sizes.borderThin),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final o in options)
            Expanded(
              child: Semantics(
                selected: o.value == selected,
                button: true,
                label: o.label,
                excludeSemantics: true,
                // The whole 48 dp track height is the tap target; the thumb
                // is drawn inset by 4.
                child: InkWell(
                  onTap: () => onChanged(o.value),
                  borderRadius: context.radii.badge,
                  child: Padding(
                    padding: EdgeInsets.all(context.space.xs),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        // Selected: filled brand colour, so it stands out clearly from the rest.
                        color: o.value == selected ? c.primary : Colors.transparent,
                        borderRadius: context.radii.segmentedThumb,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (o.icon != null) ...[
                            Icon(
                              o.icon,
                              fill: o.value == selected ? 1 : 0,
                              size: context.sizes.iconSm,
                              color: o.value == selected ? c.onPrimary : c.onSurfaceVariant,
                            ),
                            context.space.gapXs,
                          ],
                          Flexible(
                            child: Text(
                              o.label,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.labelMedium?.copyWith(
                                color: o.value == selected ? c.onPrimary : c.onSurfaceVariant,
                                fontWeight: o.value == selected ? FarmTapWeights.bold : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Onboarding header: back arrow 28, "Step x of 8" centred (labelMedium),
/// optional "Skip" (labelLarge, primary); 6 dp progress bar below.
class StepHeader extends StatelessWidget {
  const new({required this.step, required this.total, super.key, this.onBack, this.onSkip});

  final int step;
  final int total;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final side = context.sizes.touchTarget + context.space.lg;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: context.sizes.appBarHeight,
          child: Row(
            children: [
              SizedBox(
                width: side,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: onBack == null
                      ? null
                      : IconButton(onPressed: onBack, tooltip: l10n.back, icon: const Icon(Symbols.arrow_back_rounded)),
                ),
              ),
              Expanded(
                child: Text(
                  l10n.stepOfTotal(step, total),
                  textAlign: TextAlign.center,
                  style: context.text.labelMedium?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ),
              SizedBox(
                width: side,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: onSkip == null ? null : TextAction(label: l10n.skip, onPressed: onSkip),
                ),
              ),
            ],
          ),
        ),
        FarmTapProgress(value: step / total, thin: true),
      ],
    );
  }
}

/// Progress bar: 10 tall (6 when [thin]), rounded, track c3, optional label
/// row (labelMedium) above.
class FarmTapProgress extends StatelessWidget {
  const new({required this.value, super.key, this.thin = false, this.label, this.trailingLabel, this.color});

  final double value;
  final bool thin;
  final String? label;
  final String? trailingLabel;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bar = ClipRRect(
      borderRadius: context.radii.badge,
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: thin ? context.sizes.progressBarThin : context.sizes.progressBar,
        backgroundColor: context.colors.surfaceContainerHigh,
        color: color ?? context.colors.primary,
      ),
    );
    if (label == null && trailingLabel == null) return bar;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: Text(label ?? '', style: context.text.labelMedium)),
            if (trailingLabel != null)
              Text(trailingLabel!, style: context.text.labelMedium?.copyWith(color: context.colors.onSurfaceVariant)),
          ],
        ),
        context.space.gapSm,
        bar,
      ],
    );
  }
}

/// Page dots: 10 dp dots, the current one a 28 wide pill, gap 8.
class PageDots extends StatelessWidget {
  const new({required this.count, required this.current, super.key});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) context.space.gapSm,
          AnimatedContainer(
            duration: context.motion.fast,
            width: i == current ? context.sizes.dotActiveWidth : context.sizes.dot,
            height: context.sizes.dot,
            decoration: BoxDecoration(
              color: i == current ? context.colors.primary : context.colors.outlineVariant,
              borderRadius: context.radii.badge,
            ),
          ),
        ],
      ],
    );
  }
}

/// Search field: 52 tall (48 in the desktop top bar), pill, fill c2, search
/// icon 24 at x16, bodyLarge hint.
class SearchField extends StatelessWidget {
  const new({super.key, this.hint, this.onChanged, this.compactHeight = false, this.trailing});

  final String? hint;
  final ValueChanged<String>? onChanged;

  /// 48 tall (desktop top-bar pill).
  final bool compactHeight;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final height = compactHeight ? context.sizes.searchPillHeight : context.sizes.searchHeight;
    final border = OutlineInputBorder(borderRadius: context.radii.badge, borderSide: BorderSide.none);
    final hintStyle = (compactHeight ? context.text.bodyMedium : context.text.bodyLarge)?.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    return SizedBox(
      height: height,
      child: TextField(
        onChanged: onChanged,
        style: compactHeight ? context.text.bodyMedium : context.text.bodyLarge,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: hint ?? l10n.searchHint,
          hintStyle: hintStyle,
          filled: true,
          fillColor: context.colors.surfaceContainer,
          constraints: BoxConstraints.tightFor(height: height),
          contentPadding: EdgeInsets.zero,
          isDense: true,
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: BorderSide(color: context.colors.primary, width: context.sizes.focusRing),
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: context.space.lg, right: context.space.md),
            child: Icon(Symbols.search_rounded, size: context.sizes.iconMd, color: context.colors.onSurfaceVariant),
          ),
          prefixIconConstraints: const BoxConstraints(),
          suffixIcon: trailing,
        ),
      ),
    );
  }
}

/// Checkbox + label; the whole row is the 48 dp target and the 24 dp box
/// lines up with the fields above it.
class CheckRow extends StatelessWidget {
  const new({required this.label, required this.value, required this.onChanged, super.key, this.subtitle});

  final String label;

  /// Second line (bodySmall), e.g. "Before 10:00".
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value,
      label: subtitle == null ? label : '$label, $subtitle',
      excludeSemantics: true,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: context.sizes.touchTarget),
          child: Row(
            children: [
              SizedBox.square(
                dimension: context.sizes.checkbox,
                child: Transform.scale(
                  scale: context.sizes.checkbox / context.sizes.materialCheckbox,
                  child: Checkbox(
                    value: value,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (v) => onChanged(v ?? false),
                  ),
                ),
              ),
              context.space.gapMd,
              Expanded(
                child: subtitle == null
                    ? Text(label, style: context.text.bodyMedium)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(label, style: context.text.titleSmall),
                          Text(subtitle!, style: context.text.bodySmall),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
