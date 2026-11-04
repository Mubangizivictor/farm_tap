import 'dart:async';

import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/sms/phone_messenger.dart';
import 'package:farm_tap/core/sms/presentation/send_from_phone.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/sectors/cattle/operations/domain/operations_models.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

/// "Call" and "WhatsApp" for a phone number; free, from this phone.
class CallButtons extends StatelessWidget {
  const new({required this.phone, super.key});

  final String phone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: l10n.call,
          icon: Icon(Symbols.call_rounded, color: context.colors.primary),
          onPressed: () => unawaited(_open(context, Uri.parse('tel:${PhoneMessenger.international(phone)}'), null)),
        ),
        IconButton(
          tooltip: l10n.opsWhatsapp,
          icon: Icon(Symbols.chat_rounded, color: context.colors.primary),
          onPressed: () =>
              unawaited(_open(context, PhoneMessenger.uriFor(MessageRoute.whatsapp, phone, ''), MessageRoute.whatsapp)),
        ),
      ],
    );
  }

  static Future<void> _open(BuildContext context, Uri uri, MessageRoute? route) async {
    var ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      ok = false;
    }
    if (!ok && context.mounted && route != null) showSendFailed(context, route);
  }
}

/// A date field that opens the calendar.
class DateField extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.first,
    required this.last,
    super.key,
    this.clearable = false,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime first;
  final DateTime last;
  final bool clearable;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = MaterialLocalizations.of(context);
    return FarmTapCard(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value == null || value!.isBefore(first) || value!.isAfter(last) ? first : value!,
          firstDate: first,
          lastDate: last,
        );
        if (picked != null) onChanged(picked);
      },
      child: Row(
        children: [
          Icon(Symbols.calendar_month_rounded, color: context.colors.primary),
          context.space.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.text.labelMedium?.copyWith(color: context.colors.onSurfaceVariant)),
                Text(
                  value == null ? l10n.opsNoDate : fmt.formatMediumDate(value!),
                  style: context.text.bodyLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (clearable && value != null)
            IconButton(
              tooltip: l10n.opsClear,
              icon: const Icon(Symbols.close_rounded),
              onPressed: () => onChanged(null),
            ),
        ],
      ),
    );
  }
}

/// Bottom-sheet form body: title, scrolling fields, then Save / Cancel.
class FormSheet extends StatelessWidget {
  const new({
    required this.title,
    required this.children,
    required this.onSave,
    super.key,
    this.saving = false,
    this.onDelete,
    this.saveLabel,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback? onSave;
  final VoidCallback? onDelete;
  final bool saving;
  final String? saveLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetTitle(title),
          context.space.gapMd,
          for (final c in children) ...[c, context.space.gapMd],
          FarmTapButton(label: saveLabel ?? l10n.save, loading: saving, onPressed: saving ? null : onSave),
          if (onDelete != null) ...[
            context.space.gapSm,
            FarmTapButton(label: l10n.opsRemove, kind: ButtonKind.text, onPressed: saving ? null : onDelete),
          ],
        ],
      ),
    );
  }
}

/// Owners and managers change things; workers see a note instead.
class ViewOnlyNote extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: context.space.md),
    child: Text(
      AppLocalizations.of(context).opsViewOnly,
      textAlign: TextAlign.center,
      style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
    ),
  );
}

String contactKindLabel(AppLocalizations l10n, ContactKind k) => switch (k) {
  ContactKind.vet => l10n.opsKindVet,
  ContactKind.aiTechnician => l10n.opsKindAi,
  ContactKind.feedSupplier => l10n.opsKindFeed,
  ContactKind.agrovet => l10n.opsKindAgrovet,
  ContactKind.buyer => l10n.opsKindBuyer,
  ContactKind.transporter => l10n.opsKindTransport,
  ContactKind.emergency => l10n.opsKindEmergency,
  ContactKind.other => l10n.opsKindOther,
};

String dutyLabel(AppLocalizations l10n, Duty d) => switch (d.activity) {
  DutyActivity.milking => l10n.opsDutyMilking,
  DutyActivity.feeding => l10n.opsDutyFeeding,
  DutyActivity.health => l10n.opsDutyHealth,
  DutyActivity.cleaning => l10n.opsDutyCleaning,
  DutyActivity.grazing => l10n.opsDutyGrazing,
  DutyActivity.security => l10n.opsDutySecurity,
  DutyActivity.collection => l10n.opsDutyCollection,
  DutyActivity.manager => l10n.opsDutyManager,
  DutyActivity.other => d.label ?? l10n.opsDutyOther,
};

String activityLabel(AppLocalizations l10n, DutyActivity a) => dutyLabel(l10n, Duty(id: '', activity: a, staffId: ''));

String shiftLabel(AppLocalizations l10n, DutyShift s) => switch (s) {
  DutyShift.morning => l10n.opsShiftMorning,
  DutyShift.afternoon => l10n.opsShiftAfternoon,
  DutyShift.evening => l10n.opsShiftEvening,
  DutyShift.night => l10n.opsShiftNight,
  DutyShift.allDay => l10n.opsShiftAllDay,
};

/// Short day names, 0 = Sunday.
List<String> shortDays(BuildContext context) {
  final names = MaterialLocalizations.of(context).narrowWeekdays;
  return names;
}
