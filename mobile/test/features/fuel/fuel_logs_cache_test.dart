import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drivevault/core/database/app_database.dart';
import 'package:drivevault/features/fuel/domain/fuel_log.dart';

final _epoch = DateTime.utc(2026, 1, 1);

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('fuelLogFromDriftRow round-trips correctly', () async {
    const vehicleId = 'v-001';
    final log = FuelLog(
      id: 'fl-test',
      vehicleId: vehicleId,
      date: '2026-06-27',
      liters: 30.5,
      priceCents: 450000,
      currency: 'LKR',
      odometer: 45000,
      isFullTank: true,
      createdAt: _epoch,
    );
    await db.fuelLogsDao.upsertOne(log.toDrift());
    final rows = await db.fuelLogsDao.getByVehicle(vehicleId);
    expect(rows.length, 1);
    final roundTripped = fuelLogFromDriftRow(rows.first);
    expect(roundTripped.id, 'fl-test');
    expect(roundTripped.liters, 30.5);
    expect(roundTripped.priceCents, 450000);
  });
}

