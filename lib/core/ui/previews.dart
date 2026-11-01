import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:flutter/material.dart';

/// How an SMS looks on the farmer's phone: grey bubble, sender and time.
/// Used for delivery receipts and statements (G11) and WhatsApp-style
/// previews (L04).
class SmsPreviewBubble extends StatelessWidget {
  const new({required this.message, super.key, this.sender, this.time});

  final String message;
  final String? sender;
  final String? time;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: context.space.sm, bottom: context.space.xs),
          child: Text(
            [sender ?? l10n.appName, ?time].join(' · '),
            style: context.text.labelMedium?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ),
        Container(
          padding: context.space.card,
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHigh,
            borderRadius: context.radii.card.copyWith(bottomLeft: Radius.circular(context.radii.xs)),
          ),
          child: Text(message, style: context.text.bodyLarge),
        ),
      ],
    );
  }
}

/// The printed NFC card as it will look: brand green, gold ring, name and
/// number. Shown before printing and when assigning a card (K03).
class PrintedCardPreview extends StatelessWidget {
  const new({required this.name, required this.cardNumber, super.key, this.subtitle});

  final String name;
  final String cardNumber;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final on = context.colors.onPrimary;
    return Semantics(
      label: '$name $cardNumber',
      image: true,
      child: Container(
        width: context.sizes.cardPreviewWidth,
        padding: context.space.card,
        decoration: BoxDecoration(color: context.status.brandGreen, borderRadius: context.radii.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.wb_sunny_rounded, color: context.status.brandGold, size: context.sizes.iconLg),
                context.space.gapSm,
                Text(
                  l10n.appName,
                  style: context.text.titleMedium?.copyWith(color: on, fontWeight: FarmTapWeights.bold),
                ),
                const Spacer(),
                Icon(Icons.contactless_rounded, color: context.status.brandGold, size: context.sizes.iconLg),
              ],
            ),
            context.space.gapXl,
            Text(
              name,
              style: context.text.titleLarge?.copyWith(color: on, fontWeight: FarmTapWeights.bold),
            ),
            if (subtitle != null) Text(subtitle!, style: context.text.bodyMedium?.copyWith(color: on)),
            context.space.gapSm,
            Text(cardNumber, style: context.textStyles.tagNumber.copyWith(color: context.status.brandGold)),
          ],
        ),
      ),
    );
  }
}
