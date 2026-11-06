# Switching on Blaze (one command)

Everything that needs the Firebase **Blaze** (pay as you go) plan is already
written and tested. It stays off until you run one command.

## What you do

1. Firebase console > project **farm-tap-1dd15** > bottom left **Upgrade** >
   Blaze > add your card. Set a budget alert (Billing > Budgets, e.g. USD 25
   a month) so you are emailed before costs grow.
2. On your computer, in the repo folder (`~/farm_tap`):

   ```
   git pull
   bash tool/activate-blaze.sh
   ```

   It signs you in if needed, builds the website, tests the server code,
   deploys everything (website, database rules and indexes, file storage
   rules, server functions) and switches the server jobs on. The first
   time, a browser window may open once for Google sign-in.
   If you do not have the Google Cloud CLI (`gcloud`), the script tells you
   to flip the switches in **Admin > Integrations > Server jobs** instead.

3. Paste the API keys when you have them, in **Admin > APIs and keys**
   (never in chat, never in the code). Each feature waits for its key:

| Feature | Keys (Admin > APIs and keys) | Also |
| --- | --- | --- |
| MTN Mobile Money payments | MTN collection subscription key, API user, API key | Admin > Payments: turn MTN on, "Pay inside the app" on |
| Airtel Money payments | Airtel client id, client secret | Admin > Payments: Airtel on |
| Card payments | Flutterwave secret key, webhook hash | Flutterwave dashboard: webhook URL `https://europe-west1-farm-tap-1dd15.cloudfunctions.net/paymentWebhook` |
| Automatic SMS | Africa's Talking username + API key (or Twilio) | Admin > Integrations: SMS company, sender name |
| Automatic WhatsApp | WhatsApp token | Admin > Integrations > WhatsApp: phone number id, approved template name, language |
| AI assistant, server route (decision 0028) | Google Gemini API key as `gemini_api_key` | Deploy `aiAssistant` and `aiUsageNow`, then Admin > AI Control Centre > AI assistant > Route: Secure server |
| Refunds through the provider | MTN disbursement key, user, API key (Airtel / Flutterwave use the payment keys) | Admin > Receipts and refunds |

Without keys, payments are taken by hand (farmer sends the transaction ID,
you approve it in Admin > Money), and SMS/WhatsApp go free from the
manager's own phone (decision 0015).

## Server jobs (Admin > Integrations > Server jobs)

| Switch | What it does |
| --- | --- |
| `alerts` | Every hour: today's duty, vaccination, calving, trial and plan reminders as push notifications, and SMS/WhatsApp to workers |
| `autoSms` | Sends queued SMS through the SMS company |
| `whatsappApi` | Sends queued WhatsApp messages through the WhatsApp Business API |
| `billingPdf` | Numbers each payment and stores its receipt and invoice PDF |
| `refundsApi` | Pays approved refunds back through MTN, Airtel or Flutterwave |
| `accountErase` | Turns off sign-in for closed accounts and erases them after 90 days |

Turn all off again: `cd functions && node scripts/activate.mjs off`.
Show them: `node scripts/activate.mjs --show`.

## Closed accounts (support)

Closed accounts are kept 90 days. Restore in **Admin > Deleted accounts**,
or from the computer:

```
cd functions && npm run build
node scripts/accounts.mjs list
node scripts/accounts.mjs restore <uid>
node scripts/accounts.mjs erase <uid>    # only when the person asks, cannot be undone
```

## Cost guide

For a few hundred farms the functions, storage and database stay inside
Blaze's free monthly amounts or a few dollars. SMS cost is the SMS company's
price per message; WhatsApp Business messages are priced by Meta.
