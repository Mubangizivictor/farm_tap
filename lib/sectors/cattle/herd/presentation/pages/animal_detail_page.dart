// E03 animal detail, E06 record-event sheet, E07 calf born, E08 confirm death.
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

enum _Tab { timeline, milk, health, breeding }

class AnimalDetailPage extends StatefulWidget {
  const new({
    required this.repo,
    required this.animalId,
    required this.onEvent,
    super.key,
    this.onLabels,
    this.onEdit,
    this.onGone,
    this.today,
  });

  final HerdRepository repo;
  final String animalId;

  /// A record kind was chosen in the E06 sheet (milk, treatment, heat).
  final ValueChanged<HerdEventKind> onEvent;
  final VoidCallback? onLabels;
  final VoidCallback? onEdit;

  /// After recording a death: leave the page.
  final VoidCallback? onGone;
  final DateTime? today;

  @override
  State<AnimalDetailPage> createState() => _AnimalDetailPageState();
}

class _AnimalDetailPageState extends State<AnimalDetailPage> {
  late Future<AnimalDetail?> _detail = widget.repo.detail(widget.animalId).then((r) => r.data);
  _Tab _tab = _Tab.timeline;
  StreamSubscription<Object?>? _changes;

  @override
  void initState() {
    super.initState();
    // Edits, photos and new records show as soon as they are saved.
    _changes = widget.repo.watchAnimals().skip(1).listen((_) => _reload());
  }

  @override
  void dispose() {
    unawaited(_changes?.cancel());
    super.dispose();
  }

  void _reload() {
    if (mounted) setState(() => _detail = widget.repo.detail(widget.animalId).then((r) => r.data));
  }

  Future<void> _sell(Animal animal) async {
    final l10n = AppLocalizations.of(context);
    final sale = await showSellAnimalSheet(context, animal.name.isEmpty ? animal.tagNumber : animal.name);
    if (sale == null || !mounted) return;
    await widget.repo.recordSale(animal.id, price: sale.$1, buyer: sale.$2);
    if (!mounted) return;
    FarmTapToast.show(context, message: l10n.animalSoldSaved(animal.name.isEmpty ? animal.tagNumber : animal.name));
    widget.onGone?.call();
  }

  Future<void> _nameCalf(Animal calf) async {
    final l10n = AppLocalizations.of(context);
    final name = await showTextEntrySheet(context, title: l10n.nameTheCalf, label: l10n.nameLabel);
    if (name == null || name.trim().isEmpty) return;
    await widget.repo.updateAnimal(calf.copyWith(name: name.trim()));
    if (mounted) FarmTapToast.show(context, message: l10n.animalSaved(name.trim()));
  }

