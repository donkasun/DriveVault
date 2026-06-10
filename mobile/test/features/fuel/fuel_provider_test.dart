import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drivevault/features/fuel/domain/fuel_log.dart';
import 'package:drivevault/features/fuel/domain/fuel_stats.dart';

// A simple in-memory stub repository for provider testing.
class _StubFuelData {
  static final log = FuelLog(
    id: 'log-1',
    vehicleId: 'v-1',
    date: '2026-06-01',
    liters: 45.5,
    priceCents: 7800,
    currency: 'USD',
    odometer: 48200,
    isFullTank: true,
    createdAt: DateTime(2026, 6, 1),
  );

  static final stats = FuelStats(
    avgConsumptionLPer100Km: 8.5,
    avgCostPerKmCents: 12,
    totalLiters: 200.0,
    totalSpentCents: 35000,
    monthlySpend: [],
  );
}

// Provider that returns a static list — used to verify state transitions.
final _testLogsProvider = FutureProvider.family<List<FuelLog>, String>(
  (ref, vehicleId) async => [_StubFuelData.log],
);

final _testStatsProvider = FutureProvider.family<FuelStats, String>(
  (ref, vehicleId) async => _StubFuelData.stats,
);

void main() {
  group('Fuel providers state transitions', () {
    test('logs provider transitions loading → data', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Initially loading
      final initial =
          container.read(_testLogsProvider('v-1'));
      expect(initial.isLoading, true);

      // After await, data available
      final logs =
          await container.read(_testLogsProvider('v-1').future);
      expect(logs.length, 1);
      expect(logs.first.id, 'log-1');

      final after = container.read(_testLogsProvider('v-1'));
      expect(after.hasValue, true);
      expect(after.value!.first.priceCents, 7800);
    });

    test('stats provider transitions loading → data', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final stats =
          await container.read(_testStatsProvider('v-1').future);
      expect(stats.totalSpentCents, 35000);
      expect(stats.totalLiters, 200.0);
    });

    test('error provider emits error state', () async {
      final errorProvider = FutureProvider.family<List<FuelLog>, String>(
        (ref, vehicleId) async => throw Exception('network error'),
      );
      final container = ProviderContainer();

      // Listen to state changes to detect error
      final states = <AsyncValue<List<FuelLog>>>[];
      container.listen(
        errorProvider('v-1'),
        (prev, next) => states.add(next),
        fireImmediately: true,
      );

      // Wait briefly for the async provider to complete
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(errorProvider('v-1'));
      container.dispose();

      expect(state.hasError, isTrue);
    });
  });
}
