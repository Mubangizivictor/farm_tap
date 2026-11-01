# FarmTap UX Specification (V1 Dairy)

This document explains how the screens behave, so developers and AI agents build them the same way. Images are in `screens/`. Theme tokens are in `lib/core/theme/` (see `docs/THEME.md`).

## 1. Form factors and breakpoints

Use the available **width** of the window, never the device type.

| Class | Width | Navigation | Content | Popups |
|---|---|---|---|---|
| Compact | < 600 dp (phones, mobile web) | Bottom navigation bar (5 items) | One column, 16 dp side padding | Bottom sheets; dialogs full-width minus 32 dp |
| Medium | 600–1023 dp (tablets, small laptops) | Navigation rail (left, 96 dp) | Grids of 2–3 columns, 24 dp padding | Centered dialogs (max 560 dp) |
| Expanded | ≥ 1024 dp (desktop web, big tablets landscape) | Sidebar (264 dp) with farm switcher, trial card, sync status; top bar with search, notifications, profile | Max content width 1120 dp, centered; 32 dp padding; lists become tables | Centered dialogs (max 560 dp); toasts bottom-right |

### Rules so any NEW screen fits automatically
1. Build every screen inside `AdaptiveScaffold` (shared shell): it picks bottom bar / rail / sidebar.
2. Lay out content with `ResponsiveGrid(minItemWidth: …)`: columns = floor((width + gap) / (minItemWidth + gap)), max 4. Use minItemWidth 150–180 for metric/action tiles, 420–460 for paired cards.
3. Lists of records use `RecordCollection`: a `ListView` of tiles when width < 700, a `DataTable` above.
4. Popups use `showAdaptiveSheet`: bottom sheet on compact, dialog on medium/expanded.
5. Primary action: FAB (extended with label) bottom-right on all classes. Full-width primary buttons only inside forms and sheets.
6. Never hard-code widths. Use theme tokens (`context.space`, `context.sizes`).

## 2. Navigation map

- Farm (bottom bar): Home · Herd · Milk · Health · More
- Collection centre (bottom bar): Home · Collect · Farmers · Pay · More
- "Both" farms show the farm bar plus a Collect shortcut on Home.
- Rail / sidebar show all sections: Home, Herd, Milk, Collection centre, Health, Feeding, Breeding, Workers, Money, Reports, Settings.
- Back arrow on every non-root screen. Android back closes sheets and dialogs first.

## 3. Core flows

**First launch:** A01 splash → A02 sign-in (Google / Apple on iOS / email) → B01–B10 onboarding → D01 home (owner).
**Daily use on the farm phone:** A01 → C01 tap card (or C02 number) → C03 PIN → D02 worker home (role-based).
**Record milk (farm):** F01 → F02 pick cow → F03 keypad → F04 read-back → F05 celebration → auto-advance to next cow.
**Receive milk (centre):** G02 tap card → G03 keypad → G04 read-back → G05 saved toast + "tap next card". Target under 15 s per farmer.
**Treatment:** H01 → H02 → H03 celebration; milk is blocked (F06 warning) until the withdrawal date.
**Trial:** banner from day 1 (D01), popup day 13–14 (M04), read-only after day 14 (M05), payment (M02 → M03).

## 4. Popups, sheets and toasts

| Type | When | Behaviour |
|---|---|---|
| Bottom sheet / dialog | Choices, short forms, read-back | Drag handle on phones; tap scrim or back to close (except read-back, which needs a choice) |
| Confirmation dialog | Destructive or reported actions (death, close session, sign out, reject milk) | Icon in a coloured bubble, plain-language title, consequence in one sentence, primary action named by its verb ("Record death", never "OK") |
| Toast / snackbar | Saved, synced, offline | 3 s, one optional action (Undo for 5 s on deliveries), above the bottom bar; bottom-right on wide |
| Full-screen celebration | Milk saved, calf born, treatment saved, pregnancy confirmed, payment received, setup complete | Phone: full screen; tablet/web: dialog. Plays once (1.5–2 s), then shows buttons. Never blocks repeated work: milk/delivery flows auto-advance after 2 s |
| Banner | Trial, offline, withdrawal, read-only | Inline at top of content, not dismissible while true |
| Permission rationale | Before camera, notifications, NFC settings | Shown just before the feature is used, never at first launch |

## 5. Animations (assets/animations)

