# 0025 — Free AI Intelligence (replaces the Gemini plan in 0010)

- Status: accepted (2026-11-06)
- Date: 2026-11-06
- Decided by: Mubangizi Victor (owner): "AI must be free … no paid AI APIs"
- Replaces: decision 0010 and ROADMAP section 13's technology line ("Firebase AI Logic + Gemini"). AI-03 (safety framing), AI-04 (privacy) and AI-06 (history) still apply. AI-05 (30 paid questions a month) is dropped: nothing is charged per question.
- Full map: `docs/ai/AI_IMPLEMENTATION_MAP.md`

## Decision

1. **No paid AI service.** No OpenAI, Gemini, Claude, or any per-request, per-token or per-image API. Nothing in FarmTap sends farm data to a public AI service.
2. **Calculated first.** Most of what farmers need ("how much milk today", "which cows are dropping", "when does feed run out") is answered exactly from their own records with plain calculations and statistics. These answers are labelled **Calculated** or **Statistical**, never "AI", so nobody mistakes a sum for a guess.
3. **One shared engine.** The rules live in `shared/ai*.ts` (TypeScript), copied into the web app and Cloud Functions by `shared/sync.mjs`. The phone gets a Dart port of the same rules next (`lib/core/ai/`), checked against the same test cases.
4. **Language model optional and self-hosted.** The assistant works with no model at all. A Super Admin can later connect a self-hosted Ollama server running Qwen3 (Apache-2.0; note Qwen2.5-3B is *not* Apache — it uses the Qwen Research licence, so it is not used) in the AI Control Centre. When connected, the model only rephrases and routes questions. All numbers still come from the calculations, and only those numbers are sent, with no names, phone numbers, farm names or GPS. If the server is down, FarmTap falls back to the calculated answers.
5. **Photo screening is experimental.** No open, commercially licensed, validated model for cattle skin, eye, wound, lameness or mastitis screening was found (checked 6 Nov 2026: published lumpy-skin studies and Roboflow/Kaggle datasets are small, single-region, and either unlicensed for commercial use or released without a model). The photo workflow is built and saves to the animal's health history, but every result says "No screening model installed — ask your vet", until a model passes the evaluation harness in `tools/ai_eval/`. FarmTap never claims to detect a disease that a model has not been trained and tested on.
6. **Vet safety.** The Vet Assistant shows *possible* causes and red-flag warning signs from a fixed, reviewed table. It never gives a diagnosis, a drug or a dose, and every result has "Call your vet".
7. **Roles.** Existing roles only: owner, manager, clerk, worker, plus the phone's staff titles (vet, herdsman). Money and finance AI are for owner and manager, as Money already is. Firestore rules stay the protection; the AI reads only what the signed-in person can already read.
8. **New records** (phone, web and rules together):
   - `milkBatches`: milk kept on the farm (litres, when it was collected, cooled or not, sold or thrown away).
   - `storageReadings`: a temperature reading of a can or cooler.
   - `healthAssessments`: a saved Vet Assistant or photo-screening result (append-only).
   - `aiAlertStates`: an alert acknowledged or resolved.
   - `aiLog`: one line per AI request (feature, ok, milliseconds, method). It holds no farm figures, so the AI Control Centre can count use without opening farm records.
9. **Switches.** `platform/config.ai` turns AI and each module on or off for all farms; `tenants/{t}.features.ai` turns it off for one farm. Both are set only from the admin panel, with the audit log.

## Costs

- Software and models: UGX 0.
- With no model server (today): UGX 0. Everything runs in the browser or phone from records already loaded.
- If an Ollama server is added later: you pay the host, not per question. Roughly USD 10–40 a month for a small CPU server running Qwen3 4B (slow, about 5–20 seconds an answer), more for a GPU. See `docs/ai/OLLAMA_SERVER.md`.

## Not done yet

- Phone (Flutter) screens and the Dart port: Flutter cannot run in the cloud session where this was built. Next step, on a computer with Flutter.
- A real photo-screening model (none qualifies; see point 5).
