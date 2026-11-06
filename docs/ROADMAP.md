# FarmTap — Master Roadmap

> **Read this first (humans and AI agents).**
> This file is the single source of truth for what FarmTap builds, in what order, and how.
> Any developer or AI coding agent working on this repository must:
> 1. Read this whole file before writing code.
> 2. Work only on the current phase and the current week's unchecked items (Section 9).
> 3. Follow the Binding Rules (Section 2), the Architecture (Section 5) and the Theme Rules (Section 6).
> 4. Reference feature IDs (e.g. `DAIRY-MILK-02`) in commits, branches and pull requests.
> 5. Tick checkboxes in this file in the same commit that completes the work.
> 6. Never add a feature, package or screen that is not in this file without a Change Control record (Section 18).

| Item | Value |
|---|---|
| Product | **FarmTap** — farm and produce-collection records for Western Uganda |
| Company | Victorbee Technologies (Mbarara, Uganda) |
| Repository | `farm_tap` (Flutter app, package `farm_tap`, org `com.victorbee`) |
| Roadmap start | Monday, 2 November 2026 |
| V1 (Dairy) production target | Week of 25 January 2027 |
| Document version | 2.0 (31 October 2026) |

---

## Table of contents

1. Vision, market and order of work
2. Binding rules
3. Business model: pricing and free trial
4. Technology stack
5. Architecture and folder structure
6. Theme and brand rules
7. Authentication, onboarding and roles
8. Data model
9. **V1 Dairy — weekly schedule (strict)**
10. V1 Dairy — feature specification
11. V1.x Dairy completion (AI, IoT phase 1, web dashboard, iOS)
12. IoT roadmap (FarmTap Sense)
13. AI roadmap (Ask FarmTap)
14. Later sectors: Poultry, Piggery, Goats & Sheep, Crops & Produce, Fish
15. Compliance and operations
16. Quality: Definition of Done, testing, CI/CD, release
17. Sales plan and metrics
18. Change Control and decision log
19. Risk register
20. Glossary

---

## 1. Vision, market and order of work

### 1.1 Vision

FarmTap lets farms and milk collection centres record what happens every day — animals, milk, treatments, feed, workers and money — on ordinary Android phones, offline, in Runyankore and English. Owners get proof and reports they can trust.

**Pitch:** *Tap the card, record the work, the farmer gets proof, the owner gets a report, nobody cheats.*

### 1.2 Who pays (V1)

| Segment | Example | Why they pay |
|---|---|---|
| Commercial dairy farms | 10–300 cows around Mbarara, Kiruhura, Kazo, Isingiro, Ibanda | Theft control, treatment and breeding tracking, milk records, profit |
| Absentee owners | Owner lives in Kampala or Mbarara town | Daily WhatsApp report, worker accountability |
| Milk collection centres | Private and cooperative centres | End delivery disputes, automatic farmer statements and payment sheets |
| Dairy cooperatives | Several centres | Combined records and statements |

Smallholder farmers are **not** the V1 buyer. They benefit as recipients of SMS statements from collection centres.

### 1.3 Order of work: Dairy first, completely

```
V0   Foundation ............................. Nov 2026 (Week 1)
V1   Dairy (cattle) ......................... Nov 2026 - Jan 2027  -> PRODUCTION
V1.x Dairy completion ....................... Feb - Apr 2027
       (AI, Bluetooth scale, IoT cold-chain pilot, beef/ranching, web dashboard, iOS)
V2   Poultry (layers, broilers, egg collection)   earliest May 2027, Gate G2
V3   Piggery                                      Gate G3
V4   Goats & Sheep                                Gate G4
V5   Crops & Produce buying                       Gate G5
V6   Fish farming                                 Gate G6
IoT  phases 2+ (per sector)                       Gate GI
```

**Dairy must be complete, in production, with paying customers before any other sector's code is written.** The onboarding screen still lists all sectors (Section 7.3) so non-dairy users can join a waitlist. That waitlist is evidence for the gates in Section 14.

### 1.4 Geography

- Phase 1: Mbarara City and Mbarara District.
- Phase 2: Kiruhura, Kazo, Isingiro, Ibanda, Ntungamo, Sheema, Bushenyi.
- Later: rest of Uganda.

---

## 2. Binding rules

1. **Dairy first.** No poultry, piggery, goat/sheep, crop or fish code until V1 is in production and that sector's gate (Section 14) is passed. Shared `core/` code is allowed only if Dairy needs it.
2. **Nothing outside this file** gets built without a Change Control record (Section 18).
3. **Sell while building, from Week 1.** Every week has sales targets (Section 9). A week with zero sales conversations is a failed week, even if the code is done.
4. **Pilots before polish.** The Pilot Build (end of Week 4) goes to real users even if imperfect.
5. **Free trial, then pay.** Every new farm gets a 14-day free trial, then UGX 70,000/month (Section 3). No free use after the trial.
6. **Offline first.** Every recording screen must work with no network.
7. **Low-literacy design.** Recording must work with numbers, icons, photos, read-back confirmation and voice prompts, without reading full sentences.
8. **Theme tokens only.** No hard-coded colours, sizes, fonts, radii, spacing or durations outside `lib/core/theme/` (Section 6). Enforced by test.
9. **Definition of Done** (Section 16) applies to every feature.
10. **Weekly review every Sunday** in `docs/weekly-reviews/YYYY-Www.md`.
11. **AI-generated code is reviewed line by line** before merging. Nobody ships code they don't understand.
12. **No phone-number OTP.** Sign-in is Google, Apple or email only (Section 7).
13. **No personal data to AI services** (names, phone numbers, exact locations) (Section 13).
14. **Buffer week:** one floating week may be inserted once in Weeks 3–8 for the founder's family (birth of child). It shifts all later dates by one week.

---

## 3. Business model: pricing and free trial

### 3.1 Plan

| Plan | Price | Who |
|---|---|---|
| **FarmTap Dairy** | **UGX 70,000 per month** per farm or per collection centre | All V1 users |
| FarmTap Dairy — annual | UGX 770,000 per year (12 months for the price of 11) | Prepaid customers |
| Cooperative (several centres) | Custom quote | Cooperatives |

**Included in UGX 70,000/month:**
- All Dairy features in this roadmap for that farm or centre
- Up to 10 staff (workers, clerks, managers) on NFC cards
- Up to 300 SMS per month (weekly farmer statements, reminders)
- Daily owner report by WhatsApp
- Offline use, backups, support by phone/WhatsApp (same-day response)
- Ask FarmTap AI: 30 questions per month (from V1.x)

**Paid extras (supplier cost + margin; prices set from real quotes):**
- SMS above 300/month
- NFC cards (printed with photo and number)
- QR ear-tag labels
- Bluetooth milk scale, thermal receipt printer (V1.x)
- FarmTap Sense IoT devices and monitoring (Section 12)
- Ask FarmTap questions above the monthly allowance

### 3.2 Free trial rules

| Rule | Detail |
|---|---|
| Length | 14 days from the moment the farm is created in onboarding |
| Features | Everything in the plan (trial SMS cap: 50) |
| Payment details | Not required to start |
| Reminders | In-app + SMS/WhatsApp on day 10, day 13 and day 14 |
| Trial ends unpaid | Account becomes **read-only**: data visible, no new records. Data kept 90 days, then deleted after a final notice |
| After paying | Full access restored instantly; nothing lost |
| One trial per owner | A second farm by the same owner starts on the paid plan |
| Overdue subscription | 7 days grace, then read-only (same as trial end) |

### 3.3 How customers pay

- **Phase A (Weeks 1–9): manual.** Customer pays by MTN MoMo or Airtel Money to the Victorbee merchant number and enters the transaction ID in the app. An admin confirms it in the admin tool (`DAIRY-BILL-04`), which activates the subscription.
- **Phase B (from Week 10, once the API account is approved): automatic.** In-app payment via MTN MoMo / Airtel Money API or a licensed aggregator, with automatic activation.

### 3.4 Unit economics (review monthly)

- Revenue per customer: UGX 70,000/month
- Direct costs to track per customer: SMS, WhatsApp messages, Firebase usage, AI usage, support time
- Target: direct costs below UGX 15,000 per customer per month
- Trial-to-paid conversion target: ≥ 40%

