import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:drivevault/core/database/app_database.dart';
import 'package:drivevault/core/network/api_client.dart';
import 'package:drivevault/core/sync/sync_service.dart';

@GenerateMocks([ApiClient])
import 'sync_service_test.mocks.dart';

void main() {
  late AppDatabase db;
  late MockApiClient mockApi;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    mockApi = MockApiClient();
    container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      apiClientProvider.overrideWithValue(mockApi),
    ]);
  });

  tearDown(() {
    container.dispose();
    db.close();
  });

  test('pushPending POSTs pending fuel logs and marks synced', () async {
    // Insert a pending fuel log
    await db.fuelLogsDao.upsertOne(FuelLogsCompanion.insert(
      id: 'fl-pending',
      vehicleId: 'v-001',
      date: '2026-06-27',
      liters: 25.0,
      priceCents: 375000,
      odometer: 47000,
      cachedAt: DateTime.now().millisecondsSinceEpoch,
      syncStatus: const Value('pending'),
    ));

    when(mockApi.post(any, body: anyNamed('body'))).thenAnswer(
      (_) async => {
        'id': 'fl-pending',
        'vehicleId': 'v-001',
        'date': '2026-06-27',
        'liters': '25.000',
        'priceCents': 375000,
        'currency': 'LKR',
        'odometer': 47000,
        'isFullTank': true,
        'notes': null,
        'createdAt': '2026-06-27T10:00:00Z',
        'updatedAt': '2026-06-27T10:00:00Z',
      },
    );

    final svc = container.read(syncServiceProvider);
    await svc.pushPending();

    final pending = await db.fuelLogsDao.getPending();
    expect(pending.where((r) => r.id == 'fl-pending'), isEmpty);
  });

  test('pushPending marks failed after all retries exhausted', () async {
    await db.fuelLogsDao.upsertOne(FuelLogsCompanion.insert(
      id: 'fl-fail',
      vehicleId: 'v-001',
      date: '2026-06-27',
      liters: 10.0,
      priceCents: 150000,
      odometer: 48000,
      cachedAt: DateTime.now().millisecondsSinceEpoch,
      syncStatus: const Value('pending'),
    ));

    when(mockApi.post(any, body: anyNamed('body')))
        .thenThrow(Exception('network error'));

    final svc = container.read(syncServiceProvider);
    await svc.pushPending();

    final rows = await db.fuelLogsDao.getByVehicle('v-001');
    final row = rows.firstWhere((r) => r.id == 'fl-fail');
    expect(row.syncStatus, 'failed');
  });

  test('pushPending skips already-synced fuel logs', () async {
    await db.fuelLogsDao.upsertOne(FuelLogsCompanion.insert(
      id: 'fl-synced',
      vehicleId: 'v-001',
      date: '2026-06-27',
      liters: 30.0,
      priceCents: 450000,
      odometer: 49000,
      cachedAt: DateTime.now().millisecondsSinceEpoch,
      // default syncStatus is 'synced'
    ));

    final svc = container.read(syncServiceProvider);
    await svc.pushPending();

    // post should never be called for a synced row
    verifyNever(mockApi.post(any, body: anyNamed('body')));
  });

  test('pushPending POSTs pending maintenance and marks synced', () async {
    await db.maintenanceDao.upsertOne(MaintenanceRecordsCompanion.insert(
      id: 'maint-1',
      vehicleId: 'v-002',
      date: '2026-06-28',
      serviceType: 'Oil Change',
      cachedAt: DateTime.now().millisecondsSinceEpoch,
      syncStatus: const Value('pending'),
    ));

    when(mockApi.post(any, body: anyNamed('body'))).thenAnswer(
      (_) async => {
        'id': 'maint-1',
        'vehicleId': 'v-002',
        'date': '2026-06-28',
        'serviceType': 'Oil Change',
        'createdAt': '2026-06-28T10:00:00Z',
        'updatedAt': '2026-06-28T10:00:00Z',
      },
    );

    final svc = container.read(syncServiceProvider);
    await svc.pushPending();

    final pending = await db.maintenanceDao.getPending();
    expect(pending.where((r) => r.id == 'maint-1'), isEmpty);
  });
}
