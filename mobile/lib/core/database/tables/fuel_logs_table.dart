import 'package:drift/drift.dart';

@DataClassName('FuelLogRow')
class FuelLogs extends Table {
  TextColumn get id => text()();
  TextColumn get vehicleId => text()();
  TextColumn get date => text()();
  RealColumn get liters => real()();
  IntColumn get priceCents => integer()();
  TextColumn get currency => text().withDefault(const Constant('LKR'))();
  IntColumn get odometer => integer()();
  BoolColumn get isFullTank => boolean().withDefault(const Constant(true))();
  TextColumn get notes => text().nullable()();
  // 'synced' | 'pending' | 'failed'
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();
  IntColumn get cachedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
