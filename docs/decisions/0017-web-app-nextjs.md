# 0017 — FarmTap on the web (Chrome) is a Next.js app, online only

- Status: accepted (2026-11-03): Victor asked for it in the project chat ("we are using next js for the web version not flutter web because flutter web is slow, and web version there shouldn't be offline access")
- Date: 2026-11-03
- Decided by: Mubangizi Victor (owner)
- Roadmap items: the owner/manager desktop view (ROADMAP owner reports, CORE-01 sign-in). No new sector, dairy only.
- Overrides: binding rule 5 ("offline-first") **for the web app only**. The phone app stays offline-first (decision 0014).

## Decision
1. **Where:** a `webapp/` folder in this repo (`farm_tap`), not a separate repo, so the data model, rules and decisions stay in one place and one branch.
   It is not called `web/` because Flutter treats `web/` as its own Flutter-web platform folder.
2. **Stack:** Next.js (App Router, TypeScript), Firebase JS SDK (modular), no UI kit. Built as a static site (`output: 'export'`), so it is hosted free on **Firebase Hosting (Spark plan)** in the same project `farm-tap-1dd15`. No server code, no Cloud Functions needed.
3. **Online only:** Firestore uses the default memory cache (no IndexedDB persistence). When the browser is offline the app shows a banner and turns off every save button. Nothing is queued.
4. **Same data:** reads and writes the same Firestore paths as the phone (`users/{uid}`, `tenants/{t}`, `tenants/{t}/{collection}/{id}`). Web writes use the same record envelope (`id, tenantId, collection, body, createdAt, updatedAt, createdBy, updatedBy, deviceId, version, isDeleted, serverUpdatedAt`) so `firestore.rules` accept them and phones pull them with the normal sync. `deviceId` starts with `web-`.
5. **Who uses it:** owners and managers (Google, Apple, Email, binding rule 4). Workers keep using the farm phone with card + PIN; the web app does not offer a worker sign-in.
6. **Same look:** Kraal theme and compact density (decision 0013). All colours, sizes, radii, fonts and durations live in `webapp/src/theme/tokens.css` only (binding rule 6 for the web). Light, dark and "same as device".
7. **No "firebaseapp.com" on sign-in:** on Firebase Hosting the `/__/auth/handler` page is served from our own domain, so `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN` is set to the site's domain (`farm-tap-1dd15.web.app` now, the custom domain later). Google's account picker then says "to continue to farm-tap-1dd15.web.app" (or `app.farmtap.ug`), not firebaseapp.com.

## Scope of the first build
- Sign-in: Google, Apple, Email (sign in, create account, forgot password). Stays signed in on the same browser until "Sign out".
- Returning user: opens straight into their farm (last farm remembered on this browser). The farm list only shows when an account belongs to more than one farm (multi-farm is a hidden, priced extra, product decision of 3 Nov).
- Owner dashboard: today's and this month's milk, 14-day milk chart, herd numbers, cows in drug withdrawal, this month's spending, workers and today's attendance, centre deliveries (centres only), trial/read-only status.
- Pages: Herd, Milk, Health, Money, Workers, Farmers (centres), Settings. Each list has search and CSV download.
- Saves from the web (owner/manager, online, not read-only): add an expense, add an animal, record milk (herd total or per cow), add a supplier farmer (centre).

## Small extras added without being asked (Victor's standing instruction, 3 Nov)
- Offline banner with save buttons turned off.
- Read-only banner after the trial (binding rule 3), matching the rules' own check.
- CSV download on every list, and Print on the dashboard and lists (A4, no navigation).
- Theme choice (Device / Light / Dark), remembered on the browser.
- Friendly sign-in errors (wrong password, popup blocked, Apple not set up yet).
- Help link to the support WhatsApp +256 793 128 137.

## Not in this build
- Staff card design/printing, staff sign-in, SMS/WhatsApp sending and payments are other threads' work; the web app will show them once their data exists.
- Super admin panel (comes later, product decision of 3 Nov).

## What Victor sets up once (Firebase console, free)
1. Project settings → Your apps → Add app → Web. Copy the config into `webapp/.env.local` (see `webapp/.env.example`).
2. Authentication → Settings → Authorized domains: add `localhost` (there by default) and `farm-tap-1dd15.web.app`.
3. Google Cloud → Credentials → Web client → Authorized redirect URIs: add `https://farm-tap-1dd15.web.app/__/auth/handler` (so the Google window names our site, not firebaseapp.com).
4. Apple on the web needs an Apple **Services ID** + key (Apple Developer account, which Victor has). Until then the Apple button shows "Apple sign-in is not set up for the web yet".
5. Hosting: `firebase deploy --only hosting` (free Spark plan). `firebase.json` now has a `hosting` block pointing at `webapp/out`.

## Testing
Tested in Chrome against the Firebase emulators with the real `firestore.rules`: account creation, farm setup, record milk, add expense, add animal, add supplier (duplicate card refused), offline banner, light/dark, phone and desktop widths.
