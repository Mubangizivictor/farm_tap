// Worker form fields shared by B09 (first worker) and K01/K02 (add / edit
// worker): name, job (a list or their own words), what they can do, phone,
// pay, 4-digit PIN and the card note.
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/people/domain/staff_member.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

String staffRoleLabel(AppLocalizations l10n, StaffRole r) => switch (r) {
  StaffRole.manager => l10n.roleManager,
  StaffRole.herdsman => l10n.roleHerdsman,
  StaffRole.clerk => l10n.roleMilkClerk,
  StaffRole.worker => l10n.roleWorker,
  StaffRole.vet => l10n.roleVet,
};

String staffCanDo(AppLocalizations l10n, StaffRole r) => switch (r) {
  StaffRole.manager => l10n.canDoManager,
  StaffRole.herdsman => l10n.canDoHerdsman,
  StaffRole.clerk => l10n.canDoClerk,
  StaffRole.worker => l10n.canDoWorker,
  StaffRole.vet => l10n.canDoVet,
};

/// Their job as shown in lists: their own title, else the access name.
String staffTitle(AppLocalizations l10n, StaffMember s) =>
    (s.title ?? '').trim().isEmpty ? staffRoleLabel(l10n, s.role) : s.title!;

/// Jobs offered in the list, with the access each one starts with.
List<(String, StaffRole)> staffJobs(AppLocalizations l10n) => [
  (l10n.roleHerdsman, StaffRole.herdsman),
  (l10n.roleMilker, StaffRole.herdsman),
  (l10n.roleMilkClerk, StaffRole.clerk),
  (l10n.roleWorker, StaffRole.worker),
  (l10n.roleManager, StaffRole.manager),
  (l10n.roleSupervisor, StaffRole.manager),
  (l10n.roleVet, StaffRole.vet),
  (l10n.roleSecretary, StaffRole.clerk),
  (l10n.roleAccountant, StaffRole.clerk),
  (l10n.roleDriver, StaffRole.worker),
  (l10n.roleGuard, StaffRole.worker),
  (l10n.roleCook, StaffRole.worker),
  (l10n.roleFamily, StaffRole.worker),
];

class StaffFormFields extends StatelessWidget {
  const new({
    required this.name,
    required this.job,
    required this.onJob,
    required this.access,
    required this.onAccess,
    required this.onChanged,
    super.key,
    this.phone,
    this.wage,
    this.pin,
    this.onPin,
    this.nameError,
    this.pinError,
    this.showCardNote = true,
  });

  final TextEditingController name;

  /// The job title shown in lists.
  final String job;
  final ValueChanged<String> onJob;

  /// What they can do in the app; a listed job sets it, and it can be changed.
  final StaffRole access;
  final ValueChanged<StaffRole> onAccess;
  final VoidCallback onChanged;

  /// Optional extra details; null hides the field.
  final TextEditingController? phone;
  final TextEditingController? wage;

  /// The chosen PIN; null hides the PIN field (edit uses Reset PIN).
  final String? pin;
  final ValueChanged<String>? onPin;
  final String? nameError;
  final String? pinError;
  final bool showCardNote;

  Future<void> _choosePin(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final chosen = await showAdaptiveSheet<String>(
      context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetTitle(l10n.choosePin, center: true),
          sheet.space.gapXl,
          PinPad(
            onCompleted: (p) async {
              Navigator.of(sheet).pop(p);
              return true;
            },
          ),
        ],
      ),
    );
    if (chosen != null) onPin?.call(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final jobs = staffJobs(l10n);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FarmTapTextField(
          label: l10n.nameLabel,
          icon: Symbols.person_rounded,
          controller: name,
          error: nameError,
          textInputAction: TextInputAction.next,
          onChanged: (_) => onChanged(),
        ),
        context.space.gapLg,
        FarmTapSelectField<String>(
          label: l10n.jobLabel,
          icon: Symbols.badge_rounded,
          options: [for (final (j, _) in jobs) j],
          labelOf: (j) => j,
          value: job.isEmpty ? null : job,
          picker: (context) =>
              showSearchPicker(context, title: l10n.jobLabel, options: [for (final (j, _) in jobs) j], selected: job),
          onChanged: (j) {
            onJob(j);
            final listed = jobs.where((e) => e.$1 == j).firstOrNull;
            if (listed != null) onAccess(listed.$2);
          },
        ),
        Padding(
          padding: EdgeInsets.only(top: context.space.xs, left: context.space.lg),
          child: Text(l10n.jobHelper, style: context.text.bodySmall),
        ),
        context.space.gapLg,
        FarmTapSelectField<StaffRole>(
          label: l10n.accessLabel,
          icon: Symbols.lock_open_rounded,
          options: StaffRole.values,
          labelOf: (r) => '${staffRoleLabel(l10n, r)} · ${staffCanDo(l10n, r)}',
          value: access,
          onChanged: onAccess,
        ),
        if (phone != null) ...[
          context.space.gapLg,
          FarmTapTextField(
            label: l10n.phoneOptional,
            icon: Symbols.call_rounded,
            prefixText: l10n.phonePrefix,
            controller: phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [UgPhoneFormatter()],
            onChanged: (_) => onChanged(),
          ),
        ],
        if (wage != null) ...[
          context.space.gapLg,
          FarmTapTextField(
            label: l10n.wageOptional,
            icon: Symbols.payments_rounded,
            prefixText: 'UGX ',
            controller: wage,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => onChanged(),
          ),
        ],
        if (pin != null) ...[
          context.space.gapLg,
          Text(l10n.choosePin, style: context.text.titleSmall),
          Semantics(
            button: true,
            label: pin!.length == 4 ? l10n.pinChosen : l10n.choosePinHint,
            excludeSemantics: true,
            child: InkWell(
              onTap: () => _choosePin(context),
              borderRadius: context.radii.card,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: context.space.md),
                child: Center(
                  child: PinDots(filled: pin!.length, error: pinError != null),
                ),
              ),
            ),
          ),
          if (pinError != null)
            Text(
              pinError!,
              textAlign: TextAlign.center,
              style: context.text.bodySmall?.copyWith(color: context.colors.error),
            ),
        ],
        if (showCardNote)
          FarmTapBanner(
            tone: FarmTapTone.info,
            icon: Symbols.info_rounded,
            title: l10n.nfcLaterTitle,
            message: l10n.nfcLaterBody,
          ),
      ],
    );
  }
}
