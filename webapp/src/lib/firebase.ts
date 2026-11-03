'use client';

import { getApp, getApps, initializeApp, type FirebaseOptions } from 'firebase/app';
import { browserLocalPersistence, getAuth, setPersistence, type Auth } from 'firebase/auth';
import { getFirestore, type Firestore } from 'firebase/firestore';

// Same Firebase project as the phone app (farm-tap-1dd15). Online only
// (decision 0015): Firestore keeps its default memory cache, nothing is
// stored for offline use.
const options: FirebaseOptions = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID ?? 'farm-tap-1dd15',
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN ?? 'farm-tap-1dd15.firebaseapp.com',
};

/** False until Victor pastes the web app config into webapp/.env.local. */
export const firebaseConfigured = Boolean(options.apiKey && options.appId);

let auth: Auth | undefined;
let db: Firestore | undefined;

export function firebase(): { auth: Auth; db: Firestore } {
  if (!auth || !db) {
    const app = getApps().length ? getApp() : initializeApp(options);
    auth = getAuth(app);
    // Stay signed in on this browser until the person signs out.
    void setPersistence(auth, browserLocalPersistence);
    db = getFirestore(app);
  }
  return { auth, db };
}
