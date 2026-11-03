// B03 waitlist sheet, B04 waitlist done, B10 farm ready.
import 'dart:async';

import 'package:farm_tap/core/auth/presentation/widgets/auth_widgets.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/onboarding/domain/farm_setup.dart';
import 'package:farm_tap/core/onboarding/domain/onboarding_repository.dart';
import 'package:farm_tap/core/onboarding/presentation/pages/choice_steps.dart';
import 'package:farm_tap/core/sound/sound_service.dart';
import 'package:farm_tap/core/tenancy/domain/farm_membership.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

/// B03 — "Poultry is coming soon": join the waitlist. Bottom sheet on
/// phones, dialog wider. Resolves to the name typed when joined.
Future<String?> showWaitlistSheet(BuildContext context, {required Sector sector, required OnboardingRepository repo}) =>
    showAdaptiveSheet<String>(
      context,
      dialogAlignment: splitContentAlignment(context),
      builder: (_) => WaitlistSheet(sector: sector, repo: repo),
    );

class WaitlistSheet extends StatefulWidget {
  const new({required this.sector, required this.repo, super.key});

  final Sector sector;
  final OnboardingRepository repo;

  @override
  State<WaitlistSheet> createState() => _WaitlistSheetState();
}

class _WaitlistSheetState extends State<WaitlistSheet> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String? _nameError;
  String? _phoneError;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _nameError = _name.text.trim().isEmpty ? l10n.nameRequired : null;
      _phoneError = UgPhoneFormatter.isComplete(_phone.text) ? null : l10n.phoneIncomplete;
    });
    if (_nameError != null || _phoneError != null) return;
    await widget.repo.joinWaitlist(sector: widget.sector, name: _name.text.trim(), whatsapp: _phone.text);
    if (mounted) Navigator.of(context).pop(_name.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (sectorName, _, _) = sectorInfo(l10n, widget.sector);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetTitle(l10n.waitlistTitle(sectorName), subtitle: l10n.waitlistBody),
        Center(
          child: FarmTapAnimationView(animation: FarmTapAnimations.waitlist, size: context.sizes.animationMd),
        ),
        FarmTapTextField(
          label: l10n.yourNameLabel,
          icon: Symbols.person_rounded,
          controller: _name,
          error: _nameError,
          textInputAction: TextInputAction.next,
        ),
        context.space.gapLg,
        FarmTapTextField(
          label: l10n.whatsappLabel,
          icon: Symbols.chat_rounded,
          prefixText: l10n.phonePrefix,
          controller: _phone,
          error: _phoneError,
          keyboardType: TextInputType.phone,
          inputFormatters: [UgPhoneFormatter()],
        ),
        context.space.gapLg,
        FarmTapButton(label: l10n.joinWaitlist, icon: Symbols.notifications_active_rounded, onPressed: _join),
        context.space.gapLg,
        Center(
          child: TextAction(label: l10n.back, onPressed: () => Navigator.of(context).pop()),
        ),
      ],
    );
  }
}

/// B04 — you're on the list.
class WaitlistDonePage extends StatelessWidget {
  const new({required this.sector, required this.name, required this.onDone, super.key});

  final Sector sector;
  final String name;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (sectorName, _, _) = sectorInfo(l10n, sector);
    final firstName = name.trim().split(RegExp(r'\s+')).last;
    return CenteredLayout(
      top: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.space.sm),
        child: AuthBackButton(onBack: onDone),
      ),
      bottom: FarmTapButton(label: l10n.done, onPressed: onDone),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FarmTapAnimationView(animation: FarmTapAnimations.waitlist, size: context.sizes.animationCelebration),
          context.space.gapLg,
          Text(l10n.waitlistDoneTitle, textAlign: TextAlign.center, style: context.text.headlineSmall),
          context.space.gapSm,
          Text(
            l10n.waitlistDoneBody(sectorName, firstName),
            textAlign: TextAlign.center,
            style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// B10 — your farm is ready. Creates the farm (trial starts today), plays
/// the celebration once with a soft success sound and a short vibration.
class FarmReadyPage extends StatefulWidget {
  const new({required this.setup, required this.repo, required this.onStart, super.key});

  final FarmSetup setup;
  final OnboardingRepository repo;
  final ValueChanged<FarmMembership> onStart;

  @override
  State<FarmReadyPage> createState() => _FarmReadyPageState();
}

class _FarmReadyPageState extends State<FarmReadyPage> {
  /// Creating the farm needs the internet once; it can be tried again.
  late Future<FarmMembership?> _farm = _create();

  Future<FarmMembership?> _create() => widget.repo.createFarm(widget.setup).then((r) => r.data);

  @override
  void initState() {
    super.initState();
    unawaited(SoundService.instance.play(FarmTapSound.success));
    unawaited(HapticFeedback.mediumImpact());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final ends = widget.repo.trialEndsOn();
    Widget row(String label, String value) => Row(
      children: [
        Expanded(child: Text(label, style: context.text.bodySmall)),
        Text(value, style: context.text.titleSmall),
      ],
    );
    return FutureBuilder<FarmMembership?>(
      future: _farm,
      builder: (context, snapshot) {
        final failed = snapshot.connectionState == ConnectionState.done && snapshot.data == null;
        return CenteredLayout(
          bottom: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!failed && snapshot.data == null)
                Padding(
                  padding: EdgeInsets.only(bottom: context.space.sm),
                  child: const Center(child: FarmTapLoader()),
                ),
              if (failed || snapshot.data == null)
                Padding(
                  padding: EdgeInsets.only(bottom: context.space.md),
                  child: Text(
                    failed ? l10n.farmCreateFailed : l10n.creatingFarm,
                    textAlign: TextAlign.center,
                    style: context.text.bodySmall?.copyWith(color: failed ? context.colors.error : null),
                  ),
                ),
              if (failed)
                FarmTapButton(
                  label: l10n.tryAgain,
                  icon: Symbols.refresh_rounded,
                  large: true,
                  onPressed: () => setState(() => _farm = _create()),
                )
              else
                FarmTapButton(
                  label: l10n.startUsingFarmTap,
                  large: true,
                  onPressed: snapshot.data == null ? null : () => widget.onStart(snapshot.data!),
                ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: FarmTapAnimationView(
                  animation: FarmTapAnimations.celebration,
                  size: context.sizes.animationCelebration,
                ),
              ),
              context.space.gapLg,
              Text(l10n.farmReadyTitle, textAlign: TextAlign.center, style: context.text.headlineSmall),
              context.space.gapSm,
              Text(
                l10n.farmReadyBody(DateFormat('d MMMM', locale).format(ends)),
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
              ),
              context.space.gapLg,
              FarmTapCard(
                children: [
                  row(l10n.summaryFarm, widget.setup.farmName),
                  row(l10n.summaryPlan, l10n.planDairy),
                  row(l10n.summaryFreeUntil, DateFormat('d MMM y', locale).format(ends)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
