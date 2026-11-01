import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/adaptive_sheet.dart';
import 'package:farm_tap/core/ui/buttons.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// "Bihogo · FT-014 — 9.5 litres — Is this correct?" Shown before any save
/// that affects money or milk. Nothing is saved until "Yes".
/// Use [showReadBack] so it needs a choice (no scrim dismiss).
class ReadBackSheet extends StatelessWidget {
  const new({
    required this.valueText,
    required this.onConfirm,
    required this.onChange,
    super.key,
    this.leading,
    this.subject,
    this.detail,
    this.confirmLabel,
    this.changeLabel,
  });

  /// Avatar 88 with ring (CowAvatar / PersonAvatar) shown above.
  final Widget? leading;

  /// "Bihogo · FT-014".
  final String? subject;

  /// The number being confirmed: "9.5 litres".
  final String valueText;

  /// "Morning · recorded by Amos".
  final String? detail;
  final String? confirmLabel;
  final String? changeLabel;
  final VoidCallback onConfirm;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      explicitChildNodes: true,
      scopesRoute: true,
      namesRoute: true,
      label: '${subject ?? ''} $valueText ${l10n.isThisCorrect}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (leading != null) Center(child: leading),
          if (subject != null) ...[
            context.space.gapMd,
            Text(subject!, textAlign: TextAlign.center, style: context.textStyles.readBackLabel),
          ],
          context.space.gapSm,
          Text(valueText, textAlign: TextAlign.center, style: context.textStyles.readBackValue),
          if (detail != null) ...[
            context.space.gapSm,
            Text(
              detail!,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ],
          context.space.gapXl,
          Text(l10n.isThisCorrect, textAlign: TextAlign.center, style: context.text.titleMedium),
          context.space.gapLg,
          FarmTapButton(
            label: confirmLabel ?? l10n.yesSave,
            icon: Symbols.check_rounded,
            large: true,
            onPressed: onConfirm,
          ),
          SizedBox(height: context.space.keyGap),
          FarmTapButton(
            label: changeLabel ?? l10n.noChangeIt,
            icon: Symbols.edit_rounded,
            kind: ButtonKind.outlined,
            onPressed: onChange,
          ),
        ],
      ),
    );
  }
}

/// Opens the read-back and resolves to true only when the user says Yes.
Future<bool> showReadBack(
  BuildContext context, {
  required String valueText,
  Widget? leading,
  String? subject,
  String? detail,
}) async {
  final result = await showAdaptiveSheet<bool>(
    context,
    dismissible: false,
    builder: (ctx) => ReadBackSheet(
      leading: leading,
      subject: subject,
      valueText: valueText,
      detail: detail,
      onConfirm: () => Navigator.of(ctx).pop(true),
      onChange: () => Navigator.of(ctx).pop(false),
    ),
  );
  return result ?? false;
}

/// Plain-text variant kept for the first herd form until E04 is rebuilt.
class ReadBackConfirmSheet extends StatelessWidget {
  const new({required this.summary, required this.onConfirm, required this.onCancel, super.key});

  final String summary;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => ReadBackSheet(valueText: summary, onConfirm: onConfirm, onChange: onCancel);
}