---

## 4. Technology stack

| Layer | Choice | Notes |
|---|---|---|
| App | Flutter 3.47+ / Dart 3.13+ | Android first; iOS in V1.x |
| State | flutter_bloc (Bloc + Cubit) | |
| Routing | go_router | |
| Dependency injection | get_it (manual registration) | |
| Models | freezed + json_serializable | build_runner |
| Offline database | isar_community (+ flutter_libs, generator) | Source of truth on the device |
| Backend | Firebase | Two projects: `farmtap-dev`, `farmtap-prod` |
| Auth | Firebase Auth: **Google, Apple, Email/password** | No phone OTP |
| Database | Cloud Firestore | Multi-tenant |
| Server logic | Cloud Functions (TypeScript) | SMS, WhatsApp, payments, billing, reports, IoT ingest |
| Files | Cloud Storage | Animal and evidence photos |
| Notifications | FCM + flutter_local_notifications + timezone (Africa/Kampala) | |
| Monitoring | Crashlytics, Analytics | |
| Security | App Check + Firestore Security Rules | |
| NFC | nfc_manager | Cards for people only |
| QR | mobile_scanner | Animal ear tags |
| Photos | image_picker, flutter_image_compress, cached_network_image | |
| Reports | pdf, printing, share_plus | |
| Charts | fl_chart | |
| Voice prompts | just_audio | Recorded Runyankore clips |
| Background sync | workmanager, connectivity_plus | |
| Secure storage | flutter_secure_storage, crypto | Session, staff PIN hashes |
| SMS | Ugandan bulk SMS provider via Cloud Functions | Server-side only; no Android SMS permission |
| WhatsApp | WhatsApp Business Platform (Cloud API) via Cloud Functions | Approved message templates |
| Payments | MTN MoMo / Airtel Money API or licensed aggregator | Phase B |
| AI (V1.x) | Free, self-hosted only: shared TypeScript engine; optional Ollama + Qwen3 (decision 0025 replaces Gemini) | Section 13 |
| IoT (V1.x+) | Bluetooth LE (scales); ESP32 devices posting to Cloud Functions over HTTPS | Section 12 |
| Web (V1.x) | Next.js + TypeScript + Tailwind on Cloudflare (OpenNext) | Website first, dashboard later |
| Lints | very_good_analysis | |
| Tests | flutter_test, bloc_test, mocktail, integration_test | |
| Brand tools | flutter_native_splash, flutter_launcher_icons | |

**Already done (31 Oct 2026):**
- [x] Flutter project `farm_tap` created
- [x] Brand pack installed (Kraal Ring logo, launcher icons, splash, animations, Outfit font)
- [x] Token-based theme system installed in `lib/core/theme/`
- [x] `pubspec.yaml`, `l10n.yaml`, `analysis_options.yaml` prepared

---

## 5. Architecture and folder structure

### 5.1 Clean Architecture, feature-first

Each feature has three layers. Dependencies point inward only: `presentation -> domain <- data`.

- **domain:** entities, repository interfaces, use cases. Pure Dart. No Flutter, Isar, Firebase or JSON imports.
- **data:** models (freezed/json), Isar collections, local and remote data sources, repository implementations, mappers.
- **presentation:** blocs/cubits, pages, widgets.

**Errors:** sealed `Result<T>` (`Success` / `Failure`) and a sealed `Failure` hierarchy (`CacheFailure`, `NetworkFailure`, `AuthFailure`, `ValidationFailure`, `PermissionFailure`, `SubscriptionFailure`, `UnexpectedFailure`). Repositories return `Future<Result<T>>`. Nothing throws across layers.

**Offline-first write flow:**
1. UI calls a use case.
2. Repository writes to Isar immediately with `syncStatus = pending`.
3. UI updates from the local database (streams).
4. `SyncService` pushes pending records to Firestore when online, sets `synced` or `failed`, retries with backoff.
5. Remote changes are pulled and merged (last-write-wins by `updatedAt`, with audit log preserved).

**Base fields on every record:** `id` (UUID v4 generated on the device), `tenantId`, `createdAt`, `updatedAt`, `createdBy` (staff person id), `updatedBy`, `deviceId`, `syncStatus`, `isDeleted` (soft delete).

### 5.2 Repository layout

```
farm_tap/
  AGENTS.md                      # rules for AI agents (copy of Sections 2, 5, 6 summary)
  ARCHITECTURE.md                # layer rules, how to add a feature
  lib/
    main.dart                    # bootstrap(Flavor.dev)
    main_prod.dart               # bootstrap(Flavor.prod)
    app/
      app.dart                   # MaterialApp.router, FarmTapTheme, l10n
      bootstrap.dart             # Firebase, DI, Isar, error handlers, runApp
      flavor.dart
      router/  app_router.dart, routes.dart, guards.dart
      di/      injection.dart
    core/
      theme/                     # DONE - token theme system (do not restructure)
      error/                     # Result, Failure
      usecase/                   # UseCase base
      utils/                     # uuid, clock, logger, validators, formatters (UGX, litres)
      database/                  # Isar setup, base fields, migrations
      sync/                      # SyncService, queue, conflict rules
      auth/                      # Google / Apple / Email sign-in
      onboarding/                # sector choice, farm profile, contacts, trial start
      tenancy/                   # tenant, membership, current-tenant holder
      people/                    # staff, farmers, customers; NFC cards; PINs
      nfc/                       # NFC reader service + fallbacks
      subscription/              # trial, plan, payments, read-only enforcement
      messaging/                 # SMS + WhatsApp request queue (client side)
      reminders/                 # local notifications, schedules
      audit/                     # audit logger
      media/                     # photos: capture, compress, upload
      reports/                   # PDF builders, share
      l10n/                      # app_en.arb, app_nyn.arb, generated/
      ui/                        # BigNumberKeypad, ReadBackConfirmSheet, StatusBanner,
                                 # IconActionButton, PersonTapCard, EmptyState, SyncBadge
    sectors/
      cattle/                    # V1 Dairy lives here (beef added in V1.x)
        herd/              {data,domain,presentation}
        milk/              {data,domain,presentation}
        collection_centre/ {data,domain,presentation}
        health/            {data,domain,presentation}
        feeding/           {data,domain,presentation}
        breeding/          {data,domain,presentation}
        workers/           {data,domain,presentation}
        finance/           {data,domain,presentation}
        owner_reports/     {data,domain,presentation}
      # poultry/, piggery/, small_ruminants/, crops/, fish/  -> NOT before their gates
    admin/                       # Victorbee admin tool (role-gated): confirm payments, support
  functions/                     # Firebase Cloud Functions (TypeScript)
    src/ sms/, whatsapp/, payments/, billing/, reports/, iot/, ai/, scheduled/
  firestore.rules
  storage.rules
  firmware/                      # IoT device firmware (from V1.x, Section 12)
  test/                          # mirrors lib/
  integration_test/
  assets/                        # DONE - branding, animations, icon, splash, fonts, audio/
  docs/
    ROADMAP.md                   # this file
    THEME.md
    decisions/                   # Change Control records NNNN-title.md
    weekly-reviews/
    pilots/
    releases/
```

### 5.3 Dependency rules

- `core/` never imports from `sectors/` or `admin/`.
- A sector feature may import `core/`.
- Sector features never import another feature's `data/` or `presentation/`; they share through `domain/` interfaces only.
- `admin/` may import `core/` only.

---

## 6. Theme and brand rules

Brand and theme are DONE. Details: `docs/THEME.md`.

- Import styling only via `package:farm_tap/core/theme/theme.dart`.
- Colours: `context.colors.*` (Material roles) or `context.status.*` (FarmTap roles: success, warning, danger, info, synced, syncPending, syncFailed, withdrawal, nfcActive, keypadKey...).
- Text: `context.text.*` or `context.textStyles.*` (keypadDigit, readBackValue, metricValue, tagNumber...). Weights via `FarmTapWeights`.
- Spacing: `context.space.*`; corners: `context.radii.*`; sizes: `context.sizes.*`; animation: `context.motion.*`.
- Change the whole app's size, text size or roundness only in `lib/core/theme/farmtap_design.dart`.
- Raw colours exist only in `lib/core/theme/tokens/farmtap_palette.dart`.
- Assets via `FarmTapAssets` constants; light/dark via `FarmTapAssets.byBrightness`.
- `test/core/theme/theme_guard_test.dart` must pass on every commit.

