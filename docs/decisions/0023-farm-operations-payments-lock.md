# 0023 Plans, payments, hard lock and connected farm operations

- Status: proposed (4 Nov 2026, for Victor)
- Builds on: 0022 web client, 0020 super admin panel, 0018 one farm per account

## Why

Victor asked for: a pricing screen (also opened from the trial badge), plans
he can edit in the admin panel, MTN, Airtel and card payments with keys pasted
later and each way to pay mutable, a hard lock after a trial whose length he
sets (14 days), "Switch farm" only for owners of two farms, no Control panel
link for farm owners, and farm work that is connected: feed, health, workers,
suppliers and breeding spending flowing into Money; milk by the cows actually
milked; who feeds, who supplies, the vet's number; a duty roster with
stand-ins and who is in charge when the manager is away.

## Decision

### Plans and pricing
- Plans live in `plans/{id}` (name, price, period months, ribbon, card points,
  hidden, `sample`). The admin Plans page edits them and can load three
  sample plans (Monthly 70,000, 3 months 195,000, Yearly 700,000) marked
  "Sample" until Victor sets real prices.
- Settings > Plan and payment shows the status, plan cards, ways to pay and
  payment history. The trial chip in the top bar opens it on every screen.

### Payments (server only)
- Cloud Functions in `functions/` (region europe-west1, codebase
  `payments`): `startPayment`, `checkPayment`, `paymentWebhook`
  (`/mtn`, `/airtel`, `/flutterwave`) and `sweepPayments` (scheduled).
- MTN MoMo Collection, Airtel Money (Uganda) and card through Flutterwave
  hosted checkout. Bank transfer and other manual ways stay as claims the
  admin confirms.
- Keys are pasted in the admin panel and stored in `platformSecrets/{name}`,
  which no app can read. Apps never call a provider.
- The price always comes from `plans/{id}` on the server. A payment counts
  only when the provider says it is paid in full; then one transaction writes
  the payment, extends `subscription.paidUntil`, sets `planId`, copies it to
  `platformPayments` and writes an `adminAudit` line. Repeating it is a no-op.
- Each way to pay can be on ("Available"), muted ("Coming soon") or hidden.
  New ways start muted. Mode Test or Live and the MTN environment are set in
  APIs and keys.

### Hard lock (no grace)
- `canWrite` = not suspended and (now < `trialEndsAt` or now < `paidUntil`).
  There is no grace and no slack. The trial length is `platform/config.trialDays`
  (default 14), set in admin Settings.
- When locked, the security rules refuse every write to the farm profile,
  members, worker logins, cards, scans and records. The only write left is a
  manual payment claim by the owner or manager. The server functions check
  the same rule.
- The app shows a lock screen on every page except Settings, with "Choose a
  plan and pay" and "Look at my records" (read only). Banners warn 3 days
  before a trial ends and 5 days before a plan ends. The admin panel still
  shows "Due in N days" for paid farms near their end.

### One farm per account
- "Switch farm" shows only when the account owns two farms (or works on
  several). More farms are asked for through WhatsApp support. Farm owners no
  longer see a Control panel link; the super admin uses its own sign-in.

### Connected spending
- Feed purchases, treatments, vaccinations, worker pay, supplier payments and
  breeding service costs each write their record and a matching expense in
  one batch (`lib/linked.ts`). The expense carries `sourceId`, `sourceType`,
  `supplierId` and `payMethod`. Editing replaces both; removing removes both,
  from either side. Categories stay in the phone's list.
- Money shows where each expense came from and the total paid to each
  supplier. Reports gives a monthly profit, cost of a litre and feed cost of a
  litre, with CSV and print.

### Farm operations
- Workers: pay by hour, day, week, month, year or contract, paid by cash, MTN
  MoMo, Airtel Money, bank or other, with a reference.
- Milk: total mode asks how many cows were milked or which ones; each-cow mode
  ticks only the cows milked.
- New pages: Feeds (store, buy, feeding, who feeds, suppliers), Contacts (vet,
  suppliers, buyers, with call and WhatsApp and spend per supplier), Duty
  roster (who is on, stand-in, mark away, in charge today), Breeding (heat,
  served, pregnancy check, calved), Reports. Home has a "Today on the farm"
  card with duties and reminders.
- New manager-only collections: `contacts`, `duties`, `absences`,
  `feedTypes`, `vaccinations`. Every worker can read them.

## Phone app

Changed in this branch (needs a new app build): 14-day trial with no grace in
`farm_membership.dart`, and tolerant reading of web expenses and feed
purchases. Not yet on the phone: Contacts, Duty roster, Feeds store,
Vaccinations and the pay screen. The phone keeps working with these records
because they use its shapes, and the lock is enforced by the rules for both.

## Tests

- Rules: 57 pass (`firestore/rules.test.mjs`), including the lock and linked
  spending suites.
- Functions: 11 unit tests, plus `functions/scripts/payment-flow.emulator.mjs`
  (no keys, muted way, stranger refused, price from plan, underpayment fails,
  full payment extends the plan, idempotent).
- Web: 16 unit tests, typecheck, build, and a phone and desktop pass of every
  farm page and the lock screen against seeded emulators.
