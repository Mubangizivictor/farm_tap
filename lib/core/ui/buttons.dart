import 'package:farm_tap/core/theme/theme.dart';
import 'package:flutter/material.dart';

enum ButtonKind { filled, tonal, outlined, text, danger, gold, neutral }

/// The one button: full width by default, 56 tall (64 when [large]), radius
/// 14, filled 24 dp icon + 6 gap, `button` / `buttonLarge` text.
class FarmTapButton extends StatelessWidget {
  const new({
    required this.label,
    required this.onPressed,
    super.key,
    this.kind = ButtonKind.filled,
    this.icon,
    this.leading,
    this.trailingIcon,
    this.large = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Custom leading widget instead of [icon] (e.g. a provider letter badge).
  final Widget? leading;

  /// Icon pinned to the right edge with the label centred ("Continue →").
  final IconData? trailingIcon;
  final ButtonKind kind;
  final IconData? icon;
  final bool large;

  /// Full width (default) or as wide as its content.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.status;
    final (Color? bg, Color fg, BorderSide? side) = switch (kind) {
      ButtonKind.filled => (c.primary, c.onPrimary, null),
      ButtonKind.tonal => (c.primaryContainer, c.onPrimaryContainer, null),
      ButtonKind.outlined => (null, c.primary, BorderSide(color: c.outline, width: context.sizes.borderMedium)),
      ButtonKind.text => (null, c.primary, null),
      ButtonKind.danger => (s.danger, s.onDanger, null),
      ButtonKind.gold => (c.secondary, c.onSecondary, null),
      ButtonKind.neutral => (
        c.surfaceContainerLowest,
        c.onSurface,
        BorderSide(color: c.outlineVariant, width: context.sizes.borderThin),
      ),
    };
    final height = large ? context.sizes.buttonHeightLarge : context.sizes.buttonHeight;
    final style = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => bg == null
            ? Colors.transparent
            : states.contains(WidgetState.disabled)
            ? c.surfaceContainerHigh
            : bg,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled) ? c.onSurfaceVariant : fg,
      ),
      overlayColor: WidgetStatePropertyAll(fg.withValues(alpha: 0.08)),
      side: side == null ? null : WidgetStatePropertyAll(side),
      minimumSize: WidgetStatePropertyAll(Size(context.sizes.buttonMinWidth, height)),
      fixedSize: WidgetStatePropertyAll(Size.fromHeight(height)),
      padding: WidgetStatePropertyAll(context.space.button),
      shape: WidgetStatePropertyAll(context.radii.buttonShape),
      elevation: const WidgetStatePropertyAll(0),
      textStyle: WidgetStatePropertyAll(large ? context.textStyles.buttonLarge : context.textStyles.button),
      iconSize: WidgetStatePropertyAll(context.sizes.iconMd),
    );
    final text = Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);
    final lead = leading ?? (icon == null ? null : Icon(icon, fill: 1));
    final Widget child;
    if (trailingIcon != null) {
      child = Stack(
        alignment: Alignment.center,
        children: [
          text,
          Align(alignment: AlignmentDirectional.centerEnd, child: Icon(trailingIcon, fill: 1)),
        ],
      );
    } else {
      child = lead == null
          ? text
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                lead,
                SizedBox(width: leading == null ? context.space.xs + context.space.xxs : context.space.md),
                Flexible(child: text),
              ],
            );
    }
    final button = kind == ButtonKind.text
        ? TextButton(onPressed: onPressed, style: style, child: child)
        : FilledButton(onPressed: onPressed, style: style, child: child);
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Two buttons: side by side when the width is at least 420, else stacked
/// with a 12 gap ([first] on top).
class ButtonPair extends StatelessWidget {
  const new({required this.first, required this.second, super.key});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= context.sizes.buttonPairMinWidth) {
          return Row(
            children: [
              Expanded(child: first),
              context.space.gapMd,
              Expanded(child: second),
            ],
          );
        }
        return Column(mainAxisSize: MainAxisSize.min, children: [first, context.space.gapMd, second]);
      },
    );
  }
}

/// Text action in the primary colour: "Pay now", "See all" (labelLarge).
class TextAction extends StatelessWidget {
  const new({required this.label, required this.onPressed, super.key, this.color, this.small = false, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  /// labelMedium instead of labelLarge (card header actions).
  final bool small;

  /// Filled icon before the label ("Use my location").
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = (small ? context.text.labelMedium : context.text.labelLarge)?.copyWith(
      color: color ?? context.colors.primary,
      fontWeight: FarmTapWeights.semiBold,
    );
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: context.radii.button,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: context.sizes.touchTarget, minWidth: context.sizes.touchTarget),
          child: Align(
            widthFactor: 1,
            child: icon == null
                ? Text(label, style: style)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, fill: 1, size: context.sizes.iconMd, color: style?.color),
                      context.space.gapSm,
                      Text(label, style: style),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