  Future<void> _record(Animal animal) async {
    final kind = await showRecordEventSheet(context, animal.name);
    if (kind == null || !mounted) return;
    switch (kind) {
      case HerdEventKind.died:
        final cause = await showConfirmDeath(context, animal.name);
        if (cause == null || !mounted) return;
        await widget.repo.recordDeath(animal.id, cause: cause.isEmpty ? null : cause);
        widget.onGone?.call();
      case HerdEventKind.calving:
        final calf = (await widget.repo.recordCalving(animal.id, at: widget.today ?? context.clock.now())).data;
        if (calf == null || !mounted) return;
        final action = await showCalfBorn(context, mother: animal, calf: calf);
        if (action == CelebrationAction.primary && mounted) await _nameCalf(calf);
        _reload();
      case HerdEventKind.sold:
        await _sell(animal);
      case HerdEventKind.milk || HerdEventKind.treatment || HerdEventKind.heat:
        widget.onEvent(kind);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = FarmTapFormat(Localizations.localeOf(context).toLanguageTag());
    final today = DateUtils.dateOnly(widget.today ?? context.clock.now());
    return FutureBuilder<AnimalDetail?>(
      future: _detail,
      builder: (context, snapshot) {
        final d = snapshot.data;
        final a = d?.animal;
        return AdaptiveScaffold(
          title: l10n.animalTitle,
          actions: [
            BarAction(icon: Symbols.qr_code_2_rounded, tooltip: l10n.printLabels, onPressed: widget.onLabels),
            BarAction(icon: Symbols.edit_rounded, tooltip: l10n.edit, onPressed: widget.onEdit),
          ],
          floatingActionButton: a == null
              ? null
              : FarmTapFab(label: l10n.record, icon: Symbols.add_rounded, onPressed: () => _record(a)),
          body: d == null || a == null
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FarmTapCard(
                      child: Row(
                        children: [
                          CowAvatar(
                            avatarIndex: a.avatarIndex,
                            animalId: a.id,
                            photoUrl: a.photo,
                            size: context.sizes.avatarXl,
                          ),
                          context.space.gapLg,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.name, style: context.text.headlineSmall),
                                Text(
                                  l10n.animalHeaderLine(
                                    a.tagNumber,
                                    a.breed,
                                    animalKindLabel(l10n, a),
                                    a.ageYears(today),
                                  ),
                                  style: context.text.bodySmall,
                                ),
                                context.space.gapXs,
                                if (a.dairyStatus == DairyStatus.treated)
                                  const NotForSaleBadge()
                                else
                                  DairyStatusBadge(a.dairyStatus),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (d.withdrawal != null) ...[
                      context.space.gapLg,
                      FarmTapBanner(
                        tone: FarmTapTone.danger,
                        icon: Symbols.error_rounded,
                        title: l10n.notForSaleUntil(f.day(d.withdrawal!.until)),
                        message: l10n.withdrawalBody(d.withdrawal!.drug, d.withdrawal!.daysLeft(today)),
                      ),
                    ],
                    context.space.gapLg,
                    MetricStrip(
                      children: [
                        MetricCard(
                          icon: Symbols.water_drop_rounded,
                          label: l10n.avgMilkDay,
                          value: f.litresValue(d.avgMilk, trim: false),
                          unit: l10n.litreUnit,
                        ),
                        MetricCard(
                          icon: Symbols.calendar_month_rounded,
                          label: l10n.daysInMilk,
                          value: f.count(d.daysInMilk),
                          tone: FarmTapTone.gold,
                        ),
                        if (d.pregnancyCheckDue != null)
                          MetricCard(
                            icon: Symbols.favorite_rounded,
                            label: l10n.pregnancy,
                            value: l10n.pregnancyCheck,
                            caption: l10n.dueDate(f.dayMonth(d.pregnancyCheckDue!)),
                            tone: FarmTapTone.info,
                          ),
                      ],
                    ),
                    context.space.gapLg,
                    SegmentedTabs<_Tab>(
                      options: [
                        TabOption(value: _Tab.timeline, label: l10n.tabTimeline),
                        TabOption(value: _Tab.milk, label: l10n.tabMilk),
                        TabOption(value: _Tab.health, label: l10n.tabHealth),
                        TabOption(value: _Tab.breeding, label: l10n.tabBreeding),
                      ],
                      selected: _tab,
                      onChanged: (t) => setState(() => _tab = t),
                    ),
                    context.space.gapLg,
                    _TimelineCard(events: _events(d.timeline), today: today),
                  ],
                ),
        );
      },
    );
  }

  List<AnimalEvent> _events(List<AnimalEvent> all) => switch (_tab) {
    _Tab.timeline => all,
    _Tab.milk => [
      for (final e in all)
        if (e is MilkEvent) e,
    ],
    _Tab.health => [
      for (final e in all)
        if (e is TreatmentEvent || e is VaccinationEvent) e,
    ],
    _Tab.breeding => [
      for (final e in all)
        if (e is ServiceEvent) e,
    ],
  };
}

class _TimelineCard extends StatelessWidget {
  const new({required this.events, required this.today});

  final List<AnimalEvent> events;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = FarmTapFormat(Localizations.localeOf(context).toLanguageTag());
    if (events.isEmpty) {
      return FarmTapCard(child: Text(l10n.noEventsYet, style: context.text.bodyMedium));
    }
    String when(DateTime at) {
      final day = DateUtils.dateOnly(at);
      if (day == today) return l10n.today;
      if (day == today.subtract(const Duration(days: 1))) return l10n.yesterday;
      return f.dayMonth(at);
    }

