// The tab shell: one StatefulShellRoute.indexedStack branch per section, each
// with its own back stack and scroll position (docs/design/ROUTES.md).
import 'package:farm_tap/app/router/routes.dart';
import 'package:farm_tap/app/session/session_controller.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Branch order of the shell. The index of a path here is its branch index.
const List<String> shellBranches = [
  AppRoutes.home,
  AppRoutes.herd,
  AppRoutes.milk,
  AppRoutes.health,
  AppRoutes.more,
  AppRoutes.collect,
  AppRoutes.farmers,
  AppRoutes.pay,
  AppRoutes.feeding,
  AppRoutes.breeding,
  AppRoutes.workers,
  AppRoutes.money,
  AppRoutes.reports,
  AppRoutes.settings,
];

/// Sections that are not on the phone bottom bar: on phones they open from
/// More (push, back arrow); on wide screens they are root sections.
const List<String> moreSections = [
  AppRoutes.feeding,
  AppRoutes.breeding,
  AppRoutes.workers,
  AppRoutes.money,
  AppRoutes.reports,
  AppRoutes.settings,
];

class AppShell extends StatelessWidget {
  const new({required this.shell, required this.session, super.key});

  final StatefulNavigationShell shell;
  final SessionController session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final centre = session.isCentre;
    NavItem item(String path) => _item(l10n, path);
    final bottom = centre
        ? [AppRoutes.home, AppRoutes.collect, AppRoutes.farmers, AppRoutes.pay, AppRoutes.more]
        : [AppRoutes.home, AppRoutes.herd, AppRoutes.milk, AppRoutes.health, AppRoutes.more];
    final rail = centre
        ? [AppRoutes.home, AppRoutes.collect, AppRoutes.farmers, AppRoutes.pay, AppRoutes.workers, AppRoutes.more]
        : [
            AppRoutes.home,
            AppRoutes.herd,
            AppRoutes.milk,
            AppRoutes.collect,
            AppRoutes.health,
            AppRoutes.workers,
            AppRoutes.more,
          ];
    final sidebar = centre
        ? [
            AppRoutes.home,
            AppRoutes.collect,
            AppRoutes.farmers,
            AppRoutes.pay,
            AppRoutes.workers,
            AppRoutes.money,
            AppRoutes.reports,
            AppRoutes.settings,
          ]
        : [
            AppRoutes.home,
            AppRoutes.herd,
            AppRoutes.milk,
            AppRoutes.collect,
            AppRoutes.health,
            AppRoutes.feeding,
            AppRoutes.breeding,
            AppRoutes.workers,
            AppRoutes.money,
            AppRoutes.reports,
            AppRoutes.settings,
          ];
    final current = shellBranches[shell.currentIndex];
    final form = context.formFactor;
    final visible = switch (form) {
      FormFactor.compact => bottom,
      FormFactor.medium => rail,
      FormFactor.expanded => sidebar,
    };
    // A section that is not in the visible list belongs to More.
    final selected = visible.contains(current) ? current : AppRoutes.more;
    return NavigationScope(
      navigation: AdaptiveNavigation(
        items: [for (final p in bottom) item(p)],
        railItems: [for (final p in rail) item(p)],
        sidebarItems: [for (final p in sidebar) item(p)],
        selectedId: selected,
        onSelect: (path) {
          final index = shellBranches.indexOf(path);
          // Tapping the current tab again returns it to its root.
          shell.goBranch(index, initialLocation: index == shell.currentIndex);
        },
      ),
      child: shell,
    );
  }

  static NavItem _item(AppLocalizations l10n, String path) => switch (path) {
    AppRoutes.home => NavItem(id: path, icon: Symbols.home_rounded, label: l10n.home),
    AppRoutes.herd => NavItem(id: path, icon: Symbols.pets_rounded, label: l10n.herd),
    AppRoutes.milk => NavItem(id: path, icon: Symbols.water_drop_rounded, label: l10n.milk),
    AppRoutes.health => NavItem(id: path, icon: Symbols.medical_services_rounded, label: l10n.health),
    AppRoutes.more => NavItem(id: path, icon: Symbols.more_horiz_rounded, label: l10n.more),
    AppRoutes.collect => NavItem(id: path, icon: Symbols.contactless_rounded, label: l10n.collect),
    AppRoutes.farmers => NavItem(id: path, icon: Symbols.groups_rounded, label: l10n.farmers),
    AppRoutes.pay => NavItem(id: path, icon: Symbols.payments_rounded, label: l10n.pay),
    AppRoutes.feeding => NavItem(id: path, icon: Symbols.grass_rounded, label: l10n.feeding),
    AppRoutes.breeding => NavItem(id: path, icon: Symbols.favorite_rounded, label: l10n.breeding),
    AppRoutes.workers => NavItem(id: path, icon: Symbols.badge_rounded, label: l10n.workers),
    AppRoutes.money => NavItem(id: path, icon: Symbols.account_balance_wallet_rounded, label: l10n.money),
    AppRoutes.reports => NavItem(id: path, icon: Symbols.bar_chart_rounded, label: l10n.reports),
    _ => NavItem(id: path, icon: Symbols.settings_rounded, label: l10n.settings),
  };
}

/// Parent of a section root: on phones the More-sections are pushed from
/// More; everywhere else sections are roots.
String? sectionParent(BuildContext context, String path) =>
    context.isCompact && moreSections.contains(path) ? AppRoutes.more : null;
