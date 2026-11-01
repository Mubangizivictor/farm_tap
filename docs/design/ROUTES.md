# FarmTap routes

Source of truth for navigation (go_router). Overlays (sheets, dialogs, toasts, celebrations) and states are **not** routes: they belong to the screen in *Parent*.

## Rules
- Main tabs are branches of one `StatefulShellRoute.indexedStack`; each keeps its own back stack and scroll position.
  Farm bar: Home · Herd · Milk · Health · More. Centre bar: Home · Collect · Farmers · Pay · More. Rail (tablet) and sidebar (desktop) add Collect, Feeding, Breeding, Workers, Money, Reports, Settings as branches.
- On phones, Feeding, Breeding, Workers, Money, Reports and Settings open from More with `push` and show a back arrow (back → /more). On wide screens they are root sections (no back arrow).
- Detail and form screens are nested under their tab and opened with `context.push()`.
- `context.go()` only for top-level jumps: splash → sign-in, onboarding done → home, unlock → home, sign out → sign-in, and resetting a flow (milk / delivery) after save.
- Every non-root screen has a back arrow: `pop`, or go to *Parent* when there is nothing to pop (deep link / web refresh).
- iOS edge swipe and Android back behave like the back arrow. Back closes sheets and dialogs first.
- Forms with unsaved input ask *Discard changes?* (`DiscardGuard`).
- Guards (redirect): not signed in → /sign-in; signed in without a farm → /farms (has places) or /setup/language; farm phone locked → /unlock; trial ended → read-only state, no redirect.
- Web: every route is a URL; ids and emails travel in the path or query, never in `extra`, so refresh keeps the screen.

## Screens

