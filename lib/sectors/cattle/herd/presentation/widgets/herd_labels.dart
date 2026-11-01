import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/entities/animal.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

String dairyStatusLabel(AppLocalizations l10n, DairyStatus s) => switch (s) {
  DairyStatus.milking => l10n.statusMilking,
  DairyStatus.dry => l10n.statusDry,
  DairyStatus.treated => l10n.statusTreated,
  DairyStatus.pregnant => l10n.statusPregnant,
  DairyStatus.heifer => l10n.statusHeifer,
  DairyStatus.calf => l10n.statusCalf,
  DairyStatus.bull => l10n.statusBull,
};

FarmTapTone dairyStatusTone(DairyStatus s) => switch (s) {
  DairyStatus.milking => FarmTapTone.success,
  DairyStatus.treated => FarmTapTone.danger,
  DairyStatus.pregnant => FarmTapTone.info,
  DairyStatus.dry => FarmTapTone.warning,
  DairyStatus.heifer || DairyStatus.calf || DairyStatus.bull => FarmTapTone.neutral,
};

/// "Milking", "Treated" ... with its colour (never colour alone).
class DairyStatusBadge extends StatelessWidget {
  const new(this.status, {super.key});

  final DairyStatus status;

  @override
  Widget build(BuildContext context) =>
      StatusBadge(label: dairyStatusLabel(AppLocalizations.of(context), status), tone: dairyStatusTone(status));
}

/// "Cow", "Heifer", "Bull", "Calf" for the animal header.
String animalKindLabel(AppLocalizations l10n, Animal a) => switch (a.dairyStatus) {
  DairyStatus.heifer => l10n.kindHeifer,
  DairyStatus.calf => l10n.kindCalf,
  DairyStatus.bull => l10n.kindBull,
  _ => a.sex == AnimalSex.male ? l10n.kindBull : l10n.kindCow,
};

/// Treated badge on the animal header: "Treated — milk not for sale".
class NotForSaleBadge extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => StatusBadge(
    label: AppLocalizations.of(context).treatedNotForSale,
    tone: FarmTapTone.danger,
    icon: Symbols.medication_rounded,
  );
}
