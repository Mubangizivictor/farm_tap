import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/icon_bubble.dart';
import 'package:farm_tap/core/ui/tone.dart';
import 'package:flutter/material.dart';

/// Inline banner at the top of content. Not dismissible while its condition
/// is true (trial, offline, withdrawal, read-only). UX_SPEC section 4.
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
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: context.space.card,
        decoration: BoxDecoration(color: colors.container, borderRadius: context.radii.card),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colors.onContainer, size: context.sizes.iconLg),
            context.space.gapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.text.titleMedium?.copyWith(
                      color: colors.onContainer,
                      fontWeight: FarmTapWeights.bold,
                    ),
                  ),
                  if (message != null)
                    Text(message!, style: context.text.bodyMedium?.copyWith(color: colors.onContainer)),
                  if (actionLabel != null) ...[
                    context.space.gapSm,
                    InkWell(
                      onTap: onAction,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: context.sizes.touchTarget),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: 1,
                          child: Text(
                            actionLabel!,
                            style: context.text.titleMedium?.copyWith(
                              color: colors.onContainer,
                              fontWeight: FarmTapWeights.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Yellow "you are offline" banner. Records still save on the phone.
class OfflineBanner extends StatelessWidget {
  const new({super.key, this.pending = 0});

  /// Records waiting to sync.
  final int pending;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FarmTapBanner(
      tone: FarmTapTone.warning,
      icon: Icons.cloud_off_rounded,
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
      icon: Icons.savings_rounded,
      title: l10n.trialDaysLeft(daysLeft),
      message: l10n.trialThenPrice,
      actionLabel: l10n.payNow,
      onAction: onPay,
    );
  }
}

/// Compact trial card with progress, at the bottom of the sidebar.
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
      borderRadius: context.radii.card,
      child: InkWell(
        onTap: onUpgrade,
        borderRadius: context.radii.card,
        child: Padding(
          padding: context.space.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.savings_rounded, size: context.sizes.iconSm, color: colors.onContainer),
                  context.space.gapSm,
                  Expanded(
                    child: Text(
                      l10n.trialDaysLeftShort(daysLeft),
                      style: context.text.titleSmall?.copyWith(
                        color: colors.onContainer,
                        fontWeight: FarmTapWeights.bold,
                      ),
                    ),
                  ),
                ],
              ),
              context.space.gapSm,
              ClipRRect(
                borderRadius: context.radii.badge,
                child: LinearProgressIndicator(
                  value: ((totalDays - daysLeft) / totalDays).clamp(0, 1),
                  minHeight: context.sizes.progressBar,
                  color: colors.accent,
                  backgroundColor: context.colors.surfaceContainerHigh,
                ),
              ),
              context.space.gapSm,
              Text(l10n.trialUpgradeLine, style: context.text.labelMedium?.copyWith(color: colors.onContainer)),
            ],
          ),
        ),
      ),
    );
  }
}

enum SyncState { synced, pending, failed }

/// Cloud icon in the top bar: green tick = synced, amber = waiting (with
/// count), red = failed. Tap opens the sync sheet (D04).
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
      SyncState.synced => (Icons.cloud_done_rounded, context.status.synced, l10n.allRecordsSynced),
      SyncState.pending => (Icons.cloud_upload_rounded, context.status.syncPending, l10n.recordsWaiting(pending)),
      SyncState.failed => (Icons.cloud_off_rounded, context.status.syncFailed, l10n.syncFailedShort),
    };
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
                child: Icon(icon, color: color, size: context.sizes.iconLg),
              ),
              if (state == SyncState.pending && pending > 0 && !showLabel) ...[
                context.space.gapXs,
                Text(
                  '$pending',
                  style: context.text.labelLarge?.copyWith(color: color, fontWeight: FarmTapWeights.bold),
                ),
              ],
              if (showLabel) ...[
                context.space.gapSm,
                Flexible(
                  child: Text(label, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Icon + title + message row used inside dialogs and sheets.
class IconHeading extends StatelessWidget {
  const new({required this.icon, required this.title, super.key, this.message, this.tone = FarmTapTone.success});

  final IconData icon;
  final String title;
  final String? message;
  final FarmTapTone tone;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconBubble(icon: icon, tone: tone, size: context.sizes.avatarLg, iconSize: context.sizes.iconXl),
        context.space.gapLg,
        Text(
          title,
          textAlign: TextAlign.center,
          style: context.text.headlineSmall?.copyWith(fontWeight: FarmTapWeights.bold),
        ),
        if (message != null) ...[
          context.space.gapSm,
          Text(
            message!,
            textAlign: TextAlign.center,
            style: context.text.bodyLarge?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}
