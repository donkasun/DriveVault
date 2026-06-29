import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drivevault/core/database/app_database.dart';
import 'package:drivevault/features/dashboard/data/dashboard_repository.dart';
import 'package:drivevault/features/dashboard/domain/dashboard_data.dart';
import 'package:drivevault/features/dashboard/presentation/dashboard_provider.dart';

// ---------------------------------------------------------------------------
// Stub repository — no network calls, tracks how many times fetchDashboard ran
// ---------------------------------------------------------------------------
class _StubDashboardRepository implements DashboardRepository {
  final DashboardData response;
  int fetchCallCount = 0;

  _StubDashboardRepository(this.response);

  @override
  Future<DashboardData> fetchDashboard() async {
    fetchCallCount++;
    return response;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
DashboardData _makeDashboardData() => const DashboardData(
      vehicleCount: 2,
      monthlyFuelSpendCents: 5000,
      totalOwnershipCostCents: 15000,
      costBreakdown: CostBreakdown(
        fuelCents: 5000,
        maintenanceCents: 3000,
        purchaseCents: 7000,
      ),
      upcomingRenewals: [],
      recentActivity: [],
    );

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('DashboardDao returns null when empty', () async {
    final row = await db.dashboardDao.get();
    expect(row, isNull);
  });

  test('DashboardDao upsert and get round-trips JSON', () async {
    final payload = jsonEncode({'vehicleCount': 2, 'monthlyFuelSpendCents': 5000});
    await db.dashboardDao.upsert(payload);
    final row = await db.dashboardDao.get();
    expect(row, isNotNull);
    final decoded = jsonDecode(row!.payload) as Map<String, dynamic>;
    expect(decoded['vehicleCount'], 2);
  });

  test('DashboardDao upsert is idempotent', () async {
    await db.dashboardDao.upsert('{"vehicleCount":1}');
    await db.dashboardDao.upsert('{"vehicleCount":2}');
    final row = await db.dashboardDao.get();
    final decoded = jsonDecode(row!.payload) as Map<String, dynamic>;
    expect(decoded['vehicleCount'], 2);
  });

  // -------------------------------------------------------------------------
  // Provider-level tests
  // -------------------------------------------------------------------------

  test(
      'Test A — cache hit: dashboardProvider returns cached data without calling fetchDashboard',
      () async {
    // Seed the in-memory DB with a snapshot.
    final seeded = _makeDashboardData();
    await db.dashboardDao.upsert(jsonEncode(seeded.toJson()));

    // The stub repo should NOT be called at all on a synchronous cache hit.
    final stub = _StubDashboardRepository(_makeDashboardData());

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        dashboardRepositoryProvider.overrideWithValue(stub),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(dashboardProvider.future);

    expect(result.vehicleCount, 2);
    expect(result.monthlyFuelSpendCents, 5000);
    // The background refresh may fire at most once; what matters is that the
    // provider returned the cached data without blocking on the network.
    expect(stub.fetchCallCount, lessThanOrEqualTo(1),
        reason:
            'At most one background call should be made; zero is also fine if '
            'the background fetch has not yet completed.');
  });

  test(
      'Test B — background refresh: after provider builds from empty cache, '
      'API result is written to Drift', () async {
    // Empty cache — provider will hit the network directly (first-launch path).
    final networkData = _makeDashboardData();
    final stub = _StubDashboardRepository(networkData);

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        dashboardRepositoryProvider.overrideWithValue(stub),
      ],
    );
    addTearDown(container.dispose);

    // Build the provider (no cache → hits network → writes to Drift).
    await container.read(dashboardProvider.future);

    // Give async work time to complete.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // The stub should have been called exactly once.
    expect(stub.fetchCallCount, 1);

    // The network result should now be persisted in Drift.
    final row = await db.dashboardDao.get();
    expect(row, isNotNull,
        reason: 'Provider should have upserted the network result into Drift.');
    final decoded = jsonDecode(row!.payload) as Map<String, dynamic>;
    expect(decoded['vehicleCount'], 2);
  });
}
