// Navigation helpers shared by every screen (docs/design/ROUTES.md).
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/ui/adaptive_scaffold.dart';
import 'package:farm_tap/core/ui/adaptive_sheet.dart';
import 'package:farm_tap/core/ui/buttons.dart';
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
    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await confirm(context);
        if (leave && context.mounted) Navigator.of(context).pop();
      },
      child: child,
    );
  }
}