---

## 7. Authentication, onboarding and roles

### 7.1 Two kinds of people

| Kind | Who | How they get in |
|---|---|---|
| **Account holders** | Owners, managers, Victorbee admins | Sign in with **Google**, **Apple** or **Email + password** (Firebase Auth). No phone OTP. |
| **Staff (device users)** | Workers, milk clerks, herdsmen, vets on the farm | No personal account. They use the farm's signed-in phone and identify themselves with their **NFC card** (or card number) + **4-digit PIN**. Every record stores which staff person did it. |

This keeps low-literacy staff away from emails and passwords, and costs nothing per login.

### 7.2 Sign-in screen

- Logo (sign-in logo, light/dark).
- Buttons: **Continue with Google**, **Continue with Apple**, **Continue with Email**.
  - Apple button: shown on iOS always (App Store rule when Google sign-in is offered). On Android, shown only if Apple sign-in via web flow is configured; otherwise hidden.
  - Email: sign up (name, email, password ≥ 8 chars), sign in, **forgot password** (Firebase reset email), email verification sent after sign-up.
- Language switch (English / Runyankore) visible on this screen.
- Links: Terms, Privacy Policy.
- After sign-in: if the user has no farm → **Onboarding**. If they have one farm → **Staff unlock** (7.5). If several → farm picker.

### 7.3 Onboarding screens (first time only)

Each step is one screen, big buttons, progress dots, Back button. Data saves as you go (can resume).

| Step | Screen | Collects | Notes |
|---|---|---|---|
| 1 | Welcome | Language: English / Runyankore | Sets app language |
| 2 | **What do you do?** | Sector: **Dairy (cattle)** / Poultry / Piggery / Goats & Sheep / Crops & Produce buying / Fish | Only **Dairy** is active in V1. Others show "Coming soon — join waitlist": saves sector + contact to `waitlist`, thanks the user, ends onboarding. |
| 3 | Dairy type | Dairy farm / Milk collection centre / Both | Decides which home tabs appear |
| 4 | Farm or centre details | Name, district (list of Ugandan districts), village/parish (text), herd size or number of supplying farmers (ranges) | Optional: GPS pin ("Use my location") |
| 5 | **Contacts for reports** | **WhatsApp number** (for daily reports), **SMS number** (for alerts and reminders); checkbox "same as WhatsApp" | Ugandan format check (+256…). Consent checkboxes: "Send me daily reports on WhatsApp", "Send me SMS alerts". Numbers are **not** verified by OTP; they are marked *unverified* until the first message is delivered successfully. |
| 6 | Your role | Owner / Manager | Owner = billing contact |
| 7 | First staff member (optional, skippable) | Name, role, PIN; "Add card later" | Owner can be staff too |
| 8 | Trial started | "Your 14 days free start today. Ends on {date}. UGX 70,000/month after." | Creates tenant + subscription (`trialing`). Button: "Start" → Home |

### 7.4 Roles and permissions

| Role | Can do |
|---|---|
| Owner | Everything for their farm, billing, staff management, delete records, see all reports |
| Manager | Everything except billing and deleting the farm |
| Clerk | Milk collection (centre), milk records, view farmer statements |
| Worker | Record milk, feeding, treatments (if allowed), attendance; view own tasks |
| Vet | Health, treatments, breeding records; view animals |
| Victorbee Admin | Admin tool: confirm payments, extend trials, support; no farm data editing |

Permissions are enforced in the app **and** in Firestore Security Rules (custom claims or membership documents).

### 7.5 Staff unlock (daily use)

- After the owner/manager signs in once, the farm phone stays signed in.
- The home screen shows **"Tap your card"** (NFC) with fallback **"Enter card number"**, then **PIN**.
- The unlocked staff person is shown at the top; auto-lock after a set idle time (default 5 min).
- Every record saves `createdBy = staffPersonId`.

---

## 8. Data model (Firestore + local Isar mirror)

```
users/{uid}                         # account holders
  displayName, email, authProvider (google|apple|password), language,
  memberships: [{tenantId, role}], isVictorbeeAdmin, createdAt

waitlist/{id}                       # non-dairy sector interest (gate evidence)
  sector, name, whatsapp, sms, district, uid?, createdAt

tenants/{tenantId}
  profile        # name, type (farm|centre|both), sector: dairy, district, village,
                 # gps?, herdSizeRange, farmerCountRange, logo?
  contacts       # whatsapp, sms, whatsappConsent, smsConsent, verified flags
  settings       # language, units, milkPricePerLitre, paymentPeriod, autoLockMinutes,
                 # reportTime, smsAllowance
  subscription   # status (trialing|active|grace|read_only|cancelled),
                 # plan (dairy_monthly|dairy_annual), trialStartedAt, trialEndsAt,
                 # currentPeriodEnd, priceUgx: 70000, smsUsedThisPeriod, aiUsedThisPeriod
  members/{uid}           # role
  payments/{id}           # amount, method (mtn|airtel), transactionId, status
                          # (submitted|confirmed|rejected), confirmedBy, confirmedAt
  staff/{personId}        # name, photo, role, phone?, pinHash, active
  farmers/{personId}      # collection-centre suppliers: name, photo, phone, card number
  nfcCards/{cardUid}      # personId, personType (staff|farmer), status (active|lost|blocked)
  animals/{animalId}      # tagNumber, qr, govIdTag, name, breed, sex, dob, damId, sireId,
                          # status (active|sold|dead|transferred), groupId, photo
  animalGroups/{groupId}
  animalEvents/{id}       # birth|death|sale|purchase|transfer|weight
  milkRecords/{id}        # animalId?, session (am|pm), litres, use (sold|home|calves|spoiled)
  milkSales/{id}          # buyer, litres, pricePerLitre, amount, paid
  deliveries/{id}         # centre: farmerId, litres, session, accepted, rejectReason, transporterId
  qualityTests/{id}
  paymentPeriods/{id}     # start, end, pricePerLitre, status (open|closed|paid)
  farmerStatements/{id}   # periodId, farmerId, litres, gross, deductions, net
  deductions/{id}
  payouts/{id}            # mobile money payout requests and status
  treatments/{id}         # animalId, problem, drugId, dose, route, givenBy, withdrawalUntil
  vaccinations/{id}
  dipping/{id}
  deworming/{id}
  vetVisits/{id}
  stockItems/{id}         # drugs, feeds, supplements; unit; reorderLevel; withdrawalDays (drugs)
  stockMovements/{id}     # purchase|usage|adjustment
  feedUsage/{id}
  breedingEvents/{id}     # heat|service|ai|pregnancyCheck|calving
  attendance/{id}         # personId, in, out, method (nfc|manual)
  tasks/{id}
  wages/{id}
  expenses/{id}
  income/{id}
  reminders/{id}
  messages/{id}           # outbound SMS/WhatsApp queue: channel, to, template, status, cost
  aiQuestions/{id}        # V1.x: question, imageRef?, answer, model, cost (no personal data)
  iotDevices/{deviceId}   # V1.x: type, location, status, battery, lastSeen
  iotReadings/{id}        # V1.x: deviceId, metric, value, at
  auditLog/{id}           # actor (uid + staffPersonId), action, path, before, after, at, deviceId
```

---

## 9. V1 Dairy — weekly schedule (strict)

Weeks run Monday–Sunday. Tick items as they are completed. Every week ends with the Sunday review.

### Week 0 — Preparation (Sun 1 Nov 2026)
- [ ] Java/JDK fixed; `flutter doctor` all green for Android
- [ ] `docs/ROADMAP.md`, `docs/THEME.md`, `AGENTS.md` added to the repo
- [ ] Private GitHub repo created and pushed
- [ ] 20–50 blank NFC cards (NTAG213/215) ordered
- [ ] Sales: list of 30 introducers written

