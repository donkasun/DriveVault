import { authErrorMessage } from './error-message';

/** Firebase JS SDK errors carry codes prefixed with `auth/`. */
const fbError = (code: string) => ({ code, name: 'FirebaseError' });

describe('authErrorMessage', () => {
  it('collapses the three "bad credentials" codes into one message', () => {
    expect(authErrorMessage(fbError('auth/wrong-password'))).toBe('Incorrect email or password');
    expect(authErrorMessage(fbError('auth/invalid-credential'))).toBe(
      'Incorrect email or password',
    );
    expect(authErrorMessage(fbError('auth/user-not-found'))).toBe('Incorrect email or password');
  });

  it('maps the remaining known codes', () => {
    expect(authErrorMessage(fbError('auth/email-already-in-use'))).toBe(
      'An account already exists with this email',
    );
    expect(authErrorMessage(fbError('auth/invalid-email'))).toBe('Enter a valid email address');
    expect(authErrorMessage(fbError('auth/weak-password'))).toBe(
      'Password must be at least 6 characters',
    );
    expect(authErrorMessage(fbError('auth/too-many-requests'))).toBe(
      'Too many attempts. Try again later',
    );
    expect(authErrorMessage(fbError('auth/network-request-failed'))).toBe(
      'No internet connection',
    );
  });

  it('handles codes without the auth/ prefix too', () => {
    expect(authErrorMessage(fbError('wrong-password'))).toBe('Incorrect email or password');
  });

  it('falls back to the generic message', () => {
    expect(authErrorMessage(fbError('auth/some-new-code'))).toBe(
      'Something went wrong. Please try again',
    );
    expect(authErrorMessage(new Error('boom'))).toBe('Something went wrong. Please try again');
    expect(authErrorMessage(null)).toBe('Something went wrong. Please try again');
  });
});
