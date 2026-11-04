# 0015 — Free WhatsApp and SMS from the phone, paid automatic sending later

- Status: accepted (2026-11-03). Owner asked: "send WhatsApp and SMS working? Can we do this without me spending any money?"
- Date: 2026-11-03
- Decided by: Mubangizi Victor (owner)
- Roadmap items: DAIRY-CENTRE SMS receipts and statements (G05, G11), owner daily report (L04), monthly report share (L03). No new sector work.
- Builds on: 0014 (the `smsOutbox` collection and record journal).

## Audit (branch `claude/project-thread-71znvn`, 3 Nov 2026)
| Feature | Before | Gap |
|---|---|---|
| Milk receipt SMS (G05) | Queued to `smsOutbox`; "SMS receipt queued" shown | No sender exists, so nothing ever left the phone |
| Weekly statements (G11) | `sendStatements()` did nothing; "Statements sent" celebration shown | Fake success |
| Daily WhatsApp report (L04) | Preview and settings only; text said "Sent every day" | No send at all |
| Monthly report (L03) | Share button showed "Coming soon" | No share |

## Options checked (prices searched 3 Nov 2026)
| Option | Cost to FarmTap | Works for farmers without the app? | Verdict |
|---|---|---|---|
| WhatsApp click-to-chat (`wa.me` link) | Free | Yes, if they have WhatsApp | **Use now** |
| Phone's own SMS app (`sms:` link, user taps Send) | Free to FarmTap; the farm's own airtime/bundle (MTN bundles ~UGX 5–6 per SMS) | Yes, any phone | **Use now** |
| Sending SMS silently from the phone's SIM (`SEND_SMS`) | Free | Yes | **Rejected**: Google Play allows `SEND_SMS` only for default SMS/Phone apps or narrow exceptions; the app would be removed |
| Firebase Cloud Messaging push | Free | No (app users only); needs Cloud Functions → Blaze plan | Later, for owner/staff alerts |
| WhatsApp Cloud API | 1,000 free service messages per number per month; since 1 Oct 2026 Meta charges for utility templates and service messages above that. Uganda is billed at "Rest of Africa" rates | Yes | Not now: needs Meta business verification + templates; most receipts are outside a 24 h chat window, so they are paid |
| Africa's Talking bulk SMS | UGX 27 (MTN), 25 (Airtel), 35 (others) per SMS at the lowest tier; sender ID through MTN/Airtel | Yes | **Paid automatic option**, ready in code |
| Twilio | About USD 0.26 per SMS to Uganda (≈ UGX 950) | Yes | Supported but ~35× dearer than Africa's Talking |

Sources: developers.facebook.com WhatsApp pricing; africastalking.com/pricing; support.google.com Play SMS/Call Log policy (answer 10208820); sent.dm Uganda SMS pricing.

## Decision
1. **Free now.** Every message is still saved to `smsOutbox` (status `queued`). The user sends it from the phone: FarmTap opens WhatsApp or the SMS app with the words typed in and the farmer's number filled; the user taps Send. The record becomes `sentFromPhone` with `via` (`sms`/`whatsapp`) and `sentAt`.
   - G05: after a delivery, "Receipt ready to send" with WhatsApp / SMS buttons.
   - G11: "Send to N farmers" really queues one statement per farmer who delivered this week (with phone and SMS receipts on), then opens **Messages to send**.
   - New screen **Messages to send** (`/settings/messages`, also in More): every waiting message, "Send next · WhatsApp / SMS" to go one by one, Don't send, and Recently sent.
   - L04: WhatsApp / SMS buttons send today's report to the owner's number; a copy is kept as sent. The "SMS if WhatsApp fails" switch is hidden (the user chooses the route).
   - L03: Share sends the monthly summary through any app on the phone (WhatsApp, SMS, email).
   - The fake "SMS left this month / extra SMS needed" rows are gone (FarmTap holds no SMS credit).
2. **Paid automatic sending, ready but off.** `functions/` has `sendQueuedSms` (Firestore trigger on `tenants/{t}/smsOutbox/{id}`) with pluggable providers (`africastalking`, `twilio`). It sends only when `SMS_PROVIDER` is set **and** the farm's tenant doc has `messaging.autoSend: true`. It claims a message in a transaction (`sending`), then writes `sent` or `failed` with the provider id and cost. No key is ever in the app.
3. **Rules.** The app may create an SMS as `queued` or `sentFromPhone`, and may change `queued` → `sentFromPhone` (to and text unchanged). It can never write `sent`/`failed`, and a farm cannot switch on `messaging.autoSend` itself.

## To switch on automatic SMS later (only money left)
1. Upgrade Firebase to Blaze; open an Africa's Talking account, top up, and request sender ID `FARMTAP` (MTN/Airtel review).
2. `cd ~/Desktop/Apps/farm_tap/functions && npm install`
3. `firebase functions:secrets:set SMS_API_KEY` (paste the Africa's Talking API key)
4. Create `functions/.env` with `SMS_PROVIDER=africastalking`, `SMS_USERNAME=<your AT username>`, `SMS_FROM=FARMTAP`
5. `firebase deploy --only functions,firestore:rules`
6. For each paying farm, set `messaging.autoSend = true` on `tenants/<id>` (Firebase console now; admin panel later).

## Known limits
- The phone cannot confirm the user actually pressed Send in WhatsApp/SMS; "sent from this phone" means the app opened with the message.
- If automatic sending is on and someone also taps Send on a phone at the same moment, the farmer can get the message twice; the phone's late update is refused by the rules.
- SMS from the phone uses the farm's airtime; WhatsApp needs data on both sides.
