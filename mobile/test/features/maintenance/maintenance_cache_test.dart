import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drivevault/core/database/app_database.dart';
import 'package:drivevault/features/maintenance/domain/maintenance_record.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('maintenanceFromDriftRow round-trips', () async {
    final record = MaintenanceRecord(
      id: 'mr-001',
      vehicleId: 'v-001',
      date: '2026-06-20',
      serviceType: 'Oil change',
      source: 'manual',
      createdAt: DateTime.utc(2026, 6, 20),
    );
    await db.maintenanceDao.upsertOne(record.toDrift());
    final rows = await db.maintenanceDao.getByVehicle('v-001');
    expect(rows.length, 1);
    expect(maintenanceFromDriftRow(rows.first).serviceType, 'Oil change');
  });
}
