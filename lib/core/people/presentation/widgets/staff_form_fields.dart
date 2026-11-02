// Worker form fields shared by B09 (first worker) and K01/K02 (add / edit
// worker): name, role, 4-digit PIN and the "card comes later" note.
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class StaffFormFields<R> extends StatelessWidget {
  const new({
    required this.name,
    required this.roles,
    required this.role,
    required this.roleLabel,
    required this.onRole,
    required this.onChanged,
    super.key,
    this.pin,
    this.onPin,
    this.nameError,
    this.pinError,
    this.showCardNote = true,
  });

  final TextEditingController name;
  final List<R> roles;
  final R role;
  final String Function(R) roleLabel;
  final ValueChanged<R> onRole;
  final VoidCallback onChanged;

  /// The chosen PIN; null hides the PIN field (edit uses Reset PIN).
  final String? pin;
  final ValueChanged<String>? onPin;
  final String? nameError;
  final String? pinError;
  final bool showCardNote;

  Future<void> _choosePin(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final chosen = await showAdaptiveSheet<String>(
      context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetTitle(l10n.choosePin, center: true),
          sheet.space.gapXl,
          PinPad(
            onCompleted: (p) async {
              Navigator.of(sheet).pop(p);
              return true;
            },
          ),
        ],
      ),
    );
    if (chosen != null) onPin?.call(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FarmTapTextField(
          label: l10n.nameLabel,
          icon: Symbols.person_rounded,
          controller: name,
          error: nameError,
          textInputAction: TextInputAction.done,
          onChanged: (_) => onChanged(),
        ),
        context.space.gapLg,
        FarmTapSelectField<R>(
          label: l10n.roleLabel,
          icon: Symbols.badge_rounded,
          options: roles,
          labelOf: roleLabel,
          value: role,
          onChanged: onRole,
        ),
        if (pin != null) ...[
          context.space.gapLg,
          Text(l10n.choosePin, style: context.text.titleSmall),
          Semantics(
            button: true,
            label: pin!.length == 4 ? l10n.pinChosen : l10n.choosePinHint,
            excludeSemantics: true,
            child: InkWell(
              onTap: () => _choosePin(context),
              borderRadius: context.radii.card,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: context.space.md),
                child: Center(
                  child: PinDots(filled: pin!.length, error: pinError != null),
                ),
              ),
            ),
          ),
          if (pinError != null)
            Text(
              pinError!,
              textAlign: TextAlign.center,
              style: context.text.bodySmall?.copyWith(color: context.colors.error),
            ),
        ],
        if (showCardNote)
          FarmTapBanner(
            tone: FarmTapTone.info,
            icon: Symbols.info_rounded,
            title: l10n.nfcLaterTitle,
            message: l10n.nfcLaterBody,
          ),
      ],
    );
  }
}
