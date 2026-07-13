/** Parity with Flutter `mobile/lib/features/auth/presentation/signup_screen.dart`. */

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

import { AppButton } from '@/components/app-button';
import { AuthField } from '@/components/auth-field';
import { BrandHeader } from '@/components/brand-header';
import { GoogleLogo } from '@/components/google-logo';
import { Colors, Spacing } from '@/constants/theme';
import { authErrorMessage } from '../error-message';
import { authRepository } from '../repository';
import { useGoogleSignIn } from '../use-google-sign-in';
import {
  validateConfirmPassword,
  validateEmail,
  validateNewPassword,
} from '../validation';
import { AuthErrorBanner } from './auth-error-banner';
import { TermsFootnote } from './terms-footnote';

export function SignupScreen() {
  const router = useRouter();
  const google = useGoogleSignIn();

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);

  const [emailError, setEmailError] = useState<string | null>(null);
  const [passwordError, setPasswordError] = useState<string | null>(null);
  const [confirmError, setConfirmError] = useState<string | null>(null);
  const [formError, setFormError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const busy = submitting || google.loading;

  async function onCreateAccount() {
    const emailIssue = validateEmail(email);
    const passwordIssue = validateNewPassword(password);
    const confirmIssue = validateConfirmPassword(password, confirm);
    setEmailError(emailIssue);
    setPasswordError(passwordIssue);
    setConfirmError(confirmIssue);
    if (emailIssue || passwordIssue || confirmIssue) return;

    setSubmitting(true);
    setFormError(null);
    try {
      // Sends the verification email, then lands on /home — a soft nudge, not a
      // gate (CLAUDE.md). The root layout's auth listener does the redirect.
      await authRepository.createUserWithEmailAndPassword(email.trim(), password);
    } catch (error) {
      setFormError(authErrorMessage(error));
    } finally {
      setSubmitting(false);
    }
  }

  const googleError = google.error ? authErrorMessage(google.error) : null;

  return (
    <View style={styles.screen}>
      <BrandHeader title="Get started" tagline="Every fill-up, service and document." />

      <KeyboardAvoidingView
        style={styles.flex}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
        <ScrollView contentContainerStyle={styles.content} keyboardShouldPersistTaps="handled">
          <AuthErrorBanner message={formError ?? googleError} />

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

          <View style={styles.gap} />

          <AuthField
            label="PASSWORD"
            value={password}
            onChangeText={setPassword}
            error={passwordError}
            secureTextEntry={!showPassword}
            textContentType="newPassword"
            placeholder="••••••••"
            prefix={<Ionicons name="lock-closed-outline" size={20} color={Colors.textMuted} />}
            suffix={
              <EyeToggle visible={showPassword} onPress={() => setShowPassword((v) => !v)} />
            }
          />

          <View style={styles.gap} />

          <AuthField
            label="CONFIRM PASSWORD"
            value={confirm}
            onChangeText={setConfirm}
            error={confirmError}
            secureTextEntry={!showConfirm}
            textContentType="newPassword"
            placeholder="••••••••"
            prefix={<Ionicons name="lock-closed-outline" size={20} color={Colors.textMuted} />}
            suffix={<EyeToggle visible={showConfirm} onPress={() => setShowConfirm((v) => !v)} />}
          />

          <View style={styles.gapLarge} />

          <AppButton
            label="Create account"
            onPress={onCreateAccount}
            loading={submitting}
            disabled={busy}
          />

          <Text style={styles.or}>or</Text>

          <AppButton
            label="Continue with Google"
            variant="secondary"
            onPress={google.signIn}
            loading={google.loading}
            disabled={busy || !google.ready}
            icon={<GoogleLogo />}
          />

          <View style={styles.signInRow}>
            <Text style={styles.signInPrompt}>Already have an account?</Text>
            <Pressable
              accessibilityRole="button"
              disabled={busy}
              onPress={() => router.back()}
              style={styles.signInButton}
            >
              <Text style={styles.signInText}>Sign in</Text>
            </Pressable>
          </View>

          <View style={styles.flex} />

          <TermsFootnote />
        </ScrollView>
      </KeyboardAvoidingView>
    </View>
  );
}

function EyeToggle({ visible, onPress }: { visible: boolean; onPress: () => void }) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={visible ? 'Hide password' : 'Show password'}
      onPress={onPress}
      style={styles.eye}
    >
      <Ionicons
        name={visible ? 'eye-off-outline' : 'eye-outline'}
        size={20}
        color={Colors.textMuted}
      />
    </Pressable>
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
  content: {
    flexGrow: 1,
    paddingHorizontal: Spacing.four,
    paddingTop: 28,
    paddingBottom: Spacing.four,
  },
  gap: {
    height: Spacing.three,
  },
  gapLarge: {
    height: Spacing.four,
  },
  eye: {
    paddingHorizontal: 14,
    paddingVertical: Spacing.two,
  },
  or: {
    textAlign: 'center',
    fontSize: 14,
    color: Colors.textMuted,
    marginVertical: 20,
  },
  signInRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 20,
  },
  signInPrompt: {
    fontSize: 14,
    color: Colors.textMuted,
  },
  signInButton: {
    paddingHorizontal: 6,
    paddingVertical: Spacing.two,
  },
  signInText: {
    fontSize: 14,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
});
