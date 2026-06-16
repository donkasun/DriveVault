const _authRoutes = {'/login', '/signup', '/forgot-password'};
const _verifyRoute = '/verify-email';

/// Pure redirect logic for the auth gate (Task C2c + C2d email-verification
/// gate). Returns a new path or null.
///
/// [isPasswordProvider] is true only for email/password accounts; Google/Apple
/// accounts arrive pre-verified and must bypass the verification gate.
String? resolveAuthRedirect({
  required String currentRoute,
  required bool isLoading,
  required bool isLoggedIn,
  required bool isEmailVerified,
  required bool isPasswordProvider,
}) {
  if (isLoading) {
    return '/splash';
  }

  final isAuthRoute = _authRoutes.contains(currentRoute);

  if (!isLoggedIn) {
    // /verify-email requires a session; signed-out users on it (or on splash or
    // any protected route) go to login. Pure auth routes are left alone.
    if (currentRoute == '/splash' || (!isAuthRoute && currentRoute != _verifyRoute)) {
      return '/login';
    }
    if (currentRoute == _verifyRoute) {
      return '/login';
    }
    return null;
  }

  // Logged in. The email-verification gate has been removed — unverified
  // password users use the app freely and are nudged by an in-app banner.
  // Keep everyone out of auth/verify/splash once authenticated.
  if (currentRoute == '/splash' || isAuthRoute || currentRoute == _verifyRoute) {
    return '/home';
  }

  return null;
}
