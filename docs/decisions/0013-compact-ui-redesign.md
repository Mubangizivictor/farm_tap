# 0013 — Compact UI redesign (supersedes the mockups as the UI reference)

- Status: accepted (2026-11-03)
- Date: 2026-11-03
- Decided by: Mubangizi Victor (owner)
- Overrides: ROADMAP binding rule 7 ("UI must match the mockups in `docs/design/screens/`") for every screen. Rule 2 is satisfied by this record.

## Context
The built UI (Sections A–L) matches the mockups, but the owner finds it too
loose: big gaps, oversized fonts, too little on one screen. The owner's CONC
Dairy Operations app (walkthrough video, Nov 2026) is the preferred reference:
dense cards, small clear type, one header pattern on every screen, actions
and tabs at the top, details in sheets.

## Decision
Redesign every screen to the compact pattern below. Keep the Kraal theme
(green / gold / cream / night, Outfit, light + dark), tokens-only styling,
offline-first, Runyankore + English, and all features and routes as they are.

### 1. Type scale (via `farmtap_typography.dart`, not per screen)
| Role | Now (approx.) | New |
|---|---|---|
| Page title | 24–28 | 18 semibold |
| Page subtitle / caption | 14–16 | 12 regular, muted |
| Body / list title | 16 | 14 medium |
| Metric value | 28–32 | 20 bold |
| Metric label | 14 | 12 regular |
| Section label | 12 caps | 13 semibold, sentence case |
| Button | 16 | 14 semibold |

### 2. Spacing and shape (tokens in `lib/core/theme/tokens/`)
- Spacing scale: xxs 2, xs 4, sm 6, md 8, lg 12, xl 16, xxl 24, xxxl 32.
- Content padding 12 (phone), 20 (tablet), 24 (desktop). List gap 8, section gap 16.
- Card padding 12, card radius 14, buttons/inputs radius 10, chips pill, sheets 20.
- Icon bubble 32 (metric and action tiles). Buttons and inputs 48 high. FAB 48.
- App bar 56, bottom bar 64, rail 80, sidebar 240.
- **Touch targets stay ≥ 48 dp** (Material pads smaller visuals). Dense look, not small hit areas.

### 3. Screen pattern (shared shell in `lib/core/ui/`)
1. **Brand bar (phone tab roots):** logo mark, farm name over "place · role", sync, alerts bell with dot, profile avatar (`_BrandBar` in `adaptive_scaffold.dart`).
2. **Page header:** title 18 + subtitle 12, the page's actions on the right (`PageHeader`). Sub-pages keep the back-arrow app bar.
3. **Content:** 2-column metric tiles (more on wide screens), compact list rows with the status badge on the title line (`RecordTile`), compact row action tiles (`ActionTile`), sentence-case section labels.
4. **Bottom bar (phone, 5 items)**, rail (tablet), sidebar (desktop) as decision 0012.
5. **Primary action:** FAB bottom-right (48 high, icon + label).
6. **Details and forms:** bottom sheet (phone) / dialog (wider) via `showAdaptiveSheet`, 16 padding.
7. Tables at ≥ 700 dp (unchanged).

### 4. Worker flows are compact too (owner's choice, 2026-11-03)
No exception: C01–C05, D02, F02–F05, G02–G05, H02–H03 and K03–K04 use the
same compact scale. Binding rule 5 (low-literacy) is kept by these floors,
which do not shrink: touch targets ≥ 48 dp, keypad keys ≥ 56 dp, read-back
before every milk or money save, icon + word on every action, colour never
alone. Re-check with a real herdsman in the first pilot; if errors rise,
revisit in a new decision record.

## Consequences
- The 816 mockups stay as feature and content references only; layout and
  sizing come from this record and `docs/design/UI_SPEC_V2.md`.
- All goldens are regenerated (on the owner's Mac: goldens are platform-specific). `tool/compare_mockups.py` scores no longer
  apply to redesigned screens; PROGRESS.md gets a new "V2 layout" column.
- Remaining sections (M–P) are built directly in the new style.
- Most of the change is in tokens and the shared UI kit, so screens follow
  automatically. V1 date (25 Jan 2027) is unchanged. Sales
  demos continue on the current build until V2 layout passes the device check.
- Test suite (916 tests) must stay green; theme guard unchanged.
