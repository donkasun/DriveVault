/**
 * Maps Firebase auth error codes to user-friendly messages.
 * Parity with Flutter `mobile/lib/features/auth/presentation/auth_error_message.dart`.
 */

const GENERIC = 'Something went wrong. Please try again';

/** Firebase JS prefixes codes with `auth/` (e.g. `auth/wrong-password`). */
function codeOf(error: unknown): string | null {
  if (error && typeof error === 'object' && 'code' in error) {
    const code = (error as { code: unknown }).code;
    if (typeof code === 'string') return code.replace(/^auth\//, '');
  }
  return null;
}

export function authErrorMessage(error: unknown): string {
  switch (codeOf(error)) {
    case 'wrong-password':
    case 'invalid-credential':
    case 'user-not-found':
      return 'Incorrect email or password';
    case 'email-already-in-use':
      return 'An account already exists with this email';
    case 'invalid-email':
      return 'Enter a valid email address';
    case 'weak-password':
      return 'Password must be at least 6 characters';
    case 'too-many-requests':
      return 'Too many attempts. Try again later';
    case 'network-request-failed':
      return 'No internet connection';
    default:
      return GENERIC;
  }
}
