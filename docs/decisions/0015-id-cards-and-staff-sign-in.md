# 0015 — Printable ID cards, one card per person, scan station and staff phone sign-in

- Status: accepted (2026-11-03): asked for by the owner in the project thread ("Build printable staff and farmer ID cards")
- Date: 2026-11-03
- Decided by: Mubangizi Victor (owner)
- Roadmap items: CORE-07 (staff unlock), DAIRY-WRK-01 (attendance), DAIRY-WRK-03 (wages), CENTRE farmer cards (G06/G07), K01-K06.
- Overrides: AGENTS.md binding rule 7 / ROADMAP rule 12 ("no phone-number sign-in") **for staff only**: workers sign in on their own phone with their phone number and a 4-digit PIN. This is not SMS OTP; no SMS is sent and nothing costs money. Owners still sign in with Google, Apple or email.

## What the owner asked for (3 Nov 2026)
1. Designed, printable ID cards for staff and milk suppliers: photo, name, role, department, more details, QR code, card number, the size of a normal bank card, download and print.
2. Photos coded fully against Firebase Storage even though Storage is not switched on yet; only paying should be left.
3. A simple 4-digit card number to type on phones without NFC; a QR code on the card to scan with the camera.
4. A card given to one person can never be given to another until it is revoked.
5. Scanning a card shows the person's ID with photo and status, then waits for the next card by itself.
   - Workers: present or not, days this month, pay status (wage, advances, paid, balance).
   - Milk suppliers: today's litres, this period, money owed, recent deliveries.
6. Non-admin workers sign in with phone number + PIN; they must choose their own PIN the first time.
7. Panels for each kind of worker, so they only see their work.
8. "Add the small features you know are missing."

## Decision

### 1. One card register for everyone (`core/people`, collection `nfcCards`)
- `CardRegistry` holds every card: its 4-digit number (the document id), the NFC chip id if it has one, who holds it (staff or farmer), status (`active`, `returned`, `lost`) and dates.
- **A card has one holder.** Issuing an active card that belongs to someone else fails with "Card 0142 belongs to Amos. Revoke it first." A lost card can never be issued again (someone may have found it). A returned card can go to a new person.
- A person has one active card. "Replace lost card" marks the old one lost in the same step.
- Blank NFC cards that only report a chip id get a free random 4-digit number (random so two offline phones are unlikely to pick the same one). The number is printed on the card and is what people type.
- Staff unlock, attendance, milk collection and the scan station all look cards up here, so a farmer's card can never clock a worker in and the other way round.

### 2. Photos with no Storage bill (`PhotoStore`)
- The camera/gallery photo is shrunk on the phone to 320 px (about 20 KB) and kept **in the person's record**, so it syncs to every farm phone and prints on the card today, on the free plan.
- The full photo (1080 px) is uploaded to Firebase Storage at `tenants/{tenantId}/people/{personId}.jpg` (`storage.rules` added). While Storage is off the upload fails quietly, the photo waits on the phone and is retried on the next start. Turning on Storage (Blaze plan) is the only step left.

### 3. ID card design and printing (`IdCardView`, `IdCardPdf`)
- CR80 size (85.6 × 54 mm), front and back. Front: farm name, photo, name, job, department, card number, staff/supplier ID, QR code. Back: phone, emergency contact, issued date, "If found, please call" with the farm's phone, and the card number again.
- QR payload `FTID:<tenantId>:<number>`; a card from another farm is refused.
- Print one card, or all cards on A4 (8 per page, with cut marks). Download/share as PDF. All print sizes are tokens in `FarmTapPrint`.

### 4. Scan station (`/cards/scan`)
- NFC keeps listening (Android) or reopens Apple's sheet after each result (iPhone). Camera QR scan and typed number work on phones without NFC (typed numbers still need a manager PIN for attendance, decision 0006).
- Each scan shows the person's ID panel and, in attendance mode, clocks the worker in or out. After a few seconds the panel clears and the next card is read with no tap needed.
- Lost or returned cards show a red warning.

### 5. Staff phone sign-in (phone + PIN), free plan only
- When a worker with a phone number is added, the manager's phone creates a Firebase email/password login for them in a second Firebase app instance (the manager stays signed in): `p<phone>v<n>@staff.farmtap.app`, password derived from the PIN. It writes `tenants/{t}/members/{uid}` (role and staffId), `users/{uid}` (the farm and "must change PIN") and `staffLogins/{phone}` (current login version).
- The worker opens FarmTap, taps "I work on a farm", types phone + PIN. The first time, they must choose a new PIN; it replaces the temporary one for both the phone login and the card unlock (`staffPins` record).
- Manager "Reset PIN" sets a new temporary PIN and creates a fresh login version; the old login loses its membership.
- **Risk (accepted):** a 4-digit PIN is weak against someone who tries many PINs. Firebase limits repeated wrong sign-ins and the app locks after 5 wrong tries. Before many farms use it, turn on App Check and later move login creation to a Cloud Function.

### 6. What the PIN is for
The card says who you are; the PIN proves it is you. Anyone can pick up a card, so the shared farm phone asks for the PIN before records are saved in that worker's name. On a worker's own phone the PIN is their password.

### 7. Panels by role (`StaffPermissions`)
| Role | Sees |
|---|---|
| Owner, manager | Everything |
| Herdsman / milker | Home, Herd, Milk, Health, Feeding, Breeding, My page |
| Clerk (milk clerk, secretary, accountant) | Home, Milk, Collect, Farmers, My page |
| Worker (driver, guard, cook, family) | Home, Milk, Feeding, My page |
| Vet | Home, Herd, Health, Breeding, My page |
Money, wages, reports, settings and staff management stay owner/manager only. Hidden sections are also blocked by the router.

**My page** (every worker): their ID card, today's clock-in, days this month, wage / advances / paid / balance, their tasks, change PIN.

### 8. Small features added without being asked
- More staff details: department, national ID (NIN), village, emergency contact.
- Revoke card ("Lost" or "Returned") on staff and farmers, with the card history on the person's page.
- Farmer cards: assign/replace/revoke from the farmer's page, photo, printable supplier card.
- Card register page: every card, who holds it, status.
- Activity on staff detail opens their attendance this month (was "coming soon").
- "What can Amos do?" now lists the sections their role opens (was "coming soon").

## Not in this decision
SMS/WhatsApp, the Next.js web app, sign-in branding and the farm picker are separate threads.
