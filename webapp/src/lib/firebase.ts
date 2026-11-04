'use client';

import { getApp, getApps, initializeApp, type FirebaseOptions } from 'firebase/app';
import { browserLocalPersistence, connectAuthEmulator, getAuth, setPersistence, type Auth } from 'firebase/auth';
import { connectFirestoreEmulator, getFirestore, type Firestore } from 'firebase/firestore';

// Same Firebase project as the phone app (farm-tap-1dd15). Online only
// (decision 0017): Firestore keeps its default memory cache, nothing is
// stored for offline use.
const options: FirebaseOptions = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID ?? 'farm-tap-1dd15',
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
  // firebaseapp.com is the only domain Firebase auto-registers as an OAuth redirect URI.
  // Using web.app here breaks redirect sign-in unless that URI is manually added in GCP.
  authDomain: 'farm-tap-1dd15.firebaseapp.com',
};

/** Local testing against `firebase emulators:start` (auth 9099, firestore 8080). */
const emulators = process.env.NEXT_PUBLIC_FIREBASE_EMULATORS === 'true';

/** False until Victor pastes the web app config into webapp/.env.local. */
export const firebaseConfigured = emulators || Boolean(options.apiKey && options.appId);

let auth: Auth | undefined;
let db: Firestore | undefined;

export function firebase(): { auth: Auth; db: Firestore } {
  if (!auth || !db) {
    const app = getApps().length ? getApp() : initializeApp(emulators ? { ...options, apiKey: options.apiKey || 'demo-key', projectId: 'demo-farmtap' } : options);
    auth = getAuth(app);
    // Stay signed in on this browser until the person signs out.
    void setPersistence(auth, browserLocalPersistence);
    db = getFirestore(app);
    if (emulators) {
      connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });
      connectFirestoreEmulator(db, '127.0.0.1', 8080);
    }
  }
  return { auth, db };
}
