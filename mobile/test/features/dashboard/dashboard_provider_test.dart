import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drivevault/features/dashboard/data/dashboard_repository.dart';
import 'package:drivevault/features/dashboard/domain/dashboard_data.dart';
import 'package:drivevault/features/dashboard/presentation/dashboard_provider.dart';

class _FakeDashboardRepository implements DashboardRepository {
  final Future<DashboardData> Function() _fetch;

  _FakeDashboardRepository(this._fetch);

  @override
  Future<DashboardData> fetchDashboard() => _fetch();
}

DashboardData _fakeDashboardData() {
  return const DashboardData(
    vehicleCount: 2,
    monthlyFuelSpendCents: 23400,
    totalOwnershipCostCents: 412000,
    costBreakdown: CostBreakdown(
      fuelCents: 70200,
      maintenanceCents: 320000,
      purchaseCents: 0,
    ),
    upcomingRenewals: [
      UpcomingRenewal(
        vehicleId: 'uuid-1',
        title: 'Insurance',
        expiryDate: '2026-12-31',
      ),
    ],
  );
}

void main() {
  group('dashboardProvider', () {
    test('transitions from loading to loaded state', () async {
      final container = ProviderContainer(
        overrides: [
          dashboardRepositoryProvider.overrideWithValue(
            _FakeDashboardRepository(() async => _fakeDashboardData()),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Initially loading
      expect(container.read(dashboardProvider), const AsyncValue<DashboardData>.loading());

      // Wait for the future to complete
      await container.read(dashboardProvider.future);

      final state = container.read(dashboardProvider);
      expect(state, isA<AsyncData<DashboardData>>());
      expect(state.value!.vehicleCount, 2);
      expect(state.value!.monthlyFuelSpendCents, 23400);
    });

    test('transitions to error state when repository throws', () async {
      final container = ProviderContainer(
        overrides: [
          dashboardRepositoryProvider.overrideWithValue(
            _FakeDashboardRepository(
              () async => throw Exception('Network error'),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Trigger the provider build.
      container.read(dashboardProvider);

      // The async fetch completes on the next microtask. Pump until settled.
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(Duration.zero);
        final s = container.read(dashboardProvider);
        if (s.hasError) break;
      }

      final state = container.read(dashboardProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<Exception>());
    });

    test('refresh() re-fetches data', () async {
      var callCount = 0;
      final container = ProviderContainer(
        overrides: [
          dashboardRepositoryProvider.overrideWithValue(
            _FakeDashboardRepository(() async {
              callCount++;
              return _fakeDashboardData();
            }),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(dashboardProvider.future);
      expect(callCount, 1);

      await container.read(dashboardProvider.notifier).refresh();
      expect(callCount, 2);
    });
  });
}
