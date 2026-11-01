# FarmTap — UI Rebuild Prompt (match the mockups exactly)

You are a senior Flutter engineer. Your only job in this task is to make the
FarmTap app UI **look and behave exactly like the approved mockups** for all
102 screens, on phone, tablet, web desktop and web mobile, in light and dark
mode. A previous agent built a first version that does not match well enough.
Audit it, keep what matches, rewrite what does not.

Project: `~/Desktop/Apps/farm_tap` (package `farm_tap`, Flutter 3.47, Dart 3.13).

---

## 0. Read first (in this order) — do not skip

1. `docs/ROADMAP.md` (Sections 2, 5, 6, 7, 10)
2. `docs/THEME.md` and everything in `lib/core/theme/`
3. `docs/design/UX_SPEC.md` (behaviour rules)
4. `docs/design/README.md` (index of all 102 screens: ID, file name, notes)
5. `docs/design/overview/*.png` (contact sheets of every section)
6. Existing code in `lib/core/ui/` and `lib/` (previous agent's work)

The mockups are the **source of truth for appearance**. For every screen ID
there are 8 images:

```
docs/design/screens/phone/{light,dark}/<ID>_<name>.png        390 x 844 dp, rendered at 2x
docs/design/screens/tablet/{light,dark}/<ID>_<name>.png       1194 x 834 dp, rendered at 1.5x
docs/design/screens/web_desktop/{light,dark}/<ID>_<name>.png  1440 x 900 dp, rendered at 1x
docs/design/screens/web_mobile/{light,dark}/<ID>_<name>.png   390 x 844 dp, rendered at 2x
```

Mockup device chrome is NOT part of the app (do not build it):
phone status bar = top 32 dp and gesture bar = bottom 24 dp; tablet status
bar = top 28 dp; desktop browser bar = top 44 dp; web-mobile browser bar =
top 56 dp.

---

## 1. Definition of "looks alike" (acceptance criteria)

For every screen, in every form factor and both modes, the built UI must
match the mockup in:

1. **Layout**: same sections in the same order, same alignment, same number
   of columns at that width, same positions of app bar / nav / FAB / sheets.
2. **Components**: same component type (card vs tinted card vs list vs table,
   chip vs segmented, sheet vs dialog), same sizes per Section 4.
3. **Content**: same titles, labels, button text, sample data, numbers, badges
   and icons as the mockup (read them from the image).
4. **Colour roles**: same role (primary, gold/secondary, danger, success,
   info, container, surface) — always via theme tokens, never hex.
5. **Typography**: same text style per element (Section 3).
6. **States**: every overlay in a mockup (sheet, dialog, toast, celebration,
   banner) is reachable by the real interaction and looks the same.

Small anti-aliasing or font-hinting differences are fine. Different spacing,
missing elements, different components, wrong colours or wrong text are NOT.

---

## 2. Setup steps before building

1. Assets must exist (stop and ask me if missing):
   `assets/animations/anim_*_{light,dark}.{webp,gif}`,
   `assets/images/avatars/avatar_cow_1..6.png`, `avatar_calf.png`,
   `assets/sounds/{tap,pop,success,celebrate,coin,error}.wav`,
   `assets/fonts/Outfit/*`. Register any missing folders in `pubspec.yaml`.
2. Icons: the mockups use **Material Symbols Rounded** (weight 400; filled
   variant for selected/primary icons). Add the package
   `material_symbols_icons` and use `Symbols.<name>` with `fill: 1` where the
   mockup shows a filled icon. This is the ONLY new package allowed besides
   those already listed in `docs/ROADMAP.md` Section 4 (fl_chart, just_audio,
   etc. are allowed; add with `flutter pub add` if missing).
3. Golden test setup: `test/flutter_test_config.dart` loads the Outfit font
   (all weights) and the Material Symbols font so goldens show real text and
   icons.
4. Create `tool/compare_mockups.py` (Python 3 + Pillow) that, for each golden
   `test/goldens/<ff>/<mode>/<ID>_<name>.png`:
   - crops the device chrome from the matching mockup (Section 0),
   - resizes both to the same size,
   - writes `test/goldens/compare/<ff>/<mode>/<ID>.png` = mockup | golden |
     difference heat-map side by side,
   - prints a similarity score (100 − mean absolute pixel difference %) and
     writes `test/goldens/compare/report.csv`.
   Golden sizes (no chrome): phone 390x788, tablet 1194x806,
   web_desktop 1440x856, web_mobile 390x788.
5. Create `docs/design/PROGRESS.md`: a table with one row per screen ID and
   columns phone / tablet / web_desktop / web_mobile × light / dark, plus
   score and notes. Update it as you go. Add `test/goldens/compare/` to
   `.gitignore`.

---

## 3. Typography (Outfit) — map every text element to one of these

| Style | Size / weight / line-height | Used for |
|---|---|---|
| hero | 44 / 700 / 1.1 | Big numbers in tinted hero cards (1,284 L, 48, 168.5 L) |
| displaySmall | 38 / 700 / 1.15 | — |
| headlineMedium | 28 / 700 / 1.2 | "9 days left" |
| headlineSmall | 24 / 600 / 1.25 | Page greeting, screen titles in body, celebration titles, desktop top-bar title |
| titleLarge | 22 / 600 / 1.3 | App bar title, sheet/dialog titles |
| titleMedium | 18 / 600 / 1.35 | Card headers, option titles |
| titleSmall | 16 / 600 / 1.35 | List tile titles, trailing values |
| bodyLarge | 18 / 400 / 1.45 | Input text, hints |
| bodyMedium | 16 / 400 / 1.45 | Subtitles, messages |
| bodySmall | 14 / 400 / 1.4 | Tile subtitles, helper text |
| labelLarge | 17 / 600 | Text actions ("Pay now", "See all") |
| labelMedium | 15 / 500 | Chips, segmented labels, sidebar items |
| labelSmall | 13 / 500 | Badges, bottom-nav labels, input floating labels |
| sectionLabel | 13 / 600, UPPERCASE | "QUICK ACTIONS", table headers |
| metricLabel | 14 / 500 | Metric card labels |
| metricValue | 32 / 700 | Metric card values |
| keypadDisplay | 48 / 700 | Number being typed |
| keypadDigit | 32 / 600 | Keypad keys |
| readBackValue | 36 / 700 | "9.5 litres" |
| readBackLabel | 18 / 500 | "Bihogo · FT-014" |
| tagNumber | 20 / 700 | Card / tag numbers |
| button / buttonLarge | 17 / 600 · 20 / 600 | Buttons (56 / 64 tall) |
| micro | 12 / 500 | Chart axis labels |

Add any style missing from `FarmTapTextStyles` as a token (both modes).

---

## 4. Exact component specification (all values in dp)

Use theme tokens for every value; add tokens where missing (light + dark).
Surface roles: `c0` = surfaceContainerLowest, `c1` = surfaceContainerLow,
`c2` = surfaceContainer, `c3` = surfaceContainerHigh, `card` = white in light,
`#18221E`-equivalent token in dark (add `FarmTapSemanticColors.card` if needed).

### 4.1 Shells (AdaptiveScaffold)

**Phone / web mobile (< 600):**
- App bar 64: leading at x16 — back arrow (28) OR logo (mark 32 + "Farm" 400
  + "Tap" 700 in primary, text ~20) on home screens OR hamburger (web mobile
  root screens). Title titleLarge, subtitle bodySmall under it. Trailing from
  right 16: staff avatar 36 with 3 dp primary ring, then sync icon
  `cloud_done` 28 (success, filled) 16 dp left of it, then action icons 28
  spaced 44.
- Content: side padding 16, top 8, default vertical gap 16.
- Bottom nav 80 tall, bg c2. Items equal width. Selected indicator 64×34
  pill (radius 17) primaryContainer at top 10; icon 28 (filled when
  selected, onPrimaryContainer; else onSurfaceVariant outline); label
  labelSmall at y50 (600 + onSurface when selected).
  Farm items: Home, Herd, Milk, Health, More. Centre items: Home, Collect,
  Farmers, Pay, More.
- Extended FAB: 64 tall, radius 20, primary, icon 28 at left 20, label
  `button`; 16 from right, 16 above the nav.

**Tablet (600–1023):** navigation rail 96 wide, bg c1, logo mark 36 at top 20;
items from y84, every 76: indicator 64×36 radius 18, icon 28, label
labelSmall below. Person avatar 40 at bottom. App bar 64 (no staff avatar).
Content padding 24. Rail items: Home, Herd, Milk, Collect, Health, Workers, More.

**Desktop (>= 1024):** sidebar 264, bg c1, 1 dp right border outlineVariant.
Logo (34) at (24, 22). Farm switcher card at y76: 232×60, radius 14, c0,
border, cow avatar 36, farm name titleSmall + "Mbarara · Owner" bodySmall,
expand icon. Nav items from y152, 44 tall, every 48: selected pill radius 22
primaryContainer; icon 24 at x28; label at x64 (labelMedium; selected
labelLarge). Items: Home, Herd, Milk, Collection centre, Health, Feeding,
Breeding, Workers, Money, Reports, Settings. Trial card 150 from bottom:
232×82, radius 14, secondaryContainer, savings icon, "Free trial · 9 days
left", 6 dp gold progress, "Upgrade · UGX 70,000/mo". Sync row at bottom
("All records synced", success cloud icon).
Top bar 76: title headlineSmall at x32 (subtitle bodySmall), right side:
search pill 290×48 radius 24 c2 ("Search animals, farmers, records"),
notifications icon 28 with 5 dp red dot, avatar 40 with ring; 1 dp bottom
border. Content max width 1120, centred, top padding 28. FAB 40 from right,
32 from bottom.

**Auth/onboarding wide (tablet & desktop) = split layout:** left brand panel
(42% desktop / 40% tablet) bg primary: logo in 52 rounded-square (radius 14,
onPrimary bg) + "FarmTap" headlineSmall onPrimary; illustration box
primaryContainer radius 28 with the screen's animation; tagline
headlineSmall + description bodyMedium in onPrimary. Right: content column
460 wide, starting 56 from top. Phones: full-screen form, padding 24, primary
buttons pinned at the bottom.

**Centered screens** (splash, check email, waitlist done, trial started,
staff tap card, PIN): content max 480, vertically centred, bottom actions
pinned 48 from bottom (phone) / 32 (others).

### 4.2 Containers
- **Card**: radius 16, padding 16, bg card, 1 dp border outlineVariant, no
  shadow, child gap 12. Cards in the same grid row have equal height.
- **Tinted hero card**: container colour (primary/secondary/…), radius 16,
  no border, padding 16; left: label (metricLabel, on-container), hero
  number, sub (bodySmall); right: animation 110–130 wide.
- **ListCard**: Card with padding 12, items separated by 1 dp dividers
  inset 56; optional header row (titleMedium + action labelMedium primary).
- **Banner**: tinted, radius 14, padding 14, icon 26 filled, title
  titleSmall, message bodySmall, action labelLarge (right-aligned when width
  > 480, else below). Gold trial banner uses secondaryContainer + savings icon.
- **Section label**: sectionLabel uppercase onSurfaceVariant, 24 tall,
  optional right action.
- **Grids**: columns = floor((w + 16) / (minItemWidth + 16)), max 4, gap 16.
  minItemWidth: metrics 160, action tiles 150, paired cards 420–460.
  At ≥ 700 dp, record lists become tables.

### 4.3 Atoms
- **IconBubble**: circle; sizes 40 (metrics, timeline), 44 (list tiles),
  52 (action tiles, options), 64 (dialogs); icon = 52% of size, filled,
  colour pair container/onContainer of its kind (primary, gold, danger, info,
  success, warning, neutral = c3/onSurfaceVariant).
- **Badge**: 26 tall, radius 13, padding 10, labelSmall, optional 16 filled
  icon; kinds as IconBubble. Animal status → badge: Milking success, Treated
  danger, Pregnant info, Heifer neutral, Dry warning.
- **Avatars**: person = circle primaryContainer (or secondaryContainer /
  infoContainer) with initials (titleSmall, 36% of size); optional 3 dp ring.
  Cow = circle c2 with cartoon `avatar_cow_N.png` clipped (or real photo).
  Sizes 36, 40, 48, 56, 64, 80, 88, 96.
- **Buttons**: full width by default, 56 tall (large 64), radius 14, icon 24
  filled + 6 gap, text `button`/`buttonLarge`. Kinds: filled (primary),
  tonal (primaryContainer), outlined (1.5 outline), text, danger (danger bg),
  gold (secondary), neutral (c0 + outlineVariant). Two buttons side by side
  when width ≥ 420, else stacked with gap 12.
- **Input**: outlined, 60 tall, radius 14, fill c0, border 1.2 outline;
  focus 2 primary (+ 3×24 caret); error 2 danger with message below;
  disabled outlineVariant. Leading icon 24 at x16, text at x52 bodyLarge,
  optional prefix ("+256", "UGX") in onSurfaceVariant. Floating label
  labelSmall sitting on the top border (primary when focused).
- **Search**: 52 tall, radius 26, fill c2, search icon 24 at x16, bodyLarge hint.
- **Chips**: 40 tall, radius 12, padding 16, labelMedium; selected =
  secondaryContainer + check icon 20 filled; unselected = c0 + outlineVariant
  border; gap 8; wrap rows 48 apart.
- **Segmented**: track 48 tall radius 24 c2; selected thumb inset 4, radius
  20, c0 with outlineVariant border; labelMedium centred.
- **Switch / checkbox / radio**: Material 3; checkbox 24 radius 6 primary
  with check; radio 20 ring + 11 dot.
- **List tile**: min 56 (48 dense); leading 48 (avatar) or 44 (bubble) in a
  56 slot; title titleSmall (2 lines max), subtitle bodySmall
  onSurfaceVariant (2 lines), optional badge 6 below; trailing value
  titleSmall + trailing sub bodySmall, right-aligned; chevron 24.
- **Metric card**: Card; IconBubble 40 top-left; optional trend badge
  top-right ("+6%", trending icon, success/danger); label metricLabel at
  y52; value metricValue with unit titleSmall onSurfaceVariant beside it;
  optional sub bodySmall.
- **Action tile**: 110 tall (124 with subtitle), radius 18, card + border;
  IconBubble 52 at (16,16); label titleSmall at y76; subtitle bodySmall at y98.
- **Option row (onboarding)**: 84 tall, radius 18; selected =
  primaryContainer + 2 dp primary border + check_circle 28; IconBubble 52;
  title titleMedium; sub bodySmall; unselected radio; "Coming soon" gold badge.
- **Step header**: back arrow 28, "Step x of 8" labelMedium centred,
  optional "Skip" labelLarge primary; 6 dp progress bar 50 below.
- **Progress**: 10 tall (6 in step header/trial card), radius = half height,
  track c3; optional label row (labelMedium) above.
- **Dots**: 10 dp dots, current = 28 wide pill, gap 8.
- **Timeline**: bubbles 40, 2 dp connector outlineVariant, title titleSmall,
  sub bodySmall (1 line), time bodySmall right, 76 per item.
- **Tables**: inside Card padding 0; header 44 tall, c1, radius 12,
  sectionLabel uppercase; rows 60 tall with 1 dp divider; first column
  titleSmall, others bodyMedium; badges/avatars inline.

### 4.4 Flow components
- **Keypad**: max width 420, centred. Display 96 tall, radius 18, c0,
  2 dp primary border, value keypadDisplay + unit titleLarge, 3×46 caret.
  Optional caption bodySmall centred 8 below. Keys: 3 columns, gap 10, 64 tall,
  radius 16, bg keypadKey token (white / dark container), outlineVariant
  border, keypadDigit; backspace icon 30. Confirm button (large, check icon)
  below.
- **PIN**: dots 22 diameter, gap 18 (primary filled / outline ring / danger
  on error); PIN keys 3 columns, 60 tall, pill radius 30, max width 340.
- **Read-back**: avatar 88 with ring, readBackLabel, readBackValue, meta
  bodyMedium, "Is this correct?" titleMedium, "Yes, save" large filled with
  check, "No, change it" outlined with edit. Must not dismiss by tapping
  outside.
- **Bottom sheet (compact)**: top radius 28, bg c1, handle 36×5 (outline) at
  top 12, content padding 24, starts 36 from top. On wide screens the same
  content shows as a dialog 560 wide with a close (×) icon.
- **Dialog**: width 400 (compact: screen − 32), radius 28, bg c1, padding 24,
  centred IconBubble 64 (or animation 150), centred title titleLarge, centred
  message bodyMedium, full-width stacked buttons gap 10. Scrim: black 42%
  light / 60% dark.
- **Toast**: 64 tall, radius 14, inverseSurface, icon 24 (filled), text
  bodyMedium, action labelLarge inversePrimary. Phone: 16 from sides, just
  above the bottom nav. Wide: 420 wide, bottom-right, 32 margin.
- **Celebration**: phone = full screen surface, animation 230 tall, title
  headlineSmall centred, message, optional summary Card, buttons. Wide = dialog
  560. Plays sound + haptic (UX_SPEC §5).
- **Charts (fl_chart)**: line 3 dp primary, area 14% primary, 4 dashed
  (4,4) grid lines outlineVariant, y labels micro; highlighted point = 7 dp
  ring + value tooltip pill (inverseSurface, radius 8); optional dashed gold
  target line. Bars ≤ 36 wide, radius 6.
- **Printed card preview (K03)**: white card, green header strip with
  "FarmTap" + contactless icon, avatar 64, name, role, card number tagNumber
  in primary, soft shadow.
- **QR labels (E10)**: real, scannable QR codes encoding
  `farmtap:animal:<tag>`. Use the `pdf` package's `BarcodeWidget`
  (`Barcode.qrCode()`) for the printable PDF and show it with `printing`'s
  preview; label layout 2 columns on phone, 4 on wide.

---

## 5. Sample data (must match the mockups)

Farm "Rwemera Dairy Farm" (Mbarara, owner Muhwezi Robert, initials MR;
manager Mugisha Tom MT); centre "Kashari Milk Centre" (clerk Ahimbisibwe Joy AJ).
Date shown: Saturday 7 Nov. Trial: 9 days left, ends 21 Nov 2026.

Cows (tag, name, avatar, breed · age, status):
FT-014 Bihogo (1) Friesian cross · 5 yrs Milking · FT-022 Kasheshe (2) Ankole ·
7 yrs Treated · FT-031 Kyasiimire (3) Jersey cross · 4 yrs Pregnant · FT-008
Ngabire (4) Friesian · 6 yrs Milking · FT-045 Rwemera (5) Ankole cross · 3 yrs
Heifer · FT-019 Kaaka (6) Friesian cross · 8 yrs Dry · FT-027 Nyinamwiza (1)
Jersey · 5 yrs Milking · FT-033 Kahara (3) Ankole · 4 yrs Milking.

Farmers (name, card, initials, litres today): Muhwezi Robert 0142 MR 42.5 ·
Kyomugisha Annet 0087 KA 18.0 · Tumusiime Jonan 0113 TJ 26.5 · Atuhaire Grace
0151 AG 12.0 · Byaruhanga Moses 0099 BM 35.0 · Ninsiima Prossy 0128 NP 9.5 ·
Asiimwe Fred 0164 AF 21.0 · Kansiime Doreen 0071 KD 15.5. Price UGX 1,100/L.

Staff: Mugisha Tom Manager MT · Twinomujuni Amos Herdsman TA · Ahimbisibwe Joy
Milk clerk AJ · Nuwagaba Peter Worker NP · Katusiime Rita Worker KR ·
Dr. Kamugisha Ivan Vet KI.

All other numbers (312 L, 48 cows, 1,284 L, UGX 18.4M…) — read them from the
mockup of that screen. Put this data in fake repositories
(`data/fake/`) behind `useFakeData = true`, registered in get_it.

---

## 6. Work plan (do every step; do not skip screens)

**Step 1 — Audit.** Generate goldens for the existing UI kit and any built
screens, run the compare script, and list in `docs/design/PROGRESS.md` what
differs from Section 4. Fix or rewrite `lib/core/ui/` components until each
matches Section 4 exactly. Rebuild the `/dev/gallery` route showing every
component in light and dark.

**Step 2 — Screens, in this order:** A01–A07, B01–B10, C01–C05, D01–D06,
E01–E10, F01–F10, G01–G13, H01–H06, I01–I03, J01–J03, K01–K06, L01–L04,
M01–M05, N01–N07, O01, P01–P06.

For **each screen**:
1. Open its phone, tablet, web_desktop and web_mobile mockups (light AND dark).
2. Build it with the shared components only (no one-off styling).
3. Wire real interactions: overlays shown in a mockup open from the real
   button/tap; navigation follows UX_SPEC §3.
4. Write goldens for all 4 form factors × 2 modes. For screens whose mockup
   shows an overlay, golden the overlay state.
5. Run `tool/compare_mockups.py`, open the side-by-side images, fix every
   difference in layout, component, content, colour role and text style.
   Repeat until they look alike. Record the score and notes in PROGRESS.md.

**Step 3 — Flows (integration tests)** for every flow in UX_SPEC §3, with
animations, sounds, haptics and transitions as specified.

**After each section:** `flutter analyze` (0 errors, 0 warnings, 0 infos),
`flutter test` (all pass, including `theme_guard_test`), commit
`feat(ui): <section> <IDs> match mockups`, update PROGRESS.md, then continue
to the next section. Stop and ask me only if you are blocked or a mockup
conflicts with the roadmap.

---

## 7. Rules

- Theme tokens only: no hex colours, no raw font sizes, no numeric
  `EdgeInsets`/`SizedBox`/`BorderRadius`, no raw durations outside
  `lib/core/theme/`. Add tokens instead.
- All strings in ARB files (English; Runyankore = "[nyn] " + English for now).
- Clean Architecture per ROADMAP §5; UI talks to repositories only through
  domain interfaces.
- No Firebase initialisation, no real NFC/SMS/payments (debug "Simulate tap"
  button for NFC).
- Do not edit or delete anything in `docs/design/`, except PROGRESS.md.
- Never mark a screen done without a compare image you have looked at.

## 8. Final report

When all sections are done: list every screen with its 8 scores, the
remaining differences and why, tokens added, packages added, and commands to
run the app on a phone, tablet emulator and Chrome.
