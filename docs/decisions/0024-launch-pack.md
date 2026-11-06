# 0024: Launch pack (phone parity, alerts, receipts, refunds, legal, deletion, stores, Blaze)

- Status: Accepted (Victor, 4 Nov 2026: "do everything still missing in one thread")
- Date: 2026-11-04
- Builds on: 0015 (free messages), 0016 (cards), 0022 (web client), 0023 (payments and hard lock)

## Decisions

1. **Phone parity.** The phone shows Contacts, Duty roster (with stand-ins and
   time away), Feeds store and Vaccinations from the same records as the web
   (`contacts`, `duties`, `absences`, `feedTypes`, `vaccinations`,
   `stockMovements`, `feedUsage`), synced both ways. Owners and managers
   change them; workers see them (contacts only when "workers can see").
2. **Pay screen and lock on the phone.** More > Subscription (and the trial
   card/banner) opens the plan screen: plans and ways to pay from the control
   panel, Mobile Money / card through the server (`startPayment`,
   `checkPayment`), or by hand with a transaction ID (`payments` claim), and
   the farm's receipts as PDF. When the trial or plan ends the phone shows the
   lock screen (pay, help, other farm, sign out); owners may "look at my
   records" in read-only, the same as the web and the rules.
3. **Reminders.** One rule set (`shared/alerts.ts` and
   `lib/core/alerts/alert_rules.dart`, same cases tested on both). The phone
   shows them as notifications and queues free WhatsApp/SMS on the manager's
   phone; the server job (`alerts`) sends push and paid messages once on. Ids
   match (`alert-<id>`) so nothing goes twice. Push tokens are kept at
   `users/{uid}/devices/{deviceId}`.
4. **Receipts.** Every payment gets one sequence number (`counters/billing`)
   and a receipt + invoice (`billingDocs/{paymentId}`), refunds a refund note.
   Numbered in the admin transaction before Blaze, by the server after. PDFs
   carry the logo, stamp and signature uploaded in Admin > Brand and documents.
5. **Refunds.** Admin records, approves and marks paid; paying back through the
   provider is coded and behind the `refundsApi` switch.
6. **Legal.** Privacy policy and terms (Uganda DPPA 2019, Victorbee
   Technologies, +256 793 128 137) are published at /privacy and /terms,
   edited and versioned in Admin > Legal documents.
7. **Deleting an account.** Consequences first, then tick + type DELETE. The
   account and the farms it owns close at once and are kept 90 days for
   restore (Admin > Deleted accounts), then erased (`accountErase`). Payment
   records are kept 7 years for tax.
8. **Photos.** Everyone can set a profile photo (`users/{uid}.photo`: small
   copy in the record, full file in storage once Blaze is on).
9. **Stores.** One pack for Google Play and the App Store (`docs/store/`):
   listing, data safety, privacy labels and manifest, signing, screenshots,
   release checklist. Version 1.0.0+1.
10. **Blaze.** Every paid job checks a switch in `platform/config.server`;
    `bash tool/activate-blaze.sh` deploys and switches them on (docs/BLAZE.md).
    Keys live only in `platformSecrets`, pasted in the control panel.

## Defaults Victor can change later

Trial length, plan prices and payment methods (Admin > Plans / Payments),
reminder hour 6 am and channels (Settings > Reminders), legal text (Admin >
Legal documents), company details on receipts (Admin > Brand and documents),
website words (Admin > Website).
