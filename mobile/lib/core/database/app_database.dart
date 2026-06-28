import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tables/vehicles_table.dart';
import 'tables/dashboard_snapshots_table.dart';

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
// Database
// ---------------------------------------------------------------------------

@DriftDatabase(
  tables: [Vehicles, DashboardSnapshots],
  daos: [VehiclesDao, DashboardDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'drivevault_cache'));

  @override
  int get schemaVersion => 1;
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
