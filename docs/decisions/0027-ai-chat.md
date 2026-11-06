# 0027 One AI chat for the whole farm (phone and web)

Status: accepted by Victor (6 Nov 2026). Builds on 0025 (free engines) and 0026 (Gemini for photos).

## What changes

AI Intelligence now opens into **one chat box**, like Claude or ChatGPT. The farmer types a question and can attach photos, PDFs, text or CSV files, audio or a short video with the plus button. Examples: "Nakato has not eaten since yesterday and her milk is down" with a photo.

- **Online** (Gemini through Firebase AI Logic, same switch as Photo Check: `platform/config.ai.photo`): Gemini answers anything (farm, a sick animal, feed, money, research). When a cow is named (or opened from its page), FarmTap adds the facts it already knows about that cow (age, milk trend, calving, treatments, vaccines due) and, when its own built-in assistant can work out a number, that calculated answer too. Names, tags, the farm name and places are replaced before sending and put back in the reply on the device.
- **Offline, switched off, or limit reached**: the built-in assistant answers simple questions from the records. The chat says why, and that files and photos were not read.
- **Saved to the animal's history**: an online answer about a named cow is saved to `healthAssessments` (kind `chat`: the question, the first 600 characters of the answer, what kind of file was attached, risk, call-the-vet level, engine `chat-1`, model). The files themselves are never stored.
- The old screens (Vet Assistant, Photo Check, Milk, Feed, alerts, reports...) are **not deleted**: Home's alert cards link into them. They sit one tap away under "Insights and tools".

## Safety (unchanged in spirit)

Every model reply goes through `readChatReply` (shared/aiChat.ts, Dart port lib/core/ai/ai_chat.dart): sentences naming a drug, a dose or an amount, or a sure-sounding diagnosis are removed; health answers always point to the vet; emergency words say "call your vet now"; reportable diseases are flagged (a vaccination question is not). Instructions found inside photos or files are ignored by the system prompt.

## Limits to know

- Gemini reads photos, video, audio, PDF and plain text/CSV. It cannot read Word or Excel files; the chat says to save them as PDF or CSV.
- Files are sent inline: at most 5 files and about 14 MB together. Longer videos need Cloud Storage (not built).
- The phone attaches photos and videos only. PDFs and other files on the phone need the `file_picker` package, which the roadmap does not list; add it only with approval.
- The daily limit counts today's successful online chat answers from the farm's AI log. A farmer can still try again offline. Google's own quota is the real backstop.
- Same App Check, billing and model-name cautions as decision 0026. Wording has not been reviewed by a vet.

## Addendum (6 Nov 2026): real errors, Google Search, buttons, chats

The first live chat showed "The answer could not be read" for every question, because every failure was folded into that one message. Changes:

- **Real reasons.** `chatFailureOf` (shared/aiChat.ts, Dart port) sorts Google's error text into network, busy, App Check, setup (Firebase AI Logic not enabled or key rejected), model (name not available), blocked or unreadable. The fallback answer says which, and a "Details for the FarmTap owner" line shows Google's own message.
- **Conversation fix.** Gemini rejects a chat that does not start with the farmer or repeats a side. `chatHistory` now guarantees that; this was the likely cause of failures from the second message onwards.
- **Google Search (grounding).** Online answers use `googleSearch` so general farming questions get current, sourced replies. If the model refuses the tool, the question is asked again without it. Sources are shown as links and Google's "Search suggestions" widget is shown in a sandboxed frame (Google requires it whenever it is returned). Grounding quota on the free tier is not documented in the pages read; check ai.google.dev/gemini-api/docs/pricing.
- **Buttons under an answer.** `chatActions`: a named cow opens that cow; a health answer opens the Vet Assistant and the vet's number; milk, vaccination, breeding, feed and money questions open that section. `chatFollowUps` offers up to three taps to carry on.
- **Chats.** History, search and delete live behind one "Chats" button (no extra sidebar). Chats are kept on the device only (web: localStorage, phone: shared_preferences). Syncing chats between devices would need a Firestore collection, phone sync registration and rules; not built, ask first. Answers about a named cow are still saved to that cow's history in Firestore.
- Answer tools: copy, ask again, follow-up chips, stop (web).
