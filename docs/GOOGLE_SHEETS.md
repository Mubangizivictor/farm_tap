# Google Sheets copy of the control panel (free)

The control panel can copy **Farms, Payments, Users and the Audit log** into your own Google Sheet, one tab each. It is free: no Google Cloud, no API key, no Blaze. A small Google Apps Script inside the sheet receives the data.

## Set up (once)

1. Make a Google Sheet, e.g. "FarmTap data", with your Google account.
2. In the sheet: **Extensions → Apps Script**. Delete what is in `Code.gs` and paste `tools/google-sheets/Code.gs`.
3. Change the `SECRET` line to a long random word (keep it private; never put the real one in this repo). Save.
4. **Deploy → New deployment → ⚙ Web app**. Execute as: **Me**. Who has access: **Anyone**. Deploy, then allow access (Advanced → Go to … → Allow).
5. Copy the **Web app URL** (ends in `/exec`).
6. Control panel → **APIs and keys → Google Sheets**: paste the link and the same secret word, tick "Send by itself" if wanted, **Save changes**, then **Send to Google Sheets**.

## How it works

- `webapp/src/lib/sheets.ts` builds the lists in the admin's browser from what that admin may already see (a finance-only admin sends no Users tab, and so on) and posts them to the web app with the secret word.
- The script checks the word, replaces each tab's rows, and writes "Last updated" on the **About** tab.
- "Send by itself": when an admin opens the Overview, at most once an hour per browser.
- The sheet holds owners' names, emails and phone numbers. Share it only with people who may see them.

## Changing the script later

Edit `Code.gs`, then **Deploy → Manage deployments → ✏ → Version: New version → Deploy**. The link stays the same.

## Later (with Blaze)

A server job can update the sheet every hour with nobody signed in, using a Google service account and the Sheets API (the API itself is free).