All animations exist as `anim_<name>_light|dark.webp` (transparent, preferred) and `.gif` (solid background fallback). Use `FarmTapAnimations.<name>.of(context)`.

| Animation | Used on | Plays |
|---|---|---|
| milk_saved (dancing milk cans) | F05 milk saved, G01 header | Once on save, loop in headers |
| milking (herdsman milking) | A01 splash, F01 header | Loop |
| calf_born | E07 calving | Once + loop while open |
| cow_grazing | B02, E09 head count | Loop |
| treatment_saved (vet thumbs-up) | H03 | Once |
| feeding (cow at trough) | I01, I02 | Loop |
| payment_received (coins into can) | M01, M03, M04, G09 | Once on success |
| tap_card (card → phone, NFC waves) | C01, G02, G05, K03 | Loop while NFC is listening |
| sms_sent | A06, statements sent | Once |
| attendance (worker waves, clock) | K04, B09 art | Loop |
| celebration (cow jumps, confetti) | B10 setup complete | Once |
| empty_herd (sleepy cow) | P01 and every empty list | Loop |
| offline_saved | P05, offline banner detail | Loop |
| sync_done | D04 sync sheet, P06 | Once |
| error_confused | P02 error state | Loop |
| locked (sad cow + padlock) | M05 read-only | Loop |
| pregnant | J01, J03 | Loop |
| waitlist (chicken + pig) | B03, B04 | Loop |
| welcome (herdsman + cow) | A02, B01, N05 | Loop |

Rules:
- Display size: 120–260 dp. Never larger than 40% of the screen height on phones.
- Respect "reduce motion" (`MediaQuery.disableAnimations`): show the first frame as a still image.
- Celebrations: pair with a short success sound (≤ 0.5 s, off when phone is silent) and `HapticFeedback.mediumImpact()`.
- Screen transitions: shared-axis horizontal for forward/back (250 ms, `context.motion.normal`), fade-through between bottom-bar tabs, sheets slide up 250 ms.
- Keypad: `HapticFeedback.selectionClick()` per key; wrong PIN: dots shake 300 ms + `HapticFeedback.heavyImpact()` twice.

## 6. Low-literacy rules (every screen)

- Numbers, icons and photos first; text second. Every action has an icon.
- Minimum touch target 48 dp; primary buttons 56 dp; keypad keys 64 dp+.
- One main action per screen; it is the biggest, filled button.
- Read-back before any save that affects money or milk ("Bihogo — 9.5 litres — Is this correct?").
- Voice prompts (Runyankore) on key steps when enabled in Settings.
- Colours always come with an icon or word (never colour alone): red + medication icon = treated.
- Plain language: "Milk not for sale until Thursday", not "Withdrawal period active".

## 7. States every screen must handle

| State | Pattern | Example |
|---|---|---|
| Loading | Skeleton tiles; spinner `loading_*.webp` only for > 1 s | — |
| Empty | Animation + title + one action | P01 |
| Error | Confused cow + "Try again"; data on phone is safe | P02 |
| Offline | Yellow banner + toast "Saved offline"; sync icon shows pending count | D05, P05 |
| Read-only (unpaid) | Red banner; record buttons disabled with lock | M05 |
| No permission (role) | Action hidden; if reached via link, explain who can do it | — |
| Treated animal | Red badge + block on milk sale | F06 |

## 8. Accessibility and dark mode

- Every screen exists in light and dark (see `screens/*/dark`). Use theme roles only.
- Text scales with the system setting up to 1.3× without clipping; test at 1.3×.
- Contrast: body text ≥ 4.5:1, large text and icons ≥ 3:1 (palette already meets this).
- Screen readers: every icon button has a label; read-back sheet is announced as a dialog.

## 9. Content and copy

- Money: "UGX 70,000" (comma thousands, no decimals). Large values: "UGX 18.4M", "UGX 538k".
- Litres: "42.5 L"; dates: "Thu 12 Nov"; times: "6:52 am".
- Names: Ugandan sample data in mockups; real data comes from the farm.
- All strings live in ARB files (English + Runyankore).

## 10. Mockup notes

- Mockups are design references, not pixel-exact specs; spacing and sizes come from theme tokens.
- Google and Apple sign-in buttons are drawn as placeholders ("G", "A"). In the app use the official buttons and logos as required by Google and Apple branding guidelines.
- Cow photos are cartoon avatars; in the app they are the farm's real photos (fallback: cartoon avatar).
