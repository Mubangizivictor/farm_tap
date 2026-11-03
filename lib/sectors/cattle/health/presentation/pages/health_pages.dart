// Health: H01 health home, H02 add treatment (+ H03 saved), H04 drug stock,
// H05 health calendar, H06 milk not for sale. Every withdrawal date and
// Treated badge is calculated from the treatment records.
import 'dart:async';

import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/core/utils/formats.dart';
import 'package:farm_tap/sectors/cattle/health/domain/health_models.dart';
import 'package:farm_tap/sectors/cattle/health/domain/health_repository.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

FarmTapFormat _fmt(BuildContext context) => FarmTapFormat(Localizations.localeOf(context).toLanguageTag());

String conditionLabel(AppLocalizations l10n, Condition c) => switch (c) {
  Condition.mastitis => l10n.condMastitis,
  Condition.lame => l10n.condLame,
  Condition.fever => l10n.condFever,
  Condition.wound => l10n.condWound,
  Condition.eye => l10n.condEye,
  Condition.diarrhoea => l10n.condDiarrhoea,
  Condition.other => l10n.condOther,
};

String routeLabel(AppLocalizations l10n, DrugRoute r) => switch (r) {
  DrugRoute.injection => l10n.routeInjection,
  DrugRoute.oral => l10n.routeOral,
  DrugRoute.spray => l10n.routeSpray,
  DrugRoute.pourOn => l10n.routePourOn,
};

String _stockText(AppLocalizations l10n, FarmTapFormat f, Drug d) =>
    d.unit == DrugUnit.bottles ? l10n.bottlesCount(d.stock.round()) : l10n.litresCount(f.litresValue(d.stock));

/// Red Treated badge, or Dry for a dry cow (her milk is not sold anyway).
Widget _animalBadge(AppLocalizations l10n, TreatmentRecord r) => r.animalDry
    ? StatusBadge(label: l10n.statusDry, tone: FarmTapTone.gold)
    : StatusBadge(label: l10n.statusTreated, tone: FarmTapTone.danger);

// ---------------------------------------------------------------- H01

enum HealthTarget { treatment, calendar, drugs, withdrawal }

class HealthHomePage extends StatelessWidget {
  const new({required this.repo, required this.onOpen, super.key, this.now});

  final TreatmentRepository repo;
  final ValueChanged<HealthTarget> onOpen;
  final DateTime? now;

