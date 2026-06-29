import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'package:drivevault/features/dashboard/domain/dashboard_data.dart';
import 'package:drivevault/features/dashboard/presentation/dashboard_provider.dart';
import 'package:drivevault/features/vehicles/domain/vehicle.dart';
import 'package:drivevault/features/vehicles/presentation/vehicles_provider.dart';
import 'package:drivevault/core/sync/app_lifecycle_observer.dart';

class _FakeDashboardNotifier extends DashboardNotifier {
  int refreshCount = 0;

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

  @override
  Future<void> refresh() async {
    refreshCount++;
  }
}

class _FakeVehiclesNotifier extends VehiclesNotifier {
  int refreshCount = 0;

  @override
  Future<List<Vehicle>> build() async => const [];

  @override
  Future<void> refresh() async {
    refreshCount++;
  }
}

void main() {
  test('resumed lifecycle triggers refresh immediately', () {
    late _FakeDashboardNotifier dashboardNotifier;
    late _FakeVehiclesNotifier vehiclesNotifier;

    final container = ProviderContainer(
      overrides: [
        dashboardProvider.overrideWith(() {
          dashboardNotifier = _FakeDashboardNotifier();
          return dashboardNotifier;
        }),
        vehiclesProvider.overrideWith(() {
          vehiclesNotifier = _FakeVehiclesNotifier();
          return vehiclesNotifier;
        }),
      ],
    );
    addTearDown(container.dispose);

    final observer = AppLifecycleObserver(
      refreshDashboard: () => dashboardNotifier.refresh(),
      refreshVehicles: () => vehiclesNotifier.refresh(),
    );
    container.read(dashboardProvider.notifier);
    container.read(vehiclesProvider.notifier);

    observer.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(dashboardNotifier.refreshCount, 0);
    expect(vehiclesNotifier.refreshCount, 0);

    observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(dashboardNotifier.refreshCount, 1);
    expect(vehiclesNotifier.refreshCount, 1);
  });
}
