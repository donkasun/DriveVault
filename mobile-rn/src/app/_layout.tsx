import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { Stack } from 'expo-router';
import * as SplashScreen from 'expo-splash-screen';
import { StatusBar } from 'expo-status-bar';
import { useEffect, useRef } from 'react';

import { authRepository } from '@/features/auth/repository';
import { useAuthStore } from '@/features/auth/store';
import { setAccessTokenProvider } from '@/lib/api-client';
import { Colors } from '@/constants/theme';

SplashScreen.preventAutoHideAsync();

// Bridge auth → api-client without a circular import: the client asks for a
// token, the auth repository supplies it.
setAccessTokenProvider(() => authRepository.getIdToken());

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

  useEffect(() => {
    return authRepository.onAuthStateChanged(setUser);
  }, [setUser]);

  useEffect(() => {
    if (status !== 'loading' && !splashHidden.current) {
      splashHidden.current = true;
      void SplashScreen.hideAsync();
    }
  }, [status]);

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
