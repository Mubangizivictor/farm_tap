// FarmTap Cloud Functions.
//
// sendQueuedSms (decision 0015): when the app queues a message in
// tenants/{t}/smsOutbox, send it through the paid provider IF
//   1. SMS_PROVIDER is set (africastalking | twilio), and
//   2. the farm has `messaging.autoSend: true` on its tenant doc
//      (Victorbee turns it on for farms that pay for automatic SMS).
// Otherwise nothing happens and the farm sends from its own phone (free).
//
// Needs the Firebase Blaze plan. Setup: see docs/decisions/0015.
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { defineSecret, defineString } = require('firebase-functions/params');
const logger = require('firebase-functions/logger');
const { providerFor } = require('./providers');

initializeApp();

const SMS_PROVIDER = defineString('SMS_PROVIDER', { default: 'none' });
// Africa's Talking username, or Twilio Account SID.
const SMS_USERNAME = defineString('SMS_USERNAME', { default: '' });
// Sender ID (e.g. FARMTAP, registered with MTN/Airtel) or Twilio number.
const SMS_FROM = defineString('SMS_FROM', { default: '' });
// Africa's Talking API key, or Twilio auth token.
const SMS_API_KEY = defineSecret('SMS_API_KEY');

/** Claims a queued message so it is sent once; returns its body or null. */
async function claim(ref) {
  return getFirestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const d = snap.data();
    if (!d || d.isDeleted || d.body?.status !== 'queued') return null;
    tx.update(ref, {
      'body.status': 'sending',
      version: (d.version ?? 1) + 1,
      updatedBy: 'server',
      serverUpdatedAt: FieldValue.serverTimestamp(),
    });
    return { body: d.body, version: (d.version ?? 1) + 1 };
  });
}

exports.sendQueuedSms = onDocumentWritten(
  { document: 'tenants/{t}/smsOutbox/{id}', region: 'europe-west1', secrets: [SMS_API_KEY] },
  async (event) => {
    const after = event.data?.after?.data();
    if (!after || after.isDeleted || after.body?.status !== 'queued') return;
    const send = providerFor(SMS_PROVIDER.value());
    if (!send) return;
    const db = getFirestore();
    const tenant = (await db.doc(`tenants/${event.params.t}`).get()).data();
    if (tenant?.messaging?.autoSend !== true) return;

    const ref = event.data.after.ref;
    const claimed = await claim(ref);
    if (!claimed) return;
    const cfg = { username: SMS_USERNAME.value(), from: SMS_FROM.value(), apiKey: SMS_API_KEY.value() };
    let result;
    try {
      result = await send({ to: claimed.body.to, text: claimed.body.text }, cfg);
    } catch (e) {
      result = { ok: false, error: String(e) };
    }
    if (!result.ok) logger.warn('sms failed', { tenant: event.params.t, id: event.params.id, error: result.error });
    await ref.update({
      'body.status': result.ok ? 'sent' : 'failed',
      'body.providerId': result.providerId ?? null,
      'body.cost': result.cost ?? null,
      'body.error': result.error ?? null,
      'body.sentAt': result.ok ? new Date().toISOString() : null,
      version: claimed.version + 1,
      updatedBy: 'server',
      serverUpdatedAt: FieldValue.serverTimestamp(),
    });
  },
);
