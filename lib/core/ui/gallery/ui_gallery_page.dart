// Hidden dev route (/dev/gallery): every shared widget in light or dark.
// Dev-only, so labels here are plain English and not in the ARB files.
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';

class UiGalleryPage extends StatefulWidget {
  const new({super.key, this.initialDark = false});

  final bool initialDark;

  @override
  State<UiGalleryPage> createState() => _UiGalleryPageState();
}

class _UiGalleryPageState extends State<UiGalleryPage> {
  late bool _dark = widget.initialDark;
  DecimalEntry _entry = const DecimalEntry(text: '9.5');
  String _filter = 'all';
  String _session = 'morning';
  SyncState _sync = SyncState.synced;

  @override
  Widget build(BuildContext context) {
    final theme = _dark ? FarmTapTheme.dark : FarmTapTheme.light;
    return Theme(
      data: theme,
      child: Builder(builder: _page),
    );
  }

  Widget _page(BuildContext context) {
    return AdaptiveScaffold(
      title: 'UI Gallery',
      subtitle: 'Shared widgets',
      showBack: true,
      syncState: _sync,
      pendingCount: 3,
      profileName: 'Muhwezi Robert',
      onSyncTap: () => setState(() => _sync = SyncState.values[(_sync.index + 1) % 3]),
      body: ListView(
        padding: EdgeInsets.only(bottom: context.space.xxxl),
        children: [
          Row(
            children: [
              Text('Dark mode', style: context.text.titleMedium),
              Switch(value: _dark, onChanged: (v) => setState(() => _dark = v)),
            ],
          ),
          _section(context, 'Metric cards + grid'),
          ResponsiveGrid(
            minItemWidth: 160,
            children: [
              MetricCard(
                icon: Icons.water_drop_rounded,
                label: 'Milk today',
                value: '312',
                unit: 'L',
                trend: '+6%',
                onTap: () {},
              ),
              MetricCard(
                icon: Icons.pets_rounded,
                label: 'Cows',
                value: '48',
                caption: '41 milking · 7 dry',
                tone: FarmTapTone.gold,
                onTap: () {},
              ),
              MetricCard(
                icon: Icons.medical_services_rounded,
                label: 'Under treatment',
                value: '3',
                caption: '2 not for sale',
                tone: FarmTapTone.danger,
                onTap: () {},
              ),
              MetricCard(
                icon: Icons.groups_rounded,
                label: 'Workers in',
                value: '5',
                unit: '/6',
                tone: FarmTapTone.info,
                onTap: () {},
              ),
            ],
          ),
          _section(context, 'Action tiles'),
          ResponsiveGrid(
            minItemWidth: 160,
            children: [
              ActionTile(icon: Icons.water_drop_rounded, label: 'Record milk', onTap: () {}),
              ActionTile(icon: Icons.contactless_rounded, label: 'Tap card', onTap: () {}),
              ActionTile(icon: Icons.medication_rounded, label: 'Treatment', tone: FarmTapTone.danger, onTap: () {}),
              ActionTile(
                icon: Icons.grass_rounded,
                label: 'Feeding',
                tone: FarmTapTone.gold,
                locked: true,
                onTap: () {},
              ),
            ],
          ),
          _section(context, 'Badges and bubbles'),
          Wrap(
            spacing: context.space.sm,
            runSpacing: context.space.sm,
            children: const [
              StatusBadge(label: 'Milking', tone: FarmTapTone.success),
              StatusBadge(label: 'Treated', tone: FarmTapTone.danger, icon: Icons.medication_rounded),
              StatusBadge(label: 'Pregnant', tone: FarmTapTone.info),
              StatusBadge(label: 'Dry', tone: FarmTapTone.warning),
              StatusBadge(label: 'Heifer'),
              IconBubble(icon: Icons.favorite_rounded, tone: FarmTapTone.info),
              CowAvatar(),
              PersonAvatar(name: 'Twinomujuni Amos'),
            ],
          ),
          _section(context, 'Banners'),
          const FarmTapBanner(
            tone: FarmTapTone.success,
            icon: Icons.check_circle_rounded,
            title: 'Saved',
            message: 'Everything is up to date.',
          ),
          context.space.gapSm,
          const FarmTapBanner(
            tone: FarmTapTone.danger,
            icon: Icons.medication_rounded,
            title: 'Kasheshe — milk not for sale',
            message: 'Penicillin · safe from Thu 12 Nov',
          ),
          context.space.gapSm,
          const FarmTapBanner(
            tone: FarmTapTone.info,
            icon: Icons.info_rounded,
            title: 'Tip',
            message: 'Tap a cow to record milk.',
          ),
          context.space.gapSm,
          TrialBanner(daysLeft: 9, onPay: () {}),
          context.space.gapSm,
          const OfflineBanner(pending: 4),
          context.space.gapSm,
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(width: context.sizes.sidebarWidth, child: const TrialCard(daysLeft: 9)),
          ),
          _section(context, 'Sync badge'),
          const Row(
            children: [
              SyncBadge(state: SyncState.synced),
              SyncBadge(state: SyncState.pending, pending: 3),
              SyncBadge(state: SyncState.failed),
            ],
          ),
          _section(context, 'Filter chips + segmented tabs'),
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
          context.space.gapMd,
          SegmentedTabs<String>(
            options: const [
              TabOption(value: 'morning', label: 'Morning', icon: Icons.wb_sunny_rounded),
              TabOption(value: 'evening', label: 'Evening', icon: Icons.nightlight_round),
            ],
            selected: _session,
            onChanged: (v) => setState(() => _session = v),
          ),
          _section(context, 'Step header'),
          const StepHeader(step: 3, total: 8, title: 'Farm details'),
          _section(context, 'Record tile'),
          Card(
            clipBehavior: Clip.antiAlias,
            child: RecordTile(
              leading: const CowAvatar(size: 48),
              title: 'Bihogo',
              subtitle: 'FT-014 · Friesian cross · 5 yrs',
              trailing: const StatusBadge(label: 'Milking', tone: FarmTapTone.success),
              onTap: () {},
            ),
          ),
          _section(context, 'Keypad + display'),
          KeypadDisplay(text: _entry.text, unit: 'L'),
          context.space.gapMd,
          Center(
            child: BigNumberKeypad(
              showDecimal: true,
              onDigit: (d) => setState(() => _entry = _entry.press(d)),
              onBackspace: () => setState(() => _entry = _entry.backspace()),
            ),
          ),
          _section(context, 'PIN pad (correct PIN is 1234)'),
          Center(
            child: PinPad(
              header: Padding(
                padding: EdgeInsets.only(bottom: context.space.lg),
                child: const PersonAvatar(name: 'Twinomujuni Amos', size: 96),
              ),
              onCompleted: (pin) async => pin == '1234',
            ),
          ),
          _section(context, 'Sheets, dialogs, toasts, celebration'),
          Wrap(
            spacing: context.space.sm,
            runSpacing: context.space.sm,
            children: [
              OutlinedButton(
                onPressed: () => showReadBack(
                  context,
                  leading: const CowAvatar(size: 96, ring: true),
                  subject: 'Bihogo · FT-014',
                  valueText: '9.5 litres',
                  detail: 'Morning · recorded by Amos',
                ),
                child: const Text('Read-back'),
              ),
              OutlinedButton(
                onPressed: () => showFarmTapDialog(
                  context,
                  icon: Icons.warning_rounded,
                  title: 'Record death?',
                  message: 'Bihogo will move to the history list.',
                  primaryLabel: 'Record death',
                  secondaryLabel: 'Cancel',
                  tone: FarmTapTone.danger,
                  destructive: true,
                ),
                child: const Text('Confirm dialog'),
              ),
              OutlinedButton(
                onPressed: () => FarmTapToast.show(
                  context,
                  message: 'Saved 42.5 L for Muhwezi Robert',
                  actionLabel: 'Undo',
                  duration: context.motion.undoWindow,
                ),
                child: const Text('Toast + Undo'),
              ),
              OutlinedButton(
                onPressed: () => showCelebration(
                  context,
                  animation: FarmTapAnimations.milkSaved,
                  title: 'Saved! 9.5 L from Bihogo',
                  message: '34 of 41 cows done this morning.',
                  primaryLabel: 'Next cow: Kahara',
                  primaryIcon: Icons.arrow_forward_rounded,
                  secondaryLabel: 'Finish session',
                  autoAdvance: true,
                ),
                child: const Text('Celebration (auto)'),
              ),
            ],
          ),
          _section(context, 'Charts'),
          const MilkLineChart(
            values: [290, 301, 285, 305, 312, 298, 312],
            labels: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
          ),
          context.space.gapLg,
          const FarmTapBarChart(
            values: [4, 6, 3, 8, 5, 7, 9],
            labels: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
          ),
          _section(context, 'Previews'),
          const SmsPreviewBubble(
            message: 'FarmTap: Muhwezi Robert delivered 42.5 L on Sat 7 Nov. Thank you.',
            time: '6:52 am',
          ),
          context.space.gapMd,
          const PrintedCardPreview(name: 'Muhwezi Robert', cardNumber: 'FT-0001', subtitle: 'Rwemera Dairy Farm'),
          _section(context, 'Animation view'),
          const Center(child: FarmTapAnimationView(animation: FarmTapAnimations.cowGrazing)),
          _section(context, 'Empty + error states'),
          SizedBox(
            height: context.sizes.chartHeight * 2,
            child: EmptyState(
              title: 'No cows yet',
              message: 'Add your first cow to start.',
              actionLabel: 'Add cow',
              actionIcon: Icons.add_rounded,
              onAction: () {},
            ),
          ),
          SizedBox(
            height: context.sizes.chartHeight * 2,
            child: ErrorState(onRetry: () {}),
          ),
          _section(context, 'Record collection (list < 700 dp, table above)'),
          RecordCollection<(String, String, String)>(
            items: const [
              ('Bihogo', 'FT-014', 'Milking'),
              ('Kasheshe', 'FT-022', 'Treated'),
              ('Kyasiimire', 'FT-031', 'Pregnant'),
            ],
            onTap: (_) {},
            tileBuilder: (context, r) => RecordTile(
              title: r.$1,
              subtitle: r.$2,
              trailing: StatusBadge(label: r.$3),
              onTap: () {},
            ),
            columns: [
              RecordColumn(
                label: 'Animal',
                sortKey: (r) => r.$1,
                cell: (c, r) => Text(r.$1, style: c.text.titleSmall),
              ),
              RecordColumn(label: 'Tag', sortKey: (r) => r.$2, cell: (c, r) => Text(r.$2)),
              RecordColumn(
                label: 'Status',
                cell: (c, r) => StatusBadge(label: r.$3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String label) => Padding(
    padding: EdgeInsets.only(top: context.space.xl, bottom: context.space.md),
    child: Text(label.toUpperCase(), style: context.textStyles.sectionLabel),
  );
}
