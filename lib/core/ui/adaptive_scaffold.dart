// The shell every screen sits in (UX_SPEC section 1, rebuild prompt 4.1):
//   compact  < 600   app bar 64 + bottom bar 80 (or hamburger on web), 16 padding
//   medium   600-1023 navigation rail 96, app bar 64, 24 padding
//   expanded >= 1024 sidebar 264 (farm switcher, trial card, sync row),
//                    top bar 76 with search, content max 1120
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/avatars.dart';
import 'package:farm_tap/core/ui/controls.dart';
import 'package:farm_tap/core/ui/farmtap_loader.dart';
import 'package:farm_tap/core/ui/navigation_scope.dart';
import 'package:farm_tap/core/ui/status_banner.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class NavItem {
  const new({required this.id, required this.icon, required this.label});

  final String id;

  /// A Material Symbols icon; drawn filled when selected.
  final IconData icon;
  final String label;
}

/// What the shell shows about the current farm in the sidebar switcher.
class FarmSwitcherInfo {
  const new({required this.name, required this.subtitle, this.avatarIndex = 1, this.photoUrl, this.onTap});

  final String name;

  /// "Mbarara · Owner".
  final String subtitle;
  final int avatarIndex;
  final String? photoUrl;
  final VoidCallback? onTap;
}

class AdaptiveNavigation {
  const new({required this.items, required this.selectedId, required this.onSelect, this.railItems, this.sidebarItems});

  /// Bottom bar destinations (5).
  final List<NavItem> items;

  /// Rail destinations (7 on tablet); defaults to [items].
  final List<NavItem>? railItems;

  /// Sidebar destinations (all sections); defaults to [items].
  final List<NavItem>? sidebarItems;
  final String selectedId;
  final ValueChanged<String> onSelect;
}

/// Extended FAB: 64 tall, radius 20, primary, icon 28, `button` label.
class FarmTapFab extends StatelessWidget {
  const new({required this.label, required this.icon, required this.onPressed, super.key});

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => FloatingActionButton.extended(
    // No hero flight: with shell branches and pushed pages several FABs can
    // sit in one route subtree, and a shared default tag throws.
    heroTag: null,
    onPressed: onPressed,
    icon: Icon(icon, size: context.sizes.iconLg),
    label: Text(label),
  );
}

class AdaptiveScaffold extends StatelessWidget {
  const new({
    required this.body,
    super.key,
    this.title,
    this.subtitle,
    this.navigation,
    this.showBack = false,
    this.onBack,
    this.backFallback,
    this.showLogo = false,
    this.showMenu = false,
    this.floatingActionButton,
    this.actions = const [],
    this.farm,
    this.trialDaysLeft,
    this.onUpgrade,
    this.syncState,
    this.showSync = true,
    this.pendingCount,
    this.onSyncTap,
    this.profileName,
    this.onProfileTap,
    this.hasNotifications = false,
    this.onNotificationsTap,
    this.onSearchChanged,
    this.padBody = true,
    this.scrollable = true,
    this.onRefresh,
    this.showNavigation = true,
  });

  /// Keys of the three navigation forms (for tests).
  static const ValueKey<String> bottomBarKey = ValueKey('farmtap-bottom-bar');
  static const ValueKey<String> railKey = ValueKey('farmtap-rail');
  static const ValueKey<String> sidebarKey = ValueKey('farmtap-sidebar');

  final String? title;
  final String? subtitle;
  final Widget body;
  final AdaptiveNavigation? navigation;

  /// Back arrow on every non-root screen.
  final bool showBack;
  final VoidCallback? onBack;

  /// Parent route used by the back arrow when there is nothing to pop.
  final String? backFallback;

  /// Logo instead of the title in the compact app bar (Home).
  final bool showLogo;

  /// Hamburger (web mobile root screens): opens the sidebar as a drawer.
  final bool showMenu;
  final Widget? floatingActionButton;

