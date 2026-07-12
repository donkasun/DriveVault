import 'server-only';

import { cert, getApps, initializeApp, type App } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getMessaging } from 'firebase-admin/messaging';

function createFirebaseApp(): App {
  const existing = getApps();
  if (existing.length > 0) {
    return existing[0];
  }

  const projectId = process.env.FIREBASE_PROJECT_ID;
  const credentialsJson = process.env.FIREBASE_CREDENTIALS_JSON?.trim();

  if (credentialsJson) {
    const serviceAccount = JSON.parse(credentialsJson);
    return initializeApp({ credential: cert(serviceAccount), projectId });
  }

  // No credentials configured (e.g. local dev without a service account, or
  // tests that mock verification entirely) — initialize with just the project
  // id so the SDK doesn't throw at import time.
  return initializeApp({ projectId });
}

declare global {
  var __drivevaultFirebaseApp: App | undefined;
}

const app = globalThis.__drivevaultFirebaseApp ?? createFirebaseApp();

if (process.env.NODE_ENV !== 'production') {
  globalThis.__drivevaultFirebaseApp = app;
}

export const firebaseAuth = getAuth(app);
export const firebaseMessaging = getMessaging(app);
