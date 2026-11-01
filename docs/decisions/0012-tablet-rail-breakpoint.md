# 0012 — Tablets keep the navigation rail up to 1279 dp

- Status: accepted
- Date: 2026-11-01
- Decided by: Mubangizi Victor (owner)

## Context
UX_SPEC section 1 put every window of 1024 dp or wider in the expanded
layout (sidebar + top bar with search). The approved tablet mockups
(`docs/design/screens/tablet/`, 1194 x 834 dp landscape) all show the
navigation rail with 7 items and a compact app bar. UX_SPEC section 2 also
said the rail shows all 11 sections, while the mockups show 7.

## Decision
Follow the mockups.
- Breakpoints: compact < 600 dp, medium (rail) 600–1279 dp, expanded
  (sidebar) >= 1280 dp. `FarmTapBreakpoints.expanded` = 1280.
- The rail shows 7 items: Home, Herd, Milk, Collect, Health, Workers, More.
  "More" opens the remaining sections. The sidebar shows all 11.
- Lists still become tables at 700 dp.

## Consequences
- Landscape tablets and small laptops (1024–1279 dp) get the rail, not the
  sidebar; desktop web (1440 dp mockups) is unchanged.
- UX_SPEC sections 1 and 2 updated. Tablet goldens regenerated.
