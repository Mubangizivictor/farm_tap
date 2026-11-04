import 'dart:async';

import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/sectors/cattle/operations/data/operations_repository.dart';
import 'package:farm_tap/sectors/cattle/operations/domain/operations_models.dart';
import 'package:farm_tap/sectors/cattle/operations/presentation/pages/operations_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Vaccinations (decision 0024): what was given, when the next dose is due,
/// and its cost as a vet expense. Reminders come from the next due date.
class VaccinationsPage extends StatefulWidget {
  const new({required this.repo, required this.canEdit, super.key});

  final OperationsRepository repo;
  final bool canEdit;

  @override
  State<VaccinationsPage> createState() => _VaccinationsPageState();
}

class _VaccinationsPageState extends State<VaccinationsPage> {
  @override
  void initState() {
    super.initState();
    if (!widget.repo.loaded) unawaited(widget.repo.restore());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = MaterialLocalizations.of(context);
    final today = context.clock.today();
    return ListenableBuilder(
      listenable: widget.repo,
      builder: (context, _) {
        final next = widget.repo.upcoming;
        final all = widget.repo.vaccinations;
        String who(Vaccination v) => v.animalIds.isEmpty ? l10n.opsWholeHerd : l10n.opsAnimals(v.animalIds.length);
        return AdaptiveScaffold(
          title: l10n.opsVaccinations,
          showBack: true,
          floatingActionButton: widget.canEdit
              ? FarmTapFab(label: l10n.opsRecordVaccination, icon: Symbols.vaccines_rounded, onPressed: _add)
              : null,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!widget.repo.loaded)
                const FarmTapPageLoader()
              else if (all.isEmpty)
                EmptyState(
                  title: l10n.opsNoVaccinations,
                  message: l10n.opsNoVaccinationsBody,
                  animation: FarmTapAnimations.treatmentSaved,
                  actionLabel: widget.canEdit ? l10n.opsRecordVaccination : null,
                  onAction: widget.canEdit ? _add : null,
                )
              else ...[
                if (next.isNotEmpty) ...[
                  ListCard(
                    title: l10n.opsNextDoses,
                    children: [
                      for (final v in next)
                        RecordTile(
                          leading: IconBubble(
                            icon: Symbols.event_rounded,
                            tone: v.nextDue!.isBefore(today) ? FarmTapTone.danger : FarmTapTone.info,
                            size: context.sizes.bubbleMd,
                          ),
                          title: v.vaccine,
                          subtitle: '${fmt.formatMediumDate(v.nextDue!)} · ${who(v)}',
                          badge: v.nextDue!.isBefore(today)
                              ? StatusBadge(label: l10n.opsOverdue, tone: FarmTapTone.danger)
                              : v.nextDue!.difference(today).inDays <= 7
                              ? StatusBadge(label: l10n.opsSoon, tone: FarmTapTone.warning)
                              : null,
                          showChevron: false,
                        ),
                    ],
                  ),
                  context.space.gapLg,
                ],
                ListCard(
                  title: l10n.opsGiven,
                  children: [
                    for (final v in all)
                      RecordTile(
                        leading: IconBubble(
                          icon: Symbols.vaccines_rounded,
                          tone: FarmTapTone.success,
                          size: context.sizes.bubbleMd,
                        ),
                        title: v.vaccine,
                        subtitle: '${fmt.formatMediumDate(v.given)} · ${who(v)}',
                        trailingValue: v.cost == null ? null : l10n.opsUgx(v.cost!),
                        showChevron: widget.canEdit,
                        onTap: widget.canEdit ? () => _remove(v) : null,
                      ),
                  ],
                ),
              ],
              if (!widget.canEdit) const ViewOnlyNote(),
            ],
          ),
        );
      },
    );
  }

  Future<void> _add() => showAdaptiveSheet<void>(
    context,
    builder: (_) => _VaccinationForm(repo: widget.repo, today: context.clock.today()),
  );

  Future<void> _remove(Vaccination v) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showFarmTapDialog(
      context,
      icon: Symbols.delete_rounded,
      title: l10n.opsRemoveVaccination,
      message: l10n.opsRemoveVaccinationBody,
      primaryLabel: l10n.opsRemove,
      primaryKind: ButtonKind.danger,
      secondaryLabel: l10n.cancel,
      tone: FarmTapTone.danger,
    );
    if (ok) await widget.repo.removeVaccination(v.id);
  }
}

class _VaccinationForm extends StatefulWidget {
  const new({required this.repo, required this.today});

  final OperationsRepository repo;
  final DateTime today;

  @override
  State<_VaccinationForm> createState() => _VaccinationFormState();
}

class _VaccinationFormState extends State<_VaccinationForm> {
  String _vaccine = commonVaccines.first;
  late DateTime _given = widget.today;
  DateTime? _next;
  final _cost = TextEditingController();
  String? _vet;
  bool _saving = false;

  @override
  void dispose() {
    _cost.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vets = widget.repo.contacts.where((c) => c.kind == ContactKind.vet).toList();
    return FormSheet(
      title: l10n.opsRecordVaccination,
      saving: _saving,
      onSave: () async {
        setState(() => _saving = true);
        await widget.repo.addVaccination(
          Vaccination(
            id: '',
            vaccine: _vaccine,
            given: _given,
            nextDue: _next,
            cost: int.tryParse(_cost.text.replaceAll(',', '')),
            vetId: _vet,
          ),
        );
        if (context.mounted) Navigator.of(context).pop();
      },
      children: [
        FarmTapCard(
          onTap: () async {
            final v = await showSearchPicker(
              context,
              title: l10n.opsVaccine,
              options: commonVaccines,
              selected: _vaccine,
            );
            if (v != null && v.trim().isNotEmpty) setState(() => _vaccine = v.trim());
          },
          child: Row(
            children: [
              Icon(Symbols.vaccines_rounded, color: context.colors.primary),
              context.space.gapMd,
              Expanded(
                child: Text(_vaccine, style: context.text.bodyLarge, overflow: TextOverflow.ellipsis),
              ),
              Icon(Symbols.expand_more_rounded, color: context.colors.onSurfaceVariant),
            ],
          ),
        ),
        Text(l10n.opsWholeHerdNote, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
        DateField(
          label: l10n.opsGivenOn,
          value: _given,
          first: widget.today.subtract(const Duration(days: 365)),
          last: widget.today,
          onChanged: (d) => setState(() => _given = d ?? _given),
        ),
        DateField(
          label: l10n.opsNextDue,
          value: _next,
          clearable: true,
          first: widget.today,
          last: widget.today.add(const Duration(days: 3 * 365)),
          onChanged: (d) => setState(() => _next = d),
        ),
        FarmTapTextField(
          label: l10n.opsCostUgx,
          controller: _cost,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        if (vets.isNotEmpty)
          FarmTapSelectField<String?>(
            label: l10n.opsVet,
            options: [null, for (final v in vets) v.id],
            value: _vet,
            labelOf: (id) => id == null ? l10n.opsNoVet : vets.firstWhere((v) => v.id == id).name,
            onChanged: (v) => setState(() => _vet = v),
          ),
      ],
    );
  }
}