  /// Extra icon buttons in the app bar (scan QR, filter).
  final List<Widget> actions;
  final FarmSwitcherInfo? farm;
  final int? trialDaysLeft;
  final VoidCallback? onUpgrade;
  final SyncState? syncState;
  final bool showSync;
  final int? pendingCount;
  final VoidCallback? onSyncTap;

  /// Staff avatar (initials) at the right of the app bar.
  final String? profileName;
  final VoidCallback? onProfileTap;
  final bool hasNotifications;
  final VoidCallback? onNotificationsTap;
  final ValueChanged<String>? onSearchChanged;

  /// Apply content padding and the 1120 max width around [body].
  final bool padBody;

  /// Wrap [body] in a scroll view (set false for lists that scroll themselves).
  final bool scrollable;

  /// Pull to refresh (Home: syncs).
  final RefreshCallback? onRefresh;

  /// False hides the phone bottom bar (full-screen tasks: add animal, scan).
  /// The rail and sidebar stay on wider screens.
  final bool showNavigation;

  @override
  Widget build(BuildContext context) {
    final form = context.formFactor;
    final nav = navigation ?? NavigationScope.maybeOf(context);
    final shell = ShellStatus.maybeOf(context);
    final syncState = this.syncState ?? shell?.syncState ?? SyncState.synced;
    final pendingCount = this.pendingCount ?? shell?.pending ?? 0;
    final onSyncTap = this.onSyncTap ?? shell?.onSyncTap;
    final profileName = this.profileName ?? shell?.profileName;
    final onProfileTap = this.onProfileTap ?? shell?.onProfileTap;
    final farm = this.farm ?? shell?.farm;
    final trialDaysLeft = this.trialDaysLeft ?? shell?.trialDaysLeft;
    final onUpgrade = this.onUpgrade ?? shell?.onUpgrade;
    final hasNotifications = this.hasNotifications || (shell?.hasNotifications ?? false);
    final onNotificationsTap = this.onNotificationsTap ?? shell?.onNotificationsTap;
    // Offline: no cloud icon in the bar; the page shows the offline banner.
    final showSync = this.showSync && (shell?.online ?? true);
    final route = RouteInfo.maybeOf(context);
    final parent = backFallback ?? route?.parent;
    final hasBack = showBack || route?.parent != null;
    final back = onBack ?? () => backOrGo(context, parent);
    final sidebar = nav == null
        ? null
        : _Sidebar(
            key: AdaptiveScaffold.sidebarKey,
            items: nav.sidebarItems ?? nav.items,
            selectedId: nav.selectedId,
            onSelect: nav.onSelect,
            farm: farm,
            trialDaysLeft: trialDaysLeft,
            onUpgrade: onUpgrade,
            syncState: syncState,
            pendingCount: pendingCount,
            onSyncTap: onSyncTap,
          );
    final useDrawer = form == FormFactor.compact && showMenu && sidebar != null;
    // Decision 0013: tab roots on phones and tablets get the brand bar (farm + role,
    // sync, alerts, profile) and the page title moves to a header under it.
    final brand = form != FormFactor.expanded && !hasBack && !useDrawer && farm != null && (showLogo || title != null);
    final showBottomBar = form == FormFactor.compact && nav != null && !useDrawer && showNavigation;
    final topBar = form == FormFactor.expanded
        ? _WideTopBar(
            title: title,
            subtitle: subtitle,
            showBack: hasBack,
            onBack: back,
            actions: actions,
            profileName: profileName,
            onProfileTap: onProfileTap,
            hasNotifications: hasNotifications,
            onNotificationsTap: onNotificationsTap,
            onSearchChanged: onSearchChanged,
          )
        : brand
        ? _BrandBar(
            farm: farm,
            showSync: showSync,
            syncState: syncState,
            pendingCount: pendingCount,
            onSyncTap: onSyncTap,
            hasNotifications: hasNotifications,
            onNotificationsTap: onNotificationsTap,
            profileName: profileName,
            onProfileTap: onProfileTap,
          )
        : _AppBar(
            title: title,
            subtitle: subtitle,
            showBack: hasBack,
            onBack: back,
            showLogo: showLogo,
            showMenu: useDrawer,
            actions: actions,
            showSync: showSync,
            syncState: syncState,
            pendingCount: pendingCount,
            onSyncTap: onSyncTap,
            profileName: form == FormFactor.compact ? profileName : null,
            onProfileTap: onProfileTap,
          );
    final content = _Content(padBody: padBody, scrollable: scrollable, form: form, onRefresh: onRefresh, child: body);
    final main = Scaffold(
      drawer: useDrawer ? Drawer(width: context.sizes.sidebarWidth, child: sidebar) : null,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: form == FormFactor.compact
          ? FloatingActionButtonLocation.endFloat
          : _InsetFabLocation(right: context.space.xxxl - context.space.sm, bottom: context.space.xxl),
      bottomNavigationBar: showBottomBar
          ? _BottomBar(
              key: AdaptiveScaffold.bottomBarKey,
              items: nav.items,
              selectedId: nav.selectedId,
              onSelect: nav.onSelect,
            )
          : null,
      body: SafeArea(
        bottom: !showBottomBar,
        child: Column(
          children: [
            topBar,
            if (brand && title != null && !showLogo) PageHeader(title: title!, subtitle: subtitle, actions: actions),
            Expanded(child: content),
          ],
        ),
      ),
    );
    if (nav == null || form == FormFactor.compact) return main;
    final rail = form == FormFactor.medium
        ? _Rail(
            key: AdaptiveScaffold.railKey,
            items: nav.railItems ?? nav.items,
            selectedId: nav.selectedId,
            onSelect: nav.onSelect,
            profileName: profileName,
            onProfileTap: onProfileTap,
          )
        : sidebar!;
    return Scaffold(
      body: Row(
        children: [
          rail,
          Expanded(child: main),
        ],
      ),
    );
  }
}

