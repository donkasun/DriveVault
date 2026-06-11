import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:drivevault/main.dart';
import 'package:drivevault/features/auth/data/auth_repository.dart';
import 'package:drivevault/features/dashboard/presentation/dashboard_screen.dart';
import 'package:drivevault/features/dashboard/presentation/dashboard_provider.dart';
import 'package:drivevault/features/dashboard/domain/dashboard_data.dart';

class FakeUser extends Fake implements User {
  @override
  String get email => 'test@example.com';
  @override
  String get displayName => 'Test User';
  @override
  String get uid => 'test-uid';
  @override
  bool get emailVerified => true;
  @override
  List<UserInfo> get providerData => [];
}

class FakeUnverifiedPasswordUser extends Fake implements User {
  @override
  String get email => 'test@example.com';
  @override
  String get uid => 'test-uid';
  @override
  bool get emailVerified => false;
  @override
  List<UserInfo> get providerData => [_FakePasswordProvider()];
}

class _FakePasswordProvider extends Fake implements UserInfo {
  @override
  String get providerId => 'password';
}

/// A stub notifier that returns empty DashboardData without hitting the network.
class _StubDashboardNotifier extends DashboardNotifier {
  @override
  Future<DashboardData> build() async {
    return const DashboardData(
      vehicleCount: 0,
      monthlyFuelSpendCents: 0,
      totalOwnershipCostCents: 0,
      costBreakdown: CostBreakdown(
        fuelCents: 0,
        maintenanceCents: 0,
        purchaseCents: 0,
      ),
      upcomingRenewals: [],
    );
  }
}

void main() {
  testWidgets('App boots to LoginScreen when signed out', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const DriveVaultApp(),
      ),
    );
    await tester.pump(); // Start navigation/redirects
    await tester.pumpAndSettle(); // Wait for transitions to finish

    // Should find the Sign In card title and login form elements
    expect(find.text('Sign In'), findsWidgets);
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
  });

  testWidgets('Login screen shows Google sign-in button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const DriveVaultApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('App boots to DashboardScreen when signed in', (
    WidgetTester tester,
  ) async {
    final fakeUser = FakeUser();

    // Stub dashboardProvider so it returns immediately without a network call.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateChangesProvider.overrideWith(
            (ref) => Stream.value(fakeUser),
          ),
          dashboardProvider.overrideWith(() => _StubDashboardNotifier()),
        ],
        child: const DriveVaultApp(),
      ),
    );
    await tester.pump(); // Start navigation/redirects
    await tester.pumpAndSettle(); // Wait for transitions to finish

    // The shell should have routed to DashboardScreen (home tab).
    expect(find.byType(DashboardScreen), findsOneWidget);
    // The empty-state is shown because vehicleCount == 0.
    expect(find.text('No vehicles yet'), findsOneWidget);
  });

  testWidgets('App boots to VerifyEmailScreen when signed in but unverified', (
    WidgetTester tester,
  ) async {
    final fakeUser = FakeUnverifiedPasswordUser();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateChangesProvider.overrideWith(
            (ref) => Stream.value(fakeUser),
          ),
          authRepositoryProvider.overrideWithValue(
            AuthRepository.testing(currentUser: fakeUser),
          ),
        ],
        child: const DriveVaultApp(),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Verify your email'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, "I've verified"), findsOneWidget);
  });
}