### Week 1 — V0 Foundation (2–8 Nov)
Build:
- [ ] Packages installed; `flutter analyze` clean; theme guard test passes
- [ ] Folder structure (Section 5.2); `ARCHITECTURE.md`
- [ ] `core/error`, `core/usecase`, `core/utils` with unit tests
- [ ] Flavors (`main.dart` dev, `main_prod.dart` prod); DI (`injection.dart`)
- [ ] Isar opened in bootstrap; base fields; first `Animal` model, repository, `AddAnimal`, `WatchAnimals`
- [ ] go_router: `/splash` -> `/sign-in` (placeholder) -> `/home` with tabs (Herd, Milk, Health, More)
- [ ] l10n: `app_en.arb`, `app_nyn.arb` (placeholder `[nyn]` values), language switch
- [ ] `core/ui`: BigNumberKeypad, ReadBackConfirmSheet, StatusBanner, IconActionButton (+ widget tests)
- [ ] **Clickable sales demo** (fake data): herd list, record milk with keypad + read-back, collection centre "tap card" (simulated), weekly summary with SMS preview, owner WhatsApp report preview
- [ ] Firebase `farmtap-dev` and `farmtap-prod` projects; `flutterfire configure`; init in bootstrap; Crashlytics (CORE-22)
- [ ] Real NFC card UID read on a physical phone
- [ ] GitHub Actions: analyze + test on every push
- [ ] Demo tested on a low-end Android phone; 2-minute demo video recorded
Sell:
- [ ] 30 introductions requested; 5 conversations held
Review:
- [ ] `docs/weekly-reviews/2026-W45.md`; decision records 0001–0010 written (Section 18.2)

### Week 2 — Alpha: accounts, onboarding, tenancy, sync (9–15 Nov)
Build:
- [ ] CORE-01 Sign-in: Google, Email (sign up, sign in, reset, verification); Apple code path (iOS)
- [ ] CORE-02 Onboarding steps 1–8 (Section 7.3) incl. sector choice, waitlist, contacts, consent
- [ ] CORE-03 Tenant creation + membership + roles; Firestore Security Rules + rules tests
- [ ] CORE-04 Subscription document: trial starts at onboarding end; trial banner with days left
- [ ] CORE-05 Staff register: name, photo, role, PIN (hashed)
- [ ] CORE-06 NFC card registration (assign card to staff), lost/block; card-number fallback
- [ ] CORE-07 Staff unlock (tap card + PIN), auto-lock
- [ ] CORE-08 Offline sync engine (pending/synced/failed, retry, pull + merge)
- [ ] CORE-09 Audit trail on every write
- [ ] CORE-10 Sync status badge in the app bar
Sell:
- [ ] 8 conversations; first trial signed up on a real farm phone

### Week 3 — Alpha: herd and milk (16–22 Nov)
Build:
- [ ] DAIRY-HERD-01 Animal register (tag, photo, name, breed, sex, DOB/estimated age, status)
- [ ] DAIRY-HERD-02 Government ID tag field
- [ ] DAIRY-HERD-03 QR ear-tag lookup + type-number fallback
- [ ] DAIRY-HERD-06 Live head count
- [ ] DAIRY-HERD-07 Animal events (birth, death + cause, sale, purchase, transfer)
- [ ] DAIRY-MILK-01 Milk per cow per session (keypad + read-back)
- [ ] DAIRY-MILK-02 Herd total quick mode
- [ ] DAIRY-MILK-03 Milk use split (sold, home, calves, spoiled)
- [ ] DAIRY-MILK-05 Treated-milk block (red warning; "not for sale")
Sell:
- [ ] 2 farms on active free trial

### Week 4 — Alpha -> Pilot Build v0.5 (23–29 Nov)
Build:
- [ ] DAIRY-MCC-01 Farmer register with NFC cards
- [ ] DAIRY-MCC-02 Tap-and-record delivery (< 15 seconds)
- [ ] DAIRY-MCC-03 AM/PM sessions; closing locks deliveries (manager PIN to edit)
- [ ] DAIRY-MCC-06 Payment periods + price per litre
- [ ] DAIRY-MCC-08 Farmer statements
- [ ] DAIRY-HLTH-01 Treatments; DAIRY-HLTH-02 withdrawal periods; DAIRY-HLTH-06 drug stock
- [ ] DAIRY-FEED-01..03 Feed items, purchases, daily usage
- [ ] DAIRY-WRK-01 Attendance by NFC tap; DAIRY-WRK-04 activity log
- [ ] DAIRY-OWN-01 Owner home dashboard
- [ ] Security rules audit; release build installed on pilot phones
Sell:
- [ ] 3 pilot sites (farms and/or centres) running on trial

### Week 5 — Beta (30 Nov–6 Dec)
- [ ] Pilot bug fixes (from `docs/pilots/`)
- [ ] CORE-12 Photo evidence (compress < 300 KB, upload on Wi-Fi/allowed)
- [ ] CORE-13 Reminders engine (local notifications, Africa/Kampala)
- [ ] CORE-14 SMS sending via Cloud Functions; per-tenant allowance; delivery status; marks numbers verified
- [ ] Trial reminders day 10 / 13 / 14 (in-app + SMS)
- [ ] Sell: weekly pilot visits; 5 new conversations

### Week 6 — Beta (7–13 Dec)
- [ ] DAIRY-MCC-04 Quality tests and rejections
- [ ] DAIRY-MCC-05 Transporters
- [ ] DAIRY-MCC-07 Deductions (advances, inputs, fees)
- [ ] DAIRY-MCC-09 Weekly SMS summaries to farmers
- [ ] DAIRY-MILK-04 Milk sales; DAIRY-MILK-06 milk trends + drop alert
- [ ] Sell: first trial converted to paid (UGX 70,000)

### Week 7 — Beta (14–20 Dec)
- [ ] DAIRY-HLTH-03 Vaccinations; -04 dipping/spraying; -05 deworming; -08 vet visits; -09 sick list
- [ ] DAIRY-BRD-01..05 Heat, service/AI, pregnancy check, expected calving + reminders, calving (creates calf)
- [ ] Sell: 2 paying customers

### Week 8 — Beta -> Beta Build v0.8 (21–27 Dec)
- [ ] DAIRY-FEED-04 Low-stock alerts; -05 feed cost per animal / per litre
- [ ] DAIRY-WRK-02 Tasks; -03 wages and advances
- [ ] DAIRY-HERD-04 QR label printing (PDF); -05 parentage; -08 groups; -10 animal timeline
- [ ] Sell: holiday week — keep pilots running; collect testimonials

### Week 9 — Release Candidate (28 Dec–3 Jan 2027)
- [ ] CORE-15 WhatsApp daily owner report (templates approved; SMS fallback)
- [ ] DAIRY-OWN-02 Daily report content; DAIRY-OWN-03 anomaly alerts (milk drop, drug/feed overuse, edits/deletes, deaths)
- [ ] DAIRY-BILL-01 Subscription screen (status, days left, price, how to pay)
- [ ] DAIRY-BILL-02 Manual payment submission (MoMo/Airtel transaction ID)
- [ ] DAIRY-BILL-03 Read-only enforcement after trial/grace
- [ ] DAIRY-BILL-04 Admin tool: confirm/reject payments, extend trial
- [ ] Sell: re-contact all leads for January

### Week 10 — RC (4–10 Jan)
- [ ] CORE-16 Mobile money payouts to farmers (if API approved; else printable payment sheet only)
- [ ] CORE-17 In-app subscription payment via mobile money (Phase B, if API approved)
- [ ] DAIRY-MCC-10 Payment sheet + payout batch; DAIRY-MCC-11 centre reconciliation
- [ ] Sell: 8 conversations; 2 new trials

### Week 11 — RC (11–17 Jan)
- [ ] CORE-18 Expenses and income; DAIRY-OWN-04 monthly profit & loss, cost per litre
- [ ] CORE-19 PDF statements and monthly report; share via WhatsApp
- [ ] CORE-21 Data export (CSV/PDF)
- [ ] CORE-11 Runyankore voice prompts (recorded clips in `assets/audio/`)
- [ ] DAIRY-HLTH-07 Drug usage anomaly alert
- [ ] Runyankore translations completed (all `[nyn]` placeholders replaced)
- [ ] Sell: pricing and trial results reviewed with evidence

