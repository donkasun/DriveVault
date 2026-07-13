/**
 * Auth form validation. Messages and rules match Flutter's TextFormField
 * validators in login_screen.dart / signup_screen.dart exactly.
 */

/** Flutter's validator regex, ported verbatim. */
const EMAIL_RE = /^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$/;

export function validateEmail(value: string): string | null {
  if (!value.trim()) return 'Please enter your email';
  if (!EMAIL_RE.test(value.trim())) return 'Please enter a valid email address';
  return null;
}

export function validatePassword(value: string): string | null {
  if (!value) return 'Please enter your password';
  if (value.length < 6) return 'Password must be at least 6 characters';
  return null;
}

/** Signup says "a password" where login says "your password" — keep both. */
export function validateNewPassword(value: string): string | null {
  if (!value) return 'Please enter a password';
  if (value.length < 6) return 'Password must be at least 6 characters';
  return null;
}

export function validateConfirmPassword(password: string, confirm: string): string | null {
  if (!confirm) return 'Please confirm your password';
  if (confirm !== password) return 'Passwords do not match';
  return null;
}
