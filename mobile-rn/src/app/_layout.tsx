import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { Stack } from 'expo-router';
import * as SplashScreen from 'expo-splash-screen';
import { StatusBar } from 'expo-status-bar';
import { useEffect, useRef, useState } from 'react';

import { runMigrations } from '@/db/client';
import { authRepository } from '@/features/auth/repository';
import { useAuthStore } from '@/features/auth/store';
import { setAccessTokenProvider } from '@/lib/api-client';
import { Colors } from '@/constants/theme';

SplashScreen.preventAutoHideAsync();

// Bridge auth → api-client without a circular import: the client asks for a
// token, the auth repository supplies it.
setAccessTokenProvider(() => authRepository.getIdToken());

// Local SQLite read-cache: create tables once at startup, before any route
// renders (best-practices.md §6). Cheap (idempotent CREATE TABLE IF NOT
// EXISTS) so this doesn't meaningfully delay first paint.
const migrationsReady = runMigrations();

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      staleTime: 30_000,
    },
  },
});

export default function RootLayout() {
  const setUser = useAuthStore((s) => s.setUser);
  const status = useAuthStore((s) => s.status);
  const splashHidden = useRef(false);
  const [migrationsDone, setMigrationsDone] = useState(false);

  useEffect(() => {
    return authRepository.onAuthStateChanged(setUser);
  }, [setUser]);

  useEffect(() => {
    let cancelled = false;
    void migrationsReady.then(() => {
      if (!cancelled) setMigrationsDone(true);
    });
    return () => {
      cancelled = true;
    };
  }, []);

  const ready = status !== 'loading' && migrationsDone;

  useEffect(() => {
    if (ready && !splashHidden.current) {
      splashHidden.current = true;
      void SplashScreen.hideAsync();
    }
  }, [ready]);

  // Hold routes until migrations have run once (best-practices.md §6) — the
  // local cache must exist before any screen tries to read/write it.
  if (!ready) return null;

  return (
    <QueryClientProvider client={queryClient}>
      <StatusBar style="dark" />
      <Stack
        screenOptions={{
          headerShown: false,
          contentStyle: { backgroundColor: Colors.background },
        }}
      />
    </QueryClientProvider>
  );
}
