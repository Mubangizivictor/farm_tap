import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// "Type card number" (decision 0006): the number printed on a card, for
/// phones without NFC or a card that does not read. Up to 4 digits.
Future<String?> showTypeCardNumber(BuildContext context, {String? initial}) {
  final l10n = AppLocalizations.of(context);
  var digits = initial ?? '';
  return showAdaptiveSheet<String>(
    context,
    builder: (sheet) => StatefulBuilder(
      builder: (sheet, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetTitle(l10n.typeCardNumber, subtitle: l10n.typeTheCardNumber),
          sheet.space.gapLg,
          KeypadDisplay(text: digits, placeholder: '0000'),
          sheet.space.gapLg,
          BigNumberKeypad(
            onDigit: (d) => setState(() => digits = digits.length < 4 ? '$digits$d' : digits),
            onBackspace: () =>
                setState(() => digits = digits.isEmpty ? digits : digits.substring(0, digits.length - 1)),
          ),
          sheet.space.gapLg,
          FarmTapButton(
            label: l10n.useCard,
            icon: Symbols.check_rounded,
            onPressed: digits.isEmpty ? null : () => Navigator.of(sheet).pop(digits.padLeft(4, '0')),
          ),
        ],
      ),
    ),
  );
}
