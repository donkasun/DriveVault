import { resolveAuthRedirect } from './redirect';

const base = { currentRoute: '/home', isLoading: false, isLoggedIn: true };

describe('resolveAuthRedirect — loading', () => {
  it('parks on splash while auth state is unknown', () => {
    expect(resolveAuthRedirect({ ...base, isLoading: true })).toBe('/splash');
  });
});

describe('resolveAuthRedirect — signed out', () => {
  const out = { ...base, isLoggedIn: false };

  it('sends protected routes to login', () => {
    expect(resolveAuthRedirect({ ...out, currentRoute: '/home' })).toBe('/login');
    expect(resolveAuthRedirect({ ...out, currentRoute: '/garage' })).toBe('/login');
  });

  it('sends splash to login', () => {
    expect(resolveAuthRedirect({ ...out, currentRoute: '/splash' })).toBe('/login');
  });

  it('sends verify-email to login (it needs a session)', () => {
    expect(resolveAuthRedirect({ ...out, currentRoute: '/verify-email' })).toBe('/login');
  });

  it('leaves the auth routes alone', () => {
    expect(resolveAuthRedirect({ ...out, currentRoute: '/login' })).toBeNull();
    expect(resolveAuthRedirect({ ...out, currentRoute: '/signup' })).toBeNull();
    expect(resolveAuthRedirect({ ...out, currentRoute: '/forgot-password' })).toBeNull();
  });
});

describe('resolveAuthRedirect — signed in', () => {
  it('kicks signed-in users off the auth routes', () => {
    expect(resolveAuthRedirect({ ...base, currentRoute: '/login' })).toBe('/home');
    expect(resolveAuthRedirect({ ...base, currentRoute: '/signup' })).toBe('/home');
    expect(resolveAuthRedirect({ ...base, currentRoute: '/forgot-password' })).toBe('/home');
  });

  it('kicks signed-in users off splash and verify-email', () => {
    expect(resolveAuthRedirect({ ...base, currentRoute: '/splash' })).toBe('/home');
    expect(resolveAuthRedirect({ ...base, currentRoute: '/verify-email' })).toBe('/home');
  });

  it('leaves protected routes alone', () => {
    expect(resolveAuthRedirect({ ...base, currentRoute: '/home' })).toBeNull();
    expect(resolveAuthRedirect({ ...base, currentRoute: '/garage' })).toBeNull();
  });

  it('does NOT gate unverified email users — soft nudge, not a hard gate', () => {
    // The whole point of removing the C2d gate: an unverified password user
    // reaches /home like everyone else. If this ever redirects, the banner
    // nudge has silently become a wall again.
    expect(resolveAuthRedirect({ ...base, currentRoute: '/home' })).toBeNull();
  });
});
