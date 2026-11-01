// Onboarding choice steps: B01 language, B02 sector, B05 dairy type, B08 role.
import 'package:farm_tap/core/auth/presentation/widgets/auth_widgets.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/onboarding/domain/farm_setup.dart';
import 'package:farm_tap/core/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:farm_tap/core/onboarding/presentation/widgets/onboarding_step.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

/// B01 — choose the language (step 1, shown as dots). Changes the app
/// language at once.
class OnboardLanguagePage extends StatelessWidget {
  const new({required this.cubit, required this.onContinue, super.key, this.onLanguage});

  final OnboardingCubit cubit;
  final VoidCallback onContinue;

  /// Switches the app language (AppSettingsCubit.setLanguage).
  final ValueChanged<String>? onLanguage;

  void _choose(BuildContext context, String code) {
    cubit.update((s) => s.copyWith(languageCode: code));
    onLanguage?.call(code);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<OnboardingCubit, FarmSetup>(
      bloc: cubit,
      builder: (context, setup) => SplitAuthLayout(
        animation: FarmTapAnimations.welcome,
        tagline: l10n.brandTagline,
        description: l10n.brandBody,
        bottom: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PageDots(count: onboardingSteps, current: 0),
            context.space.gapLg,
            FarmTapButton(
              label: l10n.continueLabel,
              trailingIcon: Symbols.arrow_forward_rounded,
              onPressed: onContinue,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.only(top: context.isCompact ? context.space.sm : context.space.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: FarmTapAnimationView(animation: FarmTapAnimations.welcome, size: context.sizes.authIllustration),
              ),
              AuthHeading(title: l10n.chooseLanguageTitle, subtitle: l10n.chooseLanguageSubtitle, center: true),
              context.space.gapLg,
              OptionRow(
                icon: Symbols.language_rounded,
                title: l10n.languageRunyankore,
                subtitle: l10n.runyankoreSubtitle,
                selected: setup.languageCode == 'nyn',
                onTap: () => _choose(context, 'nyn'),
              ),
              context.space.gapMd,
              OptionRow(
                icon: Symbols.language_rounded,
                title: l10n.languageEnglish,
                subtitle: l10n.englishSubtitle,
                selected: setup.languageCode == 'en',
                onTap: () => _choose(context, 'en'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Display name, subtitle and icon of each sector.
(String, String?, IconData) sectorInfo(AppLocalizations l10n, Sector s) => switch (s) {
  Sector.dairy => (l10n.sectorDairy, l10n.sectorDairySub, Symbols.water_drop_rounded),
  Sector.poultry => (l10n.sectorPoultry, l10n.sectorPoultrySub, Symbols.egg_rounded),
  Sector.piggery => (l10n.sectorPiggery, l10n.sectorPiggerySub, Symbols.savings_rounded),
  Sector.goats => (l10n.sectorGoats, null, Symbols.cruelty_free_rounded),
  Sector.crops => (l10n.sectorCrops, l10n.sectorCropsSub, Symbols.agriculture_rounded),
  Sector.fish => (l10n.sectorFish, null, Symbols.set_meal_rounded),
};

/// B02 — what do you do? Only Dairy continues; the others open the
/// waitlist sheet (B03).
class OnboardSectorPage extends StatelessWidget {
  const new({required this.cubit, required this.onContinue, required this.onComingSoon, super.key});

  final OnboardingCubit cubit;
  final VoidCallback onContinue;
  final ValueChanged<Sector> onComingSoon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OnboardingStep(
      step: 2,
      title: l10n.sectorTitle,
      subtitle: l10n.sectorSubtitle,
      animation: FarmTapAnimations.cowGrazing,
      onContinue: onContinue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final s in Sector.values) ...[
            if (s != Sector.dairy) context.space.gapMd,
            Builder(
              builder: (context) {
                final (title, sub, icon) = sectorInfo(l10n, s);
                final dairy = s == Sector.dairy;
                return OptionRow(
                  icon: icon,
                  title: title,
                  subtitle: sub,
                  tone: dairy ? FarmTapTone.primary : FarmTapTone.neutral,
                  selected: dairy,
                  comingSoon: !dairy,
                  onTap: dairy ? null : () => onComingSoon(s),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// B05 — what kind of dairy? Decides the home screen.
class OnboardDairyTypePage extends StatelessWidget {
  const new({required this.cubit, required this.onContinue, super.key});

  final OnboardingCubit cubit;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<OnboardingCubit, FarmSetup>(
      bloc: cubit,
      builder: (context, setup) {
        Widget option(DairyType t, IconData icon, FarmTapTone tone, String title, String sub) => OptionRow(
          icon: icon,
          tone: tone,
          title: title,
          subtitle: sub,
          selected: setup.dairyType == t,
          onTap: () => cubit.update((s) => s.copyWith(dairyType: t)),
        );
        return OnboardingStep(
          step: 3,
          title: l10n.dairyTypeTitle,
          subtitle: l10n.dairyTypeSubtitle,
          animation: FarmTapAnimations.milking,
          onContinue: onContinue,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              option(DairyType.farm, Symbols.pets_rounded, FarmTapTone.primary, l10n.dairyFarm, l10n.dairyFarmSub),
              context.space.gapMd,
              option(
                DairyType.centre,
                Symbols.storefront_rounded,
                FarmTapTone.gold,
                l10n.centreOption,
                l10n.centreOptionSub,
              ),
              context.space.gapMd,
              option(DairyType.both, Symbols.groups_rounded, FarmTapTone.info, l10n.bothOption, l10n.bothOptionSub),
            ],
          ),
        );
      },
    );
  }
}

/// B08 — owner or manager.
class OnboardRolePage extends StatelessWidget {
  const new({required this.cubit, required this.onContinue, super.key});

  final OnboardingCubit cubit;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<OnboardingCubit, FarmSetup>(
      bloc: cubit,
      builder: (context, setup) => OnboardingStep(
        step: 6,
        title: l10n.roleTitle,
        animation: FarmTapAnimations.welcome,
        onContinue: onContinue,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OptionRow(
              icon: Symbols.person_rounded,
              title: l10n.roleOwner,
              subtitle: l10n.roleOwnerSub,
              selected: setup.role == SetupRole.owner,
              onTap: () => cubit.update((s) => s.copyWith(role: SetupRole.owner)),
            ),
            context.space.gapMd,
            OptionRow(
              icon: Symbols.badge_rounded,
              tone: FarmTapTone.info,
              title: l10n.roleManager,
              subtitle: l10n.roleManagerSub,
              selected: setup.role == SetupRole.manager,
              onTap: () => cubit.update((s) => s.copyWith(role: SetupRole.manager)),
            ),
          ],
        ),
      ),
    );
  }
}
