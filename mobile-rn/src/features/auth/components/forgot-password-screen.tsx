/** Parity with Flutter `mobile/lib/features/auth/presentation/forgot_password_screen.dart`. */

import Ionicons from '@expo/vector-icons/Ionicons';
import { useRouter } from 'expo-router';
import { useState } from 'react';
import {
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { AppButton } from '@/components/app-button';
import { AuthField } from '@/components/auth-field';
import { Colors, Spacing } from '@/constants/theme';
import { authErrorMessage } from '../error-message';
import { authRepository } from '../repository';
import { validateEmail } from '../validation';
import { AuthErrorBanner } from './auth-error-banner';

const SUCCESS = 'Password reset email sent! Please check your inbox.';

export function ForgotPasswordScreen() {
  const router = useRouter();
  const insets = useSafeAreaInsets();

  const [email, setEmail] = useState('');
  const [emailError, setEmailError] = useState<string | null>(null);
  const [formError, setFormError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  async function onSendLink() {
    const emailIssue = validateEmail(email);
    setEmailError(emailIssue);
    if (emailIssue) return;

    setSubmitting(true);
    setFormError(null);
    setSuccess(null);
    try {
      await authRepository.sendPasswordResetEmail(email.trim());
      setSuccess(SUCCESS);
    } catch (error) {
      setFormError(authErrorMessage(error));
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <View style={[styles.screen, { paddingTop: insets.top }]}>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel="Back"
        onPress={() => router.back()}
        style={styles.back}
      >
        <Ionicons name="arrow-back" size={24} color={Colors.textPrimary} />
      </Pressable>

      <KeyboardAvoidingView
        style={styles.flex}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
        <ScrollView contentContainerStyle={styles.content} keyboardShouldPersistTaps="handled">
          <Text style={styles.title}>Reset Password</Text>
          <Text style={styles.subtitle}>Enter your email to receive a password reset link.</Text>

          <View style={styles.gapLarge} />

          <AuthErrorBanner message={formError} />

          {success ? (
            <View style={styles.successBanner} accessibilityRole="alert">
              <Text style={styles.successText}>{success}</Text>
            </View>
          ) : null}

          <AuthField
            label="EMAIL"
            value={email}
            onChangeText={setEmail}
            error={emailError}
            keyboardType="email-address"
            textContentType="emailAddress"
            placeholder="you@example.com"
            prefix={<Ionicons name="mail-outline" size={20} color={Colors.textMuted} />}
          />

          <View style={styles.gapLarge} />

          <AppButton
            label="Send Link"
            onPress={onSendLink}
            loading={submitting}
            disabled={submitting}
          />
        </ScrollView>
      </KeyboardAvoidingView>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  flex: {
    flex: 1,
  },
  back: {
    paddingHorizontal: Spacing.three,
    paddingVertical: Spacing.two,
    alignSelf: 'flex-start',
  },
  content: {
    flexGrow: 1,
    paddingHorizontal: Spacing.four,
    paddingTop: Spacing.three,
    paddingBottom: Spacing.four,
  },
  title: {
    fontSize: 28,
    fontWeight: '800',
    color: Colors.textPrimary,
  },
  subtitle: {
    marginTop: Spacing.two,
    fontSize: 14,
    color: Colors.textMuted,
  },
  gapLarge: {
    height: Spacing.four,
  },
  successBanner: {
    padding: 12,
    borderRadius: 10,
    backgroundColor: Colors.successBg,
    marginBottom: Spacing.three,
  },
  successText: {
    fontSize: 14,
    color: Colors.success,
  },
});
