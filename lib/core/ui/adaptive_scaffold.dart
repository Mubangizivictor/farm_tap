// The shell every screen sits in (UX_SPEC section 1):
//   compact  < 600   top bar + bottom navigation bar, 16 dp padding
//   medium   600-1023 navigation rail (96 dp), 24 dp padding
//   expanded >= 1024 sidebar (264 dp) with farm switcher, trial card and sync
//                    status; top bar with search; content max 1120 dp
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/avatars.dart';
import 'package:farm_tap/core/ui/status_banner.dart';
import 'package:flutter/material.dart';

class NavItem {
  const new({required this.id, required this.icon, required this.selectedIcon, required this.label});

  final String id;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// What the shell shows about the current farm in the sidebar switcher.
class FarmSwitcherInfo {
  const new({required this.name, required this.subtitle, this.photoUrl, this.onTap});

  final String name;

  /// "Mbarara · Owner".
  final String subtitle;
  final String? photoUrl;
  final VoidCallback? onTap;
}

class AdaptiveNavigation {
  const new({required this.items, required this.selectedId, required this.onSelect, this.sidebarItems});

  /// Bottom bar / rail destinations (5 on phones).
  final List<NavItem> items;

  /// All sections for the sidebar; defaults to [items].
  final List<NavItem>? sidebarItems;
  final String selectedId;
  final ValueChanged<String> onSelect;
}

class AdaptiveScaffold extends StatelessWidget {
  const new({
    required this.title,
    required this.body,
    super.key,
    this.subtitle,
    this.navigation,
    this.showBack = false,
    this.onBack,
    this.showLogo = false,
    this.floatingActionButton,
    this.actions = const [],
    this.farm,
    this.trialDaysLeft,
    this.onUpgrade,
    this.syncState = SyncState.synced,
    this.pendingCount = 0,
    this.onSyncTap,
    this.profileName,
    this.onProfileTap,
    this.hasNotifications = false,
    this.onNotificationsTap,
    this.onSearchChanged,
    this.padBody = true,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final AdaptiveNavigation? navigation;

  /// Back arrow on every non-root screen.
  final bool showBack;
  final VoidCallback? onBack;

  /// Logo instead of title in the compact top bar (Home).
  final bool showLogo;
  final Widget? floatingActionButton;

  /// Extra icon buttons in the top bar (scan QR, filter).
  final List<Widget> actions;
  final FarmSwitcherInfo? farm;
  final int? trialDaysLeft;
  final VoidCallback? onUpgrade;
  final SyncState syncState;
  final int pendingCount;
  final VoidCallback? onSyncTap;
  final String? profileName;
  final VoidCallback? onProfileTap;
  final bool hasNotifications;
  final VoidCallback? onNotificationsTap;
  final ValueChanged<String>? onSearchChanged;

  /// Apply screen padding and max width around [body].
  final bool padBody;

  @override
  Widget build(BuildContext context) {
    final form = context.formFactor;
    final nav = navigation;
    final content = _Content(padBody: padBody, form: form, child: body);
    final topBar = _TopBar(
      form: form,
      title: title,
      subtitle: subtitle,
      showBack: showBack,
      onBack: onBack,
      showLogo: showLogo,
      actions: actions,
      syncState: syncState,
      pendingCount: pendingCount,
      onSyncTap: onSyncTap,
      profileName: profileName,
      onProfileTap: onProfileTap,
      hasNotifications: hasNotifications,
      onNotificationsTap: onNotificationsTap,
      onSearchChanged: onSearchChanged,
    );
    final main = Scaffold(
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: form == FormFactor.compact && nav != null
          ? NavigationBar(
              selectedIndex: nav.items.indexWhere((e) => e.id == nav.selectedId).clamp(0, nav.items.length - 1),
              onDestinationSelected: (i) => nav.onSelect(nav.items[i].id),
              destinations: [
                for (final n in nav.items)
                  NavigationDestination(icon: Icon(n.icon), selectedIcon: Icon(n.selectedIcon), label: n.label),
              ],
            )
          : null,
      body: SafeArea(
        bottom: !(form == FormFactor.compact && nav != null),
        child: Column(
          children: [
            topBar,
            Expanded(child: content),
          ],
        ),
      ),
    );
    if (nav == null || form == FormFactor.compact) return main;
    if (form == FormFactor.medium) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              minWidth: context.sizes.railWidth,
              labelType: NavigationRailLabelType.all,
              selectedIndex: nav.items.indexWhere((e) => e.id == nav.selectedId).clamp(0, nav.items.length - 1),
              onDestinationSelected: (i) => nav.onSelect(nav.items[i].id),
              destinations: [
                for (final n in nav.items)
                  NavigationRailDestination(
                    icon: Icon(n.icon),
                    selectedIcon: Icon(n.selectedIcon),
                    label: Text(n.label),
                  ),
              ],
            ),
            VerticalDivider(width: context.sizes.divider),
            Expanded(child: main),
          ],
        ),
      );
    }
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            items: nav.sidebarItems ?? nav.items,
            selectedId: nav.selectedId,
            onSelect: nav.onSelect,
            farm: farm,
            trialDaysLeft: trialDaysLeft,
            onUpgrade: onUpgrade,
            syncState: syncState,
            pendingCount: pendingCount,
            onSyncTap: onSyncTap,
          ),
          VerticalDivider(width: context.sizes.divider),
          Expanded(child: main),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const new({required this.child, required this.padBody, required this.form});

  final Widget child;
  final bool padBody;
  final FormFactor form;

  @override
  Widget build(BuildContext context) {
    if (!padBody) return child;
    final pad = switch (form) {
      FormFactor.compact => context.space.lg,
      FormFactor.medium => context.space.xl,
      FormFactor.expanded => context.space.xxl,
    };
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.sizes.contentMaxWidth + pad * 2),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: pad),
          child: child,
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const new({
    required this.form,
    required this.title,
    required this.showBack,
    required this.showLogo,
    required this.actions,
    required this.syncState,
    required this.pendingCount,
    this.subtitle,
    this.onBack,
    this.onSyncTap,
    this.profileName,
    this.onProfileTap,
    this.hasNotifications = false,
    this.onNotificationsTap,
    this.onSearchChanged,
  });

  final FormFactor form;
  final String title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final bool showLogo;
  final List<Widget> actions;
  final SyncState syncState;
  final int pendingCount;
  final VoidCallback? onSyncTap;
  final String? profileName;
  final VoidCallback? onProfileTap;
  final bool hasNotifications;
  final VoidCallback? onNotificationsTap;
  final ValueChanged<String>? onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final wide = form == FormFactor.expanded;
    final pad = switch (form) {
      FormFactor.compact => context.space.lg,
      FormFactor.medium => context.space.xl,
      FormFactor.expanded => context.space.xxl,
    };
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: (wide ? context.text.headlineSmall : context.text.titleLarge)?.copyWith(
            fontWeight: FarmTapWeights.bold,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
          ),
      ],
    );
    final bar = Container(
      constraints: BoxConstraints(minHeight: context.sizes.appBarHeight),
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: context.space.sm),
      decoration: wide
          ? BoxDecoration(
              border: Border(bottom: BorderSide(color: context.colors.outlineVariant)),
            )
          : null,
      child: Row(
        children: [
          if (showBack)
            Padding(
              padding: EdgeInsets.only(right: context.space.sm),
              child: IconButton(
                onPressed: onBack ?? () => Navigator.maybePop(context),
                tooltip: l10n.back,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
          if (showLogo && !wide)
            Image.asset(
              FarmTapAssets.byBrightness(context, FarmTapAssets.appBarLogoLight, FarmTapAssets.appBarLogoDark),
              height: context.sizes.appBarLogoHeight,
              semanticLabel: l10n.appName,
            )
          else
            Expanded(child: titleBlock),
          if (showLogo && !wide) const Spacer(),
          if (wide) ...[
            const Spacer(),
            SizedBox(
              width: context.sizes.searchFieldWidth,
              child: TextField(
                onChanged: onSearchChanged,
                decoration: InputDecoration(hintText: l10n.searchHint, prefixIcon: const Icon(Icons.search_rounded)),
              ),
            ),
            context.space.gapSm,
          ],
          ...actions,
          if (wide)
            IconButton(
              onPressed: onNotificationsTap,
              tooltip: l10n.notifications,
              icon: Badge(isLabelVisible: hasNotifications, child: const Icon(Icons.notifications_none_rounded)),
            )
          else
            SyncBadge(state: syncState, pending: pendingCount, onTap: onSyncTap),
          if (profileName != null) ...[context.space.gapSm, PersonAvatar(name: profileName!, onTap: onProfileTap)],
        ],
      ),
    );
    return bar;
  }
}

