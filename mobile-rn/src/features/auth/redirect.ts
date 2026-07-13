/**
 * Pure redirect logic for the auth gate.
 * Parity with Flutter `mobile/lib/core/router/auth_redirect.dart`.
 *
 * The email-verification gate was REMOVED (CLAUDE.md): unverified password users
 * land on /home like everyone else and are nudged by an in-app banner. Do not
 * reintroduce a hard gate here.
 */

const AUTH_ROUTES = new Set(['/login', '/signup', '/forgot-password']);
const VERIFY_ROUTE = '/verify-email';
const SPLASH_ROUTE = '/splash';

export type AuthRedirectInput = {
  currentRoute: string;
  isLoading: boolean;
  isLoggedIn: boolean;
};

/** Returns the path to redirect to, or null to stay put. */
export function resolveAuthRedirect({
  currentRoute,
  isLoading,
  isLoggedIn,
}: AuthRedirectInput): string | null {
  if (isLoading) return SPLASH_ROUTE;

  const isAuthRoute = AUTH_ROUTES.has(currentRoute);

  if (!isLoggedIn) {
    // /verify-email requires a session; signed-out users on it (or on splash or
    // any protected route) go to login. Pure auth routes are left alone.
    if (currentRoute === SPLASH_ROUTE) return '/login';
    if (currentRoute === VERIFY_ROUTE) return '/login';
    if (!isAuthRoute) return '/login';
    return null;
  }

  // Signed in — keep everyone out of auth/verify/splash.
  if (currentRoute === SPLASH_ROUTE || isAuthRoute || currentRoute === VERIFY_ROUTE) {
    return '/home';
  }

  return null;
}
