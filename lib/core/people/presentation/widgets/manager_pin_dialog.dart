// P04 — manager PIN needed before a guarded action (a typed card number at
// clock in/out, editing a closed session). Dialog on every width.
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Resolves to true once a correct manager PIN is entered; false on Cancel.
Future<bool> showManagerPin(
  BuildContext context, {
  required String message,
  required Future<bool> Function(String pin) verify,
}) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialog) => DialogFrame(
      child: PinPad(
        onCompleted: (pin) async {
          final right = await verify(pin);
          if (right && dialog.mounted) Navigator.of(dialog).pop(true);
          return right;
        },
        header: Column(
          children: [
            IconBubble(icon: Symbols.lock_rounded, tone: FarmTapTone.gold, size: dialog.sizes.bubbleXl),
            dialog.space.gapLg,
            Text(l10n.managerPinNeeded, textAlign: TextAlign.center, style: dialog.text.titleLarge),
            dialog.space.gapSm,
            Text(
              message,
              textAlign: TextAlign.center,
              style: dialog.text.bodyMedium?.copyWith(color: dialog.colors.onSurfaceVariant),
            ),
            dialog.space.gapXl,
          ],
        ),
        footer: Padding(
          padding: EdgeInsets.only(top: dialog.space.lg),
          child: TextAction(label: l10n.cancel, onPressed: () => Navigator.of(dialog).pop(false)),
        ),
      ),
    ),
  );
  return ok ?? false;
}
