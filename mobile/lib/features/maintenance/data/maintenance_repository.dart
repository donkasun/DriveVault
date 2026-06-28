import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/utils/perf_log.dart';
import '../domain/maintenance_record.dart';

class MaintenanceRepository {
  final ApiClient _apiClient;
  MaintenanceRepository(this._apiClient);

  Future<List<MaintenanceRecord>> fetchRecords(String vehicleId) async {
    final list = await _apiClient.getList('/vehicles/$vehicleId/maintenance');
    return list.map(MaintenanceRecord.fromJson).toList();
  }

  Future<MaintenanceRecord> createRecord(
      String vehicleId, Map<String, dynamic> data) async {
    final json =
        await _apiClient.post('/vehicles/$vehicleId/maintenance', body: data);
    return MaintenanceRecord.fromJson(json);
  }

  Future<MaintenanceRecord> updateRecord(
      String id, Map<String, dynamic> data) async {
    final json = await _apiClient.patch('/maintenance/$id', body: data);
    return MaintenanceRecord.fromJson(json);
  }

  Future<void> deleteRecord(String id) async {
    await _apiClient.delete('/maintenance/$id');
  }
}

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>(
  (ref) => MaintenanceRepository(ref.watch(apiClientProvider)),
);

// ---------------------------------------------------------------------------
// Cache-first maintenance notifier
// ---------------------------------------------------------------------------

class MaintenanceNotifier extends AsyncNotifier<List<MaintenanceRecord>> {
  MaintenanceNotifier(this._vehicleId);

  final String _vehicleId;

  @override
  Future<List<MaintenanceRecord>> build() async {
    PerfLog.start('maintenance.$_vehicleId');
    ref.keepAlive();
    final db = ref.read(appDatabaseProvider);
    final cached = await db.maintenanceDao.getByVehicle(_vehicleId);

    if (cached.isNotEmpty) {
      PerfLog.mark('maintenance.$_vehicleId', 'cache');
      _refreshInBackground();
      return cached.map(maintenanceFromDriftRow).toList();
    }

    final records = await ref
        .read(maintenanceRepositoryProvider)
        .fetchRecords(_vehicleId);
    await db.maintenanceDao
        .upsertAll(records.map((r) => r.toDrift()).toList());
    PerfLog.mark('maintenance.$_vehicleId', 'network');
    return records;
  }

  void _refreshInBackground() {
    ref
        .read(maintenanceRepositoryProvider)
        .fetchRecords(_vehicleId)
        .then((records) async {
      final db = ref.read(appDatabaseProvider);
      await db.maintenanceDao
          .upsertAll(records.map((r) => r.toDrift()).toList());
      PerfLog.mark('maintenance.$_vehicleId', 'network');
      if (state.hasValue) state = AsyncData(records);
    }).catchError((_) {});
  }

  Future<void> createOptimistic(
      String vehicleId, Map<String, dynamic> formData) async {
    final id = generateUuidV4();
    final record = MaintenanceRecord(
      id: id,
      vehicleId: vehicleId,
      date: formData['date'] as String,
      serviceType: formData['serviceType'] as String,
      category: formData['category'] as String?,
      costCents: formData['costCents'] as int?,
      currency: 'LKR',
      odometer: formData['odometer'] as int?,
      workshop: formData['workshop'] as String?,
      notes: formData['notes'] as String?,
      source: 'manual',
      createdAt: DateTime.now(),
    );

    final db = ref.read(appDatabaseProvider);
    await db.maintenanceDao.upsertOne(record.toDrift(syncStatus: 'pending'));
    state = state.whenData((records) => [record, ...records]);

    // Fire-and-forget sync.
    ref.read(syncServiceProvider).pushPending().catchError((_) {});
  }

  Future<void> deleteRecord(String id) async {
    await ref.read(maintenanceRepositoryProvider).deleteRecord(id);
    final db = ref.read(appDatabaseProvider);
    await db.maintenanceDao.deleteById(id);
    state = state.whenData((r) => r.where((rec) => rec.id != id).toList());
  }
}

final maintenanceRecordsProvider = AsyncNotifierProvider.family<
    MaintenanceNotifier, List<MaintenanceRecord>, String>(
  (vehicleId) => MaintenanceNotifier(vehicleId),
);
