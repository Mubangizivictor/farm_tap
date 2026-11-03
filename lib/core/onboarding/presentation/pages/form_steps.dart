// Onboarding form steps: B06 farm details, B07 contacts, B09 first worker.
// Each asks "Discard changes?" when left with unsaved input.
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/onboarding/domain/farm_setup.dart';
import 'package:farm_tap/core/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:farm_tap/core/onboarding/presentation/widgets/onboarding_step.dart';
import 'package:farm_tap/core/people/presentation/widgets/staff_form_fields.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

String herdSizeLabel(AppLocalizations l10n, HerdSize h) => switch (h) {
  HerdSize.upTo10 => l10n.herd1to10,
  HerdSize.upTo30 => l10n.herd11to30,
  HerdSize.upTo100 => l10n.herd31to100,
  HerdSize.over100 => l10n.herdOver100,
};

/// B06 — about your farm.
class OnboardFarmDetailsPage extends StatefulWidget {
  const new({required this.cubit, required this.districts, required this.onContinue, super.key});

  final OnboardingCubit cubit;
  final List<String> districts;
  final VoidCallback onContinue;

  @override
  State<OnboardFarmDetailsPage> createState() => _OnboardFarmDetailsPageState();
}

class _OnboardFarmDetailsPageState extends State<OnboardFarmDetailsPage> {
  late final FarmSetup _start = widget.cubit.state;
  late final _name = TextEditingController(text: _start.farmName);
  late final _village = TextEditingController(text: _start.village);
  late String? _district = _start.district;
  late HerdSize? _herd = _start.herdSize;
  String? _nameError;

  bool get _dirty =>
      _name.text != _start.farmName ||
      _village.text != _start.village ||
      _district != _start.district ||
      _herd != _start.herdSize;

  @override
  void dispose() {
    _name.dispose();
    _village.dispose();
    super.dispose();
  }