class _InsetFabLocation extends FloatingActionButtonLocation {
  const new({required this.right, required this.bottom});

  final double right;
  final double bottom;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry g) => Offset(
    g.scaffoldSize.width - g.floatingActionButtonSize.width - right,
    g.contentBottom - g.floatingActionButtonSize.height - bottom,
  );
}

class _Content extends StatelessWidget {
  const new({required this.child, required this.padBody, required this.scrollable, required this.form, this.onRefresh});

  final Widget child;
  final bool padBody;
  final bool scrollable;
  final FormFactor form;
  final RefreshCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    if (!padBody) return child;
    // Every padded page can be pulled to refresh: its own refresh, or the app-wide one (sync).
    final refresh = onRefresh ?? FarmTapRefresh.of(context);
    final padding = context.space.content(form);
    // Leave room under the last item for the FAB.
    final bottom = padding.bottom + context.sizes.fab + context.space.lg;
    final framed = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.sizes.contentMaxWidth + padding.horizontal),
        child: Padding(
          padding: scrollable ? padding.copyWith(bottom: bottom) : padding,
          child: child,
        ),
      ),
    );
    if (!scrollable) {
      // The page scrolls its own list: refresh when that list is pulled down at the top.
      return refresh == null ? framed : _LogoRefresh(onRefresh: refresh, anyDepth: true, child: framed);
    }
    if (refresh == null) return SingleChildScrollView(child: framed);
    return _LogoRefresh(
      onRefresh: refresh,
      child: SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), child: framed),
    );
  }
}

/// The app-wide refresh (a sync with the server), provided once above every
/// screen (app.dart). Pages without their own refresh use it for pull-to-refresh.
class FarmTapRefresh extends InheritedWidget {
  const new({required this.onRefresh, required super.child, super.key});

  final RefreshCallback onRefresh;

  static RefreshCallback? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FarmTapRefresh>()?.onRefresh;

  @override
  bool updateShouldNotify(FarmTapRefresh oldWidget) => oldWidget.onRefresh != onRefresh;
}

