import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/sectors/cattle/home/domain/home_models.dart';
import 'package:farm_tap/sectors/cattle/home/domain/home_repository.dart';
import 'package:farm_tap/sectors/cattle/home/presentation/widgets/attention_tile.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// D03 — every alert, most urgent first, filtered by kind.
class AlertsPage extends StatefulWidget {
  const new({required this.repo, super.key, this.onOpen, this.today});

  final HomeRepository repo;
  final ValueChanged<Attention>? onOpen;

  /// Overrides today (goldens).
  final DateTime? today;

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  late final Future<List<Attention>> _items = widget.repo.attention().then((r) => r.data ?? const []);
  AlertCategory? _filter;
  bool _read = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AdaptiveScaffold(
      title: l10n.alerts,
      actions: [
        BarAction(
          icon: Symbols.done_all_rounded,
          tooltip: l10n.markAllRead,
          onPressed: _read ? null : () => setState(() => _read = true),
        ),
      ],
      body: FutureBuilder<List<Attention>>(
        future: _items,
        builder: (context, snapshot) {
          final all = snapshot.data ?? const <Attention>[];
          int count(AlertCategory c) => all.where((a) => a.category == c).length;
          final shown = _filter == null ? all : all.where((a) => a.category == _filter).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilterChips<AlertCategory?>(
                wrap: true,
                options: [
                  FilterOption(value: null, label: l10n.filterAll, count: all.length),
                  FilterOption(
                    value: AlertCategory.health,
                    label: l10n.filterHealth,
                    count: count(AlertCategory.health),
                  ),
                  FilterOption(value: AlertCategory.milk, label: l10n.filterMilk, count: count(AlertCategory.milk)),
                  FilterOption(value: AlertCategory.stock, label: l10n.filterStock, count: count(AlertCategory.stock)),
                  FilterOption(value: AlertCategory.money, label: l10n.filterMoney, count: count(AlertCategory.money)),
                ],
                selected: _filter,
                onSelected: (v) => setState(() => _filter = v),
              ),
              context.space.gapMd,
              if (snapshot.hasData && shown.isEmpty)
                EmptyState(title: l10n.emptyDefaultTitle, animation: FarmTapAnimations.syncDone)
              else
                ListCard(
                  children: [
                    for (final a in shown)
                      AttentionTile(item: a, showBadge: true, today: widget.today, onTap: () => widget.onOpen?.call(a)),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}
