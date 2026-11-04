// Free sending (decision 0015): the phone's SMS app or WhatsApp opens with
// the message typed in; the user taps Send. FarmTap pays nothing.
import 'dart:async';

import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/sms/phone_messenger.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// "Couldn't open WhatsApp" / "Couldn't open the SMS app".
void showSendFailed(BuildContext context, MessageRoute route) {
  final l10n = AppLocalizations.of(context);
  ScaffoldMessenger.maybeOf(
    context,
  )?.showSnackBar(SnackBar(content: Text(route == MessageRoute.sms ? l10n.smsAppOpenFailed : l10n.whatsappOpenFailed)));
}

/// SMS and WhatsApp buttons side by side. [onSend] returns false when the
/// app could not open; a message then says so.
class SendFromPhoneButtons extends StatefulWidget {
  const new({required this.onSend, super.key, this.smsLabel, this.whatsappLabel, this.forceRow = false});

  final Future<bool> Function(MessageRoute route) onSend;
  final String? smsLabel;
  final String? whatsappLabel;
  final bool forceRow;

  @override
  State<SendFromPhoneButtons> createState() => _SendFromPhoneButtonsState();
}

class _SendFromPhoneButtonsState extends State<SendFromPhoneButtons> {
  MessageRoute? _busy;

  Future<void> _send(MessageRoute route) async {
    setState(() => _busy = route);
    final ok = await widget.onSend(route);
    if (!mounted) return;
    setState(() => _busy = null);
    if (!ok) showSendFailed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ButtonPair(
      forceRow: widget.forceRow,
      first: FarmTapButton(
        label: widget.whatsappLabel ?? l10n.sendOnWhatsapp,
        icon: Symbols.chat_rounded,
        loading: _busy == MessageRoute.whatsapp,
        onPressed: _busy == null ? () => unawaited(_send(MessageRoute.whatsapp)) : null,
      ),
      second: FarmTapButton(
        label: widget.smsLabel ?? l10n.sendBySms,
        icon: Symbols.sms_rounded,
        kind: ButtonKind.tonal,
        loading: _busy == MessageRoute.sms,
        onPressed: _busy == null ? () => unawaited(_send(MessageRoute.sms)) : null,
      ),
    );
  }
}
