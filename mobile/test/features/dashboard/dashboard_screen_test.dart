import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:drivevault/features/dashboard/data/dashboard_repository.dart';
import 'package:drivevault/features/dashboard/domain/dashboard_data.dart';
import 'package:drivevault/features/dashboard/presentation/dashboard_screen.dart';

class _FakeDashboardRepository implements DashboardRepository {
  final Future<DashboardData> Function() _fetch;
  _FakeDashboardRepository(this._fetch);

  @override
  Future<DashboardData> fetchDashboard() => _fetch();
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

Widget _wrapSimple(Widget child, DashboardRepository repo) {
  return ProviderScope(
    overrides: [dashboardRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(home: child),
  );
}

Widget _wrapWithRouter(Widget child, DashboardRepository repo) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => child),
      GoRoute(
        path: '/garage',
        builder: (_, __) => const Scaffold(body: Text('Garage')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [dashboardRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('DashboardScreen states', () {
    testWidgets('shows CircularProgressIndicator while loading', (tester) async {
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

    testWidgets('shows Total Ownership Cost text when vehicleCount > 0',
        (tester) async {
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
}
