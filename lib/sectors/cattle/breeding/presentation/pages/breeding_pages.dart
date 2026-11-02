// Breeding: J01 breeding home (+ J02 heat & service sheet, pregnancy check),
// J03 pregnancy confirmed. Every date comes from the breeding records.
import 'dart:async';

import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/core/utils/formats.dart';
import 'package:farm_tap/sectors/cattle/breeding/domain/breeding_models.dart';
import 'package:farm_tap/sectors/cattle/breeding/domain/breeding_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

FarmTapFormat _fmt(BuildContext context) => FarmTapFormat(Localizations.localeOf(context).toLanguageTag());

/// Opens J02 / the check on first frame (goldens, deep links).
enum BreedingStart { none, serve, check, confirmed }

// ---------------------------------------------------------------- J01

class BreedingPage extends StatefulWidget {
  const new({
    required this.repo,
    required this.onAnimal,
    super.key,
    this.onCalendar,
    this.now,
    this.start = BreedingStart.none,
  });

  final BreedingRepository repo;
  final ValueChanged<String> onAnimal;
  final VoidCallback? onCalendar;
  final DateTime? now;
  final BreedingStart start;

  @override
  State<BreedingPage> createState() => _BreedingPageState();
}

class _BreedingPageState extends State<BreedingPage> {
  late Future<BreedingSummary?> _load = _fetch();

  Future<BreedingSummary?> _fetch() async => (await widget.repo.summary()).data;

  DateTime get _now => widget.now ?? context.clock.now();

