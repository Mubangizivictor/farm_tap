// Hidden dev route (/dev/gallery): every shared widget in light or dark.
// The first screenful replicates the D01 home shell so it can be compared
// with the mockup; the catalogue of components follows.
// Dev-only, so labels here are plain English and not in the ARB files.
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class UiGalleryPage extends StatefulWidget {
  const new({super.key, this.initialDark});

  /// Null follows the app theme.
  final bool? initialDark;

  @override
  State<UiGalleryPage> createState() => _UiGalleryPageState();
}

class _UiGalleryPageState extends State<UiGalleryPage> {
  late bool? _dark = widget.initialDark;
  DecimalEntry _entry = const DecimalEntry(text: '9.5');
  String _filter = 'all';
  String _session = 'morning';
  String _nav = 'home';
  String _option = 'dairy';
  SyncState _sync = SyncState.synced;

  static const _bottom = [
    NavItem(id: 'home', icon: Symbols.home_rounded, label: 'Home'),
    NavItem(id: 'herd', icon: Symbols.pets_rounded, label: 'Herd'),
    NavItem(id: 'milk', icon: Symbols.water_drop_rounded, label: 'Milk'),
    NavItem(id: 'health', icon: Symbols.medical_services_rounded, label: 'Health'),
    NavItem(id: 'more', icon: Symbols.more_horiz_rounded, label: 'More'),
  ];
  static const _rail = [
    NavItem(id: 'home', icon: Symbols.home_rounded, label: 'Home'),
    NavItem(id: 'herd', icon: Symbols.pets_rounded, label: 'Herd'),
    NavItem(id: 'milk', icon: Symbols.water_drop_rounded, label: 'Milk'),
    NavItem(id: 'collect', icon: Symbols.contactless_rounded, label: 'Collect'),
    NavItem(id: 'health', icon: Symbols.medical_services_rounded, label: 'Health'),
    NavItem(id: 'workers', icon: Symbols.groups_rounded, label: 'Workers'),
    NavItem(id: 'more', icon: Symbols.more_horiz_rounded, label: 'More'),
  ];
  static const _sidebar = [
    NavItem(id: 'home', icon: Symbols.home_rounded, label: 'Home'),
    NavItem(id: 'herd', icon: Symbols.pets_rounded, label: 'Herd'),
    NavItem(id: 'milk', icon: Symbols.water_drop_rounded, label: 'Milk'),
    NavItem(id: 'collect', icon: Symbols.contactless_rounded, label: 'Collection centre'),
    NavItem(id: 'health', icon: Symbols.medical_services_rounded, label: 'Health'),
    NavItem(id: 'feeding', icon: Symbols.grass_rounded, label: 'Feeding'),
    NavItem(id: 'breeding', icon: Symbols.favorite_rounded, label: 'Breeding'),
    NavItem(id: 'workers', icon: Symbols.groups_rounded, label: 'Workers'),
    NavItem(id: 'money', icon: Symbols.account_balance_wallet_rounded, label: 'Money'),
    NavItem(id: 'reports', icon: Symbols.bar_chart_rounded, label: 'Reports'),
    NavItem(id: 'settings', icon: Symbols.settings_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: (_dark ?? context.isDark) ? FarmTapTheme.dark : FarmTapTheme.light,
      child: Builder(builder: _page),
    );
  }

