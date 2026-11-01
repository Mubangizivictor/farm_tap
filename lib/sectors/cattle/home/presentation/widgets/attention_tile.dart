import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/core/utils/formats.dart';
import 'package:farm_tap/sectors/cattle/home/domain/home_models.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// One "needs attention" row (D01, D03): coloured bubble, title, detail,
/// optional Urgent badge, chevron.
class AttentionTile extends StatelessWidget {
  const new({required this.item, super.key, this.onTap, this.showBadge = false, this.today});

  final Attention item;
  final VoidCallback? onTap;

  /// Show the Urgent badge (alerts list).
  final bool showBadge;

  /// Overrides today for "In 6 days" (goldens).
  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = FarmTapFormat(Localizations.localeOf(context).toLanguageTag());
    final today = DateUtils.dateOnly(this.today ?? DateTime.now());
    final (IconData icon, FarmTapTone tone, String title, String subtitle) = switch (item) {
      MilkNotForSale(:final animal, :final drug, :final safeFrom) => (
        Symbols.medication_rounded,
        FarmTapTone.danger,
        l10n.attnNotForSale(animal),
        l10n.attnSafeFrom(drug, f.day(safeFrom)),
      ),
      MilkDropped(:final animal, :final percent, :final today, :final average) => (
        Symbols.trending_down_rounded,
        FarmTapTone.warning,
        l10n.attnMilkDrop(percent, animal),
        l10n.attnMilkDropSub(f.litresValue(today, trim: false), f.litresValue(average, trim: false)),
      ),
      CalvingDue(:final animal, :final due) => (
        Symbols.favorite_rounded,
        FarmTapTone.info,
        l10n.attnCalving(animal),
        l10n.attnInDays(due.difference(today).inDays.clamp(0, 999), f.dayMonth(due)),
      ),
      StockLow(:final item, :final bagsLeft, :final daysLeft) => (
        Symbols.inventory_2_rounded,
        FarmTapTone.gold,
        l10n.attnStockLow(item),
        l10n.attnBagsLeft(bagsLeft, daysLeft),
      ),
      RecordEdited(:final person, :final morning, :final at) => (
        Symbols.edit_rounded,
        FarmTapTone.neutral,
        l10n.attnEdited,
        l10n.attnEditedSub(person, morning ? l10n.sessionAm : l10n.sessionPm, f.clock24(at)),
      ),
      TrialEnding(:final daysLeft) => (
        Symbols.savings_rounded,
        FarmTapTone.gold,
        l10n.attnTrialEnds(daysLeft),
        l10n.attnTrialPay,
      ),
    };
    return RecordTile(
      leading: IconBubble(icon: icon, tone: tone),
      title: title,
      subtitle: subtitle,
      badge: showBadge && item.urgent ? StatusBadge(label: l10n.urgent, tone: FarmTapTone.danger) : null,
      onTap: onTap ?? () {},
    );
  }
}
