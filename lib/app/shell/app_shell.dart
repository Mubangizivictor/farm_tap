// The tab shell: one StatefulShellRoute.indexedStack branch per section, each
// with its own back stack and scroll position (docs/design/ROUTES.md).
import 'package:farm_tap/app/router/routes.dart';
import 'package:farm_tap/app/session/session_controller.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/people/domain/staff_member.dart';
import 'package:farm_tap/core/people/domain/staff_permissions.dart';
import 'package:farm_tap/core/sync/presentation/sync_status_sheet.dart';
import 'package:farm_tap/core/sync/sync_service.dart';
import 'package:farm_tap/core/tenancy/domain/farm_membership.dart';
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
  AppRoutes.me,
];

/// The section a path belongs to, for role checks (decision 0016 §7).
AppSection? sectionOf(String location) {
  for (final (path, section) in const [
    (AppRoutes.home, AppSection.home),
    (AppRoutes.herd, AppSection.herd),
    (AppRoutes.milk, AppSection.milk),
    (AppRoutes.health, AppSection.health),
    (AppRoutes.feeding, AppSection.feeding),
    (AppRoutes.breeding, AppSection.breeding),
    (AppRoutes.collect, AppSection.collect),
    (AppRoutes.farmers, AppSection.farmers),
    (AppRoutes.pay, AppSection.pay),
    (AppRoutes.workers, AppSection.workers),
    (AppRoutes.money, AppSection.money),
    (AppRoutes.reports, AppSection.reports),
    (AppRoutes.settings, AppSection.settings),
    (AppRoutes.me, AppSection.me),
  ]) {
    if (location == path || location.startsWith('$path/')) return section;
  }
  return null;
}

/// Shell paths a role may open; null = everything (owner / manager).
Set<String>? allowedPaths(StaffRole? role) {
  if (StaffPermissions.managesStaff(role)) return null;
  final sections = StaffPermissions.sections(role);
  return {
    for (final p in shellBranches)
      if (sectionOf(p) case final s? when sections.contains(s)) p,
    AppRoutes.more,
  };
}

/// Sections that are not on the phone bottom bar: on phones they open from
/// More (push, back arrow); on wide screens they are root sections.
const List<String> moreSections = [
  AppRoutes.feeding,
  AppRoutes.breeding,
  AppRoutes.workers,
  AppRoutes.money,
  AppRoutes.reports,
  AppRoutes.settings,
  AppRoutes.me,
];

class AppShell extends StatelessWidget {
  const new({required this.shell, required this.session, required this.sync, super.key});

  final StatefulNavigationShell shell;
  final SessionController session;
  final SyncService sync;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final navigation0 = shellNavigation(
      l10n,
      context.formFactor,
      current: shellBranches[shell.currentIndex],
      centre: session.isCentre,
      allowed: allowedPaths(session.staff?.role),
      onSelect: (path) {
        final index = shellBranches.indexOf(path);
        // Tapping the current tab again returns it to its root.
        shell.goBranch(index, initialLocation: index == shell.currentIndex);
      },
    );
    final farm = session.farm;
    final role = switch (farm?.role) {
      PlaceRole.owner => l10n.roleOwner,
      PlaceRole.manager => l10n.roleManager,
      PlaceRole.clerk => l10n.roleClerk,
      PlaceRole.worker => l10n.roleWorker,
      null => '',
    };
    final navigation = NavigationScope(navigation: navigation0, child: shell);
    return StreamBuilder<SyncSnapshot>(
      stream: sync.watch(),
      initialData: sync.current,
      builder: (context, snapshot) {
        final s = snapshot.data!;
        return ShellStatus(
          online: s.online,
          syncState: s.failed > 0
              ? SyncState.failed
              : s.waiting > 0
              ? SyncState.pending
              : SyncState.synced,
          pending: s.waiting,
          onSyncTap: () => showSyncStatusSheet(context, sync),
          profileName: session.staff?.name ?? session.auth.currentUser?.name,
          // The staff avatar locks the farm phone (back to C01 tap card); a
          // worker signed in on their own phone goes to My page instead.
          onProfileTap: () {
            if (session.staffLogin) {
              GoRouter.of(context).go(AppRoutes.me);
              return;
            }
            session.lock();
            GoRouter.of(context).go(AppRoutes.unlock);
          },
          farm: farm == null ? null : FarmSwitcherInfo(name: farm.name, subtitle: l10n.farmRoleLine(farm.place, role)),
          trialDaysLeft: session.trialDaysLeft,
          hasNotifications: true,
          onNotificationsTap: () => GoRouter.of(context).push(AppRoutes.homeAlerts),
          child: navigation,
        );
      },
    );
  }
}

/// Bottom bar / rail / sidebar items for a farm or a collection centre, with
/// [current] selected (a More-section highlights More where it is hidden).
AdaptiveNavigation shellNavigation(
  AppLocalizations l10n,
  FormFactor form, {
  required String current,
  required ValueChanged<String> onSelect,
  bool centre = false,
  Set<String>? allowed,
}) {
  NavItem item(String path) => _item(l10n, path);
  // A worker sees only their sections (decision 0016 §7); My page joins
  // the bar when there is room.
  List<String> only(List<String> paths, {int? max}) {
    if (allowed == null) return paths;
    final kept = [
      for (final p in paths)
        if (allowed.contains(p) && p != AppRoutes.more) p,
    ];
    for (final p in [
      AppRoutes.herd,
      AppRoutes.milk,
      AppRoutes.collect,
      AppRoutes.health,
      AppRoutes.farmers,
      AppRoutes.feeding,
      AppRoutes.breeding,
      AppRoutes.me,
    ]) {
      if (max != null && kept.length >= max) break;
      if (allowed.contains(p) && !kept.contains(p)) kept.add(p);
    }
    return [...kept, AppRoutes.more];
  }

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
  final bottomShown = only(bottom, max: 4);
  final railShown = only(rail, max: 6);
  final sidebarShown = only(sidebar);
  final visible = switch (form) {
    FormFactor.compact => bottomShown,
    FormFactor.medium => railShown,
    FormFactor.expanded => sidebarShown,
  };
  return AdaptiveNavigation(
    items: [for (final p in bottomShown) item(p)],
    railItems: [for (final p in railShown) item(p)],
    sidebarItems: [for (final p in sidebarShown) item(p)],
    selectedId: visible.contains(current) ? current : AppRoutes.more,
    onSelect: onSelect,
  );
}

NavItem _item(AppLocalizations l10n, String path) => switch (path) {
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
  AppRoutes.me => NavItem(id: path, icon: Symbols.badge_rounded, label: l10n.myPageShort),
  _ => NavItem(id: path, icon: Symbols.settings_rounded, label: l10n.settings),
};

/// The section name as on the nav bar (Workers).
String sectionLabel(AppLocalizations l10n, String path) => _item(l10n, path).label;

/// Parent of a section root: on phones the More-sections are pushed from
/// More; everywhere else sections are roots.
String? sectionParent(BuildContext context, String path) =>
    context.isCompact && moreSections.contains(path) ? AppRoutes.more : null;
