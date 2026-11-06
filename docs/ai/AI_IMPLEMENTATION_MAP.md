# FarmTap AI — implementation map

Decision: `docs/decisions/0025-free-ai-intelligence.md`. Written 6 Nov 2026 after reading the whole repository.

## 1. Existing architecture

| Part | What it is | AI fit |
|---|---|---|
| `lib/` | Flutter 3.47 phone app. Clean architecture (`domain` ← `data`, `presentation`), bloc, go_router, get_it, Isar offline journal that syncs to Firestore (0014). Injected `Clock`, sealed `Result`. | Dart port of the engine in `lib/core/ai/` (phase 2). Runs fully offline on the phone's own records. |
| `webapp/` | Next.js 16 static export on Firebase Hosting. Reads Firestore live with `useRecords`. Online only (0017). | Phase 1: full AI section, module cards, admin AI Control Centre. |
| `functions/` | Cloud Functions (TypeScript): billing, SMS, daily reminders (`alerts.ts`). | Optional Ollama bridge (`aiAsk`) for the future; off unless configured. |
| `shared/` | Pure TypeScript copied into web and functions by `sync.mjs`. | Home of the AI engine: `shared/ai*.ts`. |
| `firestore.rules` | Multi-tenant: `tenants/{t}/{collection}/{id}` records with base fields. Members read; managers-only and append-only lists; admins via `platformAdmins` permissions with the audit log. | New collections added to the same generic rule. |

## 2. Existing modules (dairy)

Milk (`milkRecords`, `milkSales`, `milkSalePayments`), Herd (`animals`), Health (`treatments`, `vaccinations`, `stockItems` drugs), Breeding (`breedingEvents`), Feeding (`feedTypes`, `feedUsage`, `stockMovements`), Money (`expenses`, `income`, `wages`), Collection centre (`farmers`, `deliveries`), Workers (`staff`, `attendance`, `duties`, `absences`, `tasks`), Reminders (`shared/alerts.ts`), Admin panel (0020).

## 3. Roles