/// Shortest time the refresh logo shows, so a quick refresh is still seen (1.5 s).
const _refreshMin = Duration(milliseconds: 1500); // theme-guard: ignore

/// Pull to refresh with the FarmTap loader at the top instead of the
/// Material spinner. The logo stays at least 1.5 seconds.
class _LogoRefresh extends StatefulWidget {
  const new({required this.onRefresh, required this.child, this.anyDepth = false});

  final RefreshCallback onRefresh;
  final Widget child;

  /// Listen to a scrolling list anywhere inside (pages that scroll their own list).
  final bool anyDepth;

  @override
  State<_LogoRefresh> createState() => _LogoRefreshState();
}

class _LogoRefreshState extends State<_LogoRefresh> {
  RefreshIndicatorStatus? _status;

  @override
  Widget build(BuildContext context) {
    final showing = switch (_status) {
      RefreshIndicatorStatus.armed || RefreshIndicatorStatus.snap || RefreshIndicatorStatus.refresh => true,
      _ => false,
    };
    return Stack(
      children: [
        RefreshIndicator.noSpinner(
          onRefresh: () async {
            await Future.wait<void>([widget.onRefresh(), Future<void>.delayed(_refreshMin)]);
          },
          notificationPredicate: widget.anyDepth
              ? (n) => n.metrics.axis == Axis.vertical
              : defaultScrollNotificationPredicate,
          onStatusChange: (s) {
            if (mounted && s != _status) setState(() => _status = s);
          },
          child: widget.child,
        ),
        if (showing)
          Positioned(
            top: context.space.md,
            left: 0,
            right: 0,
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerLowest,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.colors.outlineVariant, width: context.sizes.borderThin),
                ),
                child: Padding(
                  padding: EdgeInsets.all(context.space.sm),
                  child: FarmTapLoader(size: context.sizes.iconXl),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------- compact/medium

/// Phone tab roots (decision 0013): logo mark, farm name over "place · role",
/// then sync, alerts and the profile avatar.
class _BrandBar extends StatelessWidget {
  const new({
    required this.farm,
    required this.showSync,
    required this.syncState,
    required this.pendingCount,
    required this.hasNotifications,
    this.onSyncTap,
    this.onNotificationsTap,
    this.profileName,
    this.onProfileTap,
  });

  final FarmSwitcherInfo farm;
  final bool showSync;
  final SyncState syncState;
  final int pendingCount;
  final VoidCallback? onSyncTap;
  final bool hasNotifications;
  final VoidCallback? onNotificationsTap;
  final String? profileName;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final side = context.space.side(context.formFactor);
    return Container(
      height: context.sizes.appBarHeight,
      padding: EdgeInsets.symmetric(horizontal: side),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.colors.outlineVariant, width: context.sizes.borderThin),
        ),
      ),
      child: Row(
        children: [
          // The rail already shows the mark on tablets.
          if (context.formFactor == FormFactor.compact) ...[const FarmTapLogoMark(), context.space.gapMd],
          Expanded(
            child: InkWell(
              onTap: farm.onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(farm.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleSmall),
                  Text(farm.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
                ],
              ),
            ),
          ),
          if (showSync) SyncBadge(state: syncState, pending: pendingCount, onTap: onSyncTap),
          if (onNotificationsTap != null)
            BarAction(
              icon: Symbols.notifications_rounded,
              tooltip: l10n.alerts,
              badge: hasNotifications,
              onPressed: onNotificationsTap,
            ),
          if (profileName != null && context.formFactor == FormFactor.compact) ...[
            context.space.gapSm,
            PersonAvatar(name: profileName!, ring: true, size: context.sizes.avatarXs, onTap: onProfileTap),
          ],
        ],
      ),
    );
  }
}

