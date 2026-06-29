import 'package:drift/drift.dart';

@DataClassName('MaintenanceRow')
class MaintenanceRecords extends Table {
  TextColumn get id => text()();
  TextColumn get vehicleId => text()();
  TextColumn get date => text()();
  TextColumn get serviceType => text()();
  TextColumn get category => text().nullable()();
  IntColumn get costCents => integer().nullable()();
  TextColumn get currency => text().nullable()();
  IntColumn get odometer => integer().nullable()();
  TextColumn get workshop => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  // 'synced' | 'pending' | 'failed'
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();
  IntColumn get cachedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
