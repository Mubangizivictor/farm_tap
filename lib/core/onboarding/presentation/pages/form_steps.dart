// Onboarding form steps: B06 farm details, B07 contacts, B09 first worker.
// Each asks "Discard changes?" when left with unsaved input.
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/nfc/card_tap_listener.dart';
import 'package:farm_tap/core/onboarding/domain/farm_setup.dart';
import 'package:farm_tap/core/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:farm_tap/core/onboarding/presentation/widgets/onboarding_step.dart';
import 'package:farm_tap/core/people/domain/staff_member.dart';
import 'package:farm_tap/core/people/presentation/widgets/card_number_sheet.dart';
import 'package:farm_tap/core/people/presentation/widgets/staff_form_fields.dart';
import 'package:farm_tap/core/places/location_service.dart';
import 'package:farm_tap/core/places/uganda_districts.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

/// B06 — about your farm: name, district (from the phone's location or
/// any of Uganda's districts, searchable, or typed), village and the
/// number of cows.
class OnboardFarmDetailsPage extends StatefulWidget {
  const new({required this.cubit, required this.onContinue, super.key, this.location = const LocationService()});

  final OnboardingCubit cubit;
  final VoidCallback onContinue;
  final LocationService location;

  @override
  State<OnboardFarmDetailsPage> createState() => _OnboardFarmDetailsPageState();
}

class _OnboardFarmDetailsPageState extends State<OnboardFarmDetailsPage> {
  late final FarmSetup _start = widget.cubit.state;
  late final _name = TextEditingController(text: _start.farmName);
  late final _village = TextEditingController(text: _start.village);
  late final _cows = TextEditingController(text: _start.cows?.toString() ?? '');
  late String? _district = _start.district;
  String? _nameError;
  String? _cowsError;
  String? _locationNote;
  bool _locating = false;

  bool get _dirty =>
      _name.text != _start.farmName ||
      _village.text != _start.village ||
      _district != _start.district ||
      _cows.text != (_start.cows?.toString() ?? '');

  @override
  void dispose() {
    _name.dispose();
    _village.dispose();
    _cows.dispose();
    super.dispose();
  }

