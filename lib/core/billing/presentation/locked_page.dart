import 'dart:async';

import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/settings/presentation/pages/help_page.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// M05 The farm's trial or plan has ended (decision 0023, hard lock): nothing
/// can be added or changed, the same as the web and the server rules.
/// Owners and managers can pay or look at their records; others ask the
/// owner. Records are safe and nothing is deleted.
class LockedPage extends StatelessWidget {
  const new({
    required this.farmName,
    required this.wasPaid,
    required this.manages,
    required this.onPay,
    required this.onView,
    required this.onSwitchFarm,
    required this.onSignOut,
    super.key,
  });

  final String farmName;

  /// The farm had paid before (plan ended) rather than only trialled.
  final bool wasPaid;
  final bool manages;
  final VoidCallback onPay;
  final VoidCallback onView;
  final VoidCallback onSwitchFarm;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AdaptiveScaffold(
      showNavigation: false,
      showLogo: true,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: context.sizes.centeredMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              context.space.gapXl,
              Center(
                child: IconBubble(icon: Symbols.lock_rounded, tone: FarmTapTone.gold, size: context.sizes.bubbleXl),
              ),
              context.space.gapLg,
              Text(
                wasPaid ? l10n.lockedPlanTitle : l10n.lockedTrialTitle,
                textAlign: TextAlign.center,
                style: context.text.headlineSmall,
              ),
              context.space.gapSm,
              Text(
                l10n.lockedBody(farmName),
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
              ),
              context.space.gapXl,
              if (manages) ...[
                FarmTapButton(label: l10n.lockedPay, icon: Symbols.payments_rounded, large: true, onPressed: onPay),
                context.space.gapSm,
                FarmTapButton(
                  label: l10n.lockedView,
                  icon: Symbols.visibility_rounded,
                  kind: ButtonKind.outlined,
                  onPressed: onView,
                ),
              ] else
                FarmTapBanner(
                  tone: FarmTapTone.info,
                  icon: Symbols.info_rounded,
                  title: l10n.payAskOwner,
                  message: l10n.payAskOwnerBody,
                ),
              context.space.gapMd,
              FarmTapButton(
                label: l10n.helpWhatsapp,
                icon: Symbols.chat_rounded,
                kind: ButtonKind.text,
                onPressed: () => unawaited(openSupportWhatsApp(l10n.payHelpMessage(farmName))),
              ),
              FarmTapButton(
                label: l10n.lockedOtherFarm,
                icon: Symbols.swap_horiz_rounded,
                kind: ButtonKind.text,
                onPressed: onSwitchFarm,
              ),
              FarmTapButton(
                label: l10n.signOutLabel,
                icon: Symbols.logout_rounded,
                kind: ButtonKind.text,
                onPressed: onSignOut,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
