import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/utils/perf_log.dart';
import '../domain/fuel_log.dart';
import '../domain/fuel_stats.dart';

class FuelRepository {
  final ApiClient _apiClient;

  FuelRepository(this._apiClient);

  Future<List<FuelLog>> fetchFuelLogs(String vehicleId) async {
    final list = await _apiClient.getList('/vehicles/$vehicleId/fuel-logs');
    return list.map(FuelLog.fromJson).toList();
  }

  Future<FuelStats> fetchFuelStats(String vehicleId) async {
    final json = await _apiClient.get('/vehicles/$vehicleId/fuel-stats');
    return FuelStats.fromJson(json);
  }

  Future<FuelLog> createFuelLog(
      String vehicleId, Map<String, dynamic> data) async {
    final json = await _apiClient.post(
      '/vehicles/$vehicleId/fuel-logs',
      body: data,
    );
    return FuelLog.fromJson(json);
  }

  Future<FuelLog> updateFuelLog(
      String id, Map<String, dynamic> data) async {
    final json = await _apiClient.patch('/fuel-logs/$id', body: data);
    return FuelLog.fromJson(json);
  }

  Future<void> deleteFuelLog(String id) async {
    await _apiClient.delete('/fuel-logs/$id');
  }
}

final fuelRepositoryProvider = Provider<FuelRepository>(
  (ref) => FuelRepository(ref.watch(apiClientProvider)),
);

// ---------------------------------------------------------------------------
// Cache-first fuel logs notifier
// ---------------------------------------------------------------------------

class FuelLogsNotifier extends AsyncNotifier<List<FuelLog>> {
  FuelLogsNotifier(this._vehicleId);

  final String _vehicleId;

  @override
  Future<List<FuelLog>> build() async {
    PerfLog.start('fuelLogs.$_vehicleId');
    ref.keepAlive();
    final db = ref.read(appDatabaseProvider);
    final cached = await db.fuelLogsDao.getByVehicle(_vehicleId);

    if (cached.isNotEmpty) {
      PerfLog.mark('fuelLogs.$_vehicleId', 'cache');
      _refreshInBackground();
      return cached.map(fuelLogFromDriftRow).toList();
    }

    final logs =
        await ref.read(fuelRepositoryProvider).fetchFuelLogs(_vehicleId);
    await db.fuelLogsDao.upsertAll(logs.map((l) => l.toDrift()).toList());
    PerfLog.mark('fuelLogs.$_vehicleId', 'network');
    return logs;
  }

  void _refreshInBackground() {
    ref.read(fuelRepositoryProvider).fetchFuelLogs(_vehicleId).then(
      (logs) async {
        final db = ref.read(appDatabaseProvider);
        await db.fuelLogsDao.upsertAll(logs.map((l) => l.toDrift()).toList());
        PerfLog.mark('fuelLogs.$_vehicleId', 'network');
        if (state.hasValue) state = AsyncData(logs);
      },
    ).catchError((_) {});
  }

  /// Optimistic create: writes locally as pending, returns immediately,
  /// then pushes to the API in the background.
  Future<void> createOptimistic(
      String vehicleId, Map<String, dynamic> formData) async {
    final id = generateUuidV4();
    final now = DateTime.now();
    final log = FuelLog(
      id: id,
      vehicleId: vehicleId,
      date: formData['date'] as String,
      liters: (formData['liters'] as num).toDouble(),
      priceCents: formData['priceCents'] as int,
      currency: 'LKR',
      odometer: formData['odometer'] as int,
      isFullTank: formData['isFullTank'] as bool? ?? true,
      notes: formData['notes'] as String?,
      createdAt: now,
    );

    final db = ref.read(appDatabaseProvider);
    await db.fuelLogsDao.upsertOne(log.toDrift(syncStatus: 'pending'));
    state = state.whenData((logs) => [log, ...logs]);

    // Fire-and-forget sync.
    ref.read(syncServiceProvider).pushPending().catchError((_) {});
  }

  Future<void> deleteFuelLog(String id) async {
    await ref.read(fuelRepositoryProvider).deleteFuelLog(id);
    final db = ref.read(appDatabaseProvider);
    await db.fuelLogsDao.deleteById(id);
    state = state.whenData((logs) => logs.where((l) => l.id != id).toList());
  }
}

final fuelLogsProvider =
    AsyncNotifierProvider.family<FuelLogsNotifier, List<FuelLog>, String>(
  (vehicleId) => FuelLogsNotifier(vehicleId),
);

final fuelStatsProvider =
    FutureProvider.family<FuelStats, String>((ref, vehicleId) async {
  ref.keepAlive();
  final repo = ref.watch(fuelRepositoryProvider);
  return repo.fetchFuelStats(vehicleId);
});
