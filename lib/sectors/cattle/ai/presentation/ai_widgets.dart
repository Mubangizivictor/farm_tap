// Shared pieces of the AI screens (decision 0025, phone phase 2).
import 'dart:async';

import 'package:farm_tap/core/ai/ai_core.dart';
import 'package:farm_tap/core/ai/ai_photo.dart';
import 'package:farm_tap/core/ai/ai_repository.dart';
import 'package:farm_tap/core/ai/ai_risk.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Opens a finding's link (a web path like `/milk/`) on the phone; does
/// nothing for a path the phone has no screen for. Set by the router.
typedef AiLinkOpener = void Function(String href);

/// Opens one AI module's screen by its key.
typedef AiModuleOpener = void Function(String module);

FarmTapTone severityTone(Severity s) => switch (s) {
  Severity.critical || Severity.high => FarmTapTone.danger,
  Severity.medium => FarmTapTone.warning,
  Severity.low => FarmTapTone.info,
};

IconData moduleIcon(String key) => switch (key) {
  'assistant' => Symbols.forum_rounded,
  'vet' => Symbols.stethoscope_rounded,
  'screening' => Symbols.photo_camera_rounded,
  'milk' => Symbols.water_drop_rounded,
  'quality' => Symbols.ac_unit_rounded,
  'predictions' => Symbols.trending_up_rounded,
  'feed' => Symbols.grass_rounded,
  'breeding' => Symbols.favorite_rounded,
  'health' => Symbols.health_and_safety_rounded,
  'finance' => Symbols.account_balance_wallet_rounded,
  'inventory' => Symbols.inventory_2_rounded,
  'reports' => Symbols.bar_chart_rounded,
  'risks' => Symbols.warning_rounded,
  'recommendations' => Symbols.lightbulb_rounded,
  'alerts' => Symbols.notifications_active_rounded,
  _ => Symbols.auto_awesome_rounded,
};

/// How the answer was made, shown on every card so a sum is never called AI.
class MethodBadge extends StatelessWidget {
  const new(this.method, {super.key});

  final Method method;

  @override
  Widget build(BuildContext context) => StatusBadge(
    label: methodLabel[method]!,
    tone: method == Method.experimental ? FarmTapTone.gold : FarmTapTone.neutral,
  );
}

/// Loads the farm's records for the engine and rebuilds when asked.
class AiBody extends StatefulWidget {
  const new({
    required this.repo,
    required this.role,
    required this.title,
    required this.builder,
    super.key,
    this.actions = const [],
    this.fab,
  });

  final AiRepository repo;
  final String role;
  final String title;
  final List<Widget> actions;
  final Widget? fab;

  /// Builds the page body from loaded records; `reload` reads them again.
  final Widget Function(BuildContext context, AiFarm farm, Future<void> Function() reload) builder;

  @override
  State<AiBody> createState() => _AiBodyState();
}

