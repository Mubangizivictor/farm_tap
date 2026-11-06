// Onboarding choice steps: B02 sector, B05 dairy type, B08 role.
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/onboarding/domain/farm_setup.dart';
import 'package:farm_tap/core/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:farm_tap/core/onboarding/presentation/widgets/onboarding_step.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

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
      step: 1,
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
          step: 2,
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

/// Roles offered on B08, with the access each starts with. Anything else
/// can be typed ("Farmer's daughter").
List<(String, SetupRole)> setupRoles(AppLocalizations l10n) => [
  (l10n.roleOwner, SetupRole.owner),
  (l10n.roleCoOwner, SetupRole.owner),
  (l10n.roleFamily, SetupRole.owner),
  (l10n.roleFarmManager, SetupRole.manager),
  (l10n.roleManager, SetupRole.manager),
  (l10n.roleSupervisor, SetupRole.manager),
  (l10n.roleSecretary, SetupRole.manager),
  (l10n.roleAccountant, SetupRole.manager),
];

/// B08 — your role: pick one or type your own, then what you can do.
class OnboardRolePage extends StatelessWidget {
  const new({required this.cubit, required this.onContinue, super.key});

  final OnboardingCubit cubit;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final roles = setupRoles(l10n);
    return BlocBuilder<OnboardingCubit, FarmSetup>(
      bloc: cubit,
      builder: (context, setup) {
        final title = setup.roleTitle.isEmpty ? l10n.roleOwner : setup.roleTitle;
        return OnboardingStep(
          step: 5,
          title: l10n.roleTitle,
          animation: FarmTapAnimations.welcome,
          onContinue: () {
            if (setup.roleTitle.isEmpty) cubit.update((s) => s.copyWith(roleTitle: title));
            onContinue();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FarmTapSelectField<String>(
                label: l10n.yourRoleLabel,
                icon: Symbols.badge_rounded,
                options: [for (final (r, _) in roles) r],
                labelOf: (r) => r,
                value: title,
                picker: (context) => showSearchPicker(
                  context,
                  title: l10n.yourRoleLabel,
                  options: [for (final (r, _) in roles) r],
                  selected: title,
                ),
                onChanged: (r) {
                  final listed = roles.where((e) => e.$1 == r).firstOrNull;
                  cubit.update((s) => s.copyWith(roleTitle: r, role: listed?.$2));
                },
              ),
              Padding(
                padding: EdgeInsets.only(top: context.space.xs, left: context.space.lg),
                child: Text(l10n.jobHelper, style: context.text.bodySmall),
              ),
              context.space.gapLg,
              Text(l10n.accessTitle, style: context.text.titleSmall),
              context.space.gapMd,
              OptionRow(
                icon: Symbols.person_rounded,
                title: l10n.roleOwner,
                subtitle: l10n.ownerAccess,
                selected: setup.role == SetupRole.owner,
                onTap: () => cubit.update((s) => s.copyWith(role: SetupRole.owner)),
              ),
              context.space.gapMd,
              OptionRow(
                icon: Symbols.badge_rounded,
                tone: FarmTapTone.info,
                title: l10n.roleManager,
                subtitle: l10n.managerAccess,
                selected: setup.role == SetupRole.manager,
                onTap: () => cubit.update((s) => s.copyWith(role: SetupRole.manager)),
              ),
            ],
          ),
        );
      },
    );
  }
}
