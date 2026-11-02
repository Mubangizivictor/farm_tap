// TEMPORARY (UI rebuild): a destination whose screens are not built yet
// shows "Coming soon" (never a crash). Each section replaces its entry in
// app_router.dart; this file is deleted when the last section (P) is done.
import 'package:farm_tap/app/router/routes.dart';
import 'package:farm_tap/app/shell/app_shell.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';

class PendingSection extends StatelessWidget {
  const new({required this.path, super.key});

  final String path;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = switch (path) {
      AppRoutes.settingsSubscription => l10n.subscriptionLabel,
      AppRoutes.settingsHelp => l10n.helpSupport,
      _ => sectionLabel(l10n, path),
    };
    return AdaptiveScaffold(
      title: title,
      scrollable: false,
      body: EmptyState(title: l10n.comingSoon, message: l10n.comingSoonBody, animation: FarmTapAnimations.cowGrazing),
    );
  }
}
