// Card register (decision 0016 §1): every card on the farm, who holds it
// and whether it works. A card has one holder until it is revoked.
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/people/domain/card_registry.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/core/utils/formats.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class CardRegisterPage extends StatelessWidget {
  const new({required this.cards, super.key, this.onHolder});

  final CardRegistry cards;
  final void Function(IdCardRecord card)? onHolder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = FarmTapFormat(Localizations.localeOf(context).toLanguageTag());
    return FutureBuilder<List<IdCardRecord>>(
      future: cards.cards().then((r) => r.data ?? const []),
      builder: (context, snapshot) {
        final all = snapshot.data;
        return AdaptiveScaffold(
          title: l10n.cardRegisterTitle,
          subtitle: all == null ? null : l10n.cardsCount(all.where((c) => c.active).length),
          showNavigation: false,
          body: all == null
              ? const FarmTapPageLoader()
              : all.isEmpty
              ? EmptyState(
                  animation: FarmTapAnimations.tapCard,
                  title: l10n.noCardsYetTitle,
                  message: l10n.noCardsYetBody,
                )
              : ListCard(
                  children: [
                    for (final c in all)
                      RecordTile(
                        leading: IconBubble(
                          icon: c.holderKind == CardHolderKind.staff
                              ? Symbols.badge_rounded
                              : Symbols.agriculture_rounded,
                          tone: switch (c.status) {
                            CardStatus.active => FarmTapTone.success,
                            CardStatus.returned => FarmTapTone.neutral,
                            CardStatus.lost => FarmTapTone.danger,
                          },
                          size: context.sizes.bubbleMd,
                        ),
                        title: '${l10n.cardNumberBadge(c.number)} · ${c.holderName}',
                        subtitle: [
                          if (c.holderKind == CardHolderKind.staff) l10n.idCardStaff else l10n.idCardSupplier,
                          if (c.issuedAt != null) l10n.issuedOn(f.day(c.issuedAt!)),
                          if (c.chipId != null) l10n.nfcChipWord,
                        ].join(' · '),
                        badge: StatusBadge(
                          label: switch (c.status) {
                            CardStatus.active => l10n.cardActive,
                            CardStatus.returned => l10n.cardReturned,
                            CardStatus.lost => l10n.cardLost,
                          },
                          tone: switch (c.status) {
                            CardStatus.active => FarmTapTone.success,
                            CardStatus.returned => FarmTapTone.neutral,
                            CardStatus.lost => FarmTapTone.danger,
                          },
                        ),
                        onTap: onHolder == null ? null : () => onHolder!(c),
                      ),
                  ],
                ),
        );
      },
    );
  }
}