- Farm: `owner`, `manager` (manage), `clerk`, `worker`. Phone staff titles: worker, herdsman, clerk, vet, manager.
- Platform: `platformAdmins` with permissions `farms`, `finance`, `users`, `support`, `messages`, `settings`, `secrets`, `staff`, `audit`.
- The requested roles map onto these (owner's choice, 6 Nov): Vet → health; Dairy staff, Milk collection → milk/centre; Storekeeper → stock; Finance → owner/manager money. No new roles.

| AI module | owner | manager | clerk | worker |
|---|---|---|---|---|
| Today's insights, Alerts centre | all | all | milk, centre, stock | tasks, health reminders, feeding |
| Assistant | all questions | all questions | not money | not money |
| Vet Assistant, Screening, Animal health | ✓ | ✓ | ✓ | ✓ |
| Milk intelligence, Quality and expiry, Predictions | ✓ | ✓ | ✓ | today's milk only |
| Feed, Inventory | ✓ | ✓ | ✓ | feed left only |
| Breeding | ✓ | ✓ | ✓ | – |
| Financial intelligence, Smart reports | ✓ | ✓ | – | – |

The table is enforced in `shared/aiRoles.ts` for what is *shown*. What can be *read* is still decided by Firestore rules, so the AI cannot see more than the person could already see.

## 4. Navigation

- Web farm app: new **AI Intelligence** item in the sidebar, rail and phone "More" sheet (`/ai/`), with sub-pages. Shown when `featureOn('ai')`.
- Web admin panel: new **AI Control Centre** (`/admin/ai/`) in the Platform group.
- Phone (phase 2): a new AI tab destination in `AdaptiveScaffold`, plus cards in Home, Milk, Herd, Health, Feeding, Money.

## 5. Integration points

| Existing page | AI added |
|---|---|
| Home | "Today's AI farm insights" (top 5 alerts with links) |
| Milk | Forecast card, cows dropping, anomaly days, milk loss |
| Herd → animal | Animal health summary, production trend, breeding state, Vet Assistant link |
| Health | Repeat illness, overdue vaccinations, follow-ups, drug stock |
| Feeds | Days of feed left, run-out dates, feed cost per litre |
| Money | Cost per litre, unusual spending, next-month cash estimate |
| Breeding | Open cows past the window, repeat breeders, due to calve |

## 6. Models and methods

| Need | Method | Label shown |
|---|---|---|
| Totals, stock, costs, due dates | Arithmetic on records | Calculated |
| Production forecast | Weighted linear trend with day-of-week effect; 80% interval from residuals; refuses with fewer than 14 recorded days | Statistical model |
| Anomalies (milk drop, unusual spend, unusual feed use) | Robust z-score (median and MAD) | Statistical model |
| Assistant routing | Keyword intent matcher (no model) | Calculated |
| Assistant phrasing (optional) | Qwen3 4B via self-hosted Ollama, Apache-2.0 | AI model |
| Vet triage | Fixed red-flag and sign table (reviewed text, no doses) | Rule-based guide |
| Photo screening | None installed. Experimental workflow, evaluation harness `tools/ai_eval/` for ONNX models | Experimental |

XGBoost, scikit-learn and PyTorch are not used yet. A farm has, at most, a few hundred milk days, which is too little to train a model that beats the trend model honestly. The evaluation harness is where a trained model would have to prove itself first.

## 7. Infrastructure

- Today: none. The engine runs in the browser (and later on the phone) on records already loaded.
- Optional: one Linux server with Docker and Ollama (`docs/ai/OLLAMA_SERVER.md`), reachable only by Cloud Functions.

## 8. Security

- Tenant isolation: the engine gets one farm's records, loaded with the person's own Firestore access.
- Role-aware display: `shared/aiRoles.ts`.
- `aiLog` stores feature, outcome, duration and method only. No names, numbers or figures.
- Admin AI pages read `platform/config`, `aiLog` (collection group, counts only) and `tenants` fields. Opening a farm's records still goes through the existing read-only "open farm" with its audit.
- Optional LLM: only the question and calculated figures leave the farm, via Cloud Functions, to the farm owner's own server, with names, phones and tags removed (`shared/aiPrivacy.ts`).
- Photos: images only, 5 MB or less, own farm (`storage.rules` already). Photos are checked for type and size before saving.

## 9. Dependencies

No new npm or pub packages for phase 1. The evaluation harness uses Python `onnxruntime`, `numpy` and `pillow` (dev tool only, not shipped).

## 10. Sequence

1. Decision and map (this file).
2. Shared engine and tests.
3. Records and rules (`milkBatches`, `storageReadings`, `healthAssessments`, `aiAlertStates`, `aiLog`, `features.ai`, `config.ai`).
4. Web AI section and module cards.
5. Admin AI Control Centre.
6. Photo screening workflow and evaluation harness.
7. Checks, screenshots, PR.
8. Phase 2: Dart port and phone screens, which need Flutter.
9. Phase 3, optional: Ollama server and the `aiAsk` function.

## Phone AI (phase 2) — what was built

- Engine: `lib/core/ai/*.dart` is a by-hand Dart port of `shared/ai*.ts`. `test/core/ai/ai_parity_test.dart` runs both engines over the same six farms (`tools/ai_parity/`) and fails on any difference. After changing `shared/ai*.ts`, run `node tools/ai_parity/make_farms.mjs && node tools/ai_parity/snapshot.mjs`, then update the Dart port until the test passes.
- Data: `AiRepository` reads the phone's saved records (works offline). It writes alert states, milk batches, temperature readings, shelf rules, vet checks and the usage log through the same journal as everything else. `healthAssessments` and `storageReadings` are append-only on the phone, like the rules.
- Screens: More → **AI Intelligence** (`/more/ai`) and one page per tool (`/more/ai/:module`), plus an insights strip on Home. Code is in `lib/sectors/cattle/ai/presentation/`.
- Not on the phone yet: platform AI on/off switches and farm feature flags (the phone uses the default settings), the Ollama model call (privacy helpers are ported), and photo screening models (only a photo-quality check runs).
