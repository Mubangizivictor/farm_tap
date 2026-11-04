import 'dart:async';

import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/people/domain/staff_directory.dart';
import 'package:farm_tap/core/people/domain/staff_member.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/sectors/cattle/operations/data/operations_repository.dart';
import 'package:farm_tap/sectors/cattle/operations/domain/operations_models.dart';
import 'package:farm_tap/sectors/cattle/operations/presentation/pages/operations_widgets.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Duty roster (decision 0024): who does which job on which day, who stands
/// in when someone is away, and time away. The same records as the web.
class RosterPage extends StatefulWidget {
  const new({required this.repo, required this.staff, required this.canEdit, super.key, this.myStaffId});

  final OperationsRepository repo;
  final StaffDirectory staff;
  final bool canEdit;

  /// The signed-in worker: their own duties are marked.
  final String? myStaffId;

  @override
  State<RosterPage> createState() => _RosterPageState();
}

class _RosterPageState extends State<RosterPage> {
  List<StaffMember> _people = const [];
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    if (!widget.repo.loaded) unawaited(widget.repo.restore());
    unawaited(_loadStaff());
  }

  Future<void> _loadStaff() async {
    final r = (await widget.staff.staff()).data ?? const <StaffMember>[];
    if (mounted) setState(() => _people = r);
  }

  String _name(String? id) => _people.where((p) => p.id == id).firstOrNull?.name ?? '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = MaterialLocalizations.of(context);
    final today = context.clock.today();
    final day = today.add(Duration(days: _offset));
    final names = shortDays(context);
    return ListenableBuilder(
      listenable: widget.repo,
      builder: (context, _) {
        final list = widget.repo.dutiesOn(day);
        final away = widget.repo.absences.where((a) => !a.to.isBefore(today)).toList();
        return AdaptiveScaffold(
          title: l10n.opsRoster,
          showBack: true,
          floatingActionButton: widget.canEdit
              ? FarmTapFab(label: l10n.opsAddDuty, icon: Symbols.add_rounded, onPressed: () => _editDuty(null))
              : null,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilterChips<int>(
                options: [
                  for (var i = 0; i < 7; i++)
                    FilterOption(
                      value: i,
                      label: i == 0
                          ? l10n.today
                          : i == 1
                          ? l10n.opsTomorrow
                          : '${names[Duty.webDay(today.add(Duration(days: i)))]} ${today.add(Duration(days: i)).day}',
                    ),
                ],
                selected: _offset,
                onSelected: (v) => setState(() => _offset = v),
              ),
              context.space.gapMd,
              if (!widget.repo.loaded)
                const FarmTapPageLoader()
              else if (widget.repo.duties.isEmpty)
                EmptyState(
                  title: l10n.opsNoDuties,
                  message: l10n.opsNoDutiesBody,
                  animation: FarmTapAnimations.syncDone,
                  actionLabel: widget.canEdit ? l10n.opsAddDuty : null,
                  onAction: widget.canEdit ? () => _editDuty(null) : null,
                )
              else
                ListCard(
                  title: fmt.formatFullDate(day),
                  children: [
                    if (list.isEmpty)
                      Padding(padding: context.space.listItem, child: Text(l10n.opsNothingThatDay))
                    else
                      for (final x in list)
                        RecordTile(
                          leading: IconBubble(
                            icon: x.staffId == null ? Symbols.warning_rounded : Symbols.assignment_ind_rounded,
                            tone: x.staffId == null
                                ? FarmTapTone.danger
                                : x.staffId == widget.myStaffId
                                ? FarmTapTone.gold
                                : FarmTapTone.primary,
                            size: context.sizes.bubbleMd,
                          ),
                          title: '${dutyLabel(l10n, x.duty)} · ${shiftLabel(l10n, x.duty.shift)}',
                          subtitle: x.staffId == null
                              ? l10n.opsNobodyOn(_name(x.duty.staffId))
                              : x.covering
                              ? l10n.opsStandsIn(_name(x.staffId), _name(x.duty.staffId))
                              : _name(x.staffId),
                          badge: x.staffId == widget.myStaffId && x.staffId != null
                              ? StatusBadge(label: l10n.opsYou, tone: FarmTapTone.gold)
                              : null,
                          showChevron: widget.canEdit,
                          onTap: widget.canEdit ? () => _editDuty(x.duty) : null,
                        ),
                  ],
                ),
              context.space.gapLg,
              ListCard(
                title: l10n.opsAway,
                actionLabel: widget.canEdit ? l10n.opsAddAway : null,
                onAction: widget.canEdit ? _addAway : null,
                children: [
                  if (away.isEmpty)
                    Padding(padding: context.space.listItem, child: Text(l10n.opsNobodyAway))
                  else
                    for (final a in away)
                      RecordTile(
                        leading: PersonAvatar(name: _name(a.staffId), size: context.sizes.avatarMd),
                        title: _name(a.staffId),
                        subtitle:
                            '${fmt.formatShortMonthDay(a.from)} – ${fmt.formatShortMonthDay(a.to)}${a.reason == null ? '' : ' · ${a.reason}'}',
                        showChevron: false,
                        trailing: widget.canEdit
                            ? IconButton(
                                tooltip: l10n.opsRemove,
                                icon: const Icon(Symbols.close_rounded),
                                onPressed: () => unawaited(widget.repo.removeAbsence(a.id)),
                              )
                            : null,
                      ),
                ],
              ),
              if (!widget.canEdit) const ViewOnlyNote(),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editDuty(Duty? d) => showAdaptiveSheet<void>(
    context,
    builder: (_) => _DutyForm(repo: widget.repo, people: _people, duty: d),
  );

  Future<void> _addAway() => showAdaptiveSheet<void>(
    context,
    builder: (_) => _AwayForm(repo: widget.repo, people: _people, today: context.clock.today()),
  );
}

class _DutyForm extends StatefulWidget {
  const new({required this.repo, required this.people, this.duty});

  final OperationsRepository repo;
  final List<StaffMember> people;
  final Duty? duty;

  @override
  State<_DutyForm> createState() => _DutyFormState();
}

class _DutyFormState extends State<_DutyForm> {
  late DutyActivity _activity = widget.duty?.activity ?? DutyActivity.milking;
  late final _label = TextEditingController(text: widget.duty?.label);
  late String? _staff = widget.duty?.staffId ?? widget.people.firstOrNull?.id;
  late String? _standIn = widget.duty?.standInId;
  late DutyShift _shift = widget.duty?.shift ?? DutyShift.morning;
  late final Set<int> _days = {...?widget.duty?.days};
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_staff == null || (_activity == DutyActivity.other && _label.text.trim().isEmpty)) {
      setState(() => _error = l10n.opsDutyNeeds);
      return;
    }
    setState(() => _saving = true);
    await widget.repo.saveDuty(
      Duty(
        id: widget.duty?.id ?? '',
        activity: _activity,
        label: _activity == DutyActivity.other ? _label.text.trim() : null,
        staffId: _staff!,
        standInId: _standIn == _staff ? null : _standIn,
        days: (_days.toList()..sort()),
        shift: _shift,
        note: widget.duty?.note,
        contactId: widget.duty?.contactId,
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final names = shortDays(context);
    String nameOf(String? id) =>
        id == null ? l10n.opsNoStandIn : widget.people.where((p) => p.id == id).firstOrNull?.name ?? '';
    return FormSheet(
      title: widget.duty == null ? l10n.opsAddDuty : l10n.opsEditDuty,
      saving: _saving,
      onSave: _save,
      onDelete: widget.duty == null
          ? null
          : () async {
              setState(() => _saving = true);
              await widget.repo.removeDuty(widget.duty!.id);
              if (context.mounted) Navigator.of(context).pop();
            },
      children: [
        FarmTapSelectField<DutyActivity>(
          label: l10n.opsJob,
          options: DutyActivity.values,
          value: _activity,
          labelOf: (a) => activityLabel(l10n, a),
          onChanged: (a) => setState(() => _activity = a),
        ),
        if (_activity == DutyActivity.other) FarmTapTextField(label: l10n.opsJobName, controller: _label),
        if (widget.people.isEmpty)
          Text(l10n.opsAddWorkersFirst, style: context.text.bodyMedium)
        else ...[
          FarmTapSelectField<String>(
            label: l10n.opsWho,
            options: [for (final p in widget.people) p.id],
            value: _staff,
            labelOf: nameOf,
            error: _error,
            onChanged: (v) => setState(() => _staff = v),
          ),
          FarmTapSelectField<String?>(
            label: l10n.opsStandIn,
            options: [null, for (final p in widget.people.where((p) => p.id != _staff)) p.id],
            value: _standIn,
            labelOf: nameOf,
            onChanged: (v) => setState(() => _standIn = v),
          ),
        ],
        FarmTapSelectField<DutyShift>(
          label: l10n.opsShift,
          options: DutyShift.values,
          value: _shift,
          labelOf: (s) => shiftLabel(l10n, s),
          onChanged: (s) => setState(() => _shift = s),
        ),
        Text(l10n.opsWhichDays, style: context.text.labelLarge),
        Wrap(
          spacing: context.space.sm,
          runSpacing: context.space.sm,
          children: [
            for (var d = 0; d < 7; d++)
              FilterChip(
                label: Text(names[d]),
                selected: _days.contains(d),
                onSelected: (on) => setState(() => on ? _days.add(d) : _days.remove(d)),
              ),
          ],
        ),
        Text(
          _days.isEmpty ? l10n.opsEveryDay : l10n.opsSomeDays,
          style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _AwayForm extends StatefulWidget {
  const new({required this.repo, required this.people, required this.today});

  final OperationsRepository repo;
  final List<StaffMember> people;
  final DateTime today;

  @override
  State<_AwayForm> createState() => _AwayFormState();
}

class _AwayFormState extends State<_AwayForm> {
  late String? _staff = widget.people.firstOrNull?.id;
  late DateTime _from = widget.today;
  late DateTime _to = widget.today;
  final _reason = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final last = widget.today.add(const Duration(days: 366));
    return FormSheet(
      title: l10n.opsAddAway,
      saving: _saving,
      onSave: _staff == null
          ? null
          : () async {
              setState(() => _saving = true);
              await widget.repo.addAbsence(
                Absence(
                  id: '',
                  staffId: _staff!,
                  from: _from,
                  to: _to.isBefore(_from) ? _from : _to,
                  reason: _reason.text.trim().isEmpty ? null : _reason.text.trim(),
                ),
              );
              if (context.mounted) Navigator.of(context).pop();
            },
      children: [
        if (widget.people.isEmpty)
          Text(l10n.opsAddWorkersFirst)
        else
          FarmTapSelectField<String>(
            label: l10n.opsWho,
            options: [for (final p in widget.people) p.id],
            value: _staff,
            labelOf: (id) => widget.people.firstWhere((p) => p.id == id).name,
            onChanged: (v) => setState(() => _staff = v),
          ),
        DateField(
          label: l10n.opsFrom,
          value: _from,
          first: widget.today.subtract(const Duration(days: 30)),
          last: last,
          onChanged: (d) => setState(() => _from = d ?? _from),
        ),
        DateField(
          label: l10n.opsTo,
          value: _to,
          first: _from,
          last: last,
          onChanged: (d) => setState(() => _to = d ?? _to),
        ),
        FarmTapTextField(label: l10n.opsReason, controller: _reason),
      ],
    );
  }
}
