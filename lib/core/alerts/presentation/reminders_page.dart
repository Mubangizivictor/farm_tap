import 'dart:async';

import 'package:farm_tap/core/alerts/alert_rules.dart';
import 'package:farm_tap/core/alerts/farm_reminders.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Today's farm reminders and, for owners and managers, what is reminded
/// and how (decision 0024). The same settings as the web's Settings.
class RemindersPage extends StatefulWidget {
  const new({required this.reminders, required this.viewer, super.key, this.onMessages});

  final FarmReminders reminders;
  final ReminderViewer viewer;

  /// Opens "Messages to send" (WhatsApp / SMS from this phone).
  final VoidCallback? onMessages;

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  AlertSettings? _settings;
  List<FarmAlert>? _today;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final s = await widget.reminders.settings();
    final all = await widget.reminders.today(widget.viewer, override: s);
    if (!mounted) return;
    setState(() {
      _settings = s;
      _today = widget.reminders.forViewer(all, widget.viewer);
    });
  }

  Future<void> _change(AlertSettings s) async {
    setState(() => _settings = s);
    await widget.reminders.saveSettings(s);
    final all = await widget.reminders.today(widget.viewer, override: s);
    if (mounted) setState(() => _today = widget.reminders.forViewer(all, widget.viewer));
  }

  IconData _icon(String kind) => switch (kind) {
    'duty' => Symbols.assignment_ind_rounded,
    'vaccination' => Symbols.vaccines_rounded,
    'calving' || 'pregnancyCheck' || 'heat' => Symbols.favorite_rounded,
    _ => Symbols.savings_rounded,
  };

  FarmTapTone _tone(String kind) => switch (kind) {
    'duty' => FarmTapTone.primary,
    'vaccination' => FarmTapTone.info,
    'calving' || 'pregnancyCheck' || 'heat' => FarmTapTone.danger,
    _ => FarmTapTone.gold,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = _settings;
    final today = _today;
    return AdaptiveScaffold(
      title: l10n.remindersTitle,
      showBack: true,
      onRefresh: _load,
      body: s == null || today == null
          ? const FarmTapPageLoader()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (today.isEmpty)
                  EmptyState(
                    title: l10n.remindersNone,
                    message: l10n.remindersNoneBody,
                    animation: FarmTapAnimations.syncDone,
                  )
                else
                  ListCard(
                    title: l10n.remindersToday,
                    children: [
                      for (final a in today)
                        RecordTile(
                          leading: IconBubble(icon: _icon(a.kind), tone: _tone(a.kind), size: context.sizes.bubbleMd),
                          title: a.title,
                          subtitle: a.body,
                          showChevron: false,
                        ),
                    ],
                  ),
                if (widget.viewer.manages) ...[
                  context.space.gapLg,
                  SectionLabel(l10n.remindersWhat),
                  context.space.gapSm,
                  FarmTapCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CheckRow(
                          label: l10n.remindersDuties,
                          value: s.duties,
                          onChanged: (v) => _change(s.copyWith(duties: v)),
                        ),
                        CheckRow(
                          label: l10n.remindersVaccinations,
                          value: s.vaccinations,
                          onChanged: (v) => _change(s.copyWith(vaccinations: v)),
                        ),
                        CheckRow(
                          label: l10n.remindersCalving,
                          value: s.calving,
                          onChanged: (v) => _change(s.copyWith(calving: v)),
                        ),
                        CheckRow(
                          label: l10n.remindersPlan,
                          value: s.trial,
                          onChanged: (v) => _change(s.copyWith(trial: v)),
                        ),
                      ],
                    ),
                  ),
                  context.space.gapLg,
                  SectionLabel(l10n.remindersHow),
                  context.space.gapSm,
                  FarmTapCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CheckRow(
                          label: l10n.remindersPush,
                          subtitle: l10n.remindersPushSub,
                          value: s.push,
                          onChanged: (v) async {
                            if (v) await widget.reminders.askPermission();
                            await _change(s.copyWith(push: v));
                          },
                        ),
                        CheckRow(
                          label: l10n.remindersWhatsapp,
                          subtitle: l10n.remindersWhatsappSub,
                          value: s.whatsapp,
                          onChanged: (v) => _change(s.copyWith(whatsapp: v)),
                        ),
                        CheckRow(
                          label: l10n.remindersSms,
                          subtitle: l10n.remindersSmsSub,
                          value: s.sms,
                          onChanged: (v) => _change(s.copyWith(sms: v)),
                        ),
                      ],
                    ),
                  ),
                  context.space.gapMd,
                  FarmTapSelectField<int>(
                    label: l10n.remindersHour,
                    options: const [5, 6, 7, 8, 9, 12, 17, 18],
                    value: s.hour,
                    labelOf: (h) => MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay(hour: h, minute: 0)),
                    onChanged: (h) => _change(s.copyWith(hour: h)),
                  ),
                  if (widget.onMessages != null) ...[
                    context.space.gapLg,
                    FarmTapButton(
                      label: l10n.messagesToSend,
                      icon: Symbols.sms_rounded,
                      kind: ButtonKind.tonal,
                      onPressed: widget.onMessages,
                    ),
                  ],
                  context.space.gapSm,
                  Text(
                    l10n.remindersFreeNote,
                    textAlign: TextAlign.center,
                    style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                ],
              ],
            ),
    );
  }
}
