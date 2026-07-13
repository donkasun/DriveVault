/**
 * Soft nudge — never a gate (CLAUDE.md). Shows only for password-provider
 * users whose email is unverified; dismissible per session (resets on app
 * restart, no persistence). Parity with Flutter
 * `features/auth/presentation/widgets/verify_email_banner.dart`.
 */

import { useState } from 'react';
import { Alert, Pressable, StyleSheet, Text, View } from 'react-native';

import { Colors } from '@/constants/theme';
import { authRepository } from '@/features/auth/repository';
import { useAuthStore } from '@/features/auth/store';

export function VerifyEmailBanner() {
  const user = useAuthStore((s) => s.user);
  const [dismissed, setDismissed] = useState(false);

  const unverified = user != null && !user.emailVerified;
  if (dismissed || !user?.isPasswordProvider || !unverified) {
    return null;
  }

  const email = user.email ?? '';

  const handleResend = async () => {
    await authRepository.sendEmailVerification();
    Alert.alert('Verification link sent — check your inbox.');
  };

  return (
    <Pressable onPress={handleResend} style={styles.card}>
      <Text style={styles.icon}>✉️</Text>
      <View style={styles.textCol}>
        <Text style={styles.title}>Verify your email</Text>
        <Text numberOfLines={1} style={styles.subtitle}>
          {`Tap to resend the link to ${email}`}
        </Text>
      </View>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel="Dismiss"
        hitSlop={8}
        onPress={() => setDismissed(true)}
        style={styles.dismiss}
      >
        <Text style={styles.dismissGlyph}>✕</Text>
      </Pressable>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.photoUploadTint,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: 'rgba(251,191,36,0.30)', // AppColors.warning @ 30% — one-off, verify_email_banner.dart line 78
    paddingHorizontal: 14,
    paddingVertical: 12,
  },
  icon: {
    fontSize: 20,
  },
  textCol: {
    flex: 1,
    marginLeft: 12,
  },
  title: {
    fontSize: 13,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  subtitle: {
    marginTop: 2,
    fontSize: 12,
    fontWeight: '400',
    color: Colors.textMuted,
  },
  dismiss: {
    marginLeft: 8,
    padding: 4,
  },
  dismissGlyph: {
    fontSize: 14,
    color: Colors.textMuted,
  },
});
