import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:drivevault/features/auth/data/auth_repository.dart';
import 'package:drivevault/features/dashboard/data/dashboard_repository.dart';
import 'package:drivevault/features/dashboard/domain/dashboard_data.dart';
import 'package:drivevault/features/dashboard/presentation/dashboard_provider.dart';
import 'package:drivevault/features/dashboard/presentation/dashboard_screen.dart';
import 'package:drivevault/features/profile/data/user_repository.dart';
import 'package:drivevault/features/profile/domain/user.dart';
import 'package:drivevault/features/vehicles/domain/vehicle.dart';
import 'package:drivevault/features/vehicles/presentation/vehicles_provider.dart';

// ---------------------------------------------------------------------------
// Stub helpers
// ---------------------------------------------------------------------------

final _stubUser = AppUser(
  id: 'u-1',
  firebaseUid: 'fb-1',
  email: 'me@example.com',
  createdAt: DateTime(2026, 1, 1),
);

// Auth stub — avoids Firebase initialisation in unit tests.
final _noFirebaseAuth = AuthRepository.testing();

class _FakeDashboardRepository implements DashboardRepository {
  final Future<DashboardData> Function() _fetch;
  _FakeDashboardRepository(this._fetch);

  @override
  Future<DashboardData> fetchDashboard() => _fetch();
}

class _FakeVehiclesNotifier extends VehiclesNotifier {
  final List<Vehicle> _vehicles;
  _FakeVehiclesNotifier(this._vehicles);

  @override
  Future<List<Vehicle>> build() async => _vehicles;
}

/// An [AsyncNotifier] that immediately emits [AsyncError] in [build].
///
/// Used to test the error state of [DashboardScreen] without relying on
/// the async timing of [_FakeDashboardRepository] inside a widget test's
/// fake-timer zone.
class _ImmediateErrorNotifier extends DashboardNotifier {
  @override
  Future<DashboardData> build() async {
    // Set state synchronously before returning so widgets see the error on
    // the first pump rather than waiting for a microtask.
    state = AsyncError(Exception('Network failure'), StackTrace.empty);
    // Return a future that never resolves so Riverpod doesn't overwrite state.
    return Completer<DashboardData>().future;
  }
}

/// Returns minimal dashboard data. [vehicleCount] defaults to 2.
DashboardData _loadedData({
  int vehicleCount = 2,
  List<UpcomingRenewal>? renewals,
  List<ActivityItem>? activity,
}) {
  return DashboardData(
    vehicleCount: vehicleCount,
    monthlyFuelSpendCents: 23400,
    totalOwnershipCostCents: 412000,
    costBreakdown: const CostBreakdown(
      fuelCents: 70200,
      maintenanceCents: 320000,
      purchaseCents: 0,
    ),
    upcomingRenewals:
        renewals ??
        const [
          UpcomingRenewal(
            vehicleId: 'uuid-00000000',
            title: 'Insurance',
            expiryDate: '2026-12-31',
          ),
        ],
    recentActivity: activity ?? const [],
  );
}

// ---------------------------------------------------------------------------
// Widget wrappers
// ---------------------------------------------------------------------------

/// Wraps [child] in a plain MaterialApp + ProviderScope (no router needed).
Widget _wrapSimple(
  Widget child,
  DashboardRepository repo, {
  List<Vehicle> vehicles = const [],
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(_noFirebaseAuth),
      dashboardRepositoryProvider.overrideWithValue(repo),
      meProvider.overrideWith((ref) async => _stubUser),
      vehiclesProvider.overrideWith(() => _FakeVehiclesNotifier(vehicles)),
    ],
    child: MaterialApp(home: child),
  );
}

