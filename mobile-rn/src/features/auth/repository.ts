/**
 * Firebase auth operations. Parity with Flutter
 * `mobile/lib/features/auth/data/auth_repository.dart`.
 *
 * Google sign-in is browser-based (expo-auth-session) rather than the native
 * google_sign_in package Flutter uses — see the migration plan §1. The Firebase
 * credential exchange is identical, so the resulting session is the same.
 */

import {
  createUserWithEmailAndPassword,
  GoogleAuthProvider,
  onAuthStateChanged,
  sendEmailVerification,
  sendPasswordResetEmail,
  signInWithCredential,
  signInWithEmailAndPassword,
  signOut,
  type User,
  type UserCredential,
} from 'firebase/auth';

import { getFirebaseAuth } from '@/lib/firebase';
import type { AuthUser } from './types';

/** Maps a Firebase User to the app's session projection. */
export function toAuthUser(user: User | null): AuthUser | null {
  if (!user) return null;
  return {
    uid: user.uid,
    email: user.email,
    emailVerified: user.emailVerified,
    displayName: user.displayName,
    photoUrl: user.photoURL,
    isPasswordProvider: user.providerData.some((p) => p.providerId === 'password'),
  };
}

export const authRepository = {
  currentUser(): User | null {
    return getFirebaseAuth().currentUser;
  },

  onAuthStateChanged(listener: (user: AuthUser | null) => void): () => void {
    return onAuthStateChanged(getFirebaseAuth(), (user) => listener(toAuthUser(user)));
  },

  /** The Bearer token the API client attaches to every request. */
  async getIdToken(): Promise<string | null> {
    const user = getFirebaseAuth().currentUser;
    return user ? user.getIdToken() : null;
  },

  signInWithEmailAndPassword(email: string, password: string): Promise<UserCredential> {
    return signInWithEmailAndPassword(getFirebaseAuth(), email, password);
  },

  /**
   * Sign up, then send a verification email. Verification is a SOFT nudge:
   * the user still lands on /home (CLAUDE.md) — never a hard gate.
   */
  async createUserWithEmailAndPassword(
    email: string,
    password: string,
  ): Promise<UserCredential> {
    const credential = await createUserWithEmailAndPassword(getFirebaseAuth(), email, password);
    await this.sendEmailVerification();
    return credential;
  },

  /** Exchanges a Google OAuth ID token for a Firebase session. */
  signInWithGoogleIdToken(idToken: string): Promise<UserCredential> {
    const credential = GoogleAuthProvider.credential(idToken);
    return signInWithCredential(getFirebaseAuth(), credential);
  },

  signOut(): Promise<void> {
    return signOut(getFirebaseAuth());
  },

  sendPasswordResetEmail(email: string): Promise<void> {
    return sendPasswordResetEmail(getFirebaseAuth(), email);
  },

  /** No-op when there is no user or the address is already verified. */
  async sendEmailVerification(): Promise<void> {
    const user = getFirebaseAuth().currentUser;
    if (user && !user.emailVerified) {
      await sendEmailVerification(user);
    }
  },

  /** Refreshes `emailVerified` from the server (used by the verify banner). */
  async reloadUser(): Promise<void> {
    await getFirebaseAuth().currentUser?.reload();
  },
};
