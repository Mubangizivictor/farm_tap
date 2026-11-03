import 'package:farm_tap/core/sync/record_journal.dart';

/// Text messages the app wants sent (receipts, alerts).
///
/// The phone never holds an SMS provider key. It saves each message to the
/// farm's `smsOutbox` collection with status `queued`; the record syncs like
/// any other, even when it was saved offline. A server job (Twilio, Africa's
/// Talking, ...) picks up queued messages, sends them and records the
/// result. Until that job exists, messages wait in the outbox.
class SmsOutbox {
  const new(this.journal);

  final RecordJournal journal;

  static const collection = 'smsOutbox';

  /// Queues [text] to [to] (an international number, e.g. +256 772 451908).
  /// Pass [id] to be able to [cancel] it, e.g. after Undo.
  Future<void> queue({required String to, required String text, required String kind, String? id}) async {
    final phone = to.replaceAll(' ', '');
    if (phone.isEmpty) return;
    await journal.add(collection, {'to': phone, 'text': text, 'kind': kind, 'status': 'queued'}, id: id);
  }

  /// Withdraws a queued message; the server skips deleted ones.
  Future<void> cancel(String id) => journal.remove(collection, id);
}
