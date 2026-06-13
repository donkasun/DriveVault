import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:drivevault/features/dashboard/data/dashboard_repository.dart';
import 'package:drivevault/features/dashboard/domain/dashboard_data.dart';
import 'package:drivevault/features/dashboard/presentation/dashboard_screen.dart';
import 'package:drivevault/core/router/shell_tab_provider.dart';
import 'package:drivevault/features/profile/data/user_repository.dart';
import 'package:drivevault/features/profile/domain/user.dart';
import 'package:drivevault/features/vehicles/domain/vehicle.dart';
import 'package:drivevault/features/vehicles/presentation/vehicles_provider.dart';

final _stubUser = AppUser(
  id: 'u-1',
  firebaseUid: 'fb-1',
  email: 'me@example.com',
  createdAt: DateTime(2026, 1, 1),
);

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

Vehicle _makeVehicle({
  String id = 'uuid-00000000-1111-2222-3333-444444444444',
  String make = 'Toyota',
  String model = 'Hilux',
  int? year = 2020,
}) {
  final now = DateTime(2026, 1, 1);
  return Vehicle(
    id: id,
    make: make,
    model: model,
    year: year,
    currency: 'USD',
    createdAt: now,
    updatedAt: now,
  );
}

DashboardData _loadedData({int vehicleCount = 2}) {
  return DashboardData(
    vehicleCount: vehicleCount,
    monthlyFuelSpendCents: 23400,
    totalOwnershipCostCents: 412000,
    costBreakdown: const CostBreakdown(
      fuelCents: 70200,
      maintenanceCents: 320000,
      purchaseCents: 0,
    ),
    upcomingRenewals: const [
      UpcomingRenewal(
        vehicleId: 'uuid-00000000',
        title: 'Insurance',
        expiryDate: '2026-12-31',
      ),
    ],
  );
}

Widget _wrapSimple(
  Widget child,
  DashboardRepository repo, {
  List<Vehicle> vehicles = const [],
}) {
  return ProviderScope(
    overrides: [
      dashboardRepositoryProvider.overrideWithValue(repo),
      meProvider.overrideWith((ref) async => _stubUser),
      vehiclesProvider.overrideWith(() => _FakeVehiclesNotifier(vehicles)),
    ],
    child: MaterialApp(home: child),
  );
}

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
      dashboardRepositoryProvider.overrideWithValue(repo),
      meProvider.overrideWith((ref) async => _stubUser),
      vehiclesProvider.overrideWith(() => _FakeVehiclesNotifier(vehicles)),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('DashboardScreen states', () {
    testWidgets('shows CircularProgressIndicator while loading', (
      tester,
    ) async {
      // Use a completer that never resolves so the provider stays in loading.
      final neverCompletes = Completer<DashboardData>();

      await tester.pumpWidget(
        _wrapSimple(
          const DashboardScreen(),
          _FakeDashboardRepository(() => neverCompletes.future),
        ),
      );

      // First frame — still loading
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete the completer so no pending timers remain.
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

    testWidgets('empty state button targets the Garage tab', (tester) async {
      final container = ProviderContainer(
        overrides: [
          dashboardRepositoryProvider.overrideWithValue(
            _FakeDashboardRepository(() async => _loadedData(vehicleCount: 0)),
          ),
          meProvider.overrideWith((ref) async => _stubUser),
          vehiclesProvider.overrideWith(() => _FakeVehiclesNotifier(const [])),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Add your first vehicle'));
      await tester.pump();

      expect(container.read(pendingTabProvider), 1);
    });

    testWidgets('shows Total Ownership Cost text when vehicleCount > 0', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapSimple(
          const DashboardScreen(),
          _FakeDashboardRepository(() async => _loadedData(vehicleCount: 2)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Total Ownership Cost'), findsOneWidget);
    });

    testWidgets('shows Retry button on error', (tester) async {
      await tester.pumpWidget(
        _wrapSimple(
          const DashboardScreen(),
          _FakeDashboardRepository(
            () async => throw Exception('Network failure'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('DashboardScreen — upcoming renewals', () {
    testWidgets('renewal row shows resolved vehicle name when vehicle found', (
      tester,
    ) async {
      final vehicle = _makeVehicle(id: 'uuid-00000000');

      await tester.pumpWidget(
        _wrapSimple(
          const DashboardScreen(),
          _FakeDashboardRepository(() async => _loadedData(vehicleCount: 1)),
          vehicles: [vehicle],
        ),
      );

      await tester.pumpAndSettle();

      // Should show the human-readable name, not the raw UUID substring
      expect(find.text('Toyota Hilux 2020'), findsOneWidget);
    });

    testWidgets(
      'renewal row falls back to UUID prefix when vehicle not in list',
      (tester) async {
        await tester.pumpWidget(
          _wrapSimple(
            const DashboardScreen(),
            _FakeDashboardRepository(() async => _loadedData(vehicleCount: 1)),
            vehicles: const [], // vehicle not in list
          ),
        );

        await tester.pumpAndSettle();

        // Falls back to first 8 chars of vehicleId + ellipsis
        expect(find.textContaining('uuid-000'), findsOneWidget);
      },
    );

    testWidgets('tapping a renewal row navigates to vehicle detail', (
      tester,
    ) async {
      final vehicle = _makeVehicle(id: 'uuid-00000000');

      await tester.pumpWidget(
        _wrapWithRouter(
          const DashboardScreen(),
          _FakeDashboardRepository(() async => _loadedData(vehicleCount: 1)),
          vehicles: [vehicle],
        ),
      );

      await tester.pumpAndSettle();

      // Tap the renewal row (Insurance title)
      await tester.tap(find.text('Insurance'));
      await tester.pumpAndSettle();

      expect(find.text('Detail uuid-00000000'), findsOneWidget);
    });
  });

  group('DashboardScreen — ring widget', () {
    testWidgets('shows this month label in ring', (tester) async {
      await tester.pumpWidget(
        _wrapSimple(
          const DashboardScreen(),
          _FakeDashboardRepository(() async => _loadedData(vehicleCount: 1)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('this month'), findsOneWidget);
    });
  });
}