| ID | Path | Parent | Opened by | Back |
|---|---|---|---|---|
| A01 | /splash | — | go (app start) | —; then go /sign-in, /unlock or /home |
| A02 | /sign-in | — | go | root (exits app) |
| A03 | /sign-in/email | /sign-in | push | pop |
| A04 | /sign-in/email/sign-up | /sign-in/email | push | pop |
| A05 | /sign-in/email/forgot | /sign-in/email | push | pop |
| A06 | /verify?email= | — | go (after sign-up) | root; Continue → go /setup/language |
| A07 | /farms | — | go (signed in, several places) | root; pick → go /home |
| B01 | /setup/language | — | go (signed in, no farm) | root of onboarding |
| B02 | /setup/sector | /setup/language | push | pop (previous step) |
| B03 | sheet on B02 | /setup/sector | overlay | back closes sheet |
| B04 | /setup/waitlist-done | /setup/sector | push | pop |
| B05 | /setup/dairy-type | /setup/sector | push | pop |
| B06 | /setup/farm | /setup/dairy-type | push | pop; Discard changes? if edited |
| B07 | /setup/contacts | /setup/farm | push | pop; Discard changes? if edited |
| B08 | /setup/role | /setup/contacts | push | pop |
| B09 | /setup/staff | /setup/role | push | pop; Discard changes? if edited |
| B10 | /setup/done | — | go (end of onboarding) | root; Start → go /home |
| C01 | /unlock | — | go (farm phone locked) | root |
| C02 | /unlock/number | /unlock | push | pop |
| C03 | /unlock/pin?card= | /unlock | push | pop |
| C04 | state of C03 (wrong PIN) | /unlock/pin | state | pop |
| C05 | dialog on C01 | /unlock | overlay | back closes dialog |
| D01 | /home (owner / manager) | — | tab | root tab, no back arrow |
| D02 | /home (worker role) | — | tab / go after unlock | root tab |
| D03 | /home/alerts | /home | push | pop |
| D04 | sheet on /home | /home | overlay (sync icon) | back closes sheet |
| D05 | state of /home (offline) | /home | state | — |
| D06 | dialog on /home | /home | overlay (after first save) | back closes dialog |
| E01 | /herd | — | tab | root tab |
| E02 | sheet on E01 | /herd | overlay (filter) | back closes sheet |
| E03 | /herd/:animalId | /herd | push | pop |
| E04 | /herd/add | /herd | push (FAB) | pop; Discard changes? if edited |
| E05 | /herd/scan | /herd | push | pop |
| E06 | sheet on E03 | /herd/:animalId | overlay | back closes sheet |
| E07 | celebration on E03 | /herd/:animalId | overlay | closes to E03 |
| E08 | dialog on E03 | /herd/:animalId | overlay | back closes dialog |
| E09 | /herd/count | /herd | push | pop |
| E10 | /herd/labels | /herd | push | pop |
| F01 | /milk | — | tab | root tab |
| F02 | /milk/record | /milk | push | pop |
| F03 | /milk/record/:cowId | /milk/record | push | pop → F02 |
| F04 | read-back on F03 | /milk/record/:cowId | overlay (no scrim dismiss) | "No, change it" closes |
| F05 | celebration on F03 | /milk/record/:cowId | overlay | after save: stack resets to F02 (go /milk/record) |
| F06 | dialog on F02 | /milk/record | overlay | back closes dialog |
| F07 | /milk/herd-total | /milk | push | pop |
| F08 | /milk/use | /milk | push | pop |
| F09 | /milk/sales | /milk | push | pop |
| F10 | /milk/trends | /milk | push | pop |
| G01 | /home (collection centre) | — | tab | root tab |
| G02 | /collect | — | tab | root tab |
| G03 | /collect/:farmerId | /collect | push (card tapped) | pop → G02 |
| G04 | read-back on G03 | /collect/:farmerId | overlay (no scrim dismiss) | "No, change it" closes |
| G05 | /collect?saved=:deliveryId | /collect | state after save (toast + Undo 5 s) | stack resets to G02 (go /collect) |
| G06 | /farmers | — | tab | root tab |
| G07 | /farmers/:farmerId | /farmers | push | pop |
| G08 | dialog on G01 | /home | overlay | back closes dialog |
| G09 | /pay | — | tab | root tab |
| G10 | /pay/sheet | /pay | push | pop |
| G11 | /pay/sms | /pay | push | pop |
| G12 | sheet on G03 | /collect/:farmerId | overlay | back closes sheet |
| G13 | /home/reconcile | /home | push (Dispatch tile) | pop |
| H01 | /health | — | tab | root tab |
| H02 | /health/treatment | /health | push (FAB) | pop; Discard changes? if edited |
| H03 | celebration on H02 | /health/treatment | overlay | Done → pop to /health |
| H04 | /health/drugs | /health | push | pop |
| H05 | /health/schedule | /health | push | pop |
| H06 | /health/withdrawal | /health | push | pop |
| I01 | /feeding | /more (phones) | branch (wide) / push from More (phones) | phones: pop → /more |
| I02 | /feeding/record | /feeding | push | pop; Discard changes? if edited |
| I03 | sheet on I01 | /feeding | overlay | back closes sheet |
| J01 | /breeding | /more (phones) | branch / push from More | phones: pop → /more |
| J02 | sheet on J01 | /breeding | overlay | back closes sheet |
| J03 | celebration on J01 | /breeding | overlay | closes to J01 |
| K01 | /workers | /more (phones) | branch (rail, sidebar) / push from More | phones: pop → /more |
| K02 | /workers/:staffId | /workers | push | pop |
| K03 | /workers/:staffId/card | /workers/:staffId | push | pop |
| K04 | /workers/attendance | /workers | push | pop |
| K05 | /workers/tasks | /workers | push | pop |
| K06 | /workers/wages | /workers | push | pop |
| L01 | /money | /more (phones) | branch / push from More | phones: pop → /more |
| L02 | /money/expense | /money | push (FAB) | pop; Discard changes? if edited |
| L03 | /reports | /more (phones) | branch / push from More | phones: pop → /more |
| L04 | /reports/whatsapp | /reports | push | pop |
| M01 | /settings/subscription | /settings | push (also from trial banner) | pop |
| M02 | /settings/subscription/pay | /settings/subscription | push | pop |
| M03 | celebration on M02 | /settings/subscription/pay | overlay | Done → go /home |
| M04 | dialog on /home | /home | overlay (day 13-14) | back closes dialog |
| M05 | read-only state of /home | /home | state (trial ended) | — |
| N01 | /more | — | tab (phones) | root tab |
| N02 | /settings | /more (phones) | branch / push from More | phones: pop → /more |
| N03 | /settings/farm | /settings | push | pop; Discard changes? if edited |
| N04 | sheet on N02 | /settings | overlay | back closes sheet |
| N05 | /settings/help | /settings | push | pop |
| N06 | dialog on N02 | /settings | overlay | Sign out → go /sign-in |
| N07 | /settings/delete-account | /settings | push | pop |
| O01 | /admin/payments | — | go (admin account) | root |
| P01 | empty state of /herd | /herd | state | — |
| P02 | error state (any list) | — | state | — |
| P03 | dialog (camera permission) on /herd/scan | /herd/scan | overlay | back closes dialog |
| P04 | dialog (manager PIN) on any guarded action | — | overlay | back closes dialog |
| P05 | toast (saved offline) | — | state | auto-hides 3 s |
| P06 | toast (sync done) | — | state | auto-hides 3 s |
