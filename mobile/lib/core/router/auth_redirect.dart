const _authRoutes = {'/login', '/signup', '/forgot-password'};

/// Pure redirect logic for the auth gate (Task C2c). Returns a new path or null.
String? resolveAuthRedirect({
  required String currentRoute,
  required bool isLoading,
  required bool isLoggedIn,
}) {
  if (isLoading) {
    return '/splash';
  }

  final isAuthRoute = _authRoutes.contains(currentRoute);

  if (!isLoggedIn) {
    if (currentRoute == '/splash' || !isAuthRoute) {
      return '/login';
    }
  } else if (currentRoute == '/splash' || isAuthRoute) {
    return '/home';
  }

  return null;
}