### Week 12 — RC -> RC Build v0.9 (18–24 Jan)
- [ ] Full regression test; security rules audit; performance on low-end phone
- [ ] Compliance checklist (Section 15) complete
- [ ] Play Store listing (icon, feature graphic, screenshots light+dark, description EN)
- [ ] Sell: written case study from the best pilot

### Week 13 — V1.0 PRODUCTION (25–31 Jan 2027)
- [ ] Production Firebase live; monitoring on; budget alerts set
- [ ] Play Store release (internal -> closed -> production)
- [ ] All pilots converted to paid or closed
- [ ] Sell: target **5 paying customers**

---

## 10. V1 Dairy — feature specification

Priority: **P1** = needed for Pilot Build (Week 4); **P2** = needed for V1.0; **P3** = V1.x.

### 10.1 Core (CORE)

| ID | Feature | P | Acceptance criteria |
|---|---|---|---|
| CORE-01 | Sign-in (Google, Apple, Email) | P1 | Google + Email work on Android; Apple works on iOS; password reset and email verification work; no phone OTP anywhere |
| CORE-02 | Onboarding | P1 | Steps 1–8 of Section 7.3; resumable; non-dairy sectors go to waitlist; contacts + consent saved |
| CORE-03 | Tenancy and roles | P1 | Tenant + membership created; roles of Section 7.4 enforced in app and Firestore rules; rules tests pass |
| CORE-04 | Trial and subscription status | P1 | Trial starts at onboarding end; banner shows days left; status computed offline from stored dates |
| CORE-05 | Staff register | P1 | Name, photo, role, 4-digit PIN stored as salted hash; activate/deactivate |
| CORE-06 | NFC cards | P1 | Assign card UID to staff/farmer; block lost cards; card number printed as fallback |
| CORE-07 | Staff unlock | P1 | Tap card or enter number + PIN; auto-lock after idle; current staff shown |
| CORE-08 | Offline sync | P1 | All writes local first; sync on connectivity; no duplicates; failed items retried; pull + merge |
| CORE-09 | Audit trail | P1 | Every create/edit/delete logs actor, before/after, time, device |
| CORE-10 | Sync status badge | P1 | Shows synced / pending count / failed |
| CORE-11 | Voice prompts (Runyankore) | P2 | Key actions play recorded clips; can be turned off |
| CORE-12 | Photo evidence | P2 | Any record can carry a photo; < 300 KB; uploads when allowed |
| CORE-13 | Reminders | P2 | Local scheduled notifications; optional SMS |
| CORE-14 | SMS (server-side) | P2 | Queue -> Cloud Function -> provider; status stored; allowance enforced; number marked verified on delivery |
| CORE-15 | WhatsApp reports | P2 | Approved templates; only to consented numbers; SMS fallback |
| CORE-16 | Mobile money payouts | P2 | Batch from statements; per-payout status; retry; optional if API not approved |
| CORE-17 | Subscription payment (in-app) | P2 | Mobile money request; auto-activation on success (Phase B) |
| CORE-18 | Expenses and income | P2 | Category, amount, date, receipt photo |
| CORE-19 | PDF reports | P2 | Farmer statements, monthly farm report; share via WhatsApp |
| CORE-20 | Localization | P1 | Every string in ARB; English + Runyankore; switch anywhere |
| CORE-21 | Data export | P2 | CSV/PDF export by owner |
| CORE-22 | Crash reporting | P1 | Crashlytics in every build |
| CORE-23 | Low-literacy UI kit | P1 | Keypad, read-back sheet, status banner, icon buttons, person tap card, empty states |

### 10.2 Billing (DAIRY-BILL)

| ID | Feature | P | Acceptance criteria |
|---|---|---|---|
| DAIRY-BILL-01 | Subscription screen | P2 | Status, days left, UGX 70,000/month, annual option, how to pay |
| DAIRY-BILL-02 | Manual payment submission | P2 | Enter method + transaction ID + amount; status "submitted" |
| DAIRY-BILL-03 | Read-only enforcement | P2 | After trial end or 7-day grace: view only; clear message + Pay button |
| DAIRY-BILL-04 | Admin payment confirmation | P2 | Victorbee admin confirms/rejects; extends trial; audit logged |

### 10.3 Herd (DAIRY-HERD)

| ID | Feature | P | Acceptance criteria |
|---|---|---|---|
| DAIRY-HERD-01 | Animal register | P1 | Tag no., photo, name, breed, sex, DOB/estimated age, colour, status |
| DAIRY-HERD-02 | Government ID field | P1 | Optional national livestock ID tag number |
| DAIRY-HERD-03 | QR lookup | P1 | Scan opens record; typing tag number works |
| DAIRY-HERD-04 | QR label printing | P2 | Printable PDF labels for selected animals |
| DAIRY-HERD-05 | Parentage | P2 | Dam/sire links; calves on mother's record |
| DAIRY-HERD-06 | Head count | P1 | By status, sex, age group, group |
| DAIRY-HERD-07 | Animal events | P1 | Birth, death (cause), sale (buyer, price), purchase, transfer |
| DAIRY-HERD-08 | Groups/paddocks | P2 | Assign; bulk actions |
| DAIRY-HERD-09 | Weights | P3 | Weight or girth-tape estimate; growth chart |
| DAIRY-HERD-10 | Animal timeline | P2 | All events, milk, treatments, breeding in one screen |

### 10.4 Milk on the farm (DAIRY-MILK)

| ID | Feature | P | Acceptance criteria |
|---|---|---|---|
| DAIRY-MILK-01 | Milk per cow per session | P1 | AM/PM litres via keypad; read-back before save |
| DAIRY-MILK-02 | Herd total quick mode | P1 | One total per session |
| DAIRY-MILK-03 | Milk use | P1 | Sold/home/calves/spoiled must equal produced |
| DAIRY-MILK-04 | Milk sales | P2 | Buyer, litres, price, amount, paid/unpaid |
| DAIRY-MILK-05 | Treated-milk block | P1 | Cows under withdrawal shown red; milk "not for sale" by default |
| DAIRY-MILK-06 | Milk trends | P2 | Per cow + herd charts; alert on > 20% drop |

### 10.5 Milk collection centre (DAIRY-MCC)

| ID | Feature | P | Acceptance criteria |
|---|---|---|---|
| DAIRY-MCC-01 | Farmer register + NFC cards | P1 | Photo, phone, card |
| DAIRY-MCC-02 | Tap-and-record delivery | P1 | Tap -> litres -> read-back -> save in < 15 s |
| DAIRY-MCC-03 | Sessions | P1 | AM/PM; closing locks; edits need manager PIN + audit |
| DAIRY-MCC-04 | Quality tests and rejection | P2 | Results stored; rejected litres excluded from pay |
| DAIRY-MCC-05 | Transporters | P2 | Per-delivery transporter; totals for reconciliation |
| DAIRY-MCC-06 | Payment periods | P1 | Weekly/2-weekly/monthly; price per litre per period |
| DAIRY-MCC-07 | Deductions | P2 | Advances, inputs, fees per farmer |
| DAIRY-MCC-08 | Farmer statements | P1 | Litres, gross, deductions, net |
| DAIRY-MCC-09 | Weekly SMS summary | P2 | One SMS per farmer per week |
| DAIRY-MCC-10 | Payment sheet + payouts | P2 | Printable sheet; optional mobile money batch |
| DAIRY-MCC-11 | Reconciliation | P2 | Received vs dispatched litres; difference flagged |

### 10.6 Health and medication (DAIRY-HLTH)

| ID | Feature | P | Acceptance criteria |
|---|---|---|---|
| DAIRY-HLTH-01 | Treatments | P1 | Animal, problem, drug, dose, route, given by, date, photo |
| DAIRY-HLTH-02 | Withdrawal periods | P1 | Per-drug days; computes milk/meat safe-from date |
| DAIRY-HLTH-03 | Vaccinations | P2 | Vaccine, date, next due, reminders |
| DAIRY-HLTH-04 | Dipping/spraying | P2 | Group/herd, chemical, date, next due |
| DAIRY-HLTH-05 | Deworming | P2 | Animal/group, drug, date, next due |
| DAIRY-HLTH-06 | Drug stock | P1 | Purchases add; treatments deduct |
| DAIRY-HLTH-07 | Drug usage anomaly | P2 | Alert if usage exceeds recorded treatments |
| DAIRY-HLTH-08 | Vet visits | P2 | Vet, reason, cost, linked treatments |
| DAIRY-HLTH-09 | Sick list | P2 | Animals under treatment, days remaining |

