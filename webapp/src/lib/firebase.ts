'use client';

import { getApp, getApps, initializeApp, type FirebaseOptions } from 'firebase/app';
import { browserLocalPersistence, connectAuthEmulator, getAuth, setPersistence, type Auth } from 'firebase/auth';
import { connectFirestoreEmulator, getFirestore, type Firestore } from 'firebase/firestore';

// Same Firebase project as the phone app (farm-tap-1dd15). Online only
// (decision 0017): Firestore keeps its default memory cache, nothing is
// stored for offline use.
// Firebase web API keys are intentionally public — security is enforced by
// Firestore Security Rules and Authentication, not by keeping this key secret.
const FIREBASE_CONFIG: FirebaseOptions = {
  apiKey: 'AIzaSyAA_Ydlo-YTC9jzqFBqwEpYSGFiDv4hTVg',
  appId: '1:913049305053:web:35fb9d4efe7448362ac034',
  messagingSenderId: '913049305053',
  projectId: 'farm-tap-1dd15',
  storageBucket: 'farm-tap-1dd15.firebasestorage.app',
  // Custom domain so the Google sign-in popup shows farmtap.victorbee.com.
  // Requires https://farmtap.victorbee.com/__/auth/handler in GCP OAuth redirect URIs
  // and https://farmtap.victorbee.com in Authorized JavaScript origins — both added.
  authDomain: 'farmtap.victorbee.com',
};

/** Local testing against `firebase emulators:start` (auth 9099, firestore 8080). */
const emulators = process.env.NEXT_PUBLIC_FIREBASE_EMULATORS === 'true';

const options: FirebaseOptions = emulators
  ? { ...FIREBASE_CONFIG, apiKey: 'demo-key', projectId: 'demo-farmtap' }
  : FIREBASE_CONFIG;

export const firebaseConfigured = true;

let auth: Auth | undefined;
let db: Firestore | undefined;

export function firebase(): { auth: Auth; db: Firestore } {
  if (!auth || !db) {
    const app = getApps().length ? getApp() : initializeApp(options);
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