    return FarmTapCard(
      child: Timeline(
        entries: [
          for (final e in events)
            switch (e) {
              TreatmentEvent(:final drug, :final reason, :final vet, :final safeFrom) => TimelineEntry(
                icon: Symbols.medication_rounded,
                tone: FarmTapTone.danger,
                title: l10n.evTreatment(drug),
                subtitle: l10n.evTreatmentSub(reason, vet, f.dayMonth(safeFrom)),
                time: when(e.at),
              ),
              MilkEvent(:final morning, :final evening, :final total) => TimelineEntry(
                icon: Symbols.water_drop_rounded,
                title: l10n.evMilk(f.litresValue(total, trim: false)),
                subtitle: l10n.evMilkSub(f.litresValue(morning, trim: false), f.litresValue(evening, trim: false)),
                time: when(e.at),
              ),
              ServiceEvent(:final method, :final straw, :final by) => TimelineEntry(
                icon: Symbols.favorite_rounded,
                tone: FarmTapTone.info,
                title: l10n.evServed(method),
                subtitle: l10n.evServedSub(straw, by),
                time: when(e.at),
              ),
              VaccinationEvent(:final name, :final batch) => TimelineEntry(
                icon: Symbols.vaccines_rounded,
                tone: FarmTapTone.success,
                title: l10n.evVaccination(name),
                subtitle: l10n.evBatch(batch),
                time: when(e.at),
              ),
            },
        ],
      ),
    );
  }
}

/// E06 — what happened? Bottom sheet on phones, dialog wider.
Future<HerdEventKind?> showRecordEventSheet(BuildContext context, String animalName) =>
    showAdaptiveSheet<HerdEventKind>(context, builder: (_) => _RecordEventSheet(animalName: animalName));

class _RecordEventSheet extends StatelessWidget {
  const new({required this.animalName});

  final String animalName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget tile(HerdEventKind k, IconData icon, FarmTapTone tone, String label) =>
        ActionTile(icon: icon, label: label, tone: tone, onTap: () => Navigator.of(context).pop(k));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetTitle(l10n.recordFor(animalName), subtitle: l10n.whatHappened),
        context.space.gapLg,
        ResponsiveGrid(
          minItemWidth: context.sizes.gridAction,
          maxColumns: 3,
          spacing: context.space.md,
          children: [
            tile(HerdEventKind.milk, Symbols.water_drop_rounded, FarmTapTone.primary, l10n.evKindMilk),
            tile(HerdEventKind.treatment, Symbols.medication_rounded, FarmTapTone.danger, l10n.evKindTreatment),
            tile(HerdEventKind.heat, Symbols.favorite_rounded, FarmTapTone.danger, l10n.evKindHeat),
            tile(HerdEventKind.calving, Symbols.pets_rounded, FarmTapTone.info, l10n.evKindCalving),
            tile(HerdEventKind.sold, Symbols.sell_rounded, FarmTapTone.gold, l10n.evKindSold),
            tile(HerdEventKind.died, Symbols.cancel_rounded, FarmTapTone.neutral, l10n.evKindDied),
          ],
        ),
      ],
    );
  }
}

/// E08 — confirm a death. Resolves to the cause ('' if none) or null.
Future<String?> showConfirmDeath(BuildContext context, String animalName) => showDialog<String>(
  context: context,
  builder: (_) => _ConfirmDeathDialog(animalName: animalName),
);

class _ConfirmDeathDialog extends StatefulWidget {
  const new({required this.animalName});

  final String animalName;

  @override
  State<_ConfirmDeathDialog> createState() => _ConfirmDeathDialogState();
}

class _ConfirmDeathDialogState extends State<_ConfirmDeathDialog> {
  final _cause = TextEditingController();

  @override
  void dispose() {
    _cause.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DialogFrame(
      child: FarmTapDialog(
        icon: Symbols.cancel_rounded,
        tone: FarmTapTone.danger,
        title: l10n.recordDeathTitle(widget.animalName),
        message: l10n.recordDeathBody,
        primaryLabel: l10n.yesRecordDeath,
        primaryKind: ButtonKind.danger,
        secondaryLabel: l10n.cancel,
        secondaryKind: ButtonKind.text,
        onPrimary: () => Navigator.of(context).pop(_cause.text.trim()),
        onSecondary: () => Navigator.of(context).pop(),
        child: TextField(
          controller: _cause,
          decoration: InputDecoration(hintText: l10n.causeHint),
        ),
      ),
    );
  }
}

