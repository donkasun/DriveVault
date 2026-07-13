/**
 * Auth session store. Global state per docs/best-practices.md §4 — session only,
 * never server data (that lives in the TanStack Query cache).
 */

import { create } from 'zustand';

import type { AuthStatus, AuthUser } from './types';

type AuthState = {
  status: AuthStatus;
  user: AuthUser | null;
  /** Called from the onAuthStateChanged subscription in the root layout. */
  setUser: (user: AuthUser | null) => void;
};

export const useAuthStore = create<AuthState>((set) => ({
  status: 'loading',
  user: null,
  setUser: (user) =>
    set({
      user,
      status: user ? 'signedIn' : 'signedOut',
    }),
}));