### 10.7 Feeding (DAIRY-FEED)

| ID | Feature | P | Acceptance criteria |
|---|---|---|---|
| DAIRY-FEED-01 | Feed items and stock | P1 | Units (bags, kg) |
| DAIRY-FEED-02 | Feed purchases | P1 | Adds stock + creates expense |
| DAIRY-FEED-03 | Daily feed usage | P1 | Per group/herd; deducts stock |
| DAIRY-FEED-04 | Low-stock alerts | P2 | At reorder level |
| DAIRY-FEED-05 | Feed cost per animal / litre | P2 | Monthly |
| DAIRY-FEED-06 | Pasture and silage | P3 | Grazing rotation; silage made/used |

### 10.8 Breeding (DAIRY-BRD)

| ID | Feature | P | Acceptance criteria |
|---|---|---|---|
| DAIRY-BRD-01 | Heat records | P2 | Date, signs |
| DAIRY-BRD-02 | Service / AI | P2 | Bull or AI straw, technician, cost |
| DAIRY-BRD-03 | Pregnancy check | P2 | Result, date, by |
| DAIRY-BRD-04 | Expected calving | P2 | Computed; reminders 30 and 7 days before |
| DAIRY-BRD-05 | Calving | P2 | Creates calf linked to dam |
| DAIRY-BRD-06 | Repeat-heat alert | P3 | Served cow shows heat again |

### 10.9 Workers (DAIRY-WRK)

| ID | Feature | P | Acceptance criteria |
|---|---|---|---|
| DAIRY-WRK-01 | Attendance by NFC | P1 | Check in/out by tap; manual needs manager PIN |
| DAIRY-WRK-02 | Tasks | P2 | Assign, due, done with photo |
| DAIRY-WRK-03 | Wages and advances | P2 | Balance per worker |
| DAIRY-WRK-04 | Activity log | P1 | All records filtered by staff person |

### 10.10 Owner tools (DAIRY-OWN)

| ID | Feature | P | Acceptance criteria |
|---|---|---|---|
| DAIRY-OWN-01 | Home dashboard | P1 | Today: milk, head count, treatments, attendance, alerts, trial days left |
| DAIRY-OWN-02 | Daily WhatsApp/SMS report | P2 | At owner's chosen time |
| DAIRY-OWN-03 | Anomaly alerts | P2 | Milk drop, drug/feed overuse, edits/deletes, deaths |
| DAIRY-OWN-04 | Monthly P&L | P2 | Income vs expenses; cost per litre |
| DAIRY-OWN-05 | Multi-farm view | P3 | One owner, several farms |

---

## 11. V1.x Dairy completion (Feb – Apr 2027)

Goal: make Dairy complete and sticky before any other sector. Order is fixed; each month ends with a release.

### February 2027 — V1.1
- [ ] Production bug fixes and performance from real use
- [ ] Bulk import of animals and farmers from Excel/CSV (faster onboarding)
- [ ] **AI-01..AI-06 Ask FarmTap** (Section 13)
- [ ] DAIRY-HERD-09 Weights; DAIRY-BRD-06 Repeat-heat alert
- [ ] Sales: 10 paying customers

### March 2027 — V1.2
- [ ] **IOT-01 Bluetooth milk scale** (Section 12)
- [ ] **IOT-02 Bluetooth thermal receipt printer** for collection centres
- [ ] DAIRY-FEED-06 Pasture and silage
- [ ] **BEEF-01..05 Beef and ranching** (same herd module):
  - BEEF-01 Fattening groups and target weights
  - BEEF-02 Weight gain per animal/group (girth tape or scale)
  - BEEF-03 Cattle sales by weight/head, buyer, price
  - BEEF-04 Cost per kg gained
  - BEEF-05 Movement records (grazing areas, transfers between farms)
- [ ] Expansion to Kiruhura, Kazo, Isingiro
- [ ] Sales: 13 paying customers

### April 2027 — V1.3
- [ ] DAIRY-OWN-05 Multi-farm view
- [ ] **WEB-01..05 Owner/cooperative web dashboard** (Next.js on Cloudflare):
  - WEB-01 Public website (product, pricing UGX 70,000, trial sign-up link, contact)
  - WEB-02 Owner sign-in (Google/Apple/Email, same Firebase project)
  - WEB-03 Read-only dashboard: milk, herd, health, workers, money
  - WEB-04 Cooperative view across centres
  - WEB-05 Report downloads (PDF/CSV)
- [ ] **iOS release** (Apple sign-in active; App Store listing)
- [ ] **IOT-10..IOT-15 FarmTap Sense phase 1 pilot** (cold-chain, Section 12) at 1–2 centres
- [ ] Sales: **15 paying customers, ≥ UGX 1,050,000 monthly recurring revenue**

---

## 12. IoT roadmap — FarmTap Sense

Principle: IoT must solve a money problem the customer already has, run on cheap hardware, survive power cuts and weak signal, and feed data into the same FarmTap records. No hardware is stocked before customers pay deposits.

**Excluded:** GPS trackers on cattle (expensive per animal, batteries, patchy coverage, thieves remove collars). Standard 134.2 kHz livestock RFID ear tags (phones cannot read them) — revisit only with a dedicated reader in a later phase.

### 12.1 Phase 0 — phone-connected devices (V1.2, March 2027)

| ID | Device | Problem solved | Spec |
|---|---|---|---|
| IOT-01 | Bluetooth digital milk scale | Clerks typing wrong litres; disputes | BLE scale; weight -> litres (configurable density); value goes straight into the delivery/milk record; manual entry stays available; scale ID stored on the record |
| IOT-02 | Bluetooth thermal printer (58 mm) | Farmers want a paper slip | Prints delivery receipt and statement; works offline |
| IOT-03 | NFC card stock | Card supply | Supplier for NTAG213/215 cards with photo printing; price list |

### 12.2 Phase 1 — FarmTap Sense cold-chain pilot (V1.3, April 2027)

| ID | Item | Spec |
|---|---|---|
| IOT-10 | Milk cooler/tank temperature monitor | ESP32 + waterproof temperature probe; GSM (2G/4G module + SIM) or Wi-Fi; battery backup; reading every 5 min, sent every 15 min, buffered offline |
| IOT-11 | Device registry | `iotDevices`: id, tenant, type, location, firmware version, battery, lastSeen, status |
| IOT-12 | Secure ingest | Cloud Function HTTPS endpoint; per-device secret key; rate limits; readings saved to `iotReadings` |
| IOT-13 | Alerts | Threshold set per centre (confirm the correct cooling standard with the Dairy Development Authority); SMS + WhatsApp + in-app alert when too warm for X minutes, device offline, or battery low |
| IOT-14 | App screens | Live temperature, 24 h/7 d chart, alert history, device health |
| IOT-15 | Firmware | `firmware/` folder; PlatformIO project; OTA update plan; provisioning by QR code |

Pricing (to validate in pilot): device sold at cost + margin, plus a monitoring add-on per month. Price set only after the pilot (Change Control).

### 12.3 Phase 2+ — later (Gate GI)

| ID | Item | Sector |
|---|---|---|
| IOT-20 | Water tank level sensor | Dairy farms |
| IOT-21 | Fixed NFC reader at the gate/milking parlour for attendance | All |
| IOT-22 | Generator/power status for coolers | Collection centres |
| IOT-30 | Poultry house temperature + humidity + ammonia | Poultry (V2.x) |
| IOT-31 | Brooder heat alerts | Poultry (V2.x) |
| IOT-32 | Egg counting at collection | Poultry (V2.x) |
| IOT-40 | Pig house temperature | Piggery (V3.x) |
| IOT-50 | Fish pond water quality (temperature, dissolved oxygen, pH) | Fish (V6.x) |
| IOT-60 | Produce store temperature/humidity (coffee, grain) | Crops (V5.x) |

**Gate GI (any IoT phase beyond the current one):** ≥ 5 paying customers ask for it in writing or pay a deposit; previous phase ran 30 days with ≥ 95% data delivery; unit cost and support cost documented.

