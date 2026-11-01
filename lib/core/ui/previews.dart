import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/avatars.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

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

/// The printed NFC card as it will look (K03): white card, green header strip
/// with "FarmTap" and a gold contactless icon, avatar 64, name, role line and
/// the card number (tagNumber, primary), soft shadow. Always drawn with the
/// light theme because the printed card never goes dark.
class PrintedCardPreview extends StatelessWidget {
  const new({required this.name, required this.cardNumber, super.key, this.subtitle});

  final String name;

  /// "Card 0207".
  final String cardNumber;

  /// "Worker · Rwemera Dairy Farm".
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$name $cardNumber',
      image: true,
      child: Theme(
        data: FarmTapTheme.light,
        child: Builder(builder: _card),
      ),
    );
  }

  Widget _card(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: context.status.card,
        borderRadius: context.radii.card,
        border: Border.all(color: context.colors.outlineVariant, width: context.sizes.borderThin),
        boxShadow: [
          BoxShadow(
            color: context.colors.shadow.withValues(alpha: 0.12),
            offset: Offset(0, context.space.xs),
            blurRadius: context.space.md,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: context.colors.primary,
            padding: EdgeInsets.symmetric(horizontal: context.space.lg, vertical: context.space.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(l10n.appName, style: context.text.titleMedium?.copyWith(color: context.colors.onPrimary)),
                ),
                Icon(Symbols.contactless_rounded, color: context.status.brandGold, size: context.sizes.iconLg),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(context.space.lg, context.space.lg, context.space.lg, context.space.xxxl),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PersonAvatar(name: name, size: context.sizes.avatarLg),
                context.space.gapLg,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: context.text.titleMedium),
                      if (subtitle != null) Text(subtitle!, style: context.text.bodySmall),
                      context.space.gapSm,
                      Text(cardNumber, style: context.textStyles.tagNumber.copyWith(color: context.colors.primary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