/// E06 "Sold": the price (UGX) and who bought, or null when cancelled.
Future<(int, String?)?> showSellAnimalSheet(BuildContext context, String animalName) =>
    showAdaptiveSheet<(int, String?)>(context, builder: (_) => _SellSheet(animalName: animalName));

class _SellSheet extends StatefulWidget {
  const new({required this.animalName});

  final String animalName;

  @override
  State<_SellSheet> createState() => _SellSheetState();
}

class _SellSheetState extends State<_SellSheet> {
  final _price = TextEditingController();
  final _buyer = TextEditingController();
  bool _tried = false;

  @override
  void dispose() {
    _price.dispose();
    _buyer.dispose();
    super.dispose();
  }

  int? get _amount => int.tryParse(_price.text.replaceAll(RegExp('[^0-9]'), ''));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetTitle(l10n.sellAnimalTitle(widget.animalName), subtitle: l10n.sellAnimalBody),
        context.space.gapLg,
        FarmTapTextField(
          label: l10n.salePrice,
          controller: _price,
          prefixText: 'UGX ',
          keyboardType: TextInputType.number,
          autofocus: true,
          error: _tried && (_amount ?? 0) <= 0 ? l10n.enterPrice : null,
          onChanged: (_) => setState(() {}),
        ),
        context.space.gapMd,
        FarmTapTextField(label: l10n.boughtByOptional, controller: _buyer, icon: Symbols.person_rounded),
        context.space.gapLg,
        FarmTapButton(
          label: l10n.recordSale,
          icon: Symbols.sell_rounded,
          onPressed: () {
            setState(() => _tried = true);
            final amount = _amount ?? 0;
            if (amount <= 0) return;
            final buyer = _buyer.text.trim();
            Navigator.of(context).pop((amount, buyer.isEmpty ? null : buyer));
          },
        ),
      ],
    );
  }
}

/// A one-line text sheet ("Name the calf"); null when cancelled.
Future<String?> showTextEntrySheet(BuildContext context, {required String title, required String label}) =>
    showAdaptiveSheet<String>(
      context,
      builder: (_) => _TextEntrySheet(title: title, label: label),
    );

class _TextEntrySheet extends StatefulWidget {
  const new({required this.title, required this.label});

  final String title;
  final String label;

  @override
  State<_TextEntrySheet> createState() => _TextEntrySheetState();
}

class _TextEntrySheetState extends State<_TextEntrySheet> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetTitle(widget.title),
        context.space.gapLg,
        FarmTapTextField(
          label: widget.label,
          controller: _text,
          autofocus: true,
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        context.space.gapLg,
        FarmTapButton(
          label: l10n.save,
          icon: Symbols.check_rounded,
          onPressed: () => Navigator.of(context).pop(_text.text),
        ),
      ],
    );
  }
}

/// E07 — calf born: full-screen celebration on phones, dialog wider.
/// Resolves to the button pressed (primary = name the calf).
Future<CelebrationAction?> showCalfBorn(BuildContext context, {required Animal mother, required Animal calf}) {
  final l10n = AppLocalizations.of(context);
  final f = FarmTapFormat(Localizations.localeOf(context).toLanguageTag());
  Widget row(String label, String value) => Row(
    children: [
      Expanded(child: Text(label, style: context.text.bodySmall)),
      Text(value, style: context.text.titleSmall),
    ],
  );
  return showCelebration(
    context,
    animation: FarmTapAnimations.calfBorn,
    title: l10n.welcomeLittleOne,
    message: l10n.calfBornBody(mother.name, calf.tagNumber),
    primaryLabel: l10n.nameTheCalf,
    primaryIcon: Symbols.edit_rounded,
    secondaryLabel: l10n.done,
    secondaryKind: ButtonKind.text,
    summary: FarmTapCard(
      children: [
        row(l10n.mother, '${mother.name} · ${mother.tagNumber}'),
        row(l10n.born, l10n.todayAt(f.time(calf.dateOfBirth))),
        row(l10n.calf, l10n.heiferTag(calf.tagNumber)),
      ],
    ),
  );
}
