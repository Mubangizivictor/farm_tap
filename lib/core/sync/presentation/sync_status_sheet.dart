import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/sync/sync_service.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

/// D04 — sync status. Bottom sheet on phones, dialog wider.
Future<void> showSyncStatusSheet(BuildContext context, SyncService sync) =>
    showAdaptiveSheet<void>(context, builder: (_) => SyncStatusSheet(sync: sync));

class SyncStatusSheet extends StatelessWidget {
  const new({required this.sync, super.key});

  final SyncService sync;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final number = NumberFormat.decimalPattern(Localizations.localeOf(context).toLanguageTag());
    return StreamBuilder<SyncSnapshot>(
      stream: sync.watch(),
      initialData: sync.current,
      builder: (context, snapshot) {
        final s = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetTitle(l10n.syncStatusTitle, subtitle: l10n.syncStatusBody),
            Center(
              child: FarmTapAnimationView(animation: FarmTapAnimations.syncDone, size: context.sizes.animationSheet),
            ),
            ListCard(
              children: [
                RecordTile(
                  leading: const IconBubble(icon: Symbols.cloud_done_rounded, tone: FarmTapTone.success),
                  title: l10n.syncedLabel,
                  subtitle: l10n.recordsCount(number.format(s.synced)),
                  trailingValue: l10n.now,
                ),
                RecordTile(
                  leading: const IconBubble(icon: Symbols.schedule_rounded, tone: FarmTapTone.warning),
                  title: l10n.waitingToSend,
                  subtitle: l10n.milkRecordsCount(s.waiting),
                  trailingValue: '${s.waiting}',
                ),
                RecordTile(
                  leading: const IconBubble(icon: Symbols.error_rounded, tone: FarmTapTone.neutral),
                  title: l10n.failedLabel,
                  subtitle: l10n.recordsCount('${s.failed}'),
                  trailingValue: '${s.failed}',
                ),
              ],
            ),
            context.space.gapLg,
            FarmTapButton(label: l10n.syncNow, icon: Symbols.sync_rounded, onPressed: s.online ? sync.sync : null),
          ],
        );
      },
    );
  }
}