  Future<void> _useLocation() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _locating = true;
      _locationNote = l10n.findingLocation;
    });
    final (district, problem) = await widget.location.currentDistrict();
    if (!mounted) return;
    setState(() {
      _locating = false;
      if (district != null) _district = district;
      _locationNote = switch (problem) {
        null => null,
        LocationProblem.off => l10n.locationOff,
        LocationProblem.denied => l10n.locationDenied,
        LocationProblem.notFound => l10n.locationNotFound,
      };
    });
  }

  void _continue() {
    final l10n = AppLocalizations.of(context);
    final cows = int.tryParse(_cows.text.trim());
    setState(() {
      _nameError = _name.text.trim().isEmpty ? l10n.farmNameRequired : null;
      _cowsError = _cows.text.trim().isNotEmpty && cows == null ? l10n.cowsInvalid : null;
    });
    if (_nameError != null || _cowsError != null) return;
    widget.cubit.update(
      (s) => s.copyWith(farmName: _name.text.trim(), village: _village.text.trim(), district: _district, cows: cows),
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
              options: ugandaDistrictsSorted,
              labelOf: (d) => d,
              value: _district,
              picker: (context) => showSearchPicker(
                context,
                title: l10n.districtLabel,
                options: ugandaDistrictsSorted,
                selected: _district,
              ),
              onChanged: (d) => setState(() {
                _district = d;
                _locationNote = null;
              }),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextAction(
                label: l10n.useMyLocation,
                icon: Symbols.my_location_rounded,
                onPressed: _locating ? null : _useLocation,
              ),
            ),
            if (_locationNote != null)
              Padding(
                padding: EdgeInsets.only(bottom: context.space.sm),
                child: Text(_locationNote!, style: context.text.bodySmall),
              ),
            context.space.gapSm,
            FarmTapTextField(
              label: l10n.villageLabel,
              icon: Symbols.home_rounded,
              controller: _village,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
            ),
            context.space.gapLg,
            FarmTapTextField(
              label: l10n.cowsCountLabel,
              icon: Symbols.pets_rounded,
              controller: _cows,
              error: _cowsError,
              helper: l10n.cowsCountHelper,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
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
  late bool _daily = _start.dailyReport;
  late bool _alerts = _start.smsAlerts;
  String? _error;
  String? _smsError;

  bool get _dirty => _whatsapp.text != _start.whatsapp || _sms.text != _start.sms;

  @override
  void dispose() {
    _whatsapp.dispose();
    _sms.dispose();
    super.dispose();
  }

  void _continue() {
    final l10n = AppLocalizations.of(context);
    // WhatsApp and SMS are often different lines in Uganda: each has its own
    // number. SMS is needed only when SMS alerts are on.
    setState(() {
      _error = UgPhoneFormatter.isComplete(_whatsapp.text) ? null : l10n.phoneIncomplete;
      final needSms = _alerts || _sms.text.isNotEmpty;
      _smsError = !needSms || UgPhoneFormatter.isComplete(_sms.text) ? null : l10n.phoneIncomplete;
    });
    if (_error != null || _smsError != null) return;
    widget.cubit.update(
      (s) => s.copyWith(
        whatsapp: _whatsapp.text,
        sms: _sms.text,
        smsSameAsWhatsapp: _sms.text == _whatsapp.text,
        dailyReport: _daily,
        smsAlerts: _alerts,
      ),
    );
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
            context.space.gapLg,
            FarmTapTextField(
              label: l10n.smsNumberLabel,
              icon: Symbols.sms_rounded,
              prefixText: l10n.phonePrefix,
              controller: _sms,
              error: _smsError,
              helper: l10n.smsNumberHelp,
              keyboardType: TextInputType.phone,
              inputFormatters: [UgPhoneFormatter()],
              onChanged: (_) => setState(() => _smsError = null),
            ),
            if (_sms.text.isEmpty && _whatsapp.text.isNotEmpty)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextAction(
                  label: l10n.copyWhatsappNumber,
                  icon: Symbols.content_copy_rounded,
                  small: true,
                  onPressed: () => setState(() {
                    _sms.text = _whatsapp.text;
                    _smsError = null;
                  }),
                ),
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

/// B09 — the first worker: name, job (listed or their own words), what
/// they can do, phone, pay, PIN and their NFC card. Skip is allowed. The
/// worker is saved when the farm is created (B10).
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
  final _phone = TextEditingController();
  final _wage = TextEditingController();
  StaffRole _role = StaffRole.herdsman;
  String _job = '';
  String _pin = '';
  String? _card;
  String? _nameError;
  String? _pinError;

  bool get _dirty => _name.text.isNotEmpty || _pin.isNotEmpty || _card != null;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _wage.dispose();
    super.dispose();
  }

  Future<void> _typeCard() async {
    final card = await showTypeCardNumber(context, initial: _card);
    if (card != null && mounted) setState(() => _card = card);
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
        firstWorker: FirstWorker(
          name: _name.text.trim(),
          role: _role,
          title: _job.trim().isEmpty ? null : _job.trim(),
          phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          monthlyWage: int.tryParse(_wage.text),
          pin: _pin,
          cardNumber: _card,
        ),
      ),
    );
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DiscardGuard(
      dirty: _dirty,
      child: CardTapListener(
        onCard: (card) => setState(() => _card = card),
        prompt: l10n.tapNewCardNow,
        child: OnboardingStep(
          step: 6,
          title: l10n.firstStaffTitle,
          subtitle: l10n.firstStaffSubtitle,
          animation: FarmTapAnimations.attendance,
          onSkip: widget.onDone,
          action: FarmTapButton(label: l10n.saveWorker, icon: Symbols.person_add_rounded, onPressed: _save),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StaffFormFields(
                name: _name,
                job: _job,
                onJob: (j) => setState(() => _job = j),
                access: _role,
                onAccess: (r) => setState(() => _role = r),
                phone: _phone,
                wage: _wage,
                onChanged: () => setState(() {}),
                pin: _pin,
                onPin: (p) => setState(() => _pin = p),
                nameError: _nameError,
                pinError: _pinError,
                showCardNote: false,
              ),
              context.space.gapLg,
              FarmTapCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Symbols.contactless_rounded, color: context.colors.primary, size: context.sizes.iconMd),
                        context.space.gapSm,
                        Expanded(
                          child: Text(
                            _card == null ? l10n.cardForWorker : l10n.cardReadNumber(_card!),
                            style: context.text.titleSmall,
                          ),
                        ),
                        if (_card != null) StatusBadge(label: l10n.cardBadge, tone: FarmTapTone.success),
                      ],
                    ),
                    context.space.gapXs,
                    if (_card == null) ...[
                      Text(l10n.cardForWorkerHelp, style: context.text.bodySmall),
                      Text(l10n.noCardYet, style: context.text.bodySmall),
                    ],
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextAction(
                        label: _card == null ? l10n.typeCardNumber : l10n.changeCard,
                        icon: Symbols.dialpad_rounded,
                        onPressed: _typeCard,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
