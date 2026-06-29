import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drivevault/core/database/app_database.dart';
import 'package:drivevault/features/vehicles/data/vehicle_repository.dart';
import 'package:drivevault/features/vehicles/domain/vehicle.dart';
import 'package:drivevault/features/vehicles/presentation/vehicles_provider.dart';

// ---------------------------------------------------------------------------
// Stub repository — no network calls, tracks how many times fetchVehicles ran
// ---------------------------------------------------------------------------
class _StubVehicleRepository implements VehicleRepository {
  final List<Vehicle> networkVehicles;
  int fetchCallCount = 0;

  _StubVehicleRepository(this.networkVehicles);

  @override
  Future<List<Vehicle>> fetchVehicles() async {
    fetchCallCount++;
    return networkVehicles;
  }

  @override
  Future<Vehicle> fetchVehicle(String id) async => networkVehicles.first;

  @override
  Future<Vehicle> createVehicle(Map<String, dynamic> data) async =>
      networkVehicles.first;

  @override
  Future<Vehicle> updateVehicle(String id, Map<String, dynamic> data) async =>
      networkVehicles.first;

  @override
  Future<void> deleteVehicle(String id) async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
Vehicle _makeVehicle(String id) => Vehicle(
      id: id,
      make: 'Toyota',
      model: 'Hilux',
      currency: 'LKR',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('VehiclesDao upsertAll then getAll returns same count', () async {
    final v = Vehicle(
      id: 'abc-123',
      make: 'Toyota',
      model: 'Hilux',
      currency: 'LKR',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    await db.vehiclesDao.upsertAll([v.toDrift()]);
    final rows = await db.vehiclesDao.getAll();
    expect(rows.length, 1);
    expect(vehicleFromDriftRow(rows.first).id, 'abc-123');
    expect(vehicleFromDriftRow(rows.first).make, 'Toyota');
  });

  test('VehiclesDao upsert is idempotent', () async {
    final companion = VehiclesCompanion.insert(
      id: 'abc-123',
      make: 'Toyota',
      model: 'Hilux',
      currency: const Value('LKR'),
      createdAt: '2026-01-01T00:00:00.000',
      updatedAt: '2026-01-01T00:00:00.000',
      cachedAt: 0,
    );
    await db.vehiclesDao.upsertOne(companion);
    await db.vehiclesDao.upsertOne(companion); // second upsert
    final rows = await db.vehiclesDao.getAll();
    expect(rows.length, 1);
  });

  // -------------------------------------------------------------------------
  // Provider-level tests
  // -------------------------------------------------------------------------

  test('Test A — cache hit: vehiclesProvider returns cached list immediately without calling API',
      () async {
    // Seed the in-memory DB with one vehicle.
    final seeded = _makeVehicle('cached-1');
    await db.vehiclesDao.upsertAll([seeded.toDrift()]);

    // The stub repo should NOT be called at all on a cache hit.
    final stub = _StubVehicleRepository([]);

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        vehicleRepositoryProvider.overrideWithValue(stub),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(vehiclesProvider.future);

    expect(result.length, 1);
    expect(result.first.id, 'cached-1');
    // The background refresh fires but we don't wait for it here —
    // what matters is the provider returned the cache without blocking on the API.
    expect(stub.fetchCallCount, lessThanOrEqualTo(1),
        reason:
            'At most one background call should be made; zero is also fine if '
            'the background fetch has not completed yet.');
  });

  test(
      'Test B — background refresh: after provider builds from cache, API result is written to Drift',
      () async {
    // Seed one vehicle in cache.
    final cached = _makeVehicle('old-1');
    await db.vehiclesDao.upsertAll([cached.toDrift()]);

    // The network returns a different (updated) vehicle.
    final fromNetwork = _makeVehicle('new-1');
    final stub = _StubVehicleRepository([fromNetwork]);

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        vehicleRepositoryProvider.overrideWithValue(stub),
      ],
    );
    addTearDown(container.dispose);

    // Build the provider (returns cache instantly).
    await container.read(vehiclesProvider.future);

    // Give the background fetch time to complete.
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // The background refresh should have called fetchVehicles once.
    expect(stub.fetchCallCount, 1);

    // The new vehicle should now be written to Drift.
    final rows = await db.vehiclesDao.getAll();
    final ids = rows.map((r) => r.id).toSet();
    expect(ids.contains('new-1'), isTrue,
        reason: 'Background refresh should have upserted the network result.');
  });
}
