import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drivevault/core/database/app_database.dart';
import 'package:drivevault/features/vehicles/domain/vehicle.dart';

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
}