/// Page title (18) and one-line subtitle under the brand bar, with the
/// page's own actions on the right (decision 0013).
class PageHeader extends StatelessWidget {
  const new({required this.title, super.key, this.subtitle, this.actions = const []});

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final side = context.space.side(context.formFactor);
    return Padding(
      padding: EdgeInsets.fromLTRB(side, context.space.md, side - context.space.xs, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleLarge),
                if (subtitle != null)
                  Text(subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
              ],
            ),
          ),
          for (final a in actions) a,
        ],
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  const new({
    required this.showBack,
    required this.showLogo,
    required this.showMenu,
    required this.actions,
    required this.showSync,
    required this.syncState,
    required this.pendingCount,
    this.title,
    this.subtitle,
    this.onBack,
    this.onSyncTap,
    this.profileName,
    this.onProfileTap,
  });

  final String? title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final bool showLogo;
  final bool showMenu;
  final List<Widget> actions;
  final bool showSync;
  final SyncState syncState;
  final int pendingCount;
  final VoidCallback? onSyncTap;
  final String? profileName;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final side = context.space.side(context.formFactor);
    Widget? leading;
    if (showBack) {
      leading = _BarIcon(
        icon: Symbols.arrow_back_rounded,
        tooltip: l10n.back,
        onPressed: onBack ?? () => Navigator.maybePop(context),
      );
    } else if (showMenu) {
      leading = Builder(
        builder: (context) => _BarIcon(
          icon: Symbols.menu_rounded,
          tooltip: l10n.menu,
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      );
    }
    return Container(
      height: context.sizes.appBarHeight,
      padding: EdgeInsets.only(left: side - (leading == null ? 0 : context.space.sm), right: side),
      child: Row(
        children: [
          if (leading != null) ...[leading, context.space.gapSm],
          if (showLogo)
            const Expanded(
              child: Align(alignment: Alignment.centerLeft, child: FarmTapLogo()),
            )
          else
            Expanded(
              child: _TitleBlock(title: title, subtitle: subtitle, wide: false),
            ),
          for (final a in actions) a,
          if (showSync) SyncBadge(state: syncState, pending: pendingCount, onTap: onSyncTap),
          if (profileName != null) ...[
            context.space.gapLg,
            PersonAvatar(name: profileName!, ring: true, onTap: onProfileTap),
          ],
        ],
      ),
    );
  }
}

/// 28 dp icon button for app bars, 44 apart.
class _BarIcon extends StatelessWidget {
  const new({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    tooltip: tooltip,
    icon: Icon(icon, size: context.sizes.iconLg),
  );
}

/// App-bar action: 28 dp icon in a 44 wide touch area.
class BarAction extends StatelessWidget {
  const new({required this.icon, required this.tooltip, required this.onPressed, super.key, this.badge = false});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  /// Small red dot (notifications).
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: context.sizes.bubbleMd,
      height: context.sizes.touchTarget,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        icon: Badge(
          isLabelVisible: badge,
          smallSize: context.sizes.notificationDot * 2,
          backgroundColor: context.status.danger,
          child: Icon(icon, size: context.sizes.iconLg, color: context.colors.onSurface),
        ),
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const new({required this.title, required this.subtitle, required this.wide});

  final String? title;
  final String? subtitle;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    if (title == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: wide ? context.text.headlineSmall : context.text.titleLarge,
        ),
        if (subtitle != null)
          Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
      ],
    );
  }
}

/// Logo: mark + "Farm" (regular) + "Tap" (bold, primary). Uses the brand
/// image so the mark matches exactly.
class FarmTapLogo extends StatelessWidget {
  const new({super.key, this.height});

  final double? height;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Image.asset(
      FarmTapAssets.byBrightness(context, FarmTapAssets.appBarLogoLight, FarmTapAssets.appBarLogoDark),
      height: height ?? context.sizes.appBarLogoHeight,
      // contain, not the default scaleDown: the 1x asset must grow to the height.
      fit: BoxFit.contain,
      semanticLabel: l10n.appName,
    );
  }
}

/// The logo mark alone (rail, brand panel).
class FarmTapLogoMark extends StatelessWidget {
  const new({super.key, this.size, this.onPrimary = false});

