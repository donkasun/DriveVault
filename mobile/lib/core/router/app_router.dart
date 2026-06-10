import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/vehicles/presentation/garage_screen.dart';
import '../../features/vehicles/presentation/vehicle_detail_screen.dart';
import '../../features/vehicles/presentation/vehicle_form_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import 'auth_redirect.dart';
import 'main_shell.dart';

// We use a separate class to keep the notifier clean and prevent disposal issues
class _RouterListenable extends ChangeNotifier {
  final Ref _ref;
  AsyncValue<User?> _authState = const AsyncValue.loading();

  _RouterListenable(this._ref) {
    _ref.listen<AsyncValue<User?>>(authStateChangesProvider, (previous, next) {
      _authState = next;
      notifyListeners();
    }, fireImmediately: true);
  }

  AsyncValue<User?> get authState => _authState;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final listenable = _RouterListenable(ref);
  ref.onDispose(() => listenable.dispose());

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: listenable,
    redirect: (context, state) {
      final authValue = listenable.authState;
      final user = authValue.value;
      final isPasswordProvider =
          user?.providerData.any((p) => p.providerId == 'password') ?? false;
      return resolveAuthRedirect(
        currentRoute: state.uri.path,
        isLoading: authValue.isLoading,
        isLoggedIn: user != null,
        isEmailVerified: user?.emailVerified ?? false,
        isPasswordProvider: isPasswordProvider,
      );
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/garage',
                builder: (context, state) => const GarageScreen(),
                routes: [
                  GoRoute(
                    path: 'vehicle/:id',
                    builder: (context, state) => VehicleDetailScreen(
                      vehicleId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'add-vehicle',
                    pageBuilder: (context, state) => MaterialPage(
                      fullscreenDialog: true,
                      child: const VehicleFormScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'edit-vehicle/:id',
                    pageBuilder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>?;
                      final vehicle = extra?['vehicle'];
                      return MaterialPage(
                        fullscreenDialog: true,
                        child: VehicleFormScreen(vehicle: vehicle),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Route not found: ${state.uri}'))),
  );
});
