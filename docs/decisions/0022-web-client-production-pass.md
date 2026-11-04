# 0022 Web client production pass (farm app, supplier portal, sync)

- Status: proposed (4 Nov 2026, for Victor)
- Builds on: 0021 admin layout retouch, 0017 web app, 0016 workers and cards, 0014 offline sync

## Why

Victor asked for the client web app to be ready for production: easy to use,
no gaps or broken alignment, nothing half-working, and what is changed on the
phone or the web shows on the other when online. An audit found:

- Most pages could only read. Where the web did write, it broke the phone:
  tasks made on the web had no `staffId` (the phone's restore crashed on
  them), cards were written on the person without the card register
  (`nfcCards`), and edits replaced the whole record body with only the
  changed fields.
- The phone only picked up web changes every 15 minutes, and its task and
  supplier lists ignored web edits and removals until a restart.
- The supplier invite could not be made (the rule passed a path where a farm
  id was expected) or accepted (the farmer could not mark it used), sign-in
  did not return the supplier to the portal, and any signed-in account could
  add itself to any farmer's deliveries.

## Decision

1. Layout as in 0021 on every farm page: `Fit` grids, tabs instead of long
   scrolls, tables become cards on phones, skeletons while loading, the
   turning logo as the page loader, empty and error states with a way out.
2. The web writes the phone's shapes (`lib/domain.ts`, `lib/data.ts`):
   `putRecord` sends the full body with version + 1; soft delete only;
   append-only collections are never edited; tasks always carry `staffId`,
   `due` (18:00 that day), `when` and `doneAt`; cards go through the
   register (`lib/cards.ts`); PINs are hashed in the browser exactly as the
   phone does (`lib/pin.ts`, PBKDF2-SHA256, 20000 rounds).
3. Add, edit and remove on the web for animals (incl. sold or died),
   milk and milk sales, treatments, tasks, workers (PIN, pay, card),
   suppliers (card, delivery with SMS receipt, invite) and money.
4. Live both ways: the web listens to Firestore; the phone listens to the
   newest document of each synced collection and pulls a few seconds after
   any change (`RemoteStore.changes`), on top of the 15-minute pull. The task
   and supplier lists rebuild after a sync, so edits and removals from the
   web show, and ticking a task keeps fields the phone does not use.
5. Rules: a worker ticks a task with `doneAt`; a manager makes supplier
   invites; a farmer links their account only with an unused invite, used up
   in the same write.
6. The sidebar (farm app and control panel) can be closed to icons with the
   button beside the name or Ctrl+B, remembered in that browser; the logo
   goes home.

## Not changed

Admin sign-in and the two-account allowlist. The web stays online-only.
