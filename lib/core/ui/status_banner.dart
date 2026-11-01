import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/controls.dart';
import 'package:farm_tap/core/ui/tone.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Inline banner: tinted, radius 14, padding 14, filled icon 26, title
/// titleSmall, message bodySmall, action labelLarge (right when wider than
/// 480, else below). Not dismissible while its condition is true.
class FarmTapBanner extends StatelessWidget {
  const new({
    required this.tone,
    required this.icon,
    required this.title,
    super.key,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final FarmTapTone tone;
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = tone.of(context);
    final on = colors.onContainer;
    // The whole banner is the tap target (>= 48 dp); the action is its label.
    final action = actionLabel == null
        ? null
        : Padding(
            padding: EdgeInsets.only(top: context.space.sm),
            child: Text(
              actionLabel!,
              style: context.text.labelLarge?.copyWith(color: on, fontWeight: FarmTapWeights.semiBold),
            ),
          );
    return Semantics(
      container: true,
      liveRegion: true,
      button: onAction != null,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final actionRight = constraints.maxWidth > context.sizes.centeredMaxWidth;
          return Material(
            color: colors.container,
            borderRadius: context.radii.banner,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onAction,
              child: Padding(
                padding: EdgeInsets.all(context.space.banner),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, fill: 1, color: on, size: context.sizes.iconBanner),
                    context.space.gapMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(title, style: context.text.titleSmall?.copyWith(color: on)),
                          if (message != null) Text(message!, style: context.text.bodySmall?.copyWith(color: on)),
                          if (action != null && !actionRight) action,
                        ],
                      ),
                    ),
                    if (action != null && actionRight) ...[context.space.gapMd, action],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Amber "you are offline" banner. Records still save on the phone.
class OfflineBanner extends StatelessWidget {
  const new({super.key, this.pending = 0});

  /// Records waiting to sync.
  final int pending;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FarmTapBanner(
      tone: FarmTapTone.warning,
      icon: Symbols.cloud_off_rounded,
      title: l10n.offlineBannerTitle,
      message: pending > 0 ? '${l10n.offlineBannerBody} (${l10n.recordsWaiting(pending)})' : l10n.offlineBannerBody,
    );
  }
}

/// Gold trial banner shown from day 1 on Home. "Pay now" opens M02.
class TrialBanner extends StatelessWidget {
  const new({required this.daysLeft, super.key, this.onPay});

  final int daysLeft;
  final VoidCallback? onPay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FarmTapBanner(
      tone: FarmTapTone.gold,
      icon: Symbols.savings_rounded,
      title: l10n.trialDaysLeft(daysLeft),
      message: l10n.trialThenPrice,
      actionLabel: l10n.payNow,
      onAction: onPay,
    );
  }
}

/// Sidebar trial card: 232 x 82, radius 14, secondaryContainer, savings icon,
/// "Free trial · 9 days left", 6 dp gold progress, "Upgrade · UGX 70,000/mo".
class TrialCard extends StatelessWidget {
  const new({required this.daysLeft, super.key, this.totalDays = 14, this.onUpgrade});

  final int daysLeft;
  final int totalDays;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = FarmTapTone.gold.of(context);
    return Material(
      color: colors.container,
      borderRadius: context.radii.banner,
      child: InkWell(
        onTap: onUpgrade,
        borderRadius: context.radii.banner,
        child: Container(
          height: context.sizes.trialCardHeight,
          padding: EdgeInsets.symmetric(horizontal: context.space.banner),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(Symbols.savings_rounded, fill: 1, size: context.sizes.iconSm, color: colors.onContainer),
                  context.space.gapSm,
                  Expanded(
                    child: Text(
                      l10n.trialDaysLeftShort(daysLeft),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelMedium?.copyWith(color: colors.onContainer),
                    ),
                  ),
                ],
              ),
              context.space.gapSm,
              FarmTapProgress(value: (totalDays - daysLeft) / totalDays, thin: true, color: colors.accent),
              context.space.gapSm,
              Text(
                l10n.trialUpgradeLine,
                style: context.text.labelSmall?.copyWith(
                  color: colors.onContainer,
                  fontWeight: FarmTapWeights.semiBold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum SyncState { synced, pending, failed }

/// Cloud icon in the top bar (28, filled): success = synced, amber = waiting
/// (with count), red = failed. Tap opens the sync sheet (D04).
class SyncBadge extends StatelessWidget {
  const new({required this.state, super.key, this.pending = 0, this.onTap, this.showLabel = false});

  final SyncState state;
  final int pending;
  final VoidCallback? onTap;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (icon, color, label) = switch (state) {
      SyncState.synced => (Symbols.cloud_done_rounded, context.status.synced, l10n.allRecordsSynced),
      SyncState.pending => (Symbols.cloud_upload_rounded, context.status.syncPending, l10n.recordsWaiting(pending)),
      SyncState.failed => (Symbols.cloud_off_rounded, context.status.syncFailed, l10n.syncFailedShort),
    };
    final iconSize = showLabel ? context.sizes.iconMd : context.sizes.iconLg;
    return Semantics(
      button: onTap != null,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: context.radii.badge,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: context.sizes.touchTarget, minWidth: context.sizes.touchTarget),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ExcludeSemantics(
                child: Icon(icon, fill: 1, color: color, size: iconSize),
              ),
              if (state == SyncState.pending && pending > 0 && !showLabel) ...[
                context.space.gapXs,
                Text('$pending', style: context.text.labelLarge?.copyWith(color: color)),
              ],
              if (showLabel) ...[
                context.space.gapSm,
                Flexible(
                  child: Text(label, style: context.text.labelMedium?.copyWith(color: context.colors.onSurfaceVariant)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
