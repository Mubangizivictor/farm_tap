# FarmTap AI Intelligence — guide

Decision: `docs/decisions/0025-free-ai-intelligence.md`. Map: `AI_IMPLEMENTATION_MAP.md`.

## In one paragraph

AI Intelligence reads a farm's own records (milk, animals, treatments,
breeding, feed, money, milk batches) and tells the farmer what needs
attention, why, and what to do. It is free: no paid AI service, nothing sent
to an AI company. Each answer is labelled with how it was made:
**Calculated** (sums and dates from the records), **Statistical estimate**
(forecasts and unusual days, with a confidence), **Rule-based guide** (the vet
guide) or **Experimental** (photo screening, no model yet). When there are not
enough records, it says so instead of guessing.

## Where it is

| Web page | What it does |
|---|---|
| `/ai/` | Today's AI farm insights, risk counts, all modules |
| `/ai/assistant/` | Farm Assistant: questions answered from the records |
| `/ai/vet/` | Vet Assistant: signs → possible causes, warning signs, when to call the vet; saved to `healthAssessments` |
| `/ai/screening/` | Photo for the vet, with a photo-quality check. Experimental: no model |
| `/ai/milk/` | Day, week, month, cows dropping, unusual days, milk not accounted for |
| `/ai/quality/` | Milk batches, cooler temperatures, use-by from the farm's rule, centre rejections |
| `/ai/predictions/` | 7- and 30-day herd forecast, each cow, lactation stage |
| `/ai/feed/`, `/ai/inventory/` | Feed left, run-out dates, feed cost a litre, drug reorder |
| `/ai/breeding/`, `/ai/health/` | Calvings, checks, heats, open cows, repeat illness, vaccinations |
| `/ai/finance/` | Months, cost a litre, unusual expenses, next-month estimate (owner and manager) |
| `/ai/reports/` | "Milk report for last month" → table, CSV, print or PDF |
| `/ai/risks/`, `/ai/alerts/` | Every finding by level; mark seen or resolved |
| Home, Milk, Feeds, Health, Money, Breeding, Herd → animal | AI cards inside the existing pages |
| `/admin/ai/` | AI Control Centre: switches, engines, use and failures, farms |

## Rules that keep it honest

- Numbers only from records. Forecasts need 14 recorded days (21 for 30 days).
- Unusual means at least 3 robust standard deviations from the farm's own normal.
- Dates for calving and heat are estimates (283 and 21 days) unless a vet check confirms.
- The vet guide never names a drug or a dose, and always says to call the vet.
- Photo screening says "No model" until a model passes `tools/ai_eval/`.
- Use-by times are the farm's own rule (default 48 h at 4 °C or colder, 3 h warm) and never a safety test.
- Money AI only for owners and managers. Firestore rules still decide what anyone can read.
- The AI log (`aiLog`) keeps only feature, ok, milliseconds and method.

## Changing the engine

The rules are in `shared/ai*.ts`. Edit there, run `node shared/sync.mjs`, then
`cd webapp && npm run check`. Tests: `webapp/src/lib/ai.test.ts`.

## Phone app (next)

The phone needs the same engine in Dart (`lib/core/ai/`), checked against the
same cases as `ai.test.ts`, plus an AI tab and cards. It also needs the new
collections (`milkBatches`, `storageReadings`, `healthAssessments`,
`aiAlertStates`, `aiLog`) added to its sync. This was not done in the cloud
session because Flutter could not be installed there; it runs fully offline
once built, since everything is worked out on the phone.
