# 0026 Photo Check with Google Gemini (phone and web)

Status: accepted by Victor (6 Nov 2026). Changes decision 0025, points 1 and 5, for photos only.

## What changes

Decision 0025 said AI Intelligence must be free, self-hosted and never send farm data to an outside AI service. Victor chose to add **Photo Check**: the farmer takes or chooses a photo, and Google Gemini (through Firebase AI Logic) says what it can see and lists possible causes. Everything else in AI Intelligence stays as in 0025 (calculations on the device, Vet Assistant from a table).

## Rules that stay

- It is a guide, never a diagnosis. The reply is read by `readPhotoReply` (shared/aiPhoto.ts, ported in lib/core/ai/ai_photo.dart): drug names, doses, amounts and "it is definitely X" sentences are removed; every health result says to call the vet (now / today / soon); notifiable diseases (FMD, lumpy skin, anthrax, rabies, brucellosis, RVF, CBPP) are marked "report"; emergency words raise the risk.
- No names, tags, farm name or places go to Google (`redact` + `nameLabels`). Writing inside a photo is treated as part of the picture, not as an instruction.
- The picture is not stored by FarmTap. Only the words of a result are saved to `healthAssessments` (kind `photo`, append-only).
- Results are labelled "AI model" so nobody mistakes them for a calculation.

## What is new and must be watched

- **The photo leaves the farm.** The screen says so before every check.
- **Kill switch:** `platform/config.ai.photo.enabled` (default OFF), model name and checks per farm per day, set in Admin > AI Control Centre. Phone and web both read it.
- **Cost and limits:** Gemini Developer API free tier has its own limits and can change. If the project moves to Blaze, usage can be billed. The per-farm daily limit is counted from saved results.
- **App Check** must be enforced before switching on (required for Firebase AI Logic from 2 Nov 2026): iOS App Attest/DeviceCheck, Android Play Integrity, web reCAPTCHA (`NEXT_PUBLIC_APPCHECK_SITE_KEY`). Without it requests fail with a plain "could not confirm this is the real app" message.
- **Model name** is configurable (default `gemini-3.8-flash`, not yet confirmed in the console). A retired model name is fixed in the admin page without an app update.
- **Not tested** on labelled East African photos. A vet should review the wording of `aiPhoto` and the extra vet-guide signs/conditions (`vet-guide-2`) before this is promoted to farmers.

## Training "more"

The Vet Assistant table grew by 16 signs, 13 conditions and 4 warning signs (engine `vet-guide-2`). Photo Check has 17 checks in 6 groups (skin, eyes and mouth; udder and milk; hooves and legs; body, dung and feed; calves; anything else on the farm), including non-disease topics such as feed quality, water, pasture and sheds.