  final double? size;

  /// White mark for the green brand panel.
  final bool onPrimary;

  @override
  Widget build(BuildContext context) {
    final asset = onPrimary
        ? FarmTapAssets.logoMarkWhite
        : FarmTapAssets.byBrightness(context, FarmTapAssets.logoMarkLight, FarmTapAssets.logoMarkDark);
    final s = size ?? context.sizes.logoMark;
    return Image.asset(asset, width: s, height: s, fit: BoxFit.contain, excludeFromSemantics: true);
  }
}

class _BottomBar extends StatelessWidget {
  const new({required this.items, required this.selectedId, required this.onSelect, super.key});

  final List<NavItem> items;
  final String selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Material(
      color: context.colors.surfaceContainer,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SizedBox(
          height: context.sizes.navBarHeight,
          child: Row(
            children: [
              for (final n in items)
                Expanded(
                  child: _NavDestination(
                    item: n,
                    selected: n.id == selectedId,
                    onTap: () => onSelect(n.id),
                    indicatorHeight: context.sizes.navIndicatorHeight,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Indicator pill (64 wide) with icon 28, label labelSmall underneath.
class _NavDestination extends StatelessWidget {
  const new({required this.item, required this.selected, required this.onTap, required this.indicatorHeight});

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;
  final double indicatorHeight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        highlightShape: BoxShape.rectangle,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: context.motion.fast,
              width: context.sizes.navIndicatorWidth,
              height: indicatorHeight,
              decoration: BoxDecoration(
                color: selected ? c.primaryContainer : Colors.transparent,
                borderRadius: context.radii.badge,
              ),
              child: Icon(
                item.icon,
                fill: selected ? 1 : 0,
                size: context.sizes.iconLg,
                color: selected ? c.onPrimaryContainer : c.onSurfaceVariant,
              ),
            ),
            context.space.gapXs,
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: selected
                  ? context.text.labelSmall?.copyWith(color: c.onSurface, fontWeight: FarmTapWeights.semiBold)
                  : context.text.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const new({
    required this.items,
    required this.selectedId,
    required this.onSelect,
    super.key,
    this.profileName,
    this.onProfileTap,
  });

  final List<NavItem> items;
  final String selectedId;
  final ValueChanged<String> onSelect;
  final String? profileName;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.sizes.railWidth,
      color: context.colors.surfaceContainerLow,
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            SizedBox(height: context.space.lg + context.space.xs),
            FarmTapLogoMark(size: context.sizes.logoMarkRail),
            SizedBox(height: context.space.xxl - context.space.xs),
            for (final n in items)
              SizedBox(
                height: context.sizes.railItemPitch,
                child: _NavDestination(
                  item: n,
                  selected: n.id == selectedId,
                  onTap: () => onSelect(n.id),
                  indicatorHeight: context.sizes.railIndicatorHeight,
                ),
              ),
            const Spacer(),
            if (profileName != null)
              Padding(
                padding: EdgeInsets.only(bottom: context.space.xl),
                child: PersonAvatar(name: profileName!, ring: true, onTap: onProfileTap),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- expanded

class _WideTopBar extends StatelessWidget {
  const new({
    required this.showBack,
    required this.actions,
    required this.hasNotifications,
    this.title,
    this.subtitle,
    this.onBack,
    this.profileName,
    this.onProfileTap,
    this.onNotificationsTap,
    this.onSearchChanged,
  });

  final String? title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final String? profileName;
  final VoidCallback? onProfileTap;
  final bool hasNotifications;
  final VoidCallback? onNotificationsTap;
  final ValueChanged<String>? onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: context.sizes.topBarWide,
      padding: EdgeInsets.symmetric(horizontal: context.space.xxl),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.colors.outlineVariant, width: context.sizes.borderThin),
        ),
      ),
      child: Row(
        children: [
          if (showBack) ...[
            _BarIcon(
              icon: Symbols.arrow_back_rounded,
              tooltip: l10n.back,
              onPressed: onBack ?? () => Navigator.maybePop(context),
            ),
            context.space.gapSm,
          ],
          Expanded(
            child: _TitleBlock(title: title, subtitle: subtitle, wide: true),
          ),
          for (final a in actions) a,
          if (actions.isNotEmpty) context.space.gapLg,
          SizedBox(
            width: context.sizes.searchPillWidth,
            child: SearchField(onChanged: onSearchChanged, compactHeight: true),
          ),
          context.space.gapLg,
          BarAction(
            icon: Symbols.notifications_rounded,
            tooltip: l10n.notifications,
            onPressed: onNotificationsTap,
            badge: hasNotifications,
          ),
          if (profileName != null) ...[
            context.space.gapLg,
            PersonAvatar(name: profileName!, ring: true, onTap: onProfileTap),
          ],
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const new({
    required this.items,
    required this.selectedId,
    required this.onSelect,
    required this.syncState,
    required this.pendingCount,
    super.key,
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
    final pad = context.space.md + context.space.xxs * 2; // 16
    return Container(
      width: context.sizes.sidebarWidth,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        border: Border(
          right: BorderSide(color: context.colors.outlineVariant, width: context.sizes.borderThin),
        ),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(context.space.xl, context.space.lg + context.space.xs, 0, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FarmTapLogo(height: context.sizes.sidebarLogoHeight),
              ),
            ),
            SizedBox(height: context.space.lg + context.space.xs),
            if (farm != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: pad),
                child: _FarmSwitcher(farm: farm!),
              ),
            context.space.gapLg,
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: context.space.md),
                children: [
                  for (final n in items)
                    _SidebarItem(item: n, selected: n.id == selectedId, onTap: () => onSelect(n.id)),
                ],
              ),
            ),
            if (trialDaysLeft != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: pad),
                child: TrialCard(daysLeft: trialDaysLeft!, onUpgrade: onUpgrade),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(pad, context.space.md, pad, context.space.lg),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SyncBadge(state: syncState, pending: pendingCount, onTap: onSyncTap, showLabel: true),
              ),
            ),
          ],
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
        shape: RoundedRectangleBorder(
          borderRadius: context.radii.banner,
          side: BorderSide(color: context.colors.outlineVariant, width: context.sizes.borderThin),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: farm.onTap,
          child: Container(
            height: context.sizes.farmSwitcherHeight,
            padding: EdgeInsets.symmetric(horizontal: context.space.md),
            child: Row(
              children: [
                CowAvatar(photoUrl: farm.photoUrl, avatarIndex: farm.avatarIndex, size: context.sizes.avatarXs),
                context.space.gapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(farm.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleSmall),
                      Text(farm.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
                    ],
                  ),
                ),
                Icon(Symbols.expand_more_rounded, size: context.sizes.iconMd, color: context.colors.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 44 tall, every 48; selected = primaryContainer pill (radius 22).
/// Icon 24 at x28, label at x64 (labelMedium; selected labelLarge).
class _SidebarItem extends StatelessWidget {
  const new({required this.item, required this.selected, required this.onTap});

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = selected ? c.onPrimaryContainer : c.onSurface;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.space.xxs),
      child: Semantics(
        selected: selected,
        button: true,
        label: item.label,
        excludeSemantics: true,
        child: Material(
          color: selected ? c.primaryContainer : Colors.transparent,
          borderRadius: context.radii.badge,
          child: InkWell(
            borderRadius: context.radii.badge,
            onTap: onTap,
            child: SizedBox(
              height: context.sizes.sidebarItemHeight,
              child: Row(
                children: [
                  SizedBox(width: context.space.lg),
                  Icon(item.icon, fill: selected ? 1 : 0, color: color, size: context.sizes.iconMd),
                  context.space.gapMd,
                  Expanded(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: (selected ? context.text.labelLarge : context.text.labelMedium)?.copyWith(color: color),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
