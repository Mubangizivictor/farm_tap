# 0028 Three-layer AI: built-in first, AI only when needed, a daily allowance enforced on the server

Status: proposed by Claude for Victor (7 Nov 2026). Builds on 0025 (free engines), 0026 (Photo Check) and 0027 (the chat).

## Why

Until now the chat sent **every** question to Gemini when online, even "how much milk today?", and the daily limit was only counted in the app. That cannot scale to 10,000 farms: every number question used a Gemini answer, and anyone could go past the limit. FarmTap must work fully without AI; AI is an extra.

## The three layers

| Layer | What answers | Costs | Limit |
|---|---|---|---|
| 1. Records | Look-ups in the farm's records ("How many cows do I have?") | Nothing | None |
| 2. Built-in intelligence | Calculations, statistics, rules: milk trends and drops, forecasts, feed, breeding and calving dates, vaccinations due, money, unusual costs, stock, record gaps | Nothing | None |
| 3. AI assistant | Gemini, only for reasoning and explanations ("Why is milk declining?", "Recommend improvements…") and for photos and files | One AI answer | 10 per farm per day (set in the admin page) |

- **Classifier** (`shared/aiRoute.ts`, Dart `lib/core/ai/ai_route.dart`): a question goes to the AI only when it asks for reasoning (why, explain, recommend, causes, symptoms…), carries a file, or nothing built in can answer it. When a built-in answer exists it is used, and for AI questions it is sent along as facts. Built-in answers come back at once, without the AI spinner, labelled "Calculated from your farm records". AI answers are labelled "AI-generated".
- **New built-in insights** (`shared/aiInsights.ts`, Dart `ai_insights.dart`): milk against the previous recording (120 L → 85 L = "declined by 29.2%… Review animal health, feeding records and recent management changes."), incomplete animal records, "how much did I spend", and a farm summary. Both become alerts on Home (milk drop, record gaps). A health problem is only ever called a possibility; nothing is diagnosed.

## The daily AI allowance

- Counts **successful AI answers only**. Built-in answers, failures, timeouts, invalid questions, refusals and cached repeats count nothing.
- **Per farm**: everyone on the farm shares it. Different farms never share it, and nobody can read another farm's count.
- **Resets at midnight Africa/Kampala**, worked out on the server, never the phone's clock (timezone is a setting).
- **Concurrency-safe**: the server reserves one answer in a Firestore transaction before asking Gemini, keeps it when an answer comes back and gives it back when the request fails. A reservation from a crashed request lapses by itself. 25 questions at once with 10 left: exactly 10 are answered (tested).
- **Warnings**: at 80% ("You're approaching your daily AI limit…") and at 100% ("Your daily AI allowance has been reached."). The assistant stays open: built-in answers keep working.
- **Errors A to G** (limit, unavailable, connection, timeout, switched off, invalid, provider capacity) plus "too many questions at once" have fixed, friendly texts. Raw Google or Firebase errors are never shown to farmers; admins see them under Admin > AI Control Centre > Latest provider errors (server route) or the browser console (pilot route).

## Where it runs

- `functions/src/ai.ts`: callables `aiAssistant` (ask; streams the text) and `aiUsageNow` (the meter). `functions/src/aiServer.ts` holds the rules; `functions/src/aiProviders.ts` the provider interface and `GeminiProvider` (Gemini Developer API, same free tier the apps used). Another provider is one more class there plus an id in `AI_PROVIDERS`. No new paid provider was added.
- The server checks sign-in and farm membership (never trusting the farm id the app sends), the platform and farm AI switches, validates every field and size, limits each person to 6 AI questions a minute, chooses the model and the instructions itself, removes phone numbers and emails, trims history to the input cap, retries with back-off (at most 2 retries, model fallback), and logs.
- The Gemini key is read from `platformSecrets/gemini_api_key` (paste it in Admin > APIs and keys) or `GEMINI_API_KEY`. No app can read it.
- **Cache**: a repeated question with the same facts from the same farm is answered from `tenants/{t}/aiCache` for 6 hours, free. Never shared between farms; new farm facts make a new key, so stale numbers are not reused. Built-in calculations are never cached.

### New Firestore paths (rules and rules tests updated)

- `tenants/{t}/aiUsage/{day}`: today's count. Farm members read it; only the server writes.
- `tenants/{t}/aiCache/{hash}`: server only (no app reads it, not even the farm or the panel).
- `aiStats/{day}`, `aiStats/{day}/farms/{t}`: totals for the AI Control Centre (requests, answered, failed, limit reached, cached, average time, tokens, estimated cost, provider state). Admins with farms, support or settings access.
- `aiErrors/{id}`: provider errors (key removed), settings admins only. Has `expireAt`: add a TTL policy on `expireAt` for `aiErrors`, `aiCache` and `aiRate` in the Firebase console so they clean themselves up.
- `aiRate/{uid}`: questions per minute, server only.

## Settings (Admin > AI Control Centre > AI assistant), no app release needed

`platform/config.ai.assistant`: on/off, route, provider, model, daily limit (default 10; 0 = off), warning % (80), timezone (Africa/Kampala), longest question (2,000 characters), wait (60 s), longest answer (1,500 tokens), most sent (8,000 tokens), cache hours (6), questions per person per minute (6), prices for the cost estimate (0 on the free tier). Old configs without `assistant` follow the Photo Check switch and model as before.

## Route: pilot until Blaze (Victor's choice, 7 Nov 2026)

- `route: 'client'` (default): the apps call Gemini themselves through Firebase AI Logic, exactly as today. The classifier, built-in answers, meter, warnings and error texts all work, but the count comes from the farm's AI log and **is not enforced**: a determined user could go past it.
- `route: 'server'`: everything above, enforced. Needs: Blaze plan, `firebase deploy --only functions:payments:aiAssistant,functions:payments:aiUsageNow,firestore:rules`, the Gemini key saved as `gemini_api_key`, then set Route to "Secure server" in the admin page.
- After switching to the server, turn off Firebase AI Logic for the chat in the Firebase console (or restrict its API key) so the old direct path cannot be used to go around the limit. Photo Check (decision 0026) still uses it; moving Photo Check to the server is the next step.

## Not done / to check

- Phone code (Dart port, server call, meter, banners) was written in a cloud session without Flutter (the Flutter and Firestore-emulator downloads are blocked there). Run `dart format -l 120 lib test && flutter analyze && flutter test test/core/ai` and `cd firestore && npm test` on a computer before merging.
- Phone: no streaming on the server route yet (the answer arrives whole). New phone labels are in `ai_usage_widgets.dart` and `ai_quota.dart`, not yet in the ARB files.
- Photo Check still counts on the device (its own limit). App Check is not enforced on the callables (the phone's App Check set-up is unknown); sign-in and membership are.