  void _continue() {
    final l10n = AppLocalizations.of(context);
    setState(() => _nameError = _name.text.trim().isEmpty ? l10n.farmNameRequired : null);
    if (_nameError != null) return;
    widget.cubit.update(
      (s) =>
          s.copyWith(farmName: _name.text.trim(), village: _village.text.trim(), district: _district, herdSize: _herd),
    );
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DiscardGuard(
      dirty: _dirty,
      child: OnboardingStep(
        step: 3,
        title: l10n.farmDetailsTitle,
        animation: FarmTapAnimations.cowGrazing,
        onContinue: _continue,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FarmTapTextField(
              label: l10n.farmNameLabel,
              icon: Symbols.storefront_rounded,
              controller: _name,
              error: _nameError,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
            ),
            context.space.gapLg,
            FarmTapSelectField<String>(
              label: l10n.districtLabel,
              icon: Symbols.location_on_rounded,
              options: widget.districts,
              labelOf: (d) => d,
              value: _district,
              onChanged: (d) => setState(() => _district = d),
            ),
            context.space.gapLg,
            FarmTapTextField(
              label: l10n.villageLabel,
              icon: Symbols.home_rounded,
              controller: _village,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
            ),
            context.space.gapLg,
            Text(l10n.herdSizeLabel, style: context.text.titleSmall),
            context.space.gapMd,
            Wrap(
              spacing: context.space.chipRun,
              runSpacing: context.space.chipRun,
              children: [
                for (final h in HerdSize.values)
                  FarmTapChip(
                    label: herdSizeLabel(l10n, h),
                    selected: _herd == h,
                    onTap: () => setState(() => _herd = h),
                  ),
              ],
            ),
            context.space.gapMd,
            Padding(
              padding: EdgeInsetsDirectional.only(start: context.space.xxl + context.space.lg),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextAction(
                  label: l10n.useMyLocation,
                  icon: Symbols.location_on_rounded,
                  // UI phase: the fake location is the sample farm's district.
                  onPressed: () => setState(() => _district = widget.districts.first),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// B07 — WhatsApp and SMS numbers (not verified by OTP).
class OnboardContactsPage extends StatefulWidget {
  const new({required this.cubit, required this.onContinue, super.key});

  final OnboardingCubit cubit;
  final VoidCallback onContinue;

  @override
  State<OnboardContactsPage> createState() => _OnboardContactsPageState();
}

class _OnboardContactsPageState extends State<OnboardContactsPage> {
  late final FarmSetup _start = widget.cubit.state;
  late final _whatsapp = TextEditingController(text: _start.whatsapp);
  late final _sms = TextEditingController(text: _start.sms);
  late bool _same = _start.smsSameAsWhatsapp;
  late bool _daily = _start.dailyReport;
  late bool _alerts = _start.smsAlerts;
  String? _error;

  bool get _dirty => _whatsapp.text != _start.whatsapp || _sms.text != _start.sms;

  @override
  void dispose() {
    _whatsapp.dispose();
    _sms.dispose();
    super.dispose();
  }

  void _continue() {
    final l10n = AppLocalizations.of(context);
    setState(() => _error = UgPhoneFormatter.isComplete(_whatsapp.text) ? null : l10n.phoneIncomplete);
    if (_error != null) return;
    widget.cubit.update(
      (s) => s.copyWith(
        whatsapp: _whatsapp.text,
        sms: _same ? _whatsapp.text : _sms.text,
        smsSameAsWhatsapp: _same,
        dailyReport: _daily,
        smsAlerts: _alerts,
      ),
    );
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_same) _sms.text = _whatsapp.text;
    return DiscardGuard(
      dirty: _dirty,
      child: OnboardingStep(
        step: 4,
        title: l10n.contactsTitle,
        subtitle: l10n.contactsSubtitle,
        animation: FarmTapAnimations.smsSent,
        onContinue: _continue,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FarmTapTextField(
              label: l10n.whatsappLabel,
              icon: Symbols.chat_rounded,
              prefixText: l10n.phonePrefix,
              controller: _whatsapp,
              error: _error,
              helper: l10n.dailyReportTime,
              keyboardType: TextInputType.phone,
              inputFormatters: [UgPhoneFormatter()],
              onChanged: (_) => setState(() {}),
            ),
            CheckRow(label: l10n.smsSameAsWhatsapp, value: _same, onChanged: (v) => setState(() => _same = v)),
            FarmTapTextField(
              label: l10n.smsNumberLabel,
              icon: Symbols.sms_rounded,
              prefixText: l10n.phonePrefix,
              controller: _sms,
              enabled: !_same,
              keyboardType: TextInputType.phone,
              inputFormatters: [UgPhoneFormatter()],
              onChanged: (_) => setState(() {}),
            ),
            context.space.gapLg,
            FarmTapCard(
              children: [
                CheckRow(label: l10n.sendDailyWhatsapp, value: _daily, onChanged: (v) => setState(() => _daily = v)),
                CheckRow(label: l10n.sendSmsAlerts, value: _alerts, onChanged: (v) => setState(() => _alerts = v)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String workerRoleLabel(AppLocalizations l10n, WorkerRole r) => switch (r) {
  WorkerRole.manager => l10n.roleManager,
  WorkerRole.herdsman => l10n.roleHerdsman,
  WorkerRole.clerk => l10n.roleMilkClerk,
  WorkerRole.worker => l10n.roleWorker,
  WorkerRole.vet => l10n.roleVet,
};

/// B09 — add the first worker (card + 4-digit PIN). Skip is allowed.
class OnboardFirstStaffPage extends StatefulWidget {
  const new({required this.cubit, required this.onDone, super.key});

  final OnboardingCubit cubit;

  /// Called after Save worker or Skip.
  final VoidCallback onDone;

  @override
  State<OnboardFirstStaffPage> createState() => _OnboardFirstStaffPageState();
}

class _OnboardFirstStaffPageState extends State<OnboardFirstStaffPage> {
  final _name = TextEditingController();
  WorkerRole _role = WorkerRole.herdsman;
  String _pin = '';
  String? _nameError;
  String? _pinError;

  bool get _dirty => _name.text.isNotEmpty || _pin.isNotEmpty;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _nameError = _name.text.trim().isEmpty ? l10n.nameRequired : null;
      _pinError = _pin.length == 4 ? null : l10n.pinRequired;
    });
    if (_nameError != null || _pinError != null) return;
    widget.cubit.update(
      (s) => s.copyWith(
        firstWorker: FirstWorker(name: _name.text.trim(), role: _role, pin: _pin),
      ),
    );
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DiscardGuard(
      dirty: _dirty,
      child: OnboardingStep(
        step: 6,
        title: l10n.firstStaffTitle,
        subtitle: l10n.firstStaffSubtitle,
        animation: FarmTapAnimations.attendance,
        onSkip: widget.onDone,
        action: FarmTapButton(label: l10n.saveWorker, icon: Symbols.person_add_rounded, onPressed: _save),
        child: StaffFormFields<WorkerRole>(
          name: _name,
          roles: const [WorkerRole.herdsman, WorkerRole.clerk, WorkerRole.worker, WorkerRole.manager, WorkerRole.vet],
          role: _role,
          roleLabel: (r) => workerRoleLabel(l10n, r),
          onRole: (r) => setState(() => _role = r),
          onChanged: () => setState(() {}),
          pin: _pin,
          onPin: (p) => setState(() => _pin = p),
          nameError: _nameError,
          pinError: _pinError,
        ),
      ),
    );
  }
}
