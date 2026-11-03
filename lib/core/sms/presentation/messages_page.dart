// Messages to send (decision 0015): receipts, statements and reports
// waiting in the outbox. Each one goes out from this phone's SMS app or
// WhatsApp at no cost to FarmTap; "Send next" walks the queue one by one.
import 'dart:async';

import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/sms/phone_messenger.dart';
import 'package:farm_tap/core/sms/presentation/send_from_phone.dart';
import 'package:farm_tap/core/sms/sms_outbox.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class MessagesPage extends StatefulWidget {
  const new({required this.outbox, super.key, this.messenger = const PhoneMessenger()});

  /// Null in demo builds: nothing is ever queued there.
  final SmsOutbox? outbox;
  final PhoneMessenger messenger;

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  List<OutboxMessage>? _all;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final all = await widget.outbox?.all() ?? const <OutboxMessage>[];
    if (mounted) setState(() => _all = all);
  }

  Future<bool> _send(OutboxMessage m, MessageRoute route) async {
    final outbox = widget.outbox;
    if (outbox == null) return false;
    final ok = await outbox.sendFromPhone(m, route, messenger: widget.messenger);
    await _load();
    return ok;
  }

  Future<void> _remove(OutboxMessage m) async {
    await widget.outbox?.cancel(m.id);
    await _load();
  }

  String _kind(AppLocalizations l10n, String kind) => switch (kind) {
    'deliveryReceipt' => l10n.msgKindReceipt,
    'statement' => l10n.msgKindStatement,
    'dailyReport' => l10n.dailyWhatsapp,
    _ => l10n.messages,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final all = _all;
    final waiting = all?.where((m) => m.waiting).toList().reversed.toList() ?? const <OutboxMessage>[];
    final sent = all?.where((m) => !m.waiting).take(20).toList() ?? const <OutboxMessage>[];
    return AdaptiveScaffold(
      title: l10n.messagesToSend,
      showBack: true,
      body: all == null
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.messagesFreeNote,
                  style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                ),
                context.space.gapLg,
                if (waiting.isEmpty)
                  EmptyState(
                    title: l10n.noMessagesWaiting,
                    message: l10n.noMessagesWaitingSub,
                    animation: FarmTapAnimations.smsSent,
                  )
                else ...[
                  FarmTapCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(l10n.messagesWaiting(waiting.length), style: context.text.titleMedium),
                        context.space.gapXs,
                        Text(
                          l10n.sendNextTo(waiting.first.name ?? waiting.first.to),
                          style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                        ),
                        context.space.gapLg,
                        SendFromPhoneButtons(
                          key: ValueKey(waiting.first.id),
                          whatsappLabel: l10n.sendNextOnWhatsapp,
                          smsLabel: l10n.sendNextBySms,
                          onSend: (route) => _send(waiting.first, route),
                        ),
                      ],
                    ),
                  ),
                  context.space.gapLg,
                  for (final m in waiting) ...[
                    _MessageCard(
                      message: m,
                      kind: _kind(l10n, m.kind),
                      onSend: (route) => _send(m, route),
                      onRemove: () => unawaited(_remove(m)),
                    ),
                    context.space.gapMd,
                  ],
                ],
                if (sent.isNotEmpty) ...[
                  context.space.gapLg,
                  Text(l10n.recentlySent, style: context.textStyles.metricLabel),
                  context.space.gapMd,
                  ListCard(
                    children: [
                      for (final m in sent)
                        RecordTile(
                          leading: IconBubble(
                            icon: Symbols.done_all_rounded,
                            tone: FarmTapTone.success,
                            size: context.sizes.bubbleMd,
                          ),
                          title: m.name ?? m.to,
                          subtitle: m.text,
                          showChevron: false,
                          badge: StatusBadge(label: _status(l10n, m), tone: FarmTapTone.success),
                        ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }

  String _status(AppLocalizations l10n, OutboxMessage m) => switch (m.status) {
    SmsOutbox.sentFromPhone => l10n.sentFromThisPhone,
    'failed' => l10n.failedRetry,
    _ => l10n.msgSentAutomatically,
  };
}

class _MessageCard extends StatelessWidget {
  const new({required this.message, required this.kind, required this.onSend, required this.onRemove});

  final OutboxMessage message;
  final String kind;
  final Future<bool> Function(MessageRoute route) onSend;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FarmTapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(message.name ?? message.to, style: context.text.titleSmall)),
              StatusBadge(label: kind, tone: FarmTapTone.info),
            ],
          ),
          if (message.name != null)
            Text(message.to, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
          context.space.gapMd,
          SmsPreviewBubble(message: message.text),
          context.space.gapMd,
          SendFromPhoneButtons(onSend: onSend, forceRow: true),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FarmTapButton(label: l10n.removeMessage, kind: ButtonKind.text, expand: false, onPressed: onRemove),
          ),
        ],
      ),
    );
  }
}
