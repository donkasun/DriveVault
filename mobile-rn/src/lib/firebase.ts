/**
 * Firebase bootstrap. Auth only — DriveVault never uses Firestore (CLAUDE.md).
 */

import AsyncStorage from '@react-native-async-storage/async-storage';
import { getApp, getApps, initializeApp, type FirebaseApp } from 'firebase/app';
import {
  getAuth,
  getReactNativePersistence,
  initializeAuth,
  type Auth,
} from 'firebase/auth';

const firebaseConfig = {
  apiKey: process.env.EXPO_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.EXPO_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.EXPO_PUBLIC_FIREBASE_PROJECT_ID,
  appId: process.env.EXPO_PUBLIC_FIREBASE_APP_ID,
  messagingSenderId: process.env.EXPO_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
};

export function getFirebaseApp(): FirebaseApp {
  return getApps().length ? getApp() : initializeApp(firebaseConfig);
}

let auth: Auth | undefined;

/**
 * Auth singleton with AsyncStorage persistence so the session survives reloads
 * (parity with Flutter, where FirebaseAuth persists natively).
 */
export function getFirebaseAuth(): Auth {
  if (auth) return auth;

  const app = getFirebaseApp();
  if (getReactNativePersistence) {
    auth = initializeAuth(app, {
      persistence: getReactNativePersistence(AsyncStorage),
    });
  } else {
    // Web / test environments: fall back to the default persistence.
    auth = getAuth(app);
  }
  return auth;
}
