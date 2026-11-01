# AGENTS.md — rules for AI agents working on FarmTap

Read this first, then `docs/ROADMAP.md`, `docs/THEME.md`, `docs/design/UX_SPEC.md`,
`docs/design/README.md`. Flutter 3.47 / Dart 3.13.

## 1. Binding rules (ROADMAP section 2)
1. **Dairy first.** No poultry, piggery, goat/sheep, crop or fish code. Shared `core/` code only if Dairy needs it.
2. **Nothing outside the roadmap** gets built without a Change Control record (`docs/decisions/NNNN-title.md`). Do not invent screens, features or packages.
3. **Offline first.** Every recording screen works with no network.
4. **Low-literacy design.** Numbers, icons, photos, read-back confirmation, voice prompts; no long sentences.
5. **Free trial, then pay.** 14 days free, then UGX 70,000/month. Read-only after the trial.
6. **Theme tokens only** (section 3 below). Enforced by `test/core/theme/theme_guard_test.dart`.
7. **No phone-number OTP.** Sign-in is Google, Apple or email only.
8. **No personal data to AI services** (names, phone numbers, exact locations).
9. AI-generated code is reviewed line by line. Do not ship code you do not understand.

## 2. Architecture (ROADMAP section 5, `ARCHITECTURE.md`)
- Feature-first Clean Architecture. Dependencies point inward: `presentation -> domain <- data`.
  - **domain:** entities, repository interfaces, use cases. Pure Dart (no Flutter, Isar, Firebase, JSON).
  - **data:** models, data sources, repository implementations, mappers. Fake in-memory repositories live in `data/fake/`.
  - **presentation:** blocs/cubits, pages, widgets.
- Layout: `lib/app/` (router, di, bootstrap), `lib/core/` (theme, ui, error, l10n, sound, settings, ...), `lib/sectors/cattle/<feature>/{data,domain,presentation}`, `lib/admin/`.
- `core/` never imports `sectors/` or `admin/`. Sector features never import another feature's `data/` or `presentation/`; share through `domain/` interfaces.
- Errors: sealed `Result<T>` and a sealed `Failure` hierarchy. Nothing throws across layers.
- DI: `get_it`, manual registration in `lib/app/di/injection.dart`. While `useFakeData` is true, register the fake repositories; real Isar/Firebase repositories replace them later without touching the UI.
- Every record has base fields: `id` (UUID v4), `tenantId`, `createdAt`, `updatedAt`, `createdBy`, `updatedBy`, `deviceId`, `syncStatus`, `isDeleted`.
- All user-facing strings go in `lib/core/l10n/app_en.arb` (English) and `app_nyn.arb` (Runyankore; for now `"[nyn] "` + the English text). `tool/add_arb.py strings.json` adds a key to both. Then `flutter gen-l10n`.
- Do not add packages that are not in ROADMAP section 4 without asking.

## 3. Theme rules (ROADMAP section 6, `docs/AGENT_THEME_RULES.md`)
- Import styling only via `package:farm_tap/core/theme/theme.dart`.
- Colours: `context.colors.*` (Material roles) or `context.status.*` (success, warning, danger, info, synced, withdrawal, ...). Never `Color(0x..)`, `Colors.*` (except `Colors.transparent`).
- Text: `context.text.*` or `context.textStyles.*`. Never `fontSize`, `fontFamily`, `FontWeight.wNNN`; use `FarmTapWeights.*` in `copyWith`.
- Spacing `context.space.*` (`gapMd`, `screen`, `card`, ...), corners `context.radii.*`, sizes `context.sizes.*`, durations `context.motion.*`, breakpoints `FarmTapBreakpoints`. Never numeric `EdgeInsets`, `SizedBox`, `BorderRadius.circular(n)`, `Duration(...)`.
- Prefer plain Material widgets and let the theme style them.
- A new design value becomes a named token in `lib/core/theme/` (light and dark where it is a colour). Tell the user when you add one. Do not edit `farmtap_design.dart` values unless asked.
- Assets via `FarmTapAssets` / `FarmTapAnimations` / `FarmTapSound`; never type paths.

## 4. UX rules (`docs/design/UX_SPEC.md`)
- Breakpoints by **width**: compact < 600 (bottom bar), medium 600-1023 (rail), expanded >= 1024 (sidebar, max content 1120). Tables replace tiles at 700.
- Build every screen in `AdaptiveScaffold`; grids with `ResponsiveGrid`; record lists with `RecordCollection`; popups with `showAdaptiveSheet` (bottom sheet on compact, dialog wider).
- Primary action: FAB bottom-right. One main action per screen, biggest filled button.
- Read-back before any save affecting money or milk (`showReadBack`). Confirmation dialogs name the verb ("Record death", never "OK").
- Celebrations (`showCelebration`): full screen on phones, dialog wider; milk/delivery flows auto-advance after 2 s. Toasts 3 s; Undo 5 s on deliveries.
- States every screen handles: loading (skeleton), empty (animation + one action), error, offline banner, read-only (lock), treated animal (red badge, milk blocked).
- Colour always comes with an icon or word. Touch targets >= 48 dp, keypad keys >= 64 dp. Text must survive 1.3x scale. Every screen exists in light and dark.
- Respect `MediaQuery.disableAnimations` (`FarmTapAnimationView` does). Haptics and sounds as in UX_SPEC section 5; sounds go through `SoundService` and obey Settings > Sounds.
- Money "UGX 70,000", litres "42.5 L", dates "Thu 12 Nov", times "6:52 am".

## 5. Finding the mockups by screen ID
Every screen has an ID (A01 ... P06), listed with notes in `docs/design/README.md`. Files:

`docs/design/screens/<phone|tablet|web_desktop|web_mobile>/<light|dark>/<ID>_<name>.png`

Example: `docs/design/screens/phone/light/F03_milk_keypad.png`. Section contact sheets are in `docs/design/overview/`. Mockups define layout, order, icons (Material Symbols Rounded -> `Icons.<name>_rounded`), copy and sample data; colours, sizes, spacing and fonts come from tokens, never from measuring pixels. Overlays (sheets, dialogs, toasts, celebrations) are states of a screen. Google/Apple sign-in buttons are placeholders (normal outlined buttons, TODO for official branding).

## 6. Golden-test workflow (visual check)
- `test/flutter_test_config.dart` loads Outfit and MaterialIcons so goldens show real text. `test/helpers/pump_app.dart` has `pumpFarmTap(tester, widget, size:, brightness:)`.
- For each screen write goldens at 390x844 (phone) and 1440x900 (desktop), light and dark: `test/goldens/<ID>_<name>_<phone|desktop>_<light|dark>.png`.
- `flutter test --update-goldens test/goldens`, then OPEN each golden next to its mockup, list the differences, fix, repeat until layout and content match.

## 7. Definition of done for each section
1. `flutter analyze`: 0 errors, 0 warnings (keep infos at 0 too).
2. `flutter test` passes, including the theme guard and goldens.
3. Commit `feat(ui): <section> screens <IDs>`.
4. **STOP and report:** screens done, golden paths, differences you could not match and why, any token you added. **Wait for the user's "continue"** before the next section.

## 8. Do not
- Connect Firebase (do not initialise it), Isar writes, SMS, payments or NFC hardware in the UI phase (NFC: a "Simulate tap" button in debug builds).
- Hard-code colours, sizes, fonts, radii, spacing or durations.
