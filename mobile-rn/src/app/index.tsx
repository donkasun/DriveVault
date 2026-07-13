/**
 * Auth gate. Mirrors Flutter's go_router redirect: loading → splash, signed out
 * → login, signed in → home (even when the email is unverified — the verify
 * nudge is a banner, never a gate).
 */

import { Redirect } from 'expo-router';
import { ActivityIndicator, StyleSheet, View } from 'react-native';

import { Colors } from '@/constants/theme';
import { useAuthStore } from '@/features/auth/store';

export default function Index() {
  const status = useAuthStore((s) => s.status);

  if (status === 'loading') {
    return (
      <View style={styles.splash}>
        <ActivityIndicator color={Colors.textPrimary} />
      </View>
    );
  }

  return <Redirect href={status === 'signedIn' ? '/home' : '/login'} />;
}

const styles = StyleSheet.create({
  splash: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: Colors.background,
  },
});