---

## 13. AI roadmap — Ask FarmTap (V1.1, February 2027)

| ID | Feature | Spec |
|---|---|---|
| AI-01 | Ask a question | Text or voice-typed question in English/Runyankore; answer in the same language |
| AI-02 | Photo question | Take a photo (animal, wound, eye, dung, feed, pasture) + question |
| AI-03 | Safety framing | Every health answer says "possible causes", lists warning signs, and shows a **Call your vet** button (vet contact from settings). Never gives prescription doses. |
| AI-04 | Privacy | Send only the question and photo. No names, phone numbers, farm names or GPS. |
| AI-05 | Usage limits | 30 questions/month included; counter in `subscription.aiUsedThisPeriod`; extra questions as paid add-on |
| AI-06 | History | Saved answers per farm in `aiQuestions` |

Technology: Firebase AI Logic (`firebase_ai`) with the Gemini Developer API; App Check enabled; model name and system prompt in Remote Config so they can change without an app release.

Cost note: the Gemini Developer API free tier only applies while the Firebase project has no billing account. FarmTap production uses billing (Cloud Functions), so AI usage is pay-as-you-go there. Track AI cost per customer monthly (Section 3.4). Use a dev project without billing for testing.

---

## 14. Later sectors (fully described; locked until their gate opens)

### 14.1 Gates

| Gate | Opens | All conditions required |
|---|---|---|
| G2 | V2 Poultry | V1.0 in production ≥ 8 weeks; ≥ 10 paying Dairy customers; MRR ≥ UGX 700,000; crash-free sessions ≥ 99%; ≥ 20 poultry waitlist sign-ups **and** ≥ 3 poultry businesses committed to pay after trial |
| G3 | V3 Piggery | V2 in production ≥ 8 weeks; ≥ 15 piggery waitlist; ≥ 3 committed |
| G4 | V4 Goats & Sheep | V3 in production ≥ 8 weeks; ≥ 15 waitlist; ≥ 3 committed |
| G5 | V5 Crops & Produce buying | V2 in production ≥ 8 weeks; ≥ 15 waitlist; ≥ 3 produce buyers committed |
| G6 | V6 Fish | V5 in production ≥ 8 weeks; ≥ 10 waitlist; ≥ 3 committed |
| GI | IoT beyond current phase | Section 12.3 |
| GA | Any other add-on | A customer pays for it, or ≥ 5 customers request it in writing |

When a gate opens: write a decision record, then add a weekly schedule for that version to this file (same format as Section 9). Each new sector uses the same price model (UGX 70,000/month per business, 14-day trial) unless Change Control decides otherwise. When a sector goes live, its onboarding option switches from "Coming soon" to active and the waitlist is notified.

### 14.2 V2 — Poultry (`sectors/poultry/`)

Shared: POUL-01 house/pen register · POUL-02 batch register (layer/broiler/kienyeji, breed, date in, number, supplier, cost) · POUL-03 daily mortality + cause · POUL-04 live bird count · POUL-05 feeding + feed stock · POUL-06 vaccination schedule + reminders (configurable) · POUL-07 medication + withdrawal (eggs and meat) · POUL-08 brooding records · POUL-09 water use · POUL-10 biosecurity checklist + visitor log · POUL-11 workers (reuse core) · POUL-12 owner daily report · POUL-13 profit per batch.

Layers: LAY-01 daily egg collection (trays + loose) · LAY-02 grading (size, cracked, dirty) · LAY-03 laying % + drop alert · LAY-04 egg stock · LAY-05 egg sales · LAY-06 empty tray tracking · LAY-07 culls/spent hens · LAY-08 feed cost per tray.

Broilers: BRO-01 batch cycle to market day · BRO-02 weekly weight sampling · BRO-03 feed conversion ratio · BRO-04 market date reminders · BRO-05 bird sales (live/dressed) · BRO-06 profit per batch and per bird.

Egg collection mode: EGG-01 supplier register + NFC · EGG-02 tap-and-record trays, grade, rejects · EGG-03 periods, deductions, statements · EGG-04 weekly SMS · EGG-05 payment sheet + payouts · EGG-06 customer orders and deliveries (egg traders).

### 14.3 V3 — Piggery (`sectors/piggery/`)

PIG-01 pig register · PIG-02 sow and boar records · PIG-03 mating/AI · PIG-04 pregnancy + expected farrowing + reminders · PIG-05 farrowing (litter, alive, stillborn) · PIG-06 piglets, weaning, mortality · PIG-07 weights, daily gain · PIG-08 feeding per pen · PIG-09 vaccination, deworming, treatments, withdrawal · PIG-10 disease alert log (e.g. suspected African swine fever) + vet contact · PIG-11 sales · PIG-12 workers, reports, profit (core).

### 14.4 V4 — Goats & Sheep (`sectors/small_ruminants/`)

GOAT-01 herd register · GOAT-02 mating + expected kidding/lambing · GOAT-03 kidding/lambing, twins, mortality · GOAT-04 deworming, vaccination, treatments, foot care · GOAT-05 feeding/browsing · GOAT-06 weights · GOAT-07 dairy goat milk (reuse milk engine) · GOAT-08 sales · GOAT-09 workers, reports, profit (core).

### 14.5 V5 — Crops & Produce buying (`sectors/crops/`, `sectors/produce_buying/`)

Farm crops: CROP-01 plots · CROP-02 season plan · CROP-03 activities (preparation, planting, weeding, spraying, fertiliser, pruning/de-suckering) · CROP-04 inputs stock · CROP-05 spray records + pre-harvest intervals · CROP-06 harvest · CROP-07 sales · CROP-08 casual labour by NFC · CROP-09 profit per plot/season.

Produce buying centre (coffee, matooke, maize, beans): BUY-01 farmer register + NFC · BUY-02 tap-and-record weight, grade, moisture, price · BUY-03 payment + statements · BUY-04 SMS receipts · BUY-05 mobile money payouts · BUY-06 store stock, dispatch, reconciliation.

### 14.6 V6 — Fish (`sectors/fish/`)

FISH-01 ponds/cages · FISH-02 stocking (species, number, size, supplier) · FISH-03 feeding + stock · FISH-04 water quality (manual) · FISH-05 mortality · FISH-06 sampling · FISH-07 harvest + sales · FISH-08 profit per cycle · FISH-09 workers, reports (core).

---

## 15. Compliance and operations (all complete before V1.0, Week 12)

- [ ] Victorbee Technologies registration current (URSB)
- [ ] Registration with the Personal Data Protection Office (annual renewal) as data controller/processor
- [ ] Legal check on storing personal data on Firebase (outside Uganda) and the PDPO undertaking
- [ ] Privacy Policy and Terms (English + Runyankore summary), linked from sign-in and the Play Store
- [ ] Customer agreement: subscription terms, 14-day trial, read-only after non-payment, 90-day data retention, data ownership
- [ ] Consent records for WhatsApp and SMS (stored per tenant)
- [ ] Bulk SMS provider account; sender ID registered
- [ ] WhatsApp Business Platform account; templates approved (daily report, trial reminders, payment confirmation, farmer weekly summary)
- [ ] Mobile money: merchant number for Phase A; API/aggregator application submitted (Week 2) for Phase B
- [ ] Google Play developer account; app passes policy (no SMS/call-log permissions; data safety form complete)
- [ ] Apple Developer account (before iOS release in V1.3)
- [ ] Firebase: production project on Blaze with budget alerts; App Check enforced; backups (scheduled Firestore export)
- [ ] URA: tax registration and invoicing for subscription income
- [ ] Support: dedicated support WhatsApp number; same-day response target; support log in `docs/support/`
- [ ] Account deletion flow (Play Store requirement): user can request deletion in-app and by web form

---

## 16. Quality: Definition of Done, testing, CI/CD, release

### 16.1 Definition of Done (every feature)

1. Meets its acceptance criteria (Section 10).
2. Works offline and syncs correctly.
3. Works in English and Runyankore.
4. Works in light and dark mode.
5. Tested on the low-end test phone (2 GB RAM).
6. Firestore Security Rules cover it, with rules tests.
7. Audit log entries written.
8. `flutter analyze`: 0 errors, 0 warnings. Theme guard test passes.
9. Unit tests for business logic (totals, withdrawal dates, statements, deductions, trial/subscription dates).
10. Bloc tests for its blocs; widget tests for its key screens.
11. Reviewed (including all AI-generated code).
12. Feature ID in commit messages and CHANGELOG; checkbox ticked in this file.

