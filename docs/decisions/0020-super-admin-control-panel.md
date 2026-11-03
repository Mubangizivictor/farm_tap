# 0020 Super admin control panel

- Status: Proposed (waiting for Victor's approval)
- Date: 3 Nov 2026
- Asked by: Victor, 3 Nov 2026 ("make me able to make changes without touching the code": SMS subscription, APIs, location APIs, web and app version, payment gateway APIs, more staff)
- Replaces: the "admin panel comes later" note in the 3 Nov product changes. Victor asked for it now.

## Decision

FarmTap gets a platform control panel at `/admin/` in the Next.js web app (decision 0017). It is for Victorbee staff only. Firestore rules enforce the access, so hiding the menu is not the protection. Everything Victor may want to change later lives in Firestore and is edited from the panel, so changing a price, an API key, an app version or a feature needs no new build.

## What the panel does

| Area | What Victor can do |
|---|---|
| Overview | Farms by status, trials ending this week, MRR, this month's revenue, pending reviews, SMS credits sold |
| Farms | List with sector, owner, plan, status, last seen; approve or reject the review; open a farm read-only; suspend and reactivate; extend the trial; change plan; per-farm feature switches; farm limit (multi-farm); SMS credits; private support notes |
| Money | Record MTN, Airtel, card, bank or cash payments (extends paid-until in the same step); void a wrong entry; payment claims sent from the farms; revenue by month; MRR; CSV export |
| Plans | Create and edit plans (name, UGX price, months per period, features, SMS credits included, worker limit); hide old plans. Nothing is hard-coded. |
| SMS | SMS packages (credits and price); provider (none, Africa's Talking, Twilio), username and sender ID; API key stored write-only; top up credits per farm |
| Payments | Turn MTN MoMo, Airtel Money, card (Flutterwave) and bank on or off; pay code and instructions shown in the app; API keys stored write-only |
| Location | Maps provider; a restricted app key the phones may read; a server key stored write-only |
| App and web versions | Android and iOS minimum and latest version, store links, force-update message; web minimum build; maintenance mode with a message (admins still get in) |
| Feature flags | Default per feature, then per plan, then per farm (farm wins) |
| Sign-up | Which sectors are open; trial length in days (rules read it too); sector waitlist with counts |
| Announcements | To all farms, one sector or one farm; info or warning; start and end dates. Shown in the web app and on the phones. |
| Users and support | Search accounts; disable an account; reset a worker's card PIN to a temporary one; revoke a card; support contacts (phone, WhatsApp, email, hours) edited in one place |
| Staff | Invite by email with a role (owner, finance, support, viewer or custom permissions); turn staff off |
| Audit log | Every change made in the panel, by whom and when, filterable |

## How it is kept safe

1. **Admins:** `platformAdmins/{uid}` holds a role and permissions (`farms`, `finance`, `users`, `support`, `messages`, `settings`, `secrets`, `staff`, `audit`). The owner role has all of them. The first owner is created by hand in the Firebase console. The panel can never make an owner.
2. **Invites:** `adminInvites/{email}`. A person whose Google or email account matches a verified invite becomes staff with exactly the invited permissions.
3. **Every change is logged:** each admin write carries `lastAudit`, and the rules require that `adminAudit/{id}` is written in the same batch, by the same person, at the same time. The log cannot be edited or deleted.
4. **Secrets:** API keys go to `platformSecrets/{name}`, which no app can read (`allow read: if false`). Only server code (Cloud Functions, Admin SDK) reads them. The panel shows only the last 4 characters and who set them. No key is ever in the repo or in either app.
5. **Farm fields only the panel may change:** `subscription`, `review`, `status`, `planId`, `features`, `smsCredits`, `messaging`, `billing`, `farmLimit`. Farms cannot set them, at creation or later.
6. **Suspension** is enforced in the rules: a suspended farm stays readable but cannot write.
7. **Public settings** (`platform/config`, `plans`, `smsPackages`) are readable by the apps and hold nothing secret.

## The phones

The app reads `platform/config` and announcements when online, caches them and starts with safe built-in defaults when offline or before the first download. Offline, nothing is ever blocked by a missing setting: maintenance and force update apply only when a downloaded setting says so.

## What needs the Blaze plan (paid Firebase)

Works on the free Spark plan now: the whole panel, rules, settings, plans, payments recorded by hand, announcements, versions, flags, staff.

Needs Blaze and Cloud Functions (`admin-functions/`, codebase `admin`): fully disabling a Firebase sign-in (until then a disabled account is shown a "disabled" screen and loses farm access through its memberships), automatic SMS reading the key from `platformSecrets`, and automatic Mobile Money confirmation.

## Accepted limits

- Maintenance mode and force update are checked by the apps, not by the rules (a rule check on every write would cost a read each time).
- A phone that never comes online keeps working with its last settings.
- Plan names and prices are entered by Victor in the panel. The starting plan is the binding UGX 70,000 per month, which Victor can change.