class _Sidebar extends StatelessWidget {
  const new({
    required this.items,
    required this.selectedId,
    required this.onSelect,
    required this.syncState,
    required this.pendingCount,
    this.farm,
    this.trialDaysLeft,
    this.onUpgrade,
    this.onSyncTap,
  });

  final List<NavItem> items;
  final String selectedId;
  final ValueChanged<String> onSelect;
  final FarmSwitcherInfo? farm;
  final int? trialDaysLeft;
  final VoidCallback? onUpgrade;
  final SyncState syncState;
  final int pendingCount;
  final VoidCallback? onSyncTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: context.sizes.sidebarWidth,
      child: ColoredBox(
        color: context.colors.surface,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(context.space.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.all(context.space.sm),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Image.asset(
                      FarmTapAssets.byBrightness(context, FarmTapAssets.appBarLogoLight, FarmTapAssets.appBarLogoDark),
                      height: context.sizes.appBarLogoHeight,
                      semanticLabel: l10n.appName,
                    ),
                  ),
                ),
                context.space.gapSm,
                if (farm != null) ...[_FarmSwitcher(farm: farm!), context.space.gapSm],
                Expanded(
                  child: ListView(
                    children: [
                      for (final n in items)
                        _SidebarItem(item: n, selected: n.id == selectedId, onTap: () => onSelect(n.id)),
                    ],
                  ),
                ),
                if (trialDaysLeft != null) ...[
                  TrialCard(daysLeft: trialDaysLeft!, onUpgrade: onUpgrade),
                  context.space.gapSm,
                ],
                SyncBadge(state: syncState, pending: pendingCount, onTap: onSyncTap, showLabel: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FarmSwitcher extends StatelessWidget {
  const new({required this.farm});

  final FarmSwitcherInfo farm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: '${l10n.switchFarm}: ${farm.name}',
      excludeSemantics: true,
      child: Material(
        color: context.colors.surfaceContainerLowest,
        shape: context.radii.cardShape.copyWith(side: BorderSide(color: context.colors.outlineVariant)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: farm.onTap,
          child: Padding(
            padding: EdgeInsets.all(context.space.sm),
            child: Row(
              children: [
                CowAvatar(photoUrl: farm.photoUrl, size: context.sizes.avatarMd),
                context.space.gapSm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        farm.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleSmall?.copyWith(fontWeight: FarmTapWeights.bold),
                      ),
                      Text(
                        farm.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.expand_more_rounded, color: context.colors.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const new({required this.item, required this.selected, required this.onTap});

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? context.colors.onPrimaryContainer : context.colors.onSurfaceVariant;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.space.xxs),
      child: Semantics(
        selected: selected,
        button: true,
        label: item.label,
        excludeSemantics: true,
        child: Material(
          color: selected ? context.colors.primaryContainer : Colors.transparent,
          borderRadius: context.radii.button,
          child: InkWell(
            borderRadius: context.radii.button,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: context.sizes.touchTarget),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: context.space.md),
                child: Row(
                  children: [
                    Icon(selected ? item.selectedIcon : item.icon, color: color, size: context.sizes.iconMd),
                    context.space.gapMd,
                    Expanded(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleSmall?.copyWith(
                          color: selected ? context.colors.onPrimaryContainer : context.colors.onSurface,
                          fontWeight: selected ? FarmTapWeights.bold : FarmTapWeights.medium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
