// Navigation helpers shared by every screen (docs/design/ROUTES.md).
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/adaptive_scaffold.dart';
import 'package:farm_tap/core/ui/adaptive_sheet.dart';
import 'package:farm_tap/core/ui/buttons.dart';
import 'package:farm_tap/core/ui/status_banner.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Provided by the app shell: the bottom bar / rail / sidebar for the
/// current tab, so every page's AdaptiveScaffold shows the same navigation.
class NavigationScope extends InheritedWidget {
  const new({required this.navigation, required super.child, super.key});

  final AdaptiveNavigation navigation;

  static AdaptiveNavigation? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NavigationScope>()?.navigation;

  @override
  bool updateShouldNotify(NavigationScope oldWidget) =>
      navigation.selectedId != oldWidget.navigation.selectedId ||
      navigation.items != oldWidget.navigation.items ||
      navigation.railItems != oldWidget.navigation.railItems ||
      navigation.sidebarItems != oldWidget.navigation.sidebarItems;
}

/// Shell-wide status the app shell provides once (sync icon, staff avatar,
/// farm switcher, trial card, notifications); AdaptiveScaffold falls back to
/// it for anything a page does not set itself.
class ShellStatus extends InheritedWidget {
  const new({
    required super.child,
    super.key,
    this.syncState = SyncState.synced,
    this.pending = 0,
    this.online = true,
    this.onSyncTap,
    this.profileName,
    this.onProfileTap,
    this.farm,
    this.trialDaysLeft,
    this.onUpgrade,
    this.hasNotifications = false,
    this.onNotificationsTap,
  });

  final SyncState syncState;
  final int pending;
  final bool online;
  final VoidCallback? onSyncTap;
  final String? profileName;
  final VoidCallback? onProfileTap;
  final FarmSwitcherInfo? farm;
  final int? trialDaysLeft;
  final VoidCallback? onUpgrade;
  final bool hasNotifications;
  final VoidCallback? onNotificationsTap;

  static ShellStatus? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ShellStatus>();

  @override
  bool updateShouldNotify(ShellStatus old) =>
      syncState != old.syncState ||
      pending != old.pending ||
      online != old.online ||
      profileName != old.profileName ||
      farm?.name != old.farm?.name ||
      trialDaysLeft != old.trialDaysLeft ||
      hasNotifications != old.hasNotifications;
}

/// Set by the router around every page: the parent route (null = a root
/// screen). AdaptiveScaffold shows the back arrow for non-root screens and
/// uses [parent] when there is nothing to pop.
class RouteInfo extends InheritedWidget {
  const new({required this.parent, required super.child, super.key});

  final String? parent;

  static RouteInfo? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<RouteInfo>();

  @override
  bool updateShouldNotify(RouteInfo oldWidget) => parent != oldWidget.parent;
}

/// Back: pop when there is something to pop, otherwise go to [fallback]
/// (the parent route), e.g. after a deep link or a web refresh.
void popOrGo(BuildContext context, String? fallback) {
  final router = GoRouter.maybeOf(context);
  if (router == null) {
    Navigator.maybePop(context);
    return;
  }
  if (router.canPop()) {
    router.pop();
  } else if (fallback != null) {
    router.go(fallback);
  }
}

/// The back arrow: like [popOrGo], but asks the page's PopScope first, so a
/// dirty form shows "Discard changes?" (router.pop() skips PopScope).
void backOrGo(BuildContext context, String? fallback) {
  final router = GoRouter.maybeOf(context);
  if (router == null || router.canPop()) {
    Navigator.maybePop(context);
  } else if (fallback != null) {
    router.go(fallback);
  }
}

/// Wraps a form: when [dirty], leaving (back arrow, swipe, system back)
/// first asks "Discard changes?".
class DiscardGuard extends StatelessWidget {
  const new({required this.dirty, required this.child, super.key});

  final bool dirty;
  final Widget child;

  static Future<bool> confirm(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return showFarmTapDialog(
      context,
      icon: Symbols.edit_off_rounded,
      title: l10n.discardTitle,
      message: l10n.discardBody,
      primaryLabel: l10n.discardConfirm,
      primaryKind: ButtonKind.danger,
      secondaryLabel: l10n.keepEditing,
    );
  }

  @override
  Widget build(BuildContext context) {
    // iOS turns its edge swipe off while PopScope says no; a dirty form
    // gets its own edge strip so the swipe still asks.
    final ios = Theme.of(context).platform == TargetPlatform.iOS;
    var dragged = 0.0;
    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await confirm(context);
        if (leave && context.mounted) Navigator.of(context).pop();
      },
      child: !(dirty && ios && (ModalRoute.of(context)?.canPop ?? false))
          ? child
          : Stack(
              children: [
                child,
                PositionedDirectional(
                  start: 0,
                  top: 0,
                  bottom: 0,
                  width: context.sizes.backSwipeEdge,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragStart: (_) => dragged = 0,
                    onHorizontalDragUpdate: (d) => dragged += d.delta.dx,
                    onHorizontalDragEnd: (_) {
                      if (dragged > context.sizes.touchTarget) Navigator.maybePop(context);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