  Widget _page(BuildContext context) {
    return AdaptiveScaffold(
      showLogo: true,
      title: 'Home',
      navigation: AdaptiveNavigation(
        items: _bottom,
        railItems: _rail,
        sidebarItems: _sidebar,
        selectedId: _nav,
        onSelect: (id) => setState(() => _nav = id),
      ),
      farm: const FarmSwitcherInfo(name: 'Rwemera Dairy Farm', subtitle: 'Mbarara · Owner'),
      trialDaysLeft: 9,
      syncState: _sync,
      pendingCount: 3,
      profileName: 'Mugisha Tom',
      hasNotifications: true,
      onSyncTap: () => setState(() => _sync = SyncState.values[(_sync.index + 1) % 3]),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [..._homeReplica(context), ..._catalogue(context)],
      ),
    );
  }

  // ------------------------------------------------------------ D01 replica

  List<Widget> _homeReplica(BuildContext context) {
    final wide = !context.isCompact;
    return [
      TrialBanner(daysLeft: 9, onPay: () {}),
      context.space.gapLg,
      Text('Good morning, Muhwezi', style: context.text.headlineSmall),
      Text(
        'Rwemera Dairy Farm · Saturday 7 Nov',
        style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
      ),
      context.space.gapLg,
      ResponsiveGrid(
        minItemWidth: context.sizes.gridMetric,
        spacing: context.space.lg,
        children: [
          MetricCard(
            icon: Symbols.water_drop_rounded,
            label: 'Milk today',
            value: '312',
            unit: 'L',
            trend: '+6%',
            onTap: () {},
          ),
          MetricCard(
            icon: Symbols.pets_rounded,
            label: 'Cows',
            value: '48',
            caption: '41 milking · 7 dry',
            tone: FarmTapTone.gold,
            onTap: () {},
          ),
          MetricCard(
            icon: Symbols.medical_services_rounded,
            label: 'Under treatment',
            value: '3',
            caption: '2 not for sale',
            tone: FarmTapTone.danger,
            onTap: () {},
          ),
          MetricCard(
            icon: Symbols.groups_rounded,
            label: 'Workers in',
            value: '5',
            unit: '/6',
            tone: FarmTapTone.info,
            onTap: () {},
          ),
        ],
      ),
      context.space.gapLg,
      const SectionLabel('Quick actions'),
      context.space.gapSm,
      ResponsiveGrid(
        minItemWidth: context.sizes.gridAction,
        spacing: context.space.lg,
        children: [
          ActionTile(icon: Symbols.water_drop_rounded, label: 'Record milk', onTap: () {}),
          ActionTile(icon: Symbols.contactless_rounded, label: 'Tap card', onTap: () {}),
          ActionTile(icon: Symbols.medication_rounded, label: 'Treatment', tone: FarmTapTone.danger, onTap: () {}),
          ActionTile(icon: Symbols.grass_rounded, label: 'Feeding', tone: FarmTapTone.gold, onTap: () {}),
        ],
      ),
      context.space.gapLg,
      ResponsiveGrid(
        minItemWidth: context.sizes.gridPaired,
        spacing: context.space.lg,
        maxColumns: wide ? 2 : 1,
        children: [
          ListCard(
            title: 'Needs attention',
            actionLabel: 'See all',
            onAction: () {},
            children: [
              RecordTile(
                leading: const IconBubble(icon: Symbols.medication_rounded, tone: FarmTapTone.danger),
                title: 'Kasheshe — milk not for sale',
                subtitle: 'Penicillin · safe from Thu 12 Nov',
                onTap: () {},
              ),
              RecordTile(
                leading: const IconBubble(icon: Symbols.favorite_rounded, tone: FarmTapTone.info),
                title: 'Calving due: Kyasiimire',
                subtitle: 'In 6 days · 13 Nov',
                onTap: () {},
              ),
              RecordTile(
                leading: const IconBubble(icon: Symbols.inventory_2_rounded, tone: FarmTapTone.gold),
                title: 'Dairy meal is running low',
                subtitle: '3 bags left · about 4 days',
                onTap: () {},
              ),
            ],
          ),
          const FarmTapCard(
            children: [
              CardHeader(
                title: 'Milk this week',
                trailing: StatusBadge(label: '+6%', tone: FarmTapTone.success, icon: Symbols.trending_up_rounded),
              ),
              MilkLineChart(
                values: [296, 300, 293, 302, 305, 301, 312],
                labels: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
              ),
            ],
          ),
        ],
      ),
    ];
  }

  // ------------------------------------------------------------ catalogue

  List<Widget> _catalogue(BuildContext context) {
    return [
      _section(context, 'Dark mode'),
      Row(
        children: [
          Text('Dark mode', style: context.text.titleMedium),
          Switch(value: _dark ?? context.isDark, onChanged: (v) => setState(() => _dark = v)),
        ],
      ),
      _section(context, 'Buttons'),
      FarmTapButton(label: 'Continue with email', icon: Symbols.mail_rounded, onPressed: () {}),
      context.space.gapMd,
      FarmTapButton(label: 'Yes, save', icon: Symbols.check_rounded, large: true, onPressed: () {}),
      context.space.gapMd,
      ButtonPair(
        first: FarmTapButton(label: 'Tonal', kind: ButtonKind.tonal, onPressed: () {}),
        second: FarmTapButton(
          label: 'No, change it',
          icon: Symbols.edit_rounded,
          kind: ButtonKind.outlined,
          onPressed: () {},
        ),
      ),
      context.space.gapMd,
      ButtonPair(
        first: FarmTapButton(label: 'Record death', kind: ButtonKind.danger, onPressed: () {}),
        second: FarmTapButton(label: 'Upgrade', icon: Symbols.savings_rounded, kind: ButtonKind.gold, onPressed: () {}),
      ),
      context.space.gapMd,
      ButtonPair(
        first: FarmTapButton(label: 'Continue with Google', kind: ButtonKind.neutral, onPressed: () {}),
        second: const FarmTapButton(label: 'Disabled', onPressed: null),
      ),
      context.space.gapMd,
      Row(
        children: [
          TextAction(label: 'Pay now', onPressed: () {}),
          context.space.gapXl,
          FarmTapButton(label: 'Text', kind: ButtonKind.text, expand: false, onPressed: () {}),
        ],
      ),
      _section(context, 'Inputs and search'),
      const TextField(
        decoration: InputDecoration(labelText: 'Email', prefixIcon: Icon(Symbols.mail_rounded)),
      ),
      context.space.gapLg,
      const TextField(
        decoration: InputDecoration(labelText: 'Price per litre', prefixText: 'UGX ', errorText: 'Enter a price'),
      ),
      context.space.gapLg,
      const TextField(
        enabled: false,
        decoration: InputDecoration(labelText: 'Farm ID', hintText: 'FT-RWE-001'),
      ),
      context.space.gapLg,
      const SearchField(hint: 'Search by name or tag number'),
      _section(context, 'Chips, segmented, step header, progress, dots'),
      FilterChips<String>(
        options: const [
          FilterOption(value: 'all', label: 'All', count: 48),
          FilterOption(value: 'milking', label: 'Milking', count: 41),
          FilterOption(value: 'dry', label: 'Dry', count: 7),
          FilterOption(value: 'treated', label: 'Treated', count: 2),
        ],
        selected: _filter,
        onSelected: (v) => setState(() => _filter = v),
      ),
      context.space.gapLg,
      SegmentedTabs<String>(
        options: const [
          TabOption(value: 'morning', label: 'Morning', icon: Symbols.wb_sunny_rounded),
          TabOption(value: 'evening', label: 'Evening', icon: Symbols.dark_mode_rounded),
        ],
        selected: _session,
        onChanged: (v) => setState(() => _session = v),
      ),
      context.space.gapLg,
      StepHeader(step: 3, total: 8, onBack: () {}, onSkip: () {}),
      context.space.gapLg,
      const FarmTapProgress(value: 34 / 41, label: 'Morning milking', trailingLabel: '34 of 41 cows'),
      context.space.gapLg,
      const Center(child: PageDots(count: 3, current: 1)),
      _section(context, 'Badges, bubbles, avatars'),
      Wrap(
        spacing: context.space.sm,
        runSpacing: context.space.sm,
        children: const [
          StatusBadge(label: 'Milking', tone: FarmTapTone.success),
          StatusBadge(label: 'Treated', tone: FarmTapTone.danger, icon: Symbols.medication_rounded),
          StatusBadge(label: 'Pregnant', tone: FarmTapTone.info),
          StatusBadge(label: 'Heifer'),
          StatusBadge(label: 'Dry', tone: FarmTapTone.warning),
          StatusBadge(label: 'Coming soon', tone: FarmTapTone.gold),
        ],
      ),
      context.space.gapMd,
      Wrap(
        spacing: context.space.md,
        runSpacing: context.space.md,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final (tone, size) in [
            (FarmTapTone.primary, context.sizes.bubbleSm),
            (FarmTapTone.gold, context.sizes.bubbleMd),
            (FarmTapTone.danger, context.sizes.bubbleLg),
            (FarmTapTone.info, context.sizes.bubbleXl),
            (FarmTapTone.success, context.sizes.bubbleMd),
            (FarmTapTone.warning, context.sizes.bubbleMd),
            (FarmTapTone.neutral, context.sizes.bubbleMd),
          ])
            IconBubble(icon: Symbols.water_drop_rounded, tone: tone, size: size),
        ],
      ),
      context.space.gapMd,
      Wrap(
        spacing: context.space.md,
        runSpacing: context.space.md,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          PersonAvatar(name: 'Mugisha Tom', size: context.sizes.avatarXs, ring: true),
          const PersonAvatar(name: 'Ahimbisibwe Joy', tone: FarmTapTone.gold),
          PersonAvatar(name: 'Dr. Kamugisha Ivan', size: context.sizes.avatarMd, tone: FarmTapTone.info),
          PersonAvatar(name: 'Nuwagaba Peter', size: context.sizes.avatarLg),
          PersonAvatar(name: 'Twinomujuni Amos', size: context.sizes.avatarReadBack, ring: true),
          for (var i = 1; i <= 6; i++) CowAvatar(avatarIndex: i),
          const CowAvatar(isCalf: true),
          CowAvatar(avatarIndex: 1, size: context.sizes.avatarReadBack, ring: true),
        ],
      ),
      _section(context, 'Banners and trial card'),
      const FarmTapBanner(
        tone: FarmTapTone.danger,
        icon: Symbols.medication_rounded,
        title: 'Kasheshe — milk not for sale',
        message: 'Penicillin · safe from Thu 12 Nov',
      ),
      context.space.gapMd,
      const FarmTapBanner(
        tone: FarmTapTone.info,
        icon: Symbols.info_rounded,
        title: 'Tip',
        message: 'Tap a cow to record milk.',
      ),
      context.space.gapMd,
      const OfflineBanner(pending: 4),
      context.space.gapMd,
      Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(width: context.sizes.sidebarWidth - context.space.xxl, child: const TrialCard(daysLeft: 5)),
      ),
      context.space.gapMd,
      const Row(
        children: [
          SyncBadge(state: SyncState.synced),
          SyncBadge(state: SyncState.pending, pending: 3),
          SyncBadge(state: SyncState.failed),
        ],
      ),
      _section(context, 'Hero card'),
      ResponsiveGrid(
        minItemWidth: context.sizes.gridPaired,
        maxColumns: 2,
        spacing: context.space.lg,
        children: const [
          HeroCard(
            label: 'Collected today',
            value: '1,284',
            unit: 'L',
            sub: '86 farmers · 6:52 am last',
            animation: FarmTapAnimations.milking,
          ),
          HeroCard(
            label: 'To pay this week',
            value: 'UGX 1.4M',
            sub: '86 farmers · Friday',
            tone: FarmTapTone.gold,
            animation: FarmTapAnimations.paymentReceived,
          ),
        ],
      ),
      _section(context, 'Tiles, options, timeline'),
      ResponsiveGrid(
        minItemWidth: context.sizes.gridAction,
        spacing: context.space.lg,
        children: [
          ActionTile(
            icon: Symbols.water_drop_rounded,
            label: 'Record milk',
            subtitle: 'Morning · 34 of 41',
            onTap: () {},
          ),
          ActionTile(icon: Symbols.grass_rounded, label: 'Feeding', tone: FarmTapTone.gold, locked: true, onTap: () {}),
        ],
      ),
      context.space.gapLg,
      OptionRow(
        icon: Symbols.water_drop_rounded,
        title: 'Dairy',
        subtitle: 'Cows and milk',
        selected: _option == 'dairy',
        onTap: () => setState(() => _option = 'dairy'),
      ),
      context.space.gapMd,
      OptionRow(
        icon: Symbols.contactless_rounded,
        title: 'Milk collection centre',
        subtitle: 'Collect milk from farmers',
        selected: _option == 'centre',
        onTap: () => setState(() => _option = 'centre'),
      ),
      context.space.gapMd,
      OptionRow(
        icon: Symbols.egg_rounded,
        title: 'Poultry',
        subtitle: 'Layers and broilers',
        tone: FarmTapTone.gold,
        selected: false,
        comingSoon: true,
        onTap: () {},
      ),
      context.space.gapLg,
      const FarmTapCard(
        child: Timeline(
          entries: [
            TimelineEntry(
              icon: Symbols.water_drop_rounded,
              title: 'Milked 9.5 L',
              subtitle: 'Morning · Amos',
              time: '6:52 am',
            ),
            TimelineEntry(
              icon: Symbols.medication_rounded,
              title: 'Penicillin',
              subtitle: 'Dr. Kamugisha · 3 days',
              time: 'Thu',
              tone: FarmTapTone.danger,
            ),
            TimelineEntry(
              icon: Symbols.favorite_rounded,
              title: 'Served',
              subtitle: 'AI · Friesian',
              time: '12 Aug',
              tone: FarmTapTone.info,
            ),
          ],
        ),
      ),
      _section(context, 'Record collection (tiles < 700 dp, table above)'),
      RecordCollection<_Cow>(
        items: _cows,
        onTap: (_) {},
        tileBuilder: (context, c) => RecordTile(
          leading: CowAvatar(avatarIndex: c.avatar),
          title: c.name,
          subtitle: '${c.tag} · ${c.breed}',
          badge: StatusBadge(label: c.status, tone: c.tone),
          trailingValue: c.milk,
          onTap: () {},
        ),
        columns: [
          RecordColumn(
            label: 'Animal',
            flex: 3,
            sortKey: (c) => c.name,
            cell: (context, c) => Row(
              children: [
                CowAvatar(avatarIndex: c.avatar, size: context.sizes.avatarSm),
                context.space.gapMd,
                Text(c.name),
              ],
            ),
          ),
          RecordColumn(label: 'Tag', sortKey: (c) => c.tag, cell: (context, c) => Text(c.tag)),
          RecordColumn(label: 'Breed & age', flex: 2, cell: (context, c) => Text(c.breed)),
          RecordColumn(
            label: 'Status',
            cell: (context, c) => StatusBadge(label: c.status, tone: c.tone),
          ),
          RecordColumn(label: 'Milk today', cell: (context, c) => Text(c.milk)),
        ],
      ),
      _section(context, 'Keypad'),
      Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: context.sizes.keypadMaxWidth),
          child: Column(
            children: [
              KeypadDisplay(text: _entry.text, unit: 'L', caption: 'Yesterday morning: 9.0 L'),
              context.space.gapLg,
              BigNumberKeypad(
                showDecimal: true,
                onDigit: (d) => setState(() => _entry = _entry.press(d)),
                onBackspace: () => setState(() => _entry = _entry.backspace()),
              ),
            ],
          ),
        ),
      ),
      _section(context, 'PIN (correct PIN is 1234)'),
      Center(child: PinPad(onCompleted: (pin) async => pin == '1234')),
      context.space.gapLg,
      const Center(child: PinDots(filled: 4, error: true)),
      _section(context, 'Read-back, sheet, dialog, toast (inline states)'),
      _surface(
        context,
        ReadBackSheet(
          leading: CowAvatar(avatarIndex: 1, size: context.sizes.avatarReadBack, ring: true),
          subject: 'Bihogo · FT-014',
          valueText: '9.5 litres',
          detail: 'Morning · recorded by Amos',
          onConfirm: () {},
          onChange: () {},
        ),
      ),
      context.space.gapLg,
      _surface(
        context,
        const FarmTapDialog(
          icon: Symbols.warning_rounded,
          tone: FarmTapTone.danger,
          title: 'Record death of Bihogo?',
          message: 'She will move to the history list. This cannot be undone.',
          primaryLabel: 'Record death',
          primaryKind: ButtonKind.danger,
          secondaryLabel: 'Cancel',
        ),
        dialog: true,
      ),
      context.space.gapLg,
      ToastContent(message: 'Saved 42.5 L for Muhwezi Robert', actionLabel: 'Undo', onAction: () {}),
      context.space.gapLg,
      Wrap(
        spacing: context.space.sm,
        runSpacing: context.space.sm,
        children: [
          OutlinedButton(
            onPressed: () => showReadBack(
              context,
              leading: CowAvatar(avatarIndex: 1, size: context.sizes.avatarReadBack, ring: true),
              subject: 'Bihogo · FT-014',
              valueText: '9.5 litres',
              detail: 'Morning · recorded by Amos',
            ),
            child: const Text('Open read-back'),
          ),
          OutlinedButton(
            onPressed: () => showFarmTapDialog(
              context,
              icon: Symbols.warning_rounded,
              title: 'Record death?',
              message: 'Bihogo will move to the history list.',
              primaryLabel: 'Record death',
              secondaryLabel: 'Cancel',
              tone: FarmTapTone.danger,
              primaryKind: ButtonKind.danger,
            ),
            child: const Text('Open dialog'),
          ),
          OutlinedButton(
            onPressed: () => FarmTapToast.show(
              context,
              message: 'Saved 42.5 L for Muhwezi Robert',
              actionLabel: 'Undo',
              duration: context.motion.undoWindow,
            ),
            child: const Text('Show toast'),
          ),
          OutlinedButton(
            onPressed: () => showCelebration(
              context,
              animation: FarmTapAnimations.milkSaved,
              title: 'Saved! 9.5 L from Bihogo',
              message: '34 of 41 cows done this morning.',
              primaryLabel: 'Next cow: Kahara',
              primaryIcon: Symbols.arrow_forward_rounded,
              secondaryLabel: 'Finish session',
              autoAdvance: true,
            ),
            child: const Text('Open celebration'),
          ),
        ],
      ),
      _section(context, 'Charts'),
      const FarmTapCard(
        children: [
          CardHeader(title: 'Milk this week'),
          MilkLineChart(
            values: [296, 300, 293, 302, 305, 301, 312],
            labels: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
            target: 320,
          ),
        ],
      ),
      context.space.gapLg,
      const FarmTapCard(
        children: [
          CardHeader(title: 'Sales'),
          FarmTapBarChart(values: [4, 6, 3, 8, 5, 7, 9], labels: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']),
        ],
      ),
      _section(context, 'Previews'),
      const SmsPreviewBubble(
        message: 'FarmTap: Muhwezi Robert delivered 42.5 L on Sat 7 Nov. Thank you.',
        time: '6:52 am',
      ),
      context.space.gapLg,
      Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: context.sizes.cardPreviewWidth,
          child: const PrintedCardPreview(
            name: 'Nuwagaba Peter',
            subtitle: 'Worker · Rwemera Dairy Farm',
            cardNumber: 'Card 0207',
          ),
        ),
      ),
      _section(context, 'Empty and error states'),
      SizedBox(
        height: context.sizes.chartHeight * 2,
        child: EmptyState(
          title: 'No cows yet',
          message: 'Add your first cow to start.',
          actionLabel: 'Add cow',
          actionIcon: Symbols.add_rounded,
          onAction: () {},
        ),
      ),
      SizedBox(
        height: context.sizes.chartHeight * 2,
        child: ErrorState(onRetry: () {}),
      ),
    ];
  }

  Widget _section(BuildContext context, String label) => Padding(
    padding: EdgeInsets.only(top: context.space.xxl, bottom: context.space.md),
    child: SectionLabel(label),
  );

  /// Shows sheet / dialog content on its real surface without opening a route.
  Widget _surface(BuildContext context, Widget child, {bool dialog = false}) => Align(
    child: Container(
      constraints: BoxConstraints(maxWidth: dialog ? context.sizes.dialogWidth : context.sizes.dialogMaxWidth),
      padding: context.space.sheet,
      decoration: BoxDecoration(color: context.colors.surfaceContainerLow, borderRadius: context.radii.dialog),
      child: child,
    ),
  );
}

class _Cow {
  const new(this.name, this.tag, this.breed, this.status, this.tone, this.milk, this.avatar);

  final String name;
  final String tag;
  final String breed;
  final String status;
  final FarmTapTone tone;
  final String milk;
  final int avatar;
}

const _cows = [
  _Cow('Bihogo', 'FT-014', 'Friesian cross · 5 yrs', 'Milking', FarmTapTone.success, '18.5 L', 1),
  _Cow('Kasheshe', 'FT-022', 'Ankole · 7 yrs', 'Treated', FarmTapTone.danger, 'Not for sale', 2),
  _Cow('Kyasiimire', 'FT-031', 'Jersey cross · 4 yrs', 'Pregnant', FarmTapTone.info, '9.0 L', 3),
  _Cow('Rwemera', 'FT-045', 'Ankole cross · 3 yrs', 'Heifer', FarmTapTone.neutral, '—', 5),
  _Cow('Kaaka', 'FT-019', 'Friesian cross · 8 yrs', 'Dry', FarmTapTone.warning, 'Dry', 6),
];
