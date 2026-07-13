/** Session shape the app cares about — a thin projection of Firebase's User. */
export type AuthUser = {
  uid: string;
  email: string | null;
  emailVerified: boolean;
  displayName: string | null;
  photoUrl: string | null;
  /** True when the user signed up with email/password (vs Google). */
  isPasswordProvider: boolean;
};

export type AuthStatus = 'loading' | 'signedOut' | 'signedIn';
