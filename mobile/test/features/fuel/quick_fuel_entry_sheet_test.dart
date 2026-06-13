import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drivevault/core/network/api_client.dart';
import 'package:drivevault/features/fuel/data/fuel_repository.dart';
import 'package:drivevault/features/fuel/domain/fuel_log.dart';
import 'package:drivevault/features/fuel/domain/fuel_stats.dart';
import 'package:drivevault/features/fuel/presentation/widgets/quick_fuel_entry_sheet.dart';
import 'package:drivevault/features/profile/data/user_repository.dart';
import 'package:drivevault/features/profile/domain/user.dart';
import 'package:drivevault/features/vehicles/domain/vehicle.dart';
import 'package:drivevault/features/vehicles/presentation/vehicles_provider.dart';

// ─── Seed data ───────────────────────────────────────────────────────────────

// liters 40, priceCents 8000 → per-liter = 8000/100/40 = 2.00
final _latestLog = FuelLog(
  id: 'log-1',
  vehicleId: 'v-1',
  date: '2026-06-01',
  liters: 40.0,
  priceCents: 8000,
  currency: 'LKR',
  odometer: 50000,
  isFullTank: true,
  createdAt: DateTime(2026, 6, 1),
);

final _fakeVehicle = Vehicle(
  id: 'v-1',
  make: 'Toyota',
  model: 'Corolla',
  year: 2020,
  currency: 'LKR',
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);

final _fakeUser = AppUser(
  id: 'u-1',
  firebaseUid: 'uid-1',
  email: 'test@test.com',
  currency: 'LKR',
  distanceUnit: 'km',
  createdAt: DateTime(2025),
);

// ─── Fake FuelRepository ──────────────────────────────────────────────────────

/// A FuelRepository that records createFuelLog calls.
/// Uses a dummy ApiClient (never invoked — all methods are overridden).
class _FakeFuelRepo extends FuelRepository {
  final List<Map<String, dynamic>> calls = [];

  _FakeFuelRepo._internal(ApiClient client) : super(client);

  factory _FakeFuelRepo() {
    // Build an isolated container to get a real Ref for ApiClient's constructor.
    // The Dio instance points at localhost and will never be called because all
    // FuelRepository methods are overridden.
    late _FakeFuelRepo instance;
    final container = ProviderContainer(overrides: [
      apiClientProvider.overrideWith(
        (ref) => ApiClient(ref, dio: Dio(BaseOptions(baseUrl: 'http://localhost'))),
      ),
    ]);
    final client = container.read(apiClientProvider);
    instance = _FakeFuelRepo._internal(client);
    return instance;
  }

  @override
  Future<List<FuelLog>> fetchFuelLogs(String vehicleId) async => [_latestLog];

  @override
  Future<FuelStats> fetchFuelStats(String vehicleId) async => FuelStats(
        avgConsumptionLPer100Km: null,
        avgCostPerKmCents: null,
        totalLiters: 40.0,
        totalSpentCents: 8000,
        monthlySpend: [],
      );

  @override
  Future<FuelLog> createFuelLog(
      String vehicleId, Map<String, dynamic> data) async {
    calls.add({...data, '_vehicleId': vehicleId});
    return _latestLog;
  }
}

class _FakeVehiclesNotifier extends AsyncNotifier<List<Vehicle>>
    implements VehiclesNotifier {
  @override
  Future<List<Vehicle>> build() async => [_fakeVehicle];

  @override
  Future<void> refresh() async {}

  @override
  Future<void> create(Map<String, dynamic> data) async {}

  @override
  Future<void> updateVehicle(String id, Map<String, dynamic> data) async {}

  @override
  Future<void> deleteVehicle(String id) async {}
}

// ─── Widget builder ──────────────────────────────────────────────────────────

Widget _buildSheet(_FakeFuelRepo fakeRepo) {
  return ProviderScope(
    overrides: [
      fuelRepositoryProvider.overrideWithValue(fakeRepo),
      // Use synchronous overrides so data is available on the very first build,
      // ensuring _seedFromLatest receives the log list before _calcSeeded is set.
      meProvider.overrideWith((_) async => _fakeUser),
      vehiclesProvider.overrideWith(() => _FakeVehiclesNotifier()),
      fuelLogsProvider.overrideWith((ref, id) async => [_latestLog]),
      fuelStatsProvider.overrideWith((ref, id) async => FuelStats(
            avgConsumptionLPer100Km: null,
            avgCostPerKmCents: null,
            totalLiters: 40.0,
            totalSpentCents: 8000,
            monthlySpend: [],
          )),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: QuickFuelEntrySheet(vehicleId: 'v-1'),
      ),
    ),
  );
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('QuickFuelEntrySheet — save payload', () {
    testWidgets(
        'saves with isFullTank=true, derived liters≈50, priceCents=10000',
        (tester) async {
      final fakeRepo = _FakeFuelRepo();

      await tester.pumpWidget(_buildSheet(fakeRepo));
      // Let all async providers resolve
      await tester.pumpAndSettle();

      // All TextFields in the sheet at this point:
      final allTextFields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      // Order: Odometer, Total paid, Liters, Price/L
      expect(allTextFields.length, greaterThanOrEqualTo(4),
          reason: 'Sheet should render at least 4 text fields');

      // Enter odometer (1000 km) — first TextField
      await tester.enterText(find.byType(TextField).at(0), '1000');
      await tester.pump();

      // Enter total 100.00 — second TextField (Total paid)
      // per-liter is seeded at 2.00 by _seedFromLatest → liters = 100/2 = 50
      await tester.enterText(find.byType(TextField).at(1), '100.00');
      await tester.pump();

      // Tap Save button
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(fakeRepo.calls, hasLength(1),
          reason: 'createFuelLog should be called exactly once');
      final call = fakeRepo.calls.first;
      expect(call['isFullTank'], isTrue);
      expect((call['liters'] as double), closeTo(50.0, 0.01));
      expect(call['priceCents'], equals(10000));
    });
  });
}