### 16.2 Test devices

- Low-end Android (Tecno/Itel class, Android 8–10, 2 GB RAM)
- Mid-range Android with NFC
- iOS device (from V1.3)

### 16.3 CI/CD (GitHub Actions)

- [ ] On every push/PR: `flutter pub get`, `build_runner`, `flutter analyze`, `flutter test`
- [ ] Firestore rules tests with the Firebase emulator
- [ ] Cloud Functions: lint, type-check, unit tests
- [ ] On tag `v*`: build release AAB, upload to Play internal testing
- [ ] Secrets only in GitHub Secrets; never in code

### 16.4 Branches and commits

- `main` always releasable. Work in `feat/<ID>-short-name`, `fix/...`, `chore/...`.
- Conventional commits: `feat(milk): DAIRY-MILK-01 per-cow milk recording`.
- Versioning: `MAJOR.MINOR.PATCH+build`; V1.0.0 at production.

### 16.5 Release checklist (each release)

- [ ] All P-level items for the release ticked
- [ ] Regression on both test phones, light and dark, both languages
- [ ] Rules and functions deployed to the right project
- [ ] CHANGELOG and `docs/releases/vX.Y.Z.md` written
- [ ] Staged rollout (internal -> closed -> 20% -> 100%)
- [ ] Crashlytics watched for 48 h after rollout

---

## 17. Sales plan and metrics

### 17.1 Sales method

Warm introductions -> visit at the right time (milk centres after morning collection; farms mid-morning) -> ask about their problems before showing the app -> calculate the loss in shillings together -> 2-minute demo with their own names -> install and start the 14-day trial on the spot -> visit or call on day 3 and day 10 -> collect payment by day 14 -> ask for 3 referrals (referral reward: 1 free month when the referred customer pays).

### 17.2 Milestones

| Date | Target |
|---|---|
| 8 Nov 2026 | 30 introductions requested, 5 conversations |
| 29 Nov 2026 | 3 pilot sites on trial |
| 13 Dec 2026 | First paying customer |
| 31 Jan 2027 (V1.0) | 5 paying customers (UGX 350,000 MRR) |
| 28 Feb 2027 | 10 paying |
| 30 Apr 2027 | 15 paying (UGX 1,050,000 MRR) |
| Gate G2 | ≥ 10 paying + poultry evidence (Section 14.1) |

### 17.3 Weekly metrics (Sunday review)

| Metric | Target |
|---|---|
| Sales conversations | ≥ 5 per week |
| New trials | ≥ 2 per week (from Week 3) |
| Trial-to-paid conversion | ≥ 40% |
| Paying customers / MRR | per 17.2 |
| Waitlist sign-ups by sector | tracked (gate evidence) |
| Records per active customer per week | growing |
| Crash-free sessions | ≥ 99% |
| Sync failures | < 1% of records |
| Direct cost per customer | < UGX 15,000/month |
| Support requests answered same day | 100% |

### 17.4 Weekly review template (`docs/weekly-reviews/YYYY-Www.md`)

```
# Week NN (dates)
## Build: planned vs done (feature IDs)
## Sales: introductions / conversations / trials / paid / MRR
## Waitlist by sector
## Pilot feedback (link docs/pilots/)
## Bugs and blockers
## Costs this week (SMS, WhatsApp, Firebase, AI)
## Cash position
## Decisions needed (-> docs/decisions/)
## Next week's top 3
```

---

## 18. Change Control and decision log

### 18.1 Process

1. Write `docs/decisions/NNNN-title.md`: what, why, evidence (customer requests, payments, data), cost in days, what it delays or replaces.
2. Approve only if: a paying customer needs it; it fixes a security, data-loss or legal problem; or the weekly review shows the plan cannot meet its targets.
3. "It would be cool" is not a reason.
4. Update this file in the same commit as the decision record.

### 18.2 Decisions so far (write each as a record in Week 1)

| No. | Decision | Date |
|---|---|---|
| 0001 | Single Flutter repository `farm_tap` (web app separate, later) | 31 Oct 2026 |
| 0002 | `isar_community` as offline database (original Isar unmaintained) | 31 Oct 2026 |
| 0003 | Next.js + Cloudflare for website/dashboard, from V1.3 | 31 Oct 2026 |
| 0004 | Kraal Ring brand; token-based theme; no hard-coded styling | 31 Oct 2026 |
| 0005 | Pricing UGX 70,000/month per farm/centre; 14-day free trial (replaces earlier "paid pilots" rule and earlier tiered prices) | 31 Oct 2026 |
| 0006 | Sign-in with Google, Apple, Email only; no phone OTP; staff use NFC card + PIN | 31 Oct 2026 |
| 0007 | Onboarding chooses sector; only Dairy active; others join waitlist; collects WhatsApp + SMS numbers with consent | 31 Oct 2026 |
| 0008 | Dairy first and complete (V1 + V1.x) before any other sector | 31 Oct 2026 |
| 0009 | IoT (FarmTap Sense) added: Phase 0 Bluetooth scale/printer, Phase 1 cold-chain pilot; no cattle GPS trackers | 31 Oct 2026 |
| 0010 | Ask FarmTap AI via Firebase AI Logic in V1.1, with vet-safety and privacy rules (technology replaced by 0025) | 31 Oct 2026 |
| 0025 | Free AI Intelligence: calculated and statistical engine in shared/, no paid AI, optional self-hosted Ollama | 6 Nov 2026 |
| 0014 | Offline-first data layer: Isar record store + outbox + sync engine; Firestore rules; Phase 1 and 2 together | 3 Nov 2026 |

---

## 19. Risk register

| Risk | Impact | Mitigation |
|---|---|---|
| Building more than selling | High | Rule 3; weekly sales targets; Pilot Build in Week 4 |
| Founder time around the birth | High | Buffer week; front-load sales in Weeks 1–3 |
| Free trials that never convert | High | Day 3 and day 10 follow-ups; read-only after trial; track conversion weekly; review pricing at Week 11 |
| UGX 70,000 too high or too low | Medium | Track conversion and objections; change only via Change Control with evidence |
| Low-end phones too slow | High | Test every feature on the low-end phone |
| No NFC on customer phones | Medium | Card number + QR fallbacks everywhere |
| Staff can't use email sign-in | High | Staff never sign in; NFC card + PIN only |
| SMS/WhatsApp costs exceed allowance | Medium | Weekly summaries, allowances enforced, cost tracked per customer |
| Mobile money API delays | Medium | Phase A manual payments; payouts optional |
| AI gives unsafe health advice | High | Vet-safety framing, no doses, "Call your vet", disclaimers, logging |
| AI/IoT costs grow | Medium | Allowances, monthly cost review, gates |
| IoT hardware failures in the field | Medium | Pilot first; battery backup; offline buffering; device health alerts |
| Data protection non-compliance | High | Section 15 before V1.0 |
| Government livestock ID system overlap | Low | Store government tag ID; complement it |
| Firebase cost growth | Low–Medium | Offline-first reduces reads; budget alerts |

---

## 20. Glossary

| Term | Meaning |
|---|---|
| Tenant | One customer business (a farm or a collection centre) |
| Account holder | Owner/manager who signs in with Google, Apple or Email |
| Staff | Worker/clerk/vet who unlocks the farm phone with NFC card + PIN |
| MCC | Milk collection centre |
| Withdrawal period | Days after a drug when milk/meat must not be sold |
| Read-back | Confirmation screen repeating what was entered ("Muhwezi — 24 litres — correct?") |
| MRR | Monthly recurring revenue |
| Gate | Measurable conditions that must be met before a new version starts |
| FarmTap Sense | FarmTap's IoT devices and monitoring |
| Ask FarmTap | FarmTap's AI question-and-photo helper |
| P1 / P2 / P3 | Needed for Pilot Build / V1.0 / V1.x |

---

*End of roadmap. Update the checkboxes, the decision log and the version number at the top whenever this file changes.*