/// Wraps [child] in a GoRouter so that context.go() calls can be asserted.
Widget _wrapWithRouter(
  Widget child,
  DashboardRepository repo, {
  List<Vehicle> vehicles = const [],
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => child),
      GoRoute(
        path: '/garage',
        builder: (_, _) => const Scaffold(body: Text('Garage')),
      ),
      GoRoute(
        path: '/garage/vehicle/:id',
        builder: (_, state) =>
            Scaffold(body: Text('Detail ${state.pathParameters["id"]}')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(_noFirebaseAuth),
      dashboardRepositoryProvider.overrideWithValue(repo),
      meProvider.overrideWith((ref) async => _stubUser),
      vehiclesProvider.overrideWith(() => _FakeVehiclesNotifier(vehicles)),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('DashboardScreen — four states', () {
    testWidgets('shows skeleton boxes while loading', (tester) async {
      // Use a Completer that never resolves so the provider stays in loading.
      final neverCompletes = Completer<DashboardData>();

      await tester.pumpWidget(
        _wrapSimple(
          const DashboardScreen(),
          _FakeDashboardRepository(() => neverCompletes.future),
        ),
      );

      // First frame — still loading; skeletons are Containers with divider colour.
      await tester.pump();
      // The _LoadingState renders a ListView with several _SkeletonBox widgets.
      // Each is a Container — we check that at least one is present.
      expect(find.byType(Container), findsWidgets);
      // No loaded or error content yet.
      expect(find.text('Needs Attention'), findsNothing);
      expect(find.text('Retry'), findsNothing);

      // Resolve so no pending timers remain.
      neverCompletes.complete(_loadedData());
    });

    testWidgets('shows empty state when vehicleCount is 0', (tester) async {
      await tester.pumpWidget(
        _wrapWithRouter(
          const DashboardScreen(),
          _FakeDashboardRepository(() async => _loadedData(vehicleCount: 0)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No vehicles yet'), findsOneWidget);
      expect(find.text('Add your first vehicle'), findsOneWidget);
    });

    testWidgets('empty-state button navigates to the Garage screen', (
      tester,
    ) async {
      // The empty-state CTA calls context.go('/garage'), so we need a GoRouter.
      await tester.pumpWidget(
        _wrapWithRouter(
          const DashboardScreen(),
          _FakeDashboardRepository(() async => _loadedData(vehicleCount: 0)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Add your first vehicle'), findsOneWidget);
      await tester.tap(find.text('Add your first vehicle'));
      await tester.pumpAndSettle();

      // After tapping, GoRouter navigates to /garage.
      expect(find.text('Garage'), findsOneWidget);
    });

    testWidgets('loaded state shows TOTAL OWNERSHIP COST header', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapSimple(
          const DashboardScreen(),
          _FakeDashboardRepository(() async => _loadedData(vehicleCount: 2)),
        ),
      );

      await tester.pumpAndSettle();

      // The spend card renders 'TOTAL OWNERSHIP COST' as a labelSmall text.
      expect(find.text('TOTAL OWNERSHIP COST'), findsOneWidget);
    });

    testWidgets('shows error state when the repository throws', (tester) async {
      // Override dashboardProvider directly to emit AsyncError immediately.
      // This bypasses any timing issues with async notifier build in widget tests.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_noFirebaseAuth),
            meProvider.overrideWith((ref) async => _stubUser),
            dashboardProvider.overrideWith(() => _ImmediateErrorNotifier()),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('loaded state shows monthly fuel stat card', (tester) async {
      await tester.pumpWidget(
        _wrapSimple(
          const DashboardScreen(),
          _FakeDashboardRepository(() async => _loadedData(vehicleCount: 1)),
        ),
      );

      await tester.pumpAndSettle();

      // StatCard.label is uppercased inside the widget → 'FUEL · THIS MONTH'.
      expect(find.text('FUEL · THIS MONTH'), findsOneWidget);
    });
  });

  group('DashboardScreen — needs-attention filtering', () {
    testWidgets('overdue and soon renewals are shown in Needs Attention', (
      tester,
    ) async {
      final data = _loadedData(
        renewals: [
          const UpcomingRenewal(
            vehicleId: 'v-1',
            title: 'Insurance',
            expiryDate: '2026-01-01',
            status: RenewalStatus.overdue,
            vehicleLabel: 'Car A',
          ),
          const UpcomingRenewal(
            vehicleId: 'v-2',
            title: 'Road Tax',
            expiryDate: '2026-02-01',
            status: RenewalStatus.soon,
            daysRemaining: 14,
            vehicleLabel: 'Car B',
          ),
        ],
      );

      await tester.pumpWidget(
        _wrapSimple(
          const DashboardScreen(),
          _FakeDashboardRepository(() async => data),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Insurance'), findsOneWidget);
      expect(find.text('Road Tax'), findsOneWidget);
      // Both should appear — neither is filtered out.
    });

    testWidgets('ok-status renewals are NOT shown in Needs Attention', (
      tester,
    ) async {
      final data = _loadedData(
        renewals: [
          const UpcomingRenewal(
            vehicleId: 'v-3',
            title: 'Emission Check',
            expiryDate: '2027-12-31',
            status: RenewalStatus.ok,
            vehicleLabel: 'Car C',
          ),
        ],
      );

      await tester.pumpWidget(
        _wrapSimple(
          const DashboardScreen(),
          _FakeDashboardRepository(() async => data),
        ),
      );

      await tester.pumpAndSettle();

      // Title row absent — filtered out because status == ok.
      expect(find.text('Emission Check'), findsNothing);
      // The card should show the "all set" calm state instead.
      expect(find.textContaining("You're all set"), findsOneWidget);
    });

    testWidgets('shows calm "all set" when renewals list is empty', (
      tester,
    ) async {
      final data = _loadedData(renewals: const []);

      await tester.pumpWidget(
        _wrapSimple(
          const DashboardScreen(),
          _FakeDashboardRepository(() async => data),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining("You're all set"), findsOneWidget);
    });
  });

  group(
    'DashboardScreen — upcoming renewals (legacy vehicle-label resolution)',
    () {
      testWidgets('renewal row shows API-supplied vehicleLabel', (
        tester,
      ) async {
        final data = _loadedData(
          renewals: [
            const UpcomingRenewal(
              vehicleId: 'uuid-00000000',
              title: 'Insurance',
              expiryDate: '2026-06-01',
              status: RenewalStatus.soon,
              daysRemaining: 15,
              vehicleLabel: 'Toyota Hilux 2020',
            ),
          ],
        );

        await tester.pumpWidget(
          _wrapSimple(
            const DashboardScreen(),
            _FakeDashboardRepository(() async => data),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Toyota Hilux 2020'), findsOneWidget);
      });

      testWidgets(
        'renewal row falls back to UUID prefix when vehicleLabel absent',
        (tester) async {
          // No vehicleLabel → screen falls back to vehicleId.substring(0,8) + '…'
          final data = _loadedData(
            renewals: [
              const UpcomingRenewal(
                vehicleId: 'uuid-00000000-1111-2222-3333-444444444444',
                title: 'Insurance',
                expiryDate: '2026-06-01',
                status: RenewalStatus.soon,
                daysRemaining: 5,
              ),
            ],
          );

          await tester.pumpWidget(
            _wrapSimple(
              const DashboardScreen(),
              _FakeDashboardRepository(() async => data),
            ),
          );

          await tester.pumpAndSettle();

          // Falls back to first 8 chars of vehicleId + '…'
          expect(find.textContaining('uuid-000'), findsOneWidget);
        },
      );
    },
  );

  group('DashboardScreen — deep-link navigation', () {
    testWidgets(
      'tapping a renewal row navigates to the correct vehicle detail',
      (tester) async {
        const vehicleId = 'abc-12345678';
        final data = _loadedData(
          renewals: [
            const UpcomingRenewal(
              vehicleId: vehicleId,
              title: 'Insurance',
              expiryDate: '2026-06-01',
              status: RenewalStatus.soon,
              daysRemaining: 5,
              vehicleLabel: 'Honda Civic',
            ),
          ],
        );

        await tester.pumpWidget(
          _wrapWithRouter(
            const DashboardScreen(),
            _FakeDashboardRepository(() async => data),
          ),
        );

        await tester.pumpAndSettle();

        // Tap the renewal row
        await tester.tap(find.text('Insurance'));
        await tester.pumpAndSettle();

        // GoRouter should have navigated to /garage/vehicle/<vehicleId>
        expect(find.text('Detail $vehicleId'), findsOneWidget);
      },
    );
  });

  group('DashboardScreen — recent activity', () {
    testWidgets('recent activity section shows when items are present', (
      tester,
    ) async {
      final data = _loadedData(
        renewals: const [],
        activity: [
          ActivityItem(
            type: ActivityType.fuel,
            vehicleId: 'v-1',
            vehicleLabel: 'Car A',
            date: DateTime.now().toIso8601String().substring(0, 10),
            amountCents: 5000,
            label: 'Fuel top-up',
          ),
        ],
      );

      await tester.pumpWidget(
        _wrapSimple(
          const DashboardScreen(),
          _FakeDashboardRepository(() async => data),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.text('Fuel top-up'), findsOneWidget);
      // Friendly date: today's entry shows 'Today'
      expect(find.textContaining('Today'), findsWidgets);
    });

    testWidgets('recent activity section is absent when list is empty', (
      tester,
    ) async {
      final data = _loadedData(renewals: const [], activity: const []);

      await tester.pumpWidget(
        _wrapSimple(
          const DashboardScreen(),
          _FakeDashboardRepository(() async => data),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Recent Activity'), findsNothing);
    });
  });
}
