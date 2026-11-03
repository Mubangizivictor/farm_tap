# FarmTap web (Chrome)

The FarmTap web app for owners and managers, built in Next.js (decision 0017).
It is online only, uses the same Firebase project and data as the phone app,
and is hosted free on Firebase Hosting as a static site.

## One-time setup (Firebase console, free)
1. Project settings → Your apps → **Add app → Web** (name it "FarmTap web"). Copy `apiKey` and `appId`.
2. Authentication → Settings → **Authorized domains**: add `farm-tap-1dd15.web.app` (and your custom domain later).
3. Google Cloud console → APIs & Services → Credentials → the "Web client (auto created by Google Service)" →
   Authorized redirect URIs: add `https://farm-tap-1dd15.web.app/__/auth/handler`.
   This is what makes the Google window say *farm-tap-1dd15.web.app* instead of *firebaseapp.com*.
4. Apple on the web (optional, later): needs an Apple **Services ID** and key, entered in Authentication → Apple.

```zsh
cd ~/Desktop/Apps/farm_tap/webapp
cp .env.example .env.local
open -e .env.local   # paste apiKey and appId
npm install
```

## Run on your Mac
```zsh
cd ~/Desktop/Apps/farm_tap/webapp
npm run dev          # open http://localhost:3000
```
For `npm run dev` keep `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=farm-tap-1dd15.firebaseapp.com` until the site is deployed once.

## Try it with fake data (Firebase emulators, nothing real touched)
```zsh
cd ~/Desktop/Apps/farm_tap/firestore && npm install
npx firebase emulators:start --only auth,firestore --project demo-farmtap --config ../firebase.json
# second Terminal tab:
cd ~/Desktop/Apps/farm_tap/webapp
echo "NEXT_PUBLIC_FIREBASE_EMULATORS=true" > .env.local
npm run dev
```

## Put it online (free Spark plan)
```zsh
cd ~/Desktop/Apps/farm_tap/webapp
npm run check && npm run build
cd ~/Desktop/Apps/farm_tap
npx firebase-tools deploy --only hosting --project farm-tap-1dd15
```
Then open https://farm-tap-1dd15.web.app

## Checks
- `npm run check`: TypeScript, theme-token guard (no hard-coded colours, sizes, fonts or durations outside `src/theme/`), unit tests.