class _AiBodyState extends State<AiBody> {
  AiFarm? _farm;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final f = await widget.repo.load(role: widget.role);
      if (mounted) {
        setState(() {
          _farm = f;
          _failed = false;
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final farm = _farm;
    return AdaptiveScaffold(
      title: widget.title,
      showBack: true,
      actions: widget.actions,
      floatingActionButton: widget.fab,
      onRefresh: _load,
      body: farm != null
          ? widget.builder(context, farm, _load)
          : _failed
          ? ErrorState(onRetry: () => unawaited(_load()))
          : const FarmTapPageLoader(),
    );
  }
}

/// A short note under a screen: what the numbers are made from.
class AiNote extends StatelessWidget {
  const new(this.text, {super.key, this.icon = Symbols.info_rounded, this.tone = FarmTapTone.info});

  final String text;
  final IconData icon;
  final FarmTapTone tone;

  @override
  Widget build(BuildContext context) => FarmTapBanner(tone: tone, icon: icon, title: text);
}

/// One alert, recommendation or insight: why it was raised, what to do,
/// how it was made, with Seen / Fixed for the people who may act.
class FindingCard extends StatelessWidget {
  const new({required this.item, required this.onLink, super.key, this.onAcknowledge, this.onResolve});

  final FindingWithState item;
  final AiLinkOpener onLink;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onResolve;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = item.finding;
    final tone = severityTone(f.severity);
    final seen = item.state == 'acknowledged';
    return FarmTapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBubble(icon: moduleIcon(f.module), tone: tone, size: context.sizes.bubbleMd),
              context.space.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: context.space.xs,
                      runSpacing: context.space.xs,
                      children: [
                        StatusBadge(label: severityLabel[f.severity]!, tone: tone),
                        if (seen) StatusBadge(label: l10n.aiSeen, icon: Symbols.check_rounded),
                        MethodBadge(f.method),
                      ],
                    ),
                    context.space.gapXs,
                    Text(f.title, style: context.text.titleSmall),
                  ],
                ),
              ),
            ],
          ),
          context.space.gapSm,
          Text(f.why, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
          context.space.gapSm,
          Text(f.action, style: context.text.bodyMedium),
          if (f.links.isNotEmpty || onAcknowledge != null || onResolve != null) ...[
            context.space.gapSm,
            Wrap(
              spacing: context.space.sm,
              children: [
                for (final link in f.links.take(2))
                  TextAction(label: link.label, small: true, onPressed: () => onLink(link.href)),
                if (onAcknowledge != null && !seen)
                  TextAction(label: l10n.aiMarkSeen, small: true, onPressed: onAcknowledge),
                if (onResolve != null) TextAction(label: l10n.aiMarkFixed, small: true, onPressed: onResolve),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A list of findings, or a calm "nothing to flag".
class FindingList extends StatelessWidget {
  const new({
    required this.items,
    required this.onLink,
    super.key,
    this.repo,
    this.byName = '',
    this.onChanged,
    this.emptyTitle,
  });

  final List<FindingWithState> items;
  final AiLinkOpener onLink;

  /// With a repository the cards offer Seen and Fixed.
  final AiRepository? repo;
  final String byName;
  final Future<void> Function()? onChanged;
  final String? emptyTitle;

  Future<void> _set(BuildContext context, FindingWithState f, String status) async {
    await repo!.setAlertState(f.finding.id, status, byName);
    if (onChanged != null) await onChanged!();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (items.isEmpty) {
      return EmptyState(title: emptyTitle ?? l10n.aiNothing, message: l10n.aiNothingBody);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final f in items) ...[
          FindingCard(
            item: f,
            onLink: onLink,
            onAcknowledge: repo == null ? null : () => unawaited(_set(context, f, 'acknowledged')),
            onResolve: repo == null ? null : () => unawaited(_set(context, f, 'resolved')),
          ),
          context.space.gapMd,
        ],
      ],
    );
  }
}

/// A big number with a caption, in a row of a card.
class AiStat extends StatelessWidget {
  const new({required this.label, required this.value, super.key, this.sub});

  final String label;
  final String value;
  final String? sub;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: context.text.labelMedium?.copyWith(color: context.colors.onSurfaceVariant)),
      context.space.gapXxs,
      Text(value, style: context.text.titleLarge),
      if (sub != null) Text(sub!, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
    ],
  );
}

/// A plain table of text cells that scrolls sideways on a narrow phone.
class AiTable extends StatelessWidget {
  const new({required this.columns, required this.rows, super.key});

  final List<String> columns;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      columns: [for (final c in columns) DataColumn(label: Text(c))],
      rows: [
        for (final r in rows) DataRow(cells: [for (final c in r) DataCell(Text(c))]),
      ],
    ),
  );
}

/// Section label used between cards.
Widget aiSection(BuildContext context, String label, {List<Widget> children = const []}) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [SectionLabel(label), context.space.gapSm, ...children],
);

/// What every AI screen needs from the app: the repository, who is looking,
/// and how to open a finding's link or another AI screen.
class AiPageContext {
  const new({
    required this.repo,
    required this.role,
    required this.byName,
    required this.farmName,
    required this.onLink,
    required this.onModule,
    this.photo,
  });

  final AiRepository repo;

  /// owner, manager, clerk or worker.
  final String role;

  /// Name written on Seen / Fixed actions.
  final String byName;

  /// For the file name of an exported report.
  final String farmName;
  final AiLinkOpener onLink;
  final AiModuleOpener onModule;

  /// Sends a photo to the model (decision 0026); null where there is no model.
  final PhotoAnalyzer? photo;

  bool get manages => role == 'owner' || role == 'manager';
}

/// The page title for an AI module key.
String aiModuleLabel(String key) => aiModules.firstWhere((m) => m.key == key).label;
