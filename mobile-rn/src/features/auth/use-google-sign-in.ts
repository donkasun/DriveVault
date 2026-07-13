/**
 * Browser-based Google OAuth → Firebase credential exchange.
 *
 * Flutter uses the native `google_sign_in` package, which has no Expo Go
 * equivalent. Expo Auth Session reaches the same end state (a Firebase session
 * from a Google account) without requiring a dev client — see migration plan §1.
 */

import * as Google from 'expo-auth-session/providers/google';
import * as WebBrowser from 'expo-web-browser';
import { useCallback, useState } from 'react';

import { authRepository } from './repository';

WebBrowser.maybeCompleteAuthSession();

type Result = {
  /** Opens the Google consent screen and completes the Firebase exchange. */
  signIn: () => void;
  /** True while the browser is open or the credential is being exchanged. */
  loading: boolean;
  error: unknown;
  /** True once the OAuth prompt is ready to be shown. */
  ready: boolean;
};

export function useGoogleSignIn(): Result {
  const [request, , promptAsync] = Google.useIdTokenAuthRequest({
    clientId: process.env.EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID,
  });

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<unknown>(null);

  const signIn = useCallback(() => {
    setError(null);
    setLoading(true);

    // promptAsync resolves with the result, so no effect is needed to observe it.
    promptAsync()
      .then(async (result) => {
        // Dismissed or cancelled — not an error, just stop.
        if (result.type !== 'success') return;

        const idToken = result.params.id_token;
        if (!idToken) return;

        await authRepository.signInWithGoogleIdToken(idToken);
        // The root layout's auth listener performs the redirect.
      })
      .catch(setError)
      .finally(() => setLoading(false));
  }, [promptAsync]);

  return { signIn, loading, error, ready: !!request };
}
