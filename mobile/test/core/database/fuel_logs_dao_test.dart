import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drivevault/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('FuelLogsDao upsert and getByVehicle', () async {
    final row = FuelLogsCompanion.insert(
      id: 'fl-001',
      vehicleId: 'v-001',
      date: '2026-06-27',
      liters: 30.5,
      priceCents: 450000,
      odometer: 45000,
      cachedAt: 0,
    );
    await db.fuelLogsDao.upsertOne(row);
    final results = await db.fuelLogsDao.getByVehicle('v-001');
    expect(results.length, 1);
    expect(results.first.id, 'fl-001');
  });

  test('FuelLogsDao updateSyncStatus changes status', () async {
    await db.fuelLogsDao.upsertOne(FuelLogsCompanion.insert(
      id: 'fl-002',
      vehicleId: 'v-001',
      date: '2026-06-27',
      liters: 20.0,
      priceCents: 300000,
      odometer: 46000,
      cachedAt: 0,
      syncStatus: const Value('pending'),
    ));
    await db.fuelLogsDao.updateSyncStatus('fl-002', 'synced');
    final pending = await db.fuelLogsDao.getPending();
    expect(pending.where((r) => r.id == 'fl-002'), isEmpty);
  });
}
