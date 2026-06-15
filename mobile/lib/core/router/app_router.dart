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
import '../../features/documents/presentation/document_upload_screen.dart';
import '../../features/fuel/domain/fuel_log.dart';
import '../../features/fuel/presentation/fuel_log_form_screen.dart';
import '../../features/maintenance/domain/maintenance_record.dart';
import '../../features/maintenance/presentation/maintenance_form_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/vehicles/presentation/garage_screen.dart';
import '../../features/vehicles/presentation/vehicle_detail_screen.dart';
import '../../features/vehicles/presentation/vehicle_fuel_records_screen.dart';
import '../../features/vehicles/presentation/vehicle_form_screen.dart';
import '../../features/activity/presentation/activity_screen.dart';
import '../../features/expenses/presentation/expense_history_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
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
          // Branch 0 — Home / Dashboard (left tab, default landing)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const DashboardScreen(),
                routes: [
                  // Quick-add fuel log from Dashboard (no vehicleId pre-set)
                  GoRoute(
                    path: 'fuel/add',
                    pageBuilder: (context, state) => const MaterialPage(
                      fullscreenDialog: true,
                      child: FuelLogFormScreen(),
                    ),
                  ),
                  // Full activity history (from dashboard "See all" button)
                  GoRoute(
                    path: 'activity',
                    pageBuilder: (context, state) => const MaterialPage(
                      fullscreenDialog: true,
                      child: ActivityScreen(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Branch 1 — Garage
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
                    routes: [
                      GoRoute(
                        path: 'fuel-records',
                        builder: (context, state) => VehicleFuelRecordsScreen(
                          vehicleId: state.pathParameters['id']!,
                        ),
                      ),
                      // Fuel log — add
                      GoRoute(
                        path: 'fuel/add',
                        pageBuilder: (context, state) => MaterialPage(
                          fullscreenDialog: true,
                          child: FuelLogFormScreen(
                            vehicleId: state.pathParameters['id']!,
                          ),
                        ),
                      ),
                      // Fuel log — edit (FuelLog passed via extra)
                      GoRoute(
                        path: 'fuel/edit',
                        pageBuilder: (context, state) {
                          final log = state.extra as FuelLog?;
                          return MaterialPage(
                            fullscreenDialog: true,
                            child: FuelLogFormScreen(
                              vehicleId: state.pathParameters['id']!,
                              existing: log,
                            ),
                          );
                        },
                      ),
                      // Maintenance — add
                      GoRoute(
                        path: 'maintenance/add',
                        pageBuilder: (context, state) => MaterialPage(
                          fullscreenDialog: true,
                          child: MaintenanceFormScreen(
                            vehicleId: state.pathParameters['id']!,
                          ),
                        ),
                      ),
                      // Maintenance — edit (MaintenanceRecord passed via extra)
                      GoRoute(
                        path: 'maintenance/edit',
                        pageBuilder: (context, state) {
                          final record = state.extra as MaintenanceRecord?;
                          return MaterialPage(
                            fullscreenDialog: true,
                            child: MaintenanceFormScreen(
                              vehicleId: state.pathParameters['id']!,
                              existing: record,
                            ),
                          );
                        },
                      ),
                      // Documents — upload
                      GoRoute(
                        path: 'documents/upload',
                        pageBuilder: (context, state) => MaterialPage(
                          fullscreenDialog: true,
                          child: DocumentUploadScreen(
                            vehicleId: state.pathParameters['id']!,
                          ),
                        ),
                      ),
                    ],
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
          // Branch 2 — Expenses
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/expenses',
                builder: (context, state) => const ExpenseHistoryScreen(),
              ),
            ],
          ),
          // Branch 3 — Profile / Settings (right tab)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    pageBuilder: (context, state) => const MaterialPage(
                      fullscreenDialog: true,
                      child: EditProfileScreen(),
                    ),
                  ),
                ],
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
