import 'dart:async';

import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/sound/sound_service.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Big number keypad (milk litres, delivery litres, card number, PIN).
/// 3 columns, gap 10, keys 64 tall radius 16 (PIN: [pill], 60 tall, max 340).
/// Every key press gives a light haptic tick.
class BigNumberKeypad extends StatelessWidget {
  const new({required this.onDigit, required this.onBackspace, super.key, this.showDecimal = false, this.pill = false});

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  /// Shows "." in the bottom-left. Otherwise that cell is empty (PIN).
  final bool showDecimal;
  final bool pill;

  void _tap(VoidCallback cb) {
    unawaited(HapticFeedback.selectionClick());
    unawaited(SoundService.instance.play(FarmTapSound.tap));
    cb();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final gap = context.space.keyGap;
    Widget row(List<Widget> cells) => Padding(
      padding: EdgeInsets.only(bottom: gap),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++) ...[if (i > 0) SizedBox(width: gap), Expanded(child: cells[i])],
        ],
      ),
    );
    Widget digit(String d) => _Key(label: d, pill: pill, onTap: () => _tap(() => onDigit(d)));
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: pill ? context.sizes.pinPadMaxWidth : context.sizes.keypadMaxWidth),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          row([digit('1'), digit('2'), digit('3')]),
          row([digit('4'), digit('5'), digit('6')]),
          row([digit('7'), digit('8'), digit('9')]),
          row([
            if (showDecimal)
              _Key(label: '.', semanticLabel: l10n.keypadDecimal, pill: pill, onTap: () => _tap(() => onDigit('.')))
            else
              const SizedBox.shrink(),
            digit('0'),
            _Key(
              icon: Symbols.backspace_rounded,
              semanticLabel: l10n.keypadBackspace,
              pill: pill,
              onTap: () => _tap(onBackspace),
            ),
          ]),
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const new({required this.pill, required this.onTap, this.label, this.icon, this.semanticLabel});

  final String? label;
  final IconData? icon;
  final String? semanticLabel;
  final bool pill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = pill
        ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.radii.pill))
        : context.radii.buttonShape.copyWith(borderRadius: context.radii.keypadKey);
    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: Material(
        color: context.status.keypadKey,
        shape: shape.copyWith(side: BorderSide(color: context.colors.outlineVariant)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: pill ? context.sizes.pinKey : context.sizes.keypadKey,
            child: Center(
              child: icon != null
                  ? Icon(icon, size: context.sizes.iconBackspace, color: context.status.onKeypadKey)
                  : Text(label!, style: context.textStyles.keypadDigit.copyWith(color: context.status.onKeypadKey)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Display above the keypad: 96 tall, radius 18, c0, 2 dp primary border,
/// keypadDisplay value + caret 3x46 + unit (titleLarge); optional caption
/// (bodySmall) 8 below.
class KeypadDisplay extends StatelessWidget {
  const new({required this.text, super.key, this.unit, this.placeholder = '0', this.active = true, this.caption});

  final String text;
  final String? unit;
  final String placeholder;

  /// Draws the green frame and the blinking-style caret.
  final bool active;

  /// "Yesterday evening: 9.0 L".
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final empty = text.isEmpty;
    final display = Semantics(
      liveRegion: true,
      label: '${empty ? placeholder : text} ${unit ?? ''}',
      excludeSemantics: true,
      child: Container(
        height: context.sizes.keypadDisplayHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerLowest,
          borderRadius: context.radii.keypadDisplay,
          border: Border.all(
            color: active ? context.colors.primary : context.colors.outlineVariant,
            width: context.sizes.borderThick,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              empty ? placeholder : text,
              style: context.textStyles.keypadDisplay.copyWith(
                color: empty ? context.colors.outline : context.colors.onSurface,
              ),
            ),
            if (active)
              Container(
                width: context.sizes.keypadCaretWidth,
                height: context.sizes.keypadCaretHeight,
                margin: EdgeInsets.symmetric(horizontal: context.space.xs),
                color: context.colors.primary,
              ),
            if (unit != null)
              Text(unit!, style: context.text.titleLarge?.copyWith(color: context.colors.onSurfaceVariant)),
          ],
        ),
      ),
    );
    if (caption == null) return display;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        display,
        context.space.gapSm,
        Text(caption!, textAlign: TextAlign.center, style: context.text.bodySmall),
      ],
    );
  }
}
