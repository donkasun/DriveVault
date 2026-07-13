/** Parity with Flutter `mobile/lib/features/auth/presentation/login_screen.dart`. */

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
import { AuthErrorBanner } from './auth-error-banner';
import { TermsFootnote } from './terms-footnote';
import { validateEmail, validatePassword } from '../validation';

export function LoginScreen() {
  const router = useRouter();
  const google = useGoogleSignIn();

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [emailError, setEmailError] = useState<string | null>(null);
  const [passwordError, setPasswordError] = useState<string | null>(null);
  const [formError, setFormError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const busy = submitting || google.loading;

  async function onSignIn() {
    const emailIssue = validateEmail(email);
    const passwordIssue = validatePassword(password);
    setEmailError(emailIssue);
    setPasswordError(passwordIssue);
    if (emailIssue || passwordIssue) return;

    setSubmitting(true);
    setFormError(null);
    try {
      await authRepository.signInWithEmailAndPassword(email.trim(), password);
      // The auth listener in the root layout performs the redirect.
    } catch (error) {
      setFormError(authErrorMessage(error));
    } finally {
      setSubmitting(false);
    }
  }

  const googleError = google.error ? authErrorMessage(google.error) : null;

  return (
    <View style={styles.screen}>
      <BrandHeader title="Welcome back" tagline="Every fill-up, service and document." />

      <KeyboardAvoidingView
        style={styles.flex}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
        <ScrollView
          contentContainerStyle={styles.content}
          keyboardShouldPersistTaps="handled"
        >
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
            secureTextEntry
            textContentType="password"
            placeholder="••••••••"
            prefix={<Ionicons name="lock-closed-outline" size={20} color={Colors.textMuted} />}
            suffix={
              <Pressable
                accessibilityRole="button"
                disabled={busy}
                onPress={() => router.push('/forgot-password')}
                style={styles.forgotButton}
              >
                <Text style={styles.forgotText}>Forgot?</Text>
              </Pressable>
            }
          />

          <View style={styles.gapLarge} />

          <AppButton label="Sign in" onPress={onSignIn} loading={submitting} disabled={busy} />

          <Text style={styles.or}>or</Text>

          <AppButton
            label="Continue with Google"
            variant="secondary"
            onPress={google.signIn}
            loading={google.loading}
            disabled={busy || !google.ready}
            icon={<GoogleLogo />}
          />

          <Pressable
            accessibilityRole="button"
            disabled={busy}
            onPress={() => router.push('/signup')}
            style={styles.createAccount}
          >
            <Text style={styles.createAccountText}>Create an account</Text>
          </Pressable>

          <View style={styles.flex} />

          <TermsFootnote />
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
  forgotButton: {
    paddingHorizontal: 14,
    paddingVertical: Spacing.two,
  },
  forgotText: {
    fontSize: 13,
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  or: {
    textAlign: 'center',
    fontSize: 14,
    color: Colors.textMuted,
    marginVertical: 20,
  },
  createAccount: {
    alignItems: 'center',
    paddingVertical: Spacing.three,
    marginTop: Spacing.one,
  },
  createAccountText: {
    fontSize: 15,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
});
