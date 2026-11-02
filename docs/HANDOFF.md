# FarmTap — Handoff to a new coding session

You are continuing work on FarmTap. A previous agent session expired. Do not
start over: verify the current state, then continue exactly where it stopped.

## What FarmTap is
Offline-first Flutter app (Android first) for dairy farms and milk collection
centres in Western Uganda, by Victorbee Technologies (Victor Mubangizi,
Mbarara). Low-literacy UI, Runyankore + English, NFC cards for staff/farmers,
QR ear tags for animals. Pricing UGX 70,000/month, 14-day trial.
Project: ~/Desktop/Apps/farm_tap · GitHub: Mubangizivictor/farm_tap (main, remote "origin").

## Read first (in this order)
1. AGENTS.md (rules for agents — follow strictly)
2. docs/ROADMAP.md (binding plan; Binding rules in Section 2)
3. docs/UI_REBUILD_PROMPT.md (UI brief: exact component specs, workflow, final report)
4. docs/design/UX_SPEC.md (breakpoints, popups, animations, states)
5. docs/design/README.md (index of 102 screens A01–P06)
6. docs/design/ROUTES.md (every screen → route, parent, back behaviour)
7. docs/design/PROGRESS.md (per-screen status)
8. docs/decisions/ (0001–0012)
Mockups (source of truth for appearance, local only, gitignored):
docs/design/screens/{phone,tablet,web_desktop,web_mobile}/{light,dark}/<ID>_<name>.png

## Journey so far
- Brand (Kraal Ring logo, Kraal green/gold swatch, Outfit font), token theme
  in lib/core/theme/ (control panel farmtap_design.dart, palette is the only
  place with hex colours, theme_guard_test enforces it).
- 102 mockups × 8 (phone/tablet/web desktop/web mobile × light/dark),
  19 cartoon animations (assets/animations), cow avatars
  (assets/images/avatars), sounds (assets/sounds).
- UI-first phase (decision 0011): build every screen with fake data before backend.
- Done and committed:
  - UI kit rebuilt to spec + /dev/gallery (f3728d0)
  - Section 2 setup: material_symbols_icons, golden config with Outfit +
    Symbols fonts, test/helpers/screen_golden.dart (8 goldens per screen),
    tool/compare_mockups.py (mockup | golden | heat-map + report.csv),
    FarmTapPlatform flag for web-mobile
  - Navigation architecture: go_router StatefulShellRoute per tab, nested
    detail routes with push, go only for top-level jumps, guards, back
    arrow + iOS edge swipe + Android back + browser back, PopScope
    "Discard changes?" on forms, ROUTES.md, route back tests
  - Breakpoints (decision 0012): compact < 600 bottom bar; medium 600–1279
    navigation rail (7 items); expanded ≥ 1280 sidebar (11 items)
  - Sections A–J built, goldens ~91–97, device-checked on
    iPhone 16 Pro Max simulator (idb) in light and dark
  - Single-source fake data: farmer totals derived from one record per
    farmer (Muhwezi Robert 512.0 L → UGX 538,200 everywhere); treatments
    drive every withdrawal date, Treated badge and milk block (Kasheshe:
    Penicillin 8 Nov, 4 days → safe from Thu 12 Nov)
  - Injected Clock (core/utils/clock.dart): FakeClock fixed Sat 7 Nov 2026
    08:41 when useFakeData = true (override --dart-define=DEMO_DATE=...),
    SystemClock Africa/Kampala otherwise; clock_guard_test forbids
    DateTime.now() in lib/ outside clock.dart (8f01c81, 119b9a6)
  - Subscription calculated, never stored: stores trialStartedAt,
    trialEndsAt, paidUntil; days left / days used / grace (7 days after
    unpaid period) / read-only computed from the clock (80841dd).
    Rwemera Dairy Farm and Kashari Milk Centre trials: 2 Nov → 16 Nov 2026
    (9 days left on 7 Nov). New farms: trialEndsAt = today + 14 (0cdc19e)
- Last known state: 983 passing, 0 skipped; flutter analyze clean; latest
  commit: feat(ui): N01 more menu (after bfc72cf). Update this line at every
  section commit. I and J device-checked on iPhone 16 Pro Max via More.

## Decisions to keep (from review)
- Data wins over mockup when mockups disagree (e.g. E03 "5 days left",
  H02 new treatment "Wed 11 Nov").
- G02 is the Collect tab root (no back arrow); G01 "Tap farmer card" uses go.
- G10 /pay/sheet (page), G11 /pay/sms, G13 /home/reconcile.
- Phones portrait only; tablets and web any orientation.
- Sign-in: Google, Apple (iOS), Email only — no phone OTP. Staff: NFC card + PIN.
- No Firebase initialisation, no real NFC/SMS/payments yet (debug "Simulate tap").

## Step 1 — verify before doing anything
git log --oneline -15; git status; flutter pub get; flutter analyze;
flutter test. Report the latest commit and test count. If anything differs
from "Last known state", stop and tell me.

## Step 2 — continue the UI phase
Order: Section I (Feeding I01–I03) → J (Breeding J01–J03) → K (Workers
K01–K06) → L (Money & reports L01–L04) → M (Subscription M01–M05) →
N (Settings N01–N07) → O01 (Admin payments) → P (System states P01–P06).
For every screen follow docs/UI_REBUILD_PROMPT.md Section 6:
open all its mockups → build with kit components only → real interactions
and routes (update ROUTES.md) → 8 goldens → compare_mockups.py → fix until
alike → device check on iPhone 16 Pro Max with idb (light + dark, back
button + edge swipe) → small-screen overflow goldens (375x667, 360x640) →
update PROGRESS.md (score, Nav, Device, Small screens, A11y).
Apply the single-source rule to every new data type (feed stock/usage,
breeding events, staff/attendance/wages, money, subscription/payments):
derive all numbers from fake records, add a consistency test.
Section M: M01 "Ends Monday 16 November", M04 popup on the last trial
days, M05 read-only — all from the subscription calculation; extend the
existing date tests (15 Nov → M04, 17 Nov → M05).
After each section: analyze (0 issues), all tests green, commit
"feat(ui): <section> <IDs> match mockups", short report, then continue.
Stop only if blocked, a mockup conflicts with the roadmap, or a screen
can't get close after 3 fix attempts.

## Step 3 — finish the UI phase
Full device pass of all 102 screens on the iPhone 16 Pro Max simulator
(light and dark), iPad simulator (landscape + portrait), Chrome at 390 /
800 / 1280 / 1440 widths. Then the final report per
docs/UI_REBUILD_PROMPT.md Section 8. Do not start the backend phase until I
approve the UI.

## Rules (summary — AGENTS.md is authoritative)
Theme tokens only; strings in ARB (English; Runyankore "[nyn] " + English
for now); Clean Architecture with fake repositories behind useFakeData;
Material Symbols Rounded icons; injected Clock only; no new packages beyond
ROADMAP Section 4 + material_symbols_icons; don't edit docs/design except
PROGRESS.md, ROUTES.md and UX_SPEC.md sections already approved.
