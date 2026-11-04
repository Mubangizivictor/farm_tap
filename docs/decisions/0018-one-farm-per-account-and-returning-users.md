# 0018 — One farm per account, returning users and FarmTap-named Google sign-in

- Status: accepted (2026-11-03), asked for by the owner in the project chat
- Date: 2026-11-03
- Decided by: Mubangizi Victor (owner)
- Screens: A02 (sign-in), A07 (farm picker), B10 (farm ready), N03 (help)
- Overrides: nothing in the binding rules. Sign-in is still Google, Apple and email only (rule 4).

## Why
1. Google's sign-in sheet said "Sign in to farm-tap-1dd15.firebaseapp.com". That looks like a scam to a farmer.
2. A signed-in person saw "Choose a farm" every time they opened the app, which felt like being logged out.
3. "Choose a farm" had no context ("You have access to 1 places") and offered "Add another farm" to everyone, so one paid farm could run a dairy, a piggery and a poultry unit.

## Decision
1. **Native Google sign-in on phones.** Android and iOS use the `google_sign_in` package and give its ID token to Firebase (`signInWithCredential`). The sheet now shows the app name from the Google OAuth consent screen ("FarmTap"), not the Firebase web domain. Other platforms keep Firebase's browser flow. The OAuth client ids are in `GoogleClientIds` (not secrets). Signing out also forgets the Google account, so the next sign-in shows the account chooser.
2. **Stay signed in until you sign out.** Firebase already keeps the account on the phone. The splash now sends a signed-in person to `/farms?auto=1`, which opens the farm they used last on this phone (remembered per account) or their only farm. They see "Welcome back, Victor · Opening Rwemera Dairy Farm" with the farm's picture, then Home. Nobody is sent back to sign-in unless they sign out.
3. **A07 redesigned.** Each farm card shows its picture by sector (cow for dairy, shop for a centre, sector icon for poultry, pigs and the rest), name, kind ("Dairy farm and milk centre", "Poultry"), village and district, herd ("42 cows", "300 birds"), your role, and its trial progress ("2 of 7 days left"), payment date or read-only note, with an Open button. With no farm: "Welcome, Victor. Let's set up your farm" and one button. A new phone with no internet: "Can't load your farm" instead of offering to set up a new one.
4. **One account owns one farm.** "Add another farm" shows only when the account's `farmLimit` is higher than the farms it owns. `users/{uid}.farmLimit` is set by Victorbee (admin panel or console) for the multi-farm plan; the app can never change it.
   - Server: the farm, its owner membership and `users/{uid}.ownedFarms + 1` are written in one batch. The rules refuse a new farm unless `ownedFarms` goes up by exactly one and was below `farmLimit` (default 1). `ownedFarms` can never go down and the user document can no longer be deleted. Tests: `firestore/rules.test.mjs` "one farm per account".
   - If someone still reaches B10 with a farm already, it says "This account already has a farm…" with "Talk to us on WhatsApp" (message pre-filled).
   - The only other mention is a quiet "Running more than one farm?" row in Help & support (N03), which opens WhatsApp to the support line.

## Small additions (not asked for, found while building)
- Farm list cached on the phone now keeps sector, village, herd size and the "both" type, so the cards work offline.
- `farmLimitReached` failure on B10 instead of the generic "could not create".
- "Signed in as farmtap.ug@gmail.com" under the farm list, and "Use another account" on the no-farm screen.

## Not done here / owner actions
- Existing accounts made before today have no `ownedFarms`, so each of them could still make one more farm. Set `ownedFarms: 1` on those `users` documents in the Firebase console (only test accounts today).
- Firebase and Google Cloud console steps (consent screen name and logo, SHA-1 for release builds): see the thread reply of 3 Nov 2026.
- Multi-farm plan price: Victor to decide with the other plans.
