import 'package:farm_tap/core/sms/phone_messenger.dart';
import 'package:farm_tap/core/sync/record_journal.dart';

/// One message waiting in (or sent from) the outbox.
class OutboxMessage {
  const new({
    required this.id,
    required this.to,
    required this.text,
    required this.kind,
    required this.status,
    required this.createdAt,
    this.name,
  });

  final String id;

  /// International number, e.g. +256772451908.
  final String to;
  final String text;

  /// `deliveryReceipt`, `statement`, `dailyReport`, ...
  final String kind;

  /// `queued`, `sentFromPhone`, or (written by the server) `sending`,
  /// `sent`, `failed`.
  final String status;
  final DateTime createdAt;

  /// Who it is for, when known (a farmer's name).
  final String? name;

  bool get waiting => status == SmsOutbox.queued;
}

/// Text messages the app wants sent (receipts, statements, reports).
///
/// Every message is saved to the farm's `smsOutbox` collection with status
/// `queued`; the record syncs like any other, even when saved offline. Two
/// ways it leaves (decision 0015):
///
/// * **Free, now:** the user sends it from this phone ([PhoneMessenger]
///   opens the SMS app or WhatsApp with the text typed) and the record is
///   marked `sentFromPhone`.
/// * **Automatic, paid, later:** the `functions/` job sends queued messages
///   through a provider (Africa's Talking, Twilio) once the farm has
///   `messaging.autoSend` on. The phone never holds a provider key.
class SmsOutbox {
  const new(this.journal);

  final RecordJournal journal;

  static const collection = 'smsOutbox';
  static const queued = 'queued';
  static const sentFromPhone = 'sentFromPhone';

  /// The outbox id of the receipt for delivery [deliveryId].
  static String receiptId(String deliveryId) => 'receipt-$deliveryId';

  /// Queues [text] to [to] (any Uganda format, e.g. 0772 451908).
  /// Pass [id] to be able to [cancel] it, e.g. after Undo.
  Future<void> queue({required String to, required String text, required String kind, String? id, String? name}) async {
    final phone = PhoneMessenger.international(to);
    if (phone.isEmpty) return;
    await journal.add(collection, {'to': phone, 'text': text, 'kind': kind, 'status': queued, 'name': ?name}, id: id);
  }

  /// Every message not withdrawn, newest first.
  Future<List<OutboxMessage>> all() async {
    final records = await journal.load(collection);
    final list = [
      for (final r in records)
        OutboxMessage(
          id: r.id,
          to: r.body['to'] as String? ?? '',
          text: r.body['text'] as String? ?? '',
          kind: r.body['kind'] as String? ?? '',
          status: r.body['status'] as String? ?? queued,
          name: r.body['name'] as String?,
          createdAt: r.createdAt,
        ),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Messages still waiting to be sent, oldest first (send order).
  Future<List<OutboxMessage>> waiting() async => (await all()).where((m) => m.waiting).toList().reversed.toList();

  Future<OutboxMessage?> find(String id) async => (await all()).where((m) => m.id == id).firstOrNull;

  /// Records that the user sent [message] from this phone by [via].
  /// Only a waiting message changes (the server may have sent it already).
  Future<void> markSentFromPhone(OutboxMessage message, MessageRoute via) async {
    final current = await find(message.id);
    if (current == null || !current.waiting) return;
    await journal.put(collection, message.id, {
      'to': current.to,
      'text': current.text,
      'kind': current.kind,
      'status': sentFromPhone,
      'name': ?current.name,
      'via': via.name,
      'sentAt': journal.clock.now().toUtc().toIso8601String(),
    });
  }

  /// Opens the SMS app or WhatsApp with [message] typed in, and marks it
  /// sent when the app opened. False when nothing could open it.
  Future<bool> sendFromPhone(
    OutboxMessage message,
    MessageRoute via, {
    PhoneMessenger messenger = const PhoneMessenger(),
  }) async {
    final opened = await messenger.open(via, to: message.to, text: message.text);
    if (opened) await markSentFromPhone(message, via);
    return opened;
  }

  /// Withdraws a queued message; the server skips deleted ones.
  Future<void> cancel(String id) => journal.remove(collection, id);
}
