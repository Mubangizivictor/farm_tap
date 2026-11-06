// E01 herd list (tiles on phones, sortable table from 700 dp), E02 filter
// sheet, P01 empty herd.
import 'dart:async';

import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/core/utils/formats.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/entities/animal.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/herd_models.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/herd_repository.dart';
import 'package:farm_tap/sectors/cattle/herd/presentation/widgets/herd_labels.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class HerdListPage extends StatefulWidget {
  const new({
    required this.repo,
    required this.onAnimal,
    required this.onAdd,
    required this.onScan,
    super.key,
    this.today,
    this.initialFilter = const HerdFilter(),
  });

  final HerdRepository repo;
  final ValueChanged<Animal> onAnimal;
  final VoidCallback onAdd;
  final VoidCallback onScan;
  final DateTime? today;
  final HerdFilter initialFilter;

  @override
  State<HerdListPage> createState() => _HerdListPageState();
}

class _HerdListPageState extends State<HerdListPage> {
  late Future<(List<HerdRow>, HerdCounts?)> _load = _fetch();
  StreamSubscription<Object?>? _changes;

  @override
  void initState() {
    super.initState();
    // A new, edited, sold or dead animal shows at once, and records synced
    // from the farm's other phones.
    _changes = widget.repo.watchAnimals().skip(1).listen((_) {
      if (mounted) setState(() => _load = _fetch());
    });
  }

  @override
  void dispose() {
    unawaited(_changes?.cancel());
    super.dispose();
  }

  late HerdFilter _filter = widget.initialFilter;
  String _query = '';

  Future<(List<HerdRow>, HerdCounts?)> _fetch() async =>
      ((await widget.repo.rows()).data ?? const <HerdRow>[], (await widget.repo.counts()).data);