  @override
  void initState() {
    super.initState();
    if (widget.start != BreedingStart.none) {
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_startFlow()));
    }
  }

  Future<void> _startFlow() async {
    final s = await _load;
    if (s == null || !mounted) return;
    BreedingTask? task(BreedingTaskKind k) => s.tasks.where((t) => t.kind == k).firstOrNull;
    switch (widget.start) {
      case BreedingStart.serve:
        final t = task(BreedingTaskKind.serve);
        if (t != null) await _serve(t.record.animal, ServiceKind.ai);
      case BreedingStart.check:
        final t = task(BreedingTaskKind.check);
        if (t != null) await _check(t.record);
      case BreedingStart.confirmed:
        final t = task(BreedingTaskKind.check);
        if (t != null) await _celebrate(t.record);
      case BreedingStart.none:
    }
  }

  void _reload() => setState(() {
    _load = _fetch();
  });

  Future<void> _serve(BreedingAnimal animal, ServiceKind kind) async {
    final saved = await showAdaptiveSheet<ServiceRecord>(
      context,
      builder: (_) => _ServiceSheet(repo: widget.repo, animal: animal, kind: kind, now: _now),
    );
    if (saved == null || !mounted) return;
    FarmTapToast.show(context, message: AppLocalizations.of(context).serviceSaved(animal.name));
    _reload();
  }

  Future<void> _recordHeat() async {
    final l10n = AppLocalizations.of(context);
    final animals = (await widget.repo.animals()).data ?? const <BreedingAnimal>[];
    if (!mounted) return;
    final picked = await showAdaptiveSheet<BreedingAnimal>(
      context,
      builder: (sheet) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetTitle(l10n.whichAnimal),
          sheet.space.gapMd,
          for (final a in animals)
            RecordTile(
              leading: CowAvatar(avatarIndex: a.avatarIndex, animalId: a.id),
              title: a.name,
              subtitle: '${a.tag} · ${a.heifer ? l10n.heiferWord : l10n.cowWord}',
              onTap: () => Navigator.of(sheet).pop(a),
            ),
        ],
      ),
    );
    if (picked != null && mounted) await _serve(picked, ServiceKind.heat);
  }

  Future<void> _check(ServiceRecord service) async {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    final pregnant = await showAdaptiveSheet<bool>(
      context,
      builder: (sheet) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetTitle(l10n.isSheP(service.animal.name), subtitle: l10n.checkBody(f.dayMonth(service.at))),
          sheet.space.gapXl,
          ButtonPair(
            first: FarmTapButton(
              label: l10n.notPregnant,
              kind: ButtonKind.outlined,
              onPressed: () => Navigator.of(sheet).pop(false),
            ),
            second: FarmTapButton(
              label: l10n.yesPregnant,
              icon: Symbols.favorite_rounded,
              onPressed: () => Navigator.of(sheet).pop(true),
            ),
          ),
        ],
      ),
    );
    if (pregnant == null || !mounted) return;
    if (pregnant) {
      await _celebrate(service);
    } else {
      await widget.repo.recordCheck(serviceId: service.id, pregnant: false, by: widget.repo.technicians.last);
      if (!mounted) return;
      FarmTapToast.show(context, message: l10n.notPregnantSaved(service.animal.name));
      _reload();
    }
  }

  Future<void> _celebrate(ServiceRecord service) async {
    final p = (await widget.repo.recordCheck(
      serviceId: service.id,
      pregnant: true,
      by: widget.repo.technicians.last,
    )).data;
    if (p == null || !mounted) return;
    await showPregnancyConfirmed(context, p);
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    final now = _now;
    return AdaptiveScaffold(
      title: l10n.breeding,
      actions: [
        BarAction(icon: Symbols.calendar_month_rounded, tooltip: l10n.healthCalendar, onPressed: widget.onCalendar),
      ],
      floatingActionButton: FarmTapFab(label: l10n.recordHeat, icon: Symbols.favorite_rounded, onPressed: _recordHeat),
      body: FutureBuilder<BreedingSummary?>(
        future: _load,
        builder: (context, snapshot) {
          final s = snapshot.data;
          if (s == null) return const SizedBox.shrink();
          final calvings = ListCard(
            title: l10n.expectedCalvings,
            children: [
              for (final p in s.calvingSoon)
                RecordTile(
                  leading: CowAvatar(avatarIndex: p.animal.avatarIndex, animalId: p.animal.id),
                  title: p.animal.name,
                  subtitle: [
                    l10n.dueOn(f.dayMonth(p.due)),
                    if (p.daysToCalving(now) <= 7) l10n.inDaysCount(p.daysToCalving(now)),
                  ].join(' · '),
                  trailingValue: l10n.daysShortValue(p.daysToCalving(now)),
                  onTap: () => widget.onAnimal(p.animal.id),
                ),
            ],
          );
          final todo = ListCard(
            title: l10n.toDo,
            children: [
              for (final t in s.tasks)
                RecordTile(
                  leading: CowAvatar(avatarIndex: t.record.animal.avatarIndex, animalId: t.record.animal.id),
                  title: t.record.animal.name,
                  subtitle: t.kind == BreedingTaskKind.check
                      ? l10n.servedCheckFrom(f.dayMonth(t.record.at), f.dayMonth(t.record.checkFrom))
                      : (DateUtils.isSameDay(t.record.at, now) ? l10n.heatSeenToday : l10n.heatSeenYesterday),
                  trailingValue: t.kind == BreedingTaskKind.check ? l10n.checkAction : l10n.serveAction,
                  onTap: () =>
                      t.kind == BreedingTaskKind.check ? _check(t.record) : _serve(t.record.animal, ServiceKind.ai),
                ),
            ],
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ResponsiveGrid(
                minItemWidth: context.sizes.gridMetric,
                maxColumns: 3,
                spacing: context.space.lg,
                children: [
                  MetricCard(
                    icon: Symbols.favorite_rounded,
                    label: l10n.pregnantLabel,
                    value: f.count(s.pregnancies.length),
                    tone: FarmTapTone.info,
                  ),
                  MetricCard(
                    icon: Symbols.event_rounded,
                    label: l10n.calvingInDays(BreedingRules.calvingSoonDays),
                    value: f.count(s.calvingSoon.length),
                    tone: FarmTapTone.gold,
                  ),
                  MetricCard(
                    icon: Symbols.schedule_rounded,
                    label: l10n.checkPregnancy,
                    value: f.count(s.checksDue),
                    tone: FarmTapTone.warning,
                  ),
                ],
              ),
              context.space.gapLg,
              if (context.isExpanded)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: calvings),
                      context.space.gapLg,
                      Expanded(child: todo),
                    ],
                  ),
                )
              else ...[
                calvings,
                context.space.gapLg,
                todo,
              ],
              context.space.gapLg,
              FarmTapCard(
                child: Row(
                  children: [
                    FarmTapAnimationView(
                      animation: FarmTapAnimations.pregnant,
                      size: context.sizes.heroAnimationWidth,
                      semanticLabel: l10n.tipLabel,
                    ),
                    context.space.gapLg,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.tipLabel, style: context.text.labelMedium?.copyWith(color: context.colors.primary)),
                          context.space.gapXs,
                          Text(l10n.breedingTip, style: context.text.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------- J02

class _ServiceSheet extends StatefulWidget {
  const new({required this.repo, required this.animal, required this.kind, required this.now});

  final BreedingRepository repo;
  final BreedingAnimal animal;
  final ServiceKind kind;
  final DateTime now;

  @override
  State<_ServiceSheet> createState() => _ServiceSheetState();
}

class _ServiceSheetState extends State<_ServiceSheet> {
  late ServiceKind _kind = widget.kind;
  final _straw = TextEditingController(text: 'Friesian 4421');
  final _bull = TextEditingController();
  final _cost = TextEditingController(text: '35,000');
  late String _technician = widget.repo.technicians.first;
  late DateTime _at = widget.now;
  bool _edited = false;

  @override
  void dispose() {
    for (final c in [_straw, _bull, _cost]) {
      c.dispose();
    }
    super.dispose();
  }

  int get _costValue => _kind == ServiceKind.heat ? 0 : int.tryParse(_cost.text.replaceAll(',', '')) ?? 0;

  void _changed() => setState(() => _edited = true);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _at,
      firstDate: widget.now.subtract(const Duration(days: 60)),
      lastDate: widget.now,
    );
    if (picked == null) return;
    setState(() {
      _at = DateTime(picked.year, picked.month, picked.day, _at.hour, _at.minute);
      _edited = true;
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    // Money: read back before saving a service that costs something.
    if (_costValue > 0) {
      final ok = await showReadBack(
        context,
        leading: CowAvatar(avatarIndex: widget.animal.avatarIndex, animalId: widget.animal.id),
        subject: '${widget.animal.name} · ${_kind == ServiceKind.ai ? l10n.aiLabel : l10n.servedNatural}',
        valueText: f.money(_costValue),
        detail: _kind == ServiceKind.ai ? _straw.text.trim() : _bull.text.trim(),
      );
      if (!ok || !mounted) return;
    }
    final saved = (await widget.repo.recordService(
      animalId: widget.animal.id,
      kind: _kind,
      at: _at,
      straw: _kind == ServiceKind.ai ? _straw.text.trim() : null,
      bull: _kind == ServiceKind.natural ? _bull.text.trim() : null,
      technician: _kind == ServiceKind.ai ? _technician : null,
      cost: _costValue > 0 ? _costValue : null,
    )).data;
    if (saved != null && mounted) Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    final a = widget.animal;
    final day = DateTime(_at.year, _at.month, _at.day);
    final check = day.add(const Duration(days: BreedingRules.checkAfterDays));
    final calving = day.add(const Duration(days: BreedingRules.gestationDays));
    final dateText = DateUtils.isSameDay(_at, widget.now) ? l10n.todayAt(f.time(_at)) : f.day(_at);
    return DiscardGuard(
      dirty: _edited,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetTitle(l10n.heatAndService(a.name), subtitle: '${a.tag} · ${a.heifer ? l10n.heiferWord : l10n.cowWord}'),
          context.space.gapLg,
          SegmentedTabs<ServiceKind>(
            options: [
              TabOption(value: ServiceKind.heat, label: l10n.heatSeen),
              TabOption(value: ServiceKind.natural, label: l10n.servedNatural),
              TabOption(value: ServiceKind.ai, label: l10n.aiLabel),
            ],
            selected: _kind,
            onChanged: (k) => setState(() {
              _kind = k;
              _edited = true;
            }),
          ),
          context.space.gapLg,
          if (_kind == ServiceKind.ai) ...[
            FarmTapTextField(
              label: l10n.semenStraw,
              icon: Symbols.science_rounded,
              controller: _straw,
              onChanged: (_) => _changed(),
            ),
            context.space.gapLg,
            FarmTapSelectField<String>(
              label: l10n.technician,
              icon: Symbols.person_rounded,
              options: widget.repo.technicians,
              value: _technician,
              labelOf: (t) => t,
              onChanged: (t) => setState(() {
                _technician = t;
                _edited = true;
              }),
            ),
            context.space.gapLg,
          ],
          if (_kind == ServiceKind.natural) ...[
            FarmTapTextField(
              label: l10n.bullLabel,
              icon: Symbols.pets_rounded,
              controller: _bull,
              onChanged: (_) => _changed(),
            ),
            context.space.gapLg,
          ],
          Semantics(
            button: true,
            label: l10n.dateLabel,
            value: dateText,
            excludeSemantics: true,
            child: InkWell(
              onTap: _pickDate,
              borderRadius: context.radii.input,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.dateLabel,
                  suffixIcon: Icon(Symbols.calendar_month_rounded, size: context.sizes.iconMd),
                ),
                child: Text(dateText, style: context.text.bodyLarge),
              ),
            ),
          ),
          if (_kind != ServiceKind.heat) ...[
            context.space.gapLg,
            FarmTapTextField(
              label: l10n.costLabel,
              prefixText: 'UGX ',
              controller: _cost,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9,]'))],
              onChanged: (_) => _changed(),
            ),
            context.space.gapLg,
            FarmTapBanner(
              tone: FarmTapTone.primary,
              icon: Symbols.info_rounded,
              title: l10n.checkReminder(f.dayMonth(check)),
              message: l10n.calvingIfPregnant(f.dayMonthMaybeYear(calving, widget.now)),
            ),
          ],
          context.space.gapXl,
          FarmTapButton(label: l10n.save, icon: Symbols.check_rounded, onPressed: _save),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- J03

/// Full screen on phones, dialog wider (showCelebration).
Future<void> showPregnancyConfirmed(BuildContext context, Pregnancy p) async {
  final l10n = AppLocalizations.of(context);
  final f = _fmt(context);
  final s = p.service;
  await showCelebration(
    context,
    animation: FarmTapAnimations.pregnant,
    title: l10n.isPregnantTitle(p.animal.name),
    message: l10n.pregnantBody(f.dayMonthLong(p.due)),
    primaryLabel: l10n.done,
    summary: FarmTapCard(
      child: Column(
        children: [
          SummaryRow(
            label: l10n.servedLabel,
            value: [
              f.dayMonth(s.at),
              if (s.kind == ServiceKind.ai) l10n.aiLabel else l10n.servedNatural,
              ?(s.straw ?? s.bull),
            ].join(' · '),
          ),
          if (p.check.by != null) SummaryRow(label: l10n.checkedBy, value: p.check.by!),
          SummaryRow(label: l10n.dryOffFrom, value: f.dayMonth(p.dryOffFrom)),
        ],
      ),
    ),
  );
}
