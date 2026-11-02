// N01 More menu (phones' fifth tab; also /more on wide screens).
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

enum MoreTarget {
  profile,
  feeding,
  breeding,
  workers,
  money,
  reports,
  cards,
  subscription,
  settings,
  help,
  lock,
  signOut,
}

class MorePage extends StatelessWidget {
  const new({
    required this.name,
    required this.role,
    required this.email,
    required this.onOpen,
    super.key,
    this.trialDaysLeft,
  });

  final String name;

  /// "Owner".
  final String role;
  final String email;
  final int? trialDaysLeft;
  final ValueChanged<MoreTarget> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ActionTile tile(MoreTarget t, IconData icon, String label, FarmTapTone tone) =>
        ActionTile(icon: icon, label: label, tone: tone, onTap: () => onOpen(t));
    RecordTile row(MoreTarget t, IconData icon, String title, FarmTapTone tone, {String? subtitle}) => RecordTile(
      leading: IconBubble(icon: icon, tone: tone, size: context.sizes.bubbleMd),
      title: title,
      subtitle: subtitle,
      onTap: () => onOpen(t),
    );
    return AdaptiveScaffold(
      title: l10n.more,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FarmTapCard(
            onTap: () => onOpen(MoreTarget.profile),
            child: Row(
              children: [
                PersonAvatar(name: name, size: context.sizes.avatarLg),
                context.space.gapLg,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: context.text.titleLarge),
                      context.space.gapXs,
                      Text(
                        '$role · $email',
                        style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Icon(Symbols.chevron_right_rounded, color: context.colors.onSurfaceVariant),
              ],
            ),
          ),
          context.space.gapLg,
          ResponsiveGrid(
            minItemWidth: context.sizes.gridMetric,
            maxColumns: 3,
            spacing: context.space.lg,
            children: [
              tile(MoreTarget.feeding, Symbols.grass_rounded, l10n.feeding, FarmTapTone.gold),
              tile(MoreTarget.breeding, Symbols.favorite_rounded, l10n.breeding, FarmTapTone.danger),
              tile(MoreTarget.workers, Symbols.groups_rounded, l10n.workers, FarmTapTone.info),
              tile(MoreTarget.money, Symbols.account_balance_wallet_rounded, l10n.money, FarmTapTone.primary),
              tile(MoreTarget.reports, Symbols.bar_chart_rounded, l10n.reports, FarmTapTone.primary),
              tile(MoreTarget.cards, Symbols.contactless_rounded, l10n.cardsLabel, FarmTapTone.gold),
            ],
          ),
          context.space.gapLg,
          ListCard(
            children: [
              row(
                MoreTarget.subscription,
                Symbols.savings_rounded,
                l10n.subscriptionLabel,
                FarmTapTone.gold,
                subtitle: trialDaysLeft == null ? null : l10n.trialDaysLeftShort(trialDaysLeft!),
              ),
              row(MoreTarget.settings, Symbols.settings_rounded, l10n.settings, FarmTapTone.neutral),
              row(MoreTarget.help, Symbols.support_agent_rounded, l10n.helpSupport, FarmTapTone.info),
              row(
                MoreTarget.lock,
                Symbols.lock_rounded,
                l10n.lockPhone,
                FarmTapTone.primary,
                subtitle: l10n.lockPhoneSub,
              ),
              row(MoreTarget.signOut, Symbols.logout_rounded, l10n.signOutLabel, FarmTapTone.danger),
            ],
          ),
        ],
      ),
    );
  }
}
