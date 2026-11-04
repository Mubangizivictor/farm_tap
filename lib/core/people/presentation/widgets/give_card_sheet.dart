// Give a card (decision 0016): tap a blank NFC card, type the printed
// number, or print a QR-only card with a new number.
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/nfc/card_tap_listener.dart';
import 'package:farm_tap/core/people/presentation/widgets/card_number_sheet.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// What the person chose: [scanned] is the card read or typed; null means
/// a new number for a printed card.
class GiveCardChoice {
  const new(this.scanned);

  final String? scanned;
}

Future<GiveCardChoice?> showGiveCardSheet(BuildContext context, {required String name}) =>
    showAdaptiveSheet<GiveCardChoice>(context, builder: (_) => _GiveCard(name: name));

class _GiveCard extends StatelessWidget {
  const new({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CardTapListener(
      onCard: (c) => Navigator.of(context).pop(GiveCardChoice(c)),
      prompt: l10n.tapNewCardNow,
      autoOpenOnIos: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetTitle(l10n.tapNewCardNow, subtitle: l10n.holdBlankCard(name)),
          context.space.gapLg,
          FarmTapAnimationView(animation: FarmTapAnimations.tapCard, size: context.sizes.animationSm),
          context.space.gapLg,
          if (ScanCardButton.needed) ...[ScanCardButton(label: l10n.scanCard), context.space.gapSm],
          FarmTapButton(
            label: l10n.typeCardNumber,
            icon: Symbols.dialpad_rounded,
            kind: ButtonKind.outlined,
            onPressed: () async {
              final n = await showTypeCardNumber(context);
              if (n != null && context.mounted) Navigator.of(context).pop(GiveCardChoice(n));
            },
          ),
          context.space.gapSm,
          FarmTapButton(
            label: l10n.printedCardNoChip,
            icon: Symbols.qr_code_2_rounded,
            kind: ButtonKind.text,
            onPressed: () => Navigator.of(context).pop(const GiveCardChoice(null)),
          ),
        ],
      ),
    );
  }
}
