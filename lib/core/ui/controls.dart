import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:flutter/material.dart';

class FilterOption<T> {
  const new({required this.value, required this.label, this.count});

  final T value;
  final String label;
  final int? count;
}

/// Row of filter pills with counts: "All 48", "Milking 41", "Treated 2".
/// Selected pill shows a tick (not colour alone).
class FilterChips<T> extends StatelessWidget {
  const new({required this.options, required this.selected, required this.onSelected, super.key});

  final List<FilterOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final o in options)
            Padding(
              padding: EdgeInsets.only(right: context.space.sm),
              child: ChoiceChip(
                showCheckmark: true,
                selected: o.value == selected,
                onSelected: (_) => onSelected(o.value),
                label: Text(o.count == null ? o.label : '${o.label} ${o.count}'),
                selectedColor: context.colors.secondaryContainer,
                labelStyle: context.text.labelLarge?.copyWith(
                  color: o.value == selected ? context.colors.onSecondaryContainer : context.colors.onSurface,
                  fontWeight: FarmTapWeights.semiBold,
                ),
                materialTapTargetSize: MaterialTapTargetSize.padded,
              ),
            ),
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

/// Pill segmented control: Morning / Evening, Week / Month, Cash / Mobile Money.
class SegmentedTabs<T> extends StatelessWidget {
  const new({required this.options, required this.selected, required this.onChanged, super.key});

  final List<TabOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.space.xs),
      decoration: BoxDecoration(color: context.colors.surfaceContainer, borderRadius: context.radii.card),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: Semantics(
                selected: o.value == selected,
                button: true,
                label: o.label,
                excludeSemantics: true,
                child: Material(
                  color: o.value == selected ? context.colors.surfaceContainerLowest : Colors.transparent,
                  borderRadius: context.radii.button,
                  child: InkWell(
                    borderRadius: context.radii.button,
                    onTap: () => onChanged(o.value),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: context.sizes.touchTarget),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (o.icon != null) ...[
                            Icon(
                              o.icon,
                              size: context.sizes.iconSm,
                              color: o.value == selected ? context.colors.primary : context.colors.onSurfaceVariant,
                            ),
                            context.space.gapSm,
                          ],
                          Flexible(
                            child: Text(
                              o.label,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.titleSmall?.copyWith(
                                color: o.value == selected ? context.colors.primary : context.colors.onSurfaceVariant,
                                fontWeight: FarmTapWeights.bold,
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

/// Onboarding header: back arrow, title, "Step 3 of 8" and a progress bar.
class StepHeader extends StatelessWidget {
  const new({required this.step, required this.total, required this.title, super.key, this.onBack});

  final int step;
  final int total;
  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (onBack != null)
              IconButton(onPressed: onBack, tooltip: l10n.back, icon: const Icon(Icons.arrow_back_rounded)),
            Expanded(
              child: Text(
                l10n.stepOfTotal(step, total),
                style: context.text.labelLarge?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ),
          ],
        ),
        context.space.gapSm,
        StepProgress(step: step, total: total),
        context.space.gapLg,
        Text(title, style: context.text.headlineMedium?.copyWith(fontWeight: FarmTapWeights.bold)),
      ],
    );
  }
}

class StepProgress extends StatelessWidget {
  const new({required this.step, required this.total, super.key});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: context.radii.badge,
      child: LinearProgressIndicator(
        value: step / total,
        minHeight: context.sizes.progressBar,
        backgroundColor: context.colors.surfaceContainerHigh,
        color: context.colors.primary,
      ),
    );
  }
}