  Future<(List<TreatmentRecord>, List<HealthTask>, List<Drug>)> _load() async => (
    (await repo.treatments()).data ?? const <TreatmentRecord>[],
    (await repo.schedule()).data ?? const <HealthTask>[],
    (await repo.drugs()).data ?? const <Drug>[],
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    final now = this.now ?? context.clock.now();
    return AdaptiveScaffold(
      title: l10n.health,
      actions: [
        BarAction(
          icon: Symbols.calendar_month_rounded,
          tooltip: l10n.healthCalendar,
          onPressed: () => onOpen(HealthTarget.calendar),
        ),
      ],
      floatingActionButton: FarmTapFab(
        label: l10n.treatment,
        icon: Symbols.add_rounded,
        onPressed: () => onOpen(HealthTarget.treatment),
      ),
      body: FutureBuilder<(List<TreatmentRecord>, List<HealthTask>, List<Drug>)>(
        future: _load(),
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data == null) return const FarmTapPageLoader();
          final (records, tasks, drugs) = data;
          final active = records.where((r) => r.active(now)).toList();
          final blocked = records.where((r) => r.inWithdrawal(now)).length;
          final weekEnd = DateTime(now.year, now.month, now.day + 9);
          final week = tasks.where((t) => t.due.isBefore(weekEnd)).toList();
          final low = drugs.where((d) => d.inStockList && d.low).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MetricStrip(
                children: [
                  MetricCard(
                    icon: Symbols.medication_rounded,
                    label: l10n.underTreatment,
                    value: f.count(active.length),
                    caption: l10n.milkNotForSaleCount(blocked),
                    tone: FarmTapTone.danger,
                    onTap: () => onOpen(HealthTarget.withdrawal),
                  ),
                  MetricCard(
                    icon: Symbols.vaccines_rounded,
                    label: l10n.dueThisWeek,
                    value: f.count(week.length),
                    caption: week.map((t) => '${t.title.split(' ').first} ${f.weekdayShort(t.due)}').join(' · '),
                    tone: FarmTapTone.info,
                    onTap: () => onOpen(HealthTarget.calendar),
                  ),
                  MetricCard(
                    icon: Symbols.inventory_2_rounded,
                    label: l10n.drugsLow,
                    value: f.count(low.length),
                    caption: low.map((d) => d.shortName).join(', '),
                    tone: FarmTapTone.gold,
                    onTap: () => onOpen(HealthTarget.drugs),
                  ),
                ],
              ),
              context.space.gapLg,
              ListCard(
                title: l10n.sickList,
                actionLabel: l10n.seeAll,
                onAction: () => onOpen(HealthTarget.withdrawal),
                children: [
                  for (final r in active)
                    RecordTile(
                      leading: CowAvatar(avatarIndex: r.avatarIndex, animalId: r.animalId),
                      title: r.animalName,
                      subtitle: [
                        conditionLabel(l10n, r.condition),
                        if (r.note != null) r.note! else r.drug.shortName,
                        if (r.note == null && r.courseDays > 1) l10n.courseDay(r.courseDay(now), r.courseDays),
                      ].join(' · '),
                      badge: _animalBadge(l10n, r),
                      trailingValue: r.inWithdrawal(now) && !r.animalDry
                          ? l10n.daysWithdrawal(r.withdrawalDaysLeft(now))
                          : null,
                      trailingSub: r.inWithdrawal(now) && !r.animalDry ? l10n.withdrawalLabel : null,
                      onTap: () => onOpen(HealthTarget.withdrawal),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------- H02 / H03

class AddTreatmentPage extends StatefulWidget {
  const new({
    required this.repo,
    required this.onDone,
    super.key,
    this.animalId,
    this.onScan,
    this.now,
    this.initialCondition,
  });

  final TreatmentRepository repo;

  /// After H03: true = add another treatment.
  final ValueChanged<bool> onDone;
  final String? animalId;
  final VoidCallback? onScan;
  final DateTime? now;

  /// Goldens show Mastitis picked.
  final Condition? initialCondition;

  @override
  State<AddTreatmentPage> createState() => _AddTreatmentPageState();
}

class _AddTreatmentPageState extends State<AddTreatmentPage> {
  late final Future<(List<TreatableAnimal>, List<Drug>)> _load = _fetch();
  TreatableAnimal? _animal;
  late Condition? _condition = widget.initialCondition;
  Drug? _drug;
  DrugRoute _route = DrugRoute.injection;
  String? _vet;
  late final _dose = TextEditingController(text: widget.initialCondition == null ? '' : '20 ml');
  final _note = TextEditingController();
  bool _dirty = false;
  String? _photo;

  Future<void> _takePhoto() async {
    final key = await pickPhoto(context, canRemove: _photo != null);
    if (key == null || !mounted) return;
    _touch(() => _photo = key.isEmpty ? null : key);
  }

  Future<(List<TreatableAnimal>, List<Drug>)> _fetch() async {
    final animals = (await widget.repo.animals()).data ?? const <TreatableAnimal>[];
    final drugs = ((await widget.repo.drugs()).data ?? const <Drug>[]).where((d) => d.inStockList).toList();
    _animal = animals.where((a) => a.id == widget.animalId).firstOrNull ?? animals.firstOrNull;
    _drug = drugs.firstOrNull;
    _vet = widget.repo.vets.first;
    return (animals, drugs);
  }

  @override
  void dispose() {
    _dose.dispose();
    _note.dispose();
    super.dispose();
  }

  DateTime get _now => widget.now ?? context.clock.now();

  /// The same rule as the records: treatment day + withdrawal days.
  DateTime _safeFrom(Drug d) => DateTime(_now.year, _now.month, _now.day + d.withdrawalDays);

  void _touch(VoidCallback change) => setState(() {
    change();
    _dirty = true;
  });

  Future<void> _pickAnimal(List<TreatableAnimal> animals) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showAdaptiveSheet<TreatableAnimal>(
      context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetTitle(l10n.pickAnimal),
          context.space.gapSm,
          for (final a in animals)
            RecordTile(
              leading: CowAvatar(avatarIndex: a.avatarIndex, animalId: a.id),
              title: a.name,
              subtitle: a.tag,
              onTap: () => Navigator.of(sheet).pop(a),
            ),
        ],
      ),
    );
    if (picked != null) _touch(() => _animal = picked);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    final animal = _animal;
    final drug = _drug;
    final condition = _condition;
    if (animal == null || drug == null || condition == null) return;
    final safe = _safeFrom(drug);
    final ok = await showReadBack(
      context,
      leading: CowAvatar(
        avatarIndex: animal.avatarIndex,
        animalId: animal.id,
        size: context.sizes.avatarReadBack,
        ring: true,
      ),
      subject: '${animal.name} · ${animal.tag}',
      valueText: l10n.treatmentReadBack(conditionLabel(l10n, condition), drug.shortName),
      detail: drug.withdrawalDays > 0 ? l10n.treatmentReadBackDetail(f.day(safe)) : l10n.noWithdrawal,
    );
    if (!ok || !mounted) return;
    final saved = (await widget.repo.addTreatment(
      NewTreatment(
        animalId: animal.id,
        condition: condition,
        drugId: drug.id,
        given: _now,
        dose: _dose.text.trim().isEmpty ? null : _dose.text.trim(),
        route: _route,
        givenBy: _vet,
        photo: _photo,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      ),
    )).data;
    if (saved == null || !mounted) return;
    setState(() => _dirty = false);
    final action = await showCelebration(
      context,
      animation: FarmTapAnimations.treatmentSaved,
      sound: FarmTapSound.success,
      title: l10n.treatmentSaved,
      message: saved.drug.withdrawalDays > 0
          ? l10n.treatmentSavedBody(saved.animalName, f.weekday(saved.safeFrom))
          : l10n.treatmentSavedNoWithdrawal(saved.animalName),
      primaryLabel: l10n.done,
      secondaryLabel: l10n.addAnotherTreatment,
      secondaryKind: ButtonKind.text,
    );
    if (mounted) widget.onDone(action == CelebrationAction.secondary);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    return FutureBuilder<(List<TreatableAnimal>, List<Drug>)>(
      future: _load,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final animal = _animal;
        final drug = _drug;
        return DiscardGuard(
          dirty: _dirty,
          child: AdaptiveScaffold(
            title: l10n.newTreatment,
            showNavigation: false,
            body: data == null
                ? const FarmTapPageLoader()
                : animal == null
                ? SizedBox(
                    height: context.sizes.photoPreview * 3,
                    child: EmptyState(title: l10n.emptyHerdTitle, message: l10n.addAnimalsFirst),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FarmTapCard(
                        onTap: () => _pickAnimal(data.$1),
                        child: Row(
                          children: [
                            CowAvatar(
                              avatarIndex: animal.avatarIndex,
                              animalId: animal.id,
                              size: context.sizes.avatarLg,
                            ),
                            context.space.gapLg,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(animal.name, style: context.text.titleMedium),
                                  Text(
                                    l10n.tagTapToChange(animal.tag),
                                    style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            context.space.gapSm,
                            FarmTapButton(
                              label: l10n.scan,
                              icon: Symbols.qr_code_scanner_rounded,
                              kind: ButtonKind.tonal,
                              expand: false,
                              onPressed: widget.onScan,
                            ),
                          ],
                        ),
                      ),
                      context.space.gapLg,
                      Text(l10n.whatIsTheProblem, style: context.text.titleSmall),
                      context.space.gapSm,
                      Wrap(
                        spacing: context.space.chipRun,
                        children: [
                          for (final c in Condition.values)
                            FarmTapChip(
                              label: conditionLabel(l10n, c),
                              selected: _condition == c,
                              onTap: () => _touch(() => _condition = c),
                            ),
                        ],
                      ),
                      context.space.gapMd,
                      FarmTapTextField(
                        label: _condition == Condition.other ? l10n.diseaseName : l10n.whatYouSee,
                        icon: Symbols.visibility_rounded,
                        controller: _note,
                        onChanged: (_) => _touch(() {}),
                      ),
                      context.space.gapMd,
                      FarmTapSelectField<Drug>(
                        label: l10n.drugLabel,
                        icon: Symbols.medication_rounded,
                        options: data.$2,
                        value: drug,
                        labelOf: (d) => d.name,
                        onChanged: (d) => _touch(() => _drug = d),
                      ),
                      if (drug != null)
                        Padding(
                          padding: EdgeInsets.fromLTRB(context.space.lg, context.space.xs, 0, 0),
                          child: Text(
                            l10n.drugStockLine(_stockText(l10n, f, drug), drug.withdrawalDays),
                            style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                          ),
                        ),
                      context.space.gapMd,
                      FarmTapTextField(
                        label: l10n.doseLabel,
                        icon: Symbols.experiment_rounded,
                        controller: _dose,
                        onChanged: (_) => _touch(() {}),
                      ),
                      context.space.gapMd,
                      FarmTapSelectField<DrugRoute>(
                        label: l10n.routeLabel,
                        options: DrugRoute.values,
                        value: _route,
                        labelOf: (r) => routeLabel(l10n, r),
                        onChanged: (r) => _touch(() => _route = r),
                      ),
                      context.space.gapMd,
                      FarmTapSelectField<String>(
                        label: l10n.givenBy,
                        icon: Symbols.person_rounded,
                        options: widget.repo.vets,
                        value: _vet,
                        labelOf: (v) => v,
                        onChanged: (v) => _touch(() => _vet = v),
                        picker: (c) =>
                            showSearchPicker(c, title: l10n.givenBy, options: widget.repo.vets, selected: _vet),
                      ),
                      if (drug != null) ...[
                        context.space.gapLg,
                        if (drug.withdrawalDays > 0)
                          FarmTapBanner(
                            tone: FarmTapTone.danger,
                            icon: Symbols.error_rounded,
                            title: l10n.notForSaleUntil(f.day(_safeFrom(drug))),
                            message: l10n.blockMilkBody,
                          )
                        else
                          FarmTapBanner(
                            tone: FarmTapTone.success,
                            icon: Symbols.check_circle_rounded,
                            title: l10n.noWithdrawal,
                          ),
                      ],
                      if (_photo != null) ...[
                        context.space.gapLg,
                        ClipRRect(
                          borderRadius: context.radii.card,
                          child: SizedBox(
                            height: context.sizes.photoPreview,
                            child: StoredPhoto(
                              photoKey: _photo!,
                              placeholder: const IconBubble(icon: Symbols.photo_camera_rounded),
                            ),
                          ),
                        ),
                      ],
                      context.space.gapLg,
                      ButtonPair(
                        forceRow: true,
                        first: FarmTapButton(
                          label: _photo == null ? l10n.addPhoto : l10n.changePhoto,
                          icon: Symbols.photo_camera_rounded,
                          kind: ButtonKind.outlined,
                          onPressed: _takePhoto,
                        ),
                        second: FarmTapButton(
                          label: l10n.save,
                          icon: Symbols.check_rounded,
                          onPressed: _condition == null ? null : _save,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------- H04

class DrugStockPage extends StatefulWidget {
  const new({required this.repo, super.key});

  final TreatmentRepository repo;

  @override
  State<DrugStockPage> createState() => _DrugStockPageState();
}

class _DrugStockPageState extends State<DrugStockPage> {
  late Future<List<Drug>> _load = _fetch();

  Future<List<Drug>> _fetch() async =>
      ((await widget.repo.drugs()).data ?? const <Drug>[]).where((d) => d.inStockList).toList();

  Future<void> _openDrug(Drug d) async {
    final l10n = AppLocalizations.of(context);
    final done = await showAdaptiveSheet<bool>(
      context,
      builder: (_) => _DrugStockSheet(repo: widget.repo, drug: d),
    );
    if (done != true || !mounted) return;
    FarmTapToast.show(context, message: l10n.stockSaved);
    setState(() => _load = _fetch());
  }

  Future<void> _add() async {
    final drug = await showAdaptiveSheet<Drug>(context, builder: (_) => _AddDrugSheet(repo: widget.repo));
    if (drug == null || !mounted) return;
    setState(() {
      _load = _fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    return FutureBuilder<List<Drug>>(
      future: _load,
      builder: (context, snapshot) {
        final drugs = snapshot.data;
        final low = drugs?.where((d) => d.low).toList() ?? const <Drug>[];
        return AdaptiveScaffold(
          title: l10n.drugStock,
          actions: [BarAction(icon: Symbols.add_rounded, tooltip: l10n.addDrug, onPressed: _add)],
          body: drugs == null
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final d in low) ...[
                      FarmTapBanner(
                        tone: FarmTapTone.warning,
                        icon: Symbols.warning_rounded,
                        title: l10n.drugIsLow(d.shortName),
                        message: l10n.drugLowBody(f.count(d.stock)),
                        actionLabel: l10n.boughtMore,
                        onAction: () => _openDrug(d),
                      ),
                      context.space.gapLg,
                    ],
                    RecordCollection<Drug>(
                      items: drugs,
                      tileBuilder: (context, d) => RecordTile(
                        leading: IconBubble(
                          icon: d.unit == DrugUnit.litres && d.withdrawalDays == 0
                              ? Symbols.water_drop_rounded
                              : Symbols.medication_rounded,
                          tone: d.low
                              ? FarmTapTone.warning
                              : d.unit == DrugUnit.litres
                              ? (d.withdrawalDays == 0 ? FarmTapTone.info : FarmTapTone.gold)
                              : FarmTapTone.primary,
                          size: context.sizes.bubbleMd,
                        ),
                        title: d.name,
                        subtitle: [
                          _stockText(l10n, f, d),
                          if (d.low && d.reorderAt != null)
                            l10n.reorderAt(f.count(d.reorderAt!))
                          else if (d.unit == DrugUnit.bottles)
                            l10n.withdrawalDaysLine(d.withdrawalDays),
                        ].join(' · '),
                        badge: d.low ? StatusBadge(label: l10n.lowBadge, tone: FarmTapTone.warning) : null,
                        trailingValue: d.unit == DrugUnit.litres ? '${f.litresValue(d.stock)} L' : f.count(d.stock),
                        onTap: () => _openDrug(d),
                      ),
                      columns: [
                        RecordColumn(
                          label: l10n.drugLabel,
                          flex: 3,
                          sortKey: (d) => d.name,
                          cell: (c, d) => Text(d.name),
                        ),
                        RecordColumn(
                          label: l10n.stockLabel,
                          sortKey: (d) => d.stock,
                          cell: (c, d) => Text(_stockText(l10n, f, d)),
                        ),
                        RecordColumn(
                          label: l10n.withdrawalLabel,
                          sortKey: (d) => d.withdrawalDays,
                          cell: (c, d) => Text(l10n.daysWithdrawal(d.withdrawalDays)),
                        ),
                        RecordColumn(
                          label: l10n.colStatus,
                          cell: (c, d) => d.low
                              ? StatusBadge(label: l10n.lowBadge, tone: FarmTapTone.warning)
                              : const SizedBox.shrink(),
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

class _AddDrugSheet extends StatefulWidget {
  const new({required this.repo});

  final TreatmentRepository repo;

  @override
  State<_AddDrugSheet> createState() => _AddDrugSheetState();
}

class _AddDrugSheetState extends State<_AddDrugSheet> {
  final _name = TextEditingController();
  final _stock = TextEditingController();
  final _days = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _stock, _days]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final drug = (await widget.repo.addDrug(
      name: _name.text.trim(),
      stock: double.tryParse(_stock.text) ?? 0,
      withdrawalDays: int.tryParse(_days.text) ?? 0,
    )).data;
    if (!mounted || drug == null) return;
    FarmTapToast.show(context, message: AppLocalizations.of(context).drugSaved(drug.name));
    Navigator.of(context).pop(drug);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DiscardGuard(
      dirty: [_name, _stock, _days].any((c) => c.text.trim().isNotEmpty),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetTitle(l10n.addDrug),
          context.space.gapLg,
          FarmTapTextField(
            label: l10n.drugName,
            icon: Symbols.medication_rounded,
            controller: _name,
            onChanged: (_) => setState(() {}),
          ),
          context.space.gapLg,
          FarmTapTextField(
            label: l10n.stockLabel,
            icon: Symbols.inventory_2_rounded,
            controller: _stock,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          context.space.gapLg,
          FarmTapTextField(
            label: l10n.withdrawalDaysLabel,
            icon: Symbols.water_drop_rounded,
            controller: _days,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          context.space.gapXl,
          FarmTapButton(
            label: l10n.saveDrug,
            icon: Symbols.check_rounded,
            onPressed: _name.text.trim().isEmpty ? null : _save,
          ),
        ],
      ),
    );
  }
}

/// H04 tap on a drug: "Bought more" (adds stock, price is a vet expense)
/// or "Count" (sets what is on the shelf).
class _DrugStockSheet extends StatefulWidget {
  const new({required this.repo, required this.drug});

  final TreatmentRepository repo;
  final Drug drug;

  @override
  State<_DrugStockSheet> createState() => _DrugStockSheetState();
}

class _DrugStockSheetState extends State<_DrugStockSheet> {
  final _amount = TextEditingController();
  final _price = TextEditingController();
  bool _count = false;
  bool _tried = false;

  @override
  void dispose() {
    _amount.dispose();
    _price.dispose();
    super.dispose();
  }

  double? get _value => double.tryParse(_amount.text.replaceAll(',', '.').trim());

  Future<void> _save() async {
    setState(() => _tried = true);
    final v = _value;
    if (v == null || v < 0 || (!_count && v == 0)) return;
    if (_count) {
      await widget.repo.setDrugStock(widget.drug.id, v);
    } else {
      final price = int.tryParse(_price.text.replaceAll(RegExp('[^0-9]'), ''));
      await widget.repo.restockDrug(widget.drug.id, amount: v, price: price);
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    final d = widget.drug;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetTitle(d.name, subtitle: '${_stockText(l10n, f, d)} · ${l10n.withdrawalDaysLine(d.withdrawalDays)}'),
        context.space.gapMd,
        SegmentedTabs<bool>(
          options: [
            TabOption(value: false, label: l10n.boughtMore),
            TabOption(value: true, label: l10n.countStock),
          ],
          selected: _count,
          onChanged: (v) => setState(() => _count = v),
        ),
        context.space.gapMd,
        FarmTapTextField(
          label: _count ? l10n.howManyNow : l10n.howManyBought,
          icon: Symbols.inventory_2_rounded,
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          error: _tried && (_value == null || _value! < 0) ? l10n.enterAmount : null,
        ),
        if (!_count) ...[
          context.space.gapMd,
          FarmTapTextField(
            label: l10n.pricePaidOptional,
            controller: _price,
            prefixText: 'UGX ',
            keyboardType: TextInputType.number,
          ),
        ],
        context.space.gapLg,
        FarmTapButton(label: l10n.save, icon: Symbols.check_rounded, onPressed: _save),
      ],
    );
  }
}

// ---------------------------------------------------------------- H05

class HealthCalendarPage extends StatefulWidget {
  const new({required this.repo, super.key, this.now});

  final TreatmentRepository repo;
  final DateTime? now;

  @override
  State<HealthCalendarPage> createState() => _HealthCalendarPageState();
}

class _HealthCalendarPageState extends State<HealthCalendarPage> {
  late Future<List<HealthTask>> _load = _fetch();
  bool _month = false;

  Future<List<HealthTask>> _fetch() async => (await widget.repo.schedule()).data ?? const <HealthTask>[];

  IconData _icon(HealthTaskKind k) => switch (k) {
    HealthTaskKind.dipping => Symbols.water_drop_rounded,
    HealthTaskKind.deworming => Symbols.medication_rounded,
    HealthTaskKind.vaccination => Symbols.vaccines_rounded,
  };

  FarmTapTone _tone(HealthTaskKind k) => switch (k) {
    HealthTaskKind.dipping => FarmTapTone.info,
    HealthTaskKind.deworming => FarmTapTone.gold,
    HealthTaskKind.vaccination => FarmTapTone.success,
  };

  Future<void> _done(HealthTask t) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showFarmTapDialog(
      context,
      icon: Symbols.check_circle_rounded,
      title: l10n.markJobDone(t.title),
      primaryLabel: l10n.markDone,
      secondaryLabel: l10n.cancel,
    );
    if (!ok || !mounted) return;
    await widget.repo.setTaskDone(t.id.isEmpty ? t.title : t.id, done: true);
    if (!mounted) return;
    FarmTapToast.show(context, message: l10n.jobDone);
    setState(() => _load = _fetch());
  }

  Future<void> _add() async {
    final task = await showAdaptiveSheet<HealthTask>(
      context,
      builder: (_) => _AddTaskSheet(now: widget.now ?? context.clock.now()),
    );
    if (task == null || !mounted) return;
    await widget.repo.addTask(task);
    if (!mounted) return;
    FarmTapToast.show(context, message: AppLocalizations.of(context).taskAdded);
    setState(() {
      _load = _fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    final now = widget.now ?? context.clock.now();
    return FutureBuilder<List<HealthTask>>(
      future: _load,
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? const <HealthTask>[];
        String when(DateTime d) => d.month == now.month ? '${f.weekdayShort(d)} ${d.day}' : f.day(d);
        return AdaptiveScaffold(
          title: l10n.healthCalendar,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedTabs<bool>(
                options: [
                  TabOption(value: false, label: l10n.listView),
                  TabOption(value: true, label: l10n.monthView),
                ],
                selected: _month,
                onChanged: (v) => setState(() => _month = v),
              ),
              context.space.gapLg,
              if (_month)
                FarmTapCard(
                  child: _MonthGrid(month: now, tasks: tasks, toneOf: _tone),
                )
              else if (snapshot.hasData && tasks.isEmpty)
                EmptyState(title: l10n.noHealthJobs, message: l10n.noHealthJobsBody)
              else
                ListCard(
                  children: [
                    for (final t in tasks)
                      RecordTile(
                        leading: IconBubble(icon: _icon(t.kind), tone: _tone(t.kind), size: context.sizes.bubbleMd),
                        title: t.title,
                        subtitle: t.detail.isEmpty ? null : t.detail,
                        trailingValue: when(t.due),
                        trailingSub: t.due.isBefore(DateTime(now.year, now.month, now.day)) ? l10n.overdue : null,
                        onTap: () => _done(t),
                      ),
                  ],
                ),
              context.space.gapLg,
              FarmTapButton(
                label: l10n.addToCalendar,
                icon: Symbols.add_rounded,
                kind: ButtonKind.outlined,
                onPressed: _add,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Month view: one cell per day, a coloured dot on days with a job.
class _MonthGrid extends StatelessWidget {
  const new({required this.month, required this.tasks, required this.toneOf});

  final DateTime month;
  final List<HealthTask> tasks;
  final FarmTapTone Function(HealthTaskKind) toneOf;

  @override
  Widget build(BuildContext context) {
    final f = _fmt(context);
    final first = DateTime(month.year, month.month);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final lead = first.weekday - 1;
    final today = month.day;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('${f.monthShort(first)} ${first.year}', style: context.text.titleSmall),
        context.space.gapSm,
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var i = 0; i < 7; i++)
              Center(
                child: Text(
                  f.weekdayShort(first.add(Duration(days: i - lead))).substring(0, 1),
                  style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ),
            for (var i = 0; i < lead; i++) const SizedBox.shrink(),
            for (var d = 1; d <= days; d++)
              Builder(
                builder: (context) {
                  final due = tasks.where(
                    (t) => t.due.year == first.year && t.due.month == first.month && t.due.day == d,
                  );
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$d',
                        style: (d == today ? context.text.titleSmall : context.text.bodyMedium)?.copyWith(
                          color: d == today ? context.colors.primary : null,
                        ),
                      ),
                      if (due.isNotEmpty)
                        Icon(
                          Symbols.circle,
                          fill: 1,
                          size: context.sizes.iconXs,
                          color: toneOf(due.first.kind).of(context).accent,
                        ),
                    ],
                  );
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _AddTaskSheet extends StatefulWidget {
  const new({required this.now});

  final DateTime now;

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _title = TextEditingController();
  HealthTaskKind _kind = HealthTaskKind.vaccination;
  late DateTime _date = DateTime(widget.now.year, widget.now.month, widget.now.day + 7);

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    return DiscardGuard(
      dirty: _title.text.trim().isNotEmpty,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetTitle(l10n.addToCalendar),
          context.space.gapLg,
          FarmTapTextField(
            label: l10n.taskTitle,
            icon: Symbols.event_rounded,
            controller: _title,
            onChanged: (_) => setState(() {}),
          ),
          context.space.gapLg,
          SegmentedTabs<HealthTaskKind>(
            options: [
              TabOption(value: HealthTaskKind.vaccination, label: l10n.kindVaccination),
              TabOption(value: HealthTaskKind.dipping, label: l10n.kindDipping),
              TabOption(value: HealthTaskKind.deworming, label: l10n.kindDeworming),
            ],
            selected: _kind,
            onChanged: (k) => setState(() => _kind = k),
          ),
          context.space.gapLg,
          FarmTapSelectField<int>(
            label: l10n.taskDate,
            icon: Symbols.calendar_month_rounded,
            options: const [1, 2, 3, 7, 14, 30],
            value: _date.difference(DateTime(widget.now.year, widget.now.month, widget.now.day)).inDays,
            labelOf: (d) => f.day(DateTime(widget.now.year, widget.now.month, widget.now.day + d)),
            onChanged: (d) => setState(() => _date = DateTime(widget.now.year, widget.now.month, widget.now.day + d)),
          ),
          context.space.gapXl,
          FarmTapButton(
            label: l10n.saveTask,
            icon: Symbols.check_rounded,
            onPressed: _title.text.trim().isEmpty
                ? null
                : () =>
                      Navigator.of(context)
                          .pop(HealthTask(kind: _kind, title: _title.text.trim(), detail: '', due: _date)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- H06

class WithdrawalListPage extends StatelessWidget {
  const new({required this.repo, required this.onAnimal, super.key, this.now});

  final TreatmentRepository repo;
  final ValueChanged<String> onAnimal;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = _fmt(context);
    final now = this.now ?? context.clock.now();
    return FutureBuilder<List<TreatmentRecord>?>(
      future: repo.withdrawals(now).then((r) => r.data),
      builder: (context, snapshot) {
        final list = snapshot.data;
        return AdaptiveScaffold(
          title: l10n.milkNotForSale,
          body: list == null
              ? const SizedBox.shrink()
              : list.isEmpty
              ? SizedBox(
                  height: context.sizes.photoPreview * 3,
                  child: EmptyState(title: l10n.noWithdrawalsTitle, message: l10n.noWithdrawalsBody),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FarmTapBanner(
                      tone: FarmTapTone.danger,
                      icon: Symbols.error_rounded,
                      title: l10n.keepMilkSeparate(list.length),
                      message: l10n.keepMilkSeparateBody,
                    ),
                    context.space.gapLg,
                    ListCard(
                      children: [
                        for (final r in list)
                          RecordTile(
                            leading: CowAvatar(avatarIndex: r.avatarIndex, animalId: r.animalId),
                            title: r.animalName,
                            subtitle: l10n.drugSince(r.drug.shortName, f.dayMonth(r.given)),
                            badge: _animalBadge(l10n, r),
                            trailingValue: '${f.weekdayShort(r.safeFrom)} ${r.safeFrom.day}',
                            trailingSub: l10n.safeFrom,
                            onTap: () => onAnimal(r.animalId),
                          ),
                      ],
                    ),
                    context.space.gapLg,
                    FarmTapCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CardHeader(title: l10n.whyThisMatters),
                          context.space.gapSm,
                          Text(l10n.whyThisMattersBody, style: context.text.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
