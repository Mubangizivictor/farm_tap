# 0021 Control panel layout retouch (web only)

- Status: accepted (Victor, 4 Nov 2026)
- Builds on: 0020 super admin control panel, 0017 web app, 0013 compact UI

## Why

Victor found the control panel disorganised: cards one per row with empty
space beside them, rows that ended with an empty column, long pages to scroll
(App settings, APIs and keys), and no real phone layout.

## Decision

The super admin stays web only (no Flutter admin). Layout only; no change to
behaviour, data, rules, sign-in or the two-account allowlist.

1. Even grids (`Fit`, `lib/fit.ts`): one item is full width, 2 to 4 share one
   row, and leftovers split the last row evenly, so no row leaves an empty
   column. Columns follow the container's width (container queries at 560,
   900 and 1200), so the same grid works in a page, a card or a dialog.
2. Shortcuts instead of long scrolls: a sticky row of jump links on App
   settings and APIs and keys, highlighting the section in view; sticky tabs
   on the farm page.
3. Phones: a menu drawer (and a Menu button on the bottom bar), tables turn
   into cards with labels, filters and jump links scroll sideways, no page
   scrolls sideways.
4. Control panel content may be up to 1440 wide (`--z-content-admin`).
5. User-visible text never names the hosting or database provider.
