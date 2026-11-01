import 'package:farm_tap/app/shell/app_shell.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';

/// Wraps a page in what the app shell provides: bottom bar / rail /
/// sidebar for [current], sync icon, staff avatar, farm switcher, trial card.
/// [parent] non-null gives the page a back arrow (a pushed screen).
Widget inShell(
  Widget page, {
  String current = '/home',
  String? parent,
  bool online = true,
  bool centre = false,
  String profileName = 'Mugisha Tom',
  int? trialDaysLeft = 9,
  SyncState syncState = SyncState.synced,
}) => Builder(
  builder: (context) {
    final l10n = AppLocalizations.of(context);
    return ShellStatus(
      online: online,
      syncState: syncState,
      onSyncTap: () {},
      profileName: profileName,
      farm: const FarmSwitcherInfo(name: 'Rwemera Dairy Farm', subtitle: 'Mbarara · Owner'),
      trialDaysLeft: trialDaysLeft,
      hasNotifications: true,
      onNotificationsTap: () {},
      child: NavigationScope(
        navigation: shellNavigation(l10n, context.formFactor, current: current, centre: centre, onSelect: (_) {}),
        child: RouteInfo(parent: parent, child: page),
      ),
    );
  },
);
