import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tables/vehicles_table.dart';
import 'tables/dashboard_snapshots_table.dart';
import 'tables/fuel_logs_table.dart';
import 'tables/maintenance_records_table.dart';

part 'app_database.g.dart';

// ---------------------------------------------------------------------------
// Vehicles DAO
// ---------------------------------------------------------------------------

@DriftAccessor(tables: [Vehicles])
class VehiclesDao extends DatabaseAccessor<AppDatabase>
    with _$VehiclesDaoMixin {
  VehiclesDao(super.db);

  Future<List<VehicleRow>> getAll() => select(vehicles).get();

  Future<void> upsertAll(List<VehiclesCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(vehicles, rows));

  Future<void> upsertOne(VehiclesCompanion row) =>
      into(vehicles).insertOnConflictUpdate(row);

  Future<void> deleteById(String id) =>
      (delete(vehicles)..where((t) => t.id.equals(id))).go();

  Future<void> deleteAll() => delete(vehicles).go();
}

// ---------------------------------------------------------------------------
// Dashboard DAO
// ---------------------------------------------------------------------------

@DriftAccessor(tables: [DashboardSnapshots])
class DashboardDao extends DatabaseAccessor<AppDatabase>
    with _$DashboardDaoMixin {
  DashboardDao(super.db);

  Future<DashboardSnapshot?> get() =>
      (select(dashboardSnapshots)..where((t) => t.id.equals(1)))
          .getSingleOrNull();

  Future<void> upsert(String jsonPayload) => into(dashboardSnapshots)
      .insertOnConflictUpdate(DashboardSnapshotsCompanion.insert(
        id: const Value(1),
        payload: jsonPayload,
        cachedAt: DateTime.now().millisecondsSinceEpoch,
      ));
}

// ---------------------------------------------------------------------------
// FuelLogs DAO
// ---------------------------------------------------------------------------

@DriftAccessor(tables: [FuelLogs])
class FuelLogsDao extends DatabaseAccessor<AppDatabase>
    with _$FuelLogsDaoMixin {
  FuelLogsDao(super.db);

  Future<List<FuelLogRow>> getByVehicle(String vehicleId) =>
      (select(fuelLogs)..where((t) => t.vehicleId.equals(vehicleId))).get();

  Future<List<FuelLogRow>> getPending() =>
      (select(fuelLogs)..where((t) => t.syncStatus.equals('pending'))).get();

  Future<void> upsertAll(List<FuelLogsCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(fuelLogs, rows));

  Future<void> upsertOne(FuelLogsCompanion row) =>
      into(fuelLogs).insertOnConflictUpdate(row);

  Future<void> updateSyncStatus(String id, String status) =>
      (update(fuelLogs)..where((t) => t.id.equals(id)))
          .write(FuelLogsCompanion(syncStatus: Value(status)));

  Future<void> deleteById(String id) =>
      (delete(fuelLogs)..where((t) => t.id.equals(id))).go();
}

// ---------------------------------------------------------------------------
// Maintenance DAO
// ---------------------------------------------------------------------------

@DriftAccessor(tables: [MaintenanceRecords])
class MaintenanceDao extends DatabaseAccessor<AppDatabase>
    with _$MaintenanceDaoMixin {
  MaintenanceDao(super.db);

  Future<List<MaintenanceRow>> getByVehicle(String vehicleId) =>
      (select(maintenanceRecords)
            ..where((t) => t.vehicleId.equals(vehicleId)))
          .get();

  Future<List<MaintenanceRow>> getPending() =>
      (select(maintenanceRecords)
            ..where((t) => t.syncStatus.equals('pending')))
          .get();

  Future<void> upsertAll(List<MaintenanceRecordsCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(maintenanceRecords, rows));

  Future<void> upsertOne(MaintenanceRecordsCompanion row) =>
      into(maintenanceRecords).insertOnConflictUpdate(row);

  Future<void> updateSyncStatus(String id, String status) =>
      (update(maintenanceRecords)..where((t) => t.id.equals(id)))
          .write(MaintenanceRecordsCompanion(syncStatus: Value(status)));

  Future<void> deleteById(String id) =>
      (delete(maintenanceRecords)..where((t) => t.id.equals(id))).go();
}

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

@DriftDatabase(
  tables: [Vehicles, DashboardSnapshots, FuelLogs, MaintenanceRecords],
  daos: [VehiclesDao, DashboardDao, FuelLogsDao, MaintenanceDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'drivevault_cache'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(fuelLogs);
            await m.createTable(maintenanceRecords);
          }
        },
      );
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
