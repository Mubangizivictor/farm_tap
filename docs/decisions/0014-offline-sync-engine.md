# 0014 — Offline-first data layer and sync engine

- Status: accepted (2026-11-03): owner chose Phase 1 and 2 together, on Firebase project `farm-tap-1dd15` (dev)
- Date: 2026-11-03
- Decided by: Mubangizi Victor (owner)
- Roadmap items: CORE-07 (staff unlock), CORE-08 (offline sync), CORE-09 (audit), CORE-10 (sync badge). Pulled forward from Week 2; no new scope.
- Overrides: AGENTS.md §8 "no Isar writes / do not connect Firebase in the UI phase" (decision 0011), for the data layer only. The demo build (`useFakeData = true`) stays Firebase-free.

## Audit (branch `redesign/compact-ui-0013`, 3 Nov 2026)
| Area | Today | Gap |
|---|---|---|
| Local storage | `useFakeData = true`; every repository (A–L) is in memory. Isar only has an unused `AnimalModel`. | Nothing survives an app restart. |
| Sync queue | `FakeSyncService` shows sample numbers (1,284 synced). | No queue, no retry. |
| Conflicts | None. | No merge rule in code. |
| Connectivity | `connectivity_plus` installed, never used. Offline banner exists as UI only. | App never knows it is offline. |
| Sign-in / PIN offline | Fake auth. Staff PIN compared as plain text (`1234`). | No hashed PIN, no lockout, no cached session. |
| Trial / read-only | Computed from stored dates and the clock (works offline). | Clock can be turned back to extend the trial. |
| Packages | Both `isar` and `isar_community` in `pubspec.yaml`. | Keep `isar_community` only (decision 0002). |

## Decision
Build in two phases. Phase 1 needs no Firebase and can start now.

### Phase 1 — works fully offline (est. 5–7 days)
1. **One local record store** (`core/database`): an Isar collection `LocalRecord` (collection, id, tenantId, JSON body, base fields, `syncStatus`, `version`). Each repository keeps its domain interface and reads/writes through it; screens do not change. The mockup sample data becomes a first-run demo seed.
2. **Outbox** (`core/sync`): every write saves the record and an outbox entry in one Isar transaction, so a crash never loses one without the other.
3. **Sync engine** with a `RemoteStore` interface (Firestore adapter in Phase 2; a fake remote until then):
   - Triggers: 5 s after a write, on reconnect, on app resume, every 15 min in the background (`workmanager`, network required), and "Sync now" (D04).
   - Push in small batches (20) so 2G finishes; idempotent by device-made UUID + `version`, so a retry never duplicates a milk record or delivery.
   - Retry with exponential backoff and jitter (30 s → 1 h cap). After 8 tries the record shows as failed in D04 with "Try again"; nothing is ever dropped.
   - Pull changes since a per-collection cursor, merged by the rules in 4.
4. **Merge rules**: milk, deliveries, treatments, attendance, payments and expenses are append-only; a correction is a new record linked to the old one, so they never conflict. Other records (animal details, settings, staff) use last-write-wins by `updatedAt`, tie broken by `deviceId`. A conflict on anything with money or litres keeps both versions in the audit log and shows the owner a review item. Deletes are soft (tombstones).
5. **Connectivity**: `connectivity_plus` plus a real reachability check (a phone on a dead MTN signal still says "mobile"). Drives the offline banner and the sync badge (CORE-10) with real counts.
6. **Staff unlock offline**: PIN stored as salted PBKDF2-SHA256 (`crypto`), checked on the phone; 5 wrong PINs lock that person for 5 minutes. Card UID → person map cached locally.
7. **Trial clock guard**: store the latest time seen; if the phone clock goes backwards, use the latest time for trial and read-only.
8. **Audit** (CORE-09): every write adds an audit entry in the same transaction.

### Phase 2 — cloud (est. 3–4 days, Firebase `farm-tap-1dd15`; a separate prod project before launch)
Firestore `RemoteStore` adapter, server `updatedAt`, security rules + rules tests (`firestore/`, emulator), Firebase Auth (Google, email; Apple when iOS ships), farm list cached on the phone, photo upload queue (compressed, after records, resumable). Owner/manager sign-in stays signed in on the farm phone; only the very first sign-in needs network.

## Why
Binding rule 5 and the first selling claim ("works with no network") are not true yet: today a restart loses every record. Data loss is an approved reason for change (ROADMAP §18.1).

## What it delays
Remaining UI polish in 0013 pauses for about a week. Week 2 items CORE-07/08/09/10 finish early.

## Tests
Unit tests for outbox, backoff, merge rules, PIN hashing and lockout; a "flaky 2G" fake remote that drops 30% of calls must end with every record synced exactly once.