  List<HerdRow> _shown(List<HerdRow> rows) {
    final q = _query.trim().toLowerCase();
    return _filter
        .apply(rows)
        .where(
          (r) => q.isEmpty || r.animal.name.toLowerCase().contains(q) || r.animal.tagNumber.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> _openFilter(List<HerdRow> rows) async {
    final picked = await showHerdFilterSheet(context, filter: _filter, groups: widget.repo.groups, rows: rows);
    if (picked != null) setState(() => _filter = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = FarmTapFormat(Localizations.localeOf(context).toLanguageTag());
    final today = widget.today ?? context.clock.now();
    return FutureBuilder<(List<HerdRow>, HerdCounts?)>(
      future: _load,
      builder: (context, snapshot) {
        final (rows, counts) = snapshot.data ?? (const <HerdRow>[], null);
        final shown = _shown(rows);
        final quick = _filter.statuses.length == 1 && _filter.group == null ? _filter.statuses.first : null;
        return AdaptiveScaffold(
          title: l10n.herd,
          subtitle: counts == null ? null : l10n.animalsCount(counts.total),
          actions: [
            BarAction(icon: Symbols.qr_code_scanner_rounded, tooltip: l10n.scanTag, onPressed: widget.onScan),
            BarAction(
              icon: Symbols.tune_rounded,
              tooltip: l10n.filter,
              badge: !_filter.isEmpty && quick == null,
              onPressed: () => _openFilter(rows),
            ),
          ],
          floatingActionButton: FarmTapFab(label: l10n.addAnimal2, icon: Symbols.add_rounded, onPressed: widget.onAdd),
          body: snapshot.hasData && rows.isEmpty
              ? SizedBox(
                  height: context.sizes.photoPreview * 3,
                  child: EmptyState(
                    title: l10n.emptyHerdTitle,
                    message: l10n.emptyHerdBody,
                    actionLabel: l10n.addAnimal2,
                    actionIcon: Symbols.add_rounded,
                    onAction: widget.onAdd,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SearchField(hint: l10n.searchAnimals, onChanged: (v) => setState(() => _query = v)),
                    context.space.gapMd,
                    FilterChips<DairyStatus?>(
                      wrap: true,
                      options: [
                        FilterOption(value: null, label: l10n.filterAll, count: counts?.total),
                        FilterOption(value: DairyStatus.milking, label: l10n.statusMilking, count: counts?.milking),
                        FilterOption(value: DairyStatus.dry, label: l10n.statusDry, count: counts?.dry),
                        FilterOption(value: DairyStatus.treated, label: l10n.statusTreated, count: counts?.treated),
                        FilterOption(value: DairyStatus.pregnant, label: l10n.statusPregnant, count: counts?.pregnant),
                        FilterOption(value: DairyStatus.calf, label: l10n.filterCalves, count: counts?.calves),
                      ],
                      selected: _filter.isEmpty ? null : quick,
                      onSelected: (s) => setState(
                        () => _filter = s == null
                            ? const HerdFilter()
                            : _filter.copyWith(statuses: {s}, clearGroup: true),
                      ),
                    ),
                    context.space.gapSm,
                    if (!snapshot.hasData)
                      const FarmTapPageLoader()
                    else if (shown.isEmpty)
                      Padding(
                        padding: EdgeInsets.all(context.space.xl),
                        child: Text(l10n.noMatches, textAlign: TextAlign.center, style: context.text.bodyMedium),
                      )
                    else
                      RecordCollection<HerdRow>(
                        items: shown,
                        onTap: (r) => widget.onAnimal(r.animal),
                        tileBuilder: (context, r) => RecordTile(
                          leading: CowAvatar(
                            avatarIndex: r.animal.avatarIndex,
                            animalId: r.animal.id,
                            photoUrl: r.animal.photo,
                          ),
                          title: r.animal.name,
                          subtitle: l10n.tagAndBreedAge(r.animal.tagNumber, r.animal.breed, r.animal.ageYears(today)),
                          badge: DairyStatusBadge(r.animal.dairyStatus),
                          trailingValue: r.milkToday == null ? '—' : f.litres(r.milkToday!),
                          onTap: () => widget.onAnimal(r.animal),
                        ),
                        columns: [
                          RecordColumn(
                            label: l10n.colAnimal,
                            flex: 3,
                            sortKey: (r) => r.animal.name,
                            cell: (context, r) => Row(
                              children: [
                                CowAvatar(
                                  avatarIndex: r.animal.avatarIndex,
                                  photoUrl: r.animal.photo,
                                  size: context.sizes.avatarSm,
                                ),
                                context.space.gapMd,
                                Flexible(child: Text(r.animal.name, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          ),
                          RecordColumn(
                            label: l10n.colTag,
                            flex: 2,
                            sortKey: (r) => r.animal.tagNumber,
                            cell: (context, r) => Text(r.animal.tagNumber),
                          ),
                          RecordColumn(
                            label: l10n.colBreedAge,
                            flex: 3,
                            cell: (context, r) => Text(l10n.breedAge(r.animal.breed, r.animal.ageYears(today))),
                          ),
                          RecordColumn(
                            label: l10n.colStatus,
                            flex: 2,
                            cell: (context, r) => DairyStatusBadge(r.animal.dairyStatus),
                          ),
                          RecordColumn(
                            label: l10n.colMilkToday,
                            flex: 2,
                            sortKey: (r) => r.milkToday ?? -1,
                            cell: (context, r) => Text(
                              r.notForSale
                                  ? l10n.notForSale
                                  : r.milkToday != null
                                  ? f.litres(r.milkToday!)
                                  : r.animal.dairyStatus == DairyStatus.dry
                                  ? l10n.statusDry
                                  : '—',
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
        );
      },
    );
  }
}

/// E02 — filter animals. Bottom sheet on phones, dialog wider.
Future<HerdFilter?> showHerdFilterSheet(
  BuildContext context, {
  required HerdFilter filter,
  required List<String> groups,
  required List<HerdRow> rows,
}) => showAdaptiveSheet<HerdFilter>(
  context,
  builder: (_) => _HerdFilterSheet(filter: filter, groups: groups, rows: rows),
);

class _HerdFilterSheet extends StatefulWidget {
  const new({required this.filter, required this.groups, required this.rows});

  final HerdFilter filter;
  final List<String> groups;
  final List<HerdRow> rows;

  @override
  State<_HerdFilterSheet> createState() => _HerdFilterSheetState();
}

class _HerdFilterSheetState extends State<_HerdFilterSheet> {
  late HerdFilter _f = widget.filter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const statuses = [
      DairyStatus.milking,
      DairyStatus.dry,
      DairyStatus.treated,
      DairyStatus.pregnant,
      DairyStatus.heifer,
      DairyStatus.calf,
    ];
    Widget label(String text) => Padding(
      padding: EdgeInsets.only(top: context.space.lg, bottom: context.space.xs),
      child: Text(text, style: context.text.titleSmall),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetTitle(l10n.filterAnimals),
        label(l10n.statusLabel),
        Wrap(
          spacing: context.space.chipRun,
          children: [
            for (final s in statuses)
              FarmTapChip(
                label: dairyStatusLabel(l10n, s),
                selected: _f.statuses.contains(s),
                onTap: () => setState(() {
                  final next = {..._f.statuses};
                  if (!next.remove(s)) next.add(s);
                  _f = _f.copyWith(statuses: next);
                }),
              ),
          ],
        ),
        label(l10n.groupLabel),
        Wrap(
          spacing: context.space.chipRun,
          children: [
            FarmTapChip(
              label: l10n.filterAll,
              selected: _f.group == null,
              onTap: () => setState(() => _f = _f.copyWith(clearGroup: true)),
            ),
            for (final g in widget.groups)
              FarmTapChip(
                label: g,
                selected: _f.group == g,
                onTap: () => setState(() => _f = _f.copyWith(group: g)),
              ),
          ],
        ),
        label(l10n.sortBy),
        SegmentedTabs<HerdSort>(
          options: [
            TabOption(value: HerdSort.name, label: l10n.sortName),
            TabOption(value: HerdSort.tag, label: l10n.sortTag),
            TabOption(value: HerdSort.milk, label: l10n.sortMilk),
          ],
          selected: _f.sort,
          onChanged: (s) => setState(() => _f = _f.copyWith(sort: s)),
        ),
        context.space.gapXl,
        ButtonPair(
          forceRow: true,
          first: FarmTapButton(
            label: l10n.clear,
            kind: ButtonKind.outlined,
            onPressed: () => setState(() => _f = const HerdFilter()),
          ),
          second: FarmTapButton(
            label: l10n.showAnimals(_f.apply(widget.rows).length),
            onPressed: () => Navigator.of(context).pop(_f),
          ),
        ),
      ],
    );
  }
}
