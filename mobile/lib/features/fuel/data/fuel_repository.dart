import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/fuel_log.dart';
import '../domain/fuel_stats.dart';

class FuelRepository {
  final ApiClient _apiClient;

  FuelRepository(this._apiClient);

  Future<List<FuelLog>> fetchFuelLogs(String vehicleId) async {
    final list =
        await _apiClient.getList('/vehicles/$vehicleId/fuel-logs');
    return list.map(FuelLog.fromJson).toList();
  }

  Future<FuelStats> fetchFuelStats(String vehicleId) async {
    final json =
        await _apiClient.get('/vehicles/$vehicleId/fuel-stats');
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

final fuelLogsProvider =
    FutureProvider.family<List<FuelLog>, String>((ref, vehicleId) async {
  ref.keepAlive();
  final repo = ref.watch(fuelRepositoryProvider);
  return repo.fetchFuelLogs(vehicleId);
});

final fuelStatsProvider =
    FutureProvider.family<FuelStats, String>((ref, vehicleId) async {
  ref.keepAlive();
  final repo = ref.watch(fuelRepositoryProvider);
  return repo.fetchFuelStats(vehicleId);
});
