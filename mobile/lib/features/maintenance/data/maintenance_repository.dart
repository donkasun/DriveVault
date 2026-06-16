import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/maintenance_record.dart';

class MaintenanceRepository {
  final ApiClient _apiClient;

  MaintenanceRepository(this._apiClient);

  Future<List<MaintenanceRecord>> fetchRecords(String vehicleId) async {
    final list =
        await _apiClient.getList('/vehicles/$vehicleId/maintenance');
    return list.map(MaintenanceRecord.fromJson).toList();
  }

  Future<MaintenanceRecord> createRecord(
      String vehicleId, Map<String, dynamic> data) async {
    final json = await _apiClient.post(
      '/vehicles/$vehicleId/maintenance',
      body: data,
    );
    return MaintenanceRecord.fromJson(json);
  }

  Future<MaintenanceRecord> updateRecord(
      String id, Map<String, dynamic> data) async {
    final json =
        await _apiClient.patch('/maintenance/$id', body: data);
    return MaintenanceRecord.fromJson(json);
  }

  Future<void> deleteRecord(String id) async {
    await _apiClient.delete('/maintenance/$id');
  }
}

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>(
  (ref) => MaintenanceRepository(ref.watch(apiClientProvider)),
);

final maintenanceRecordsProvider =
    FutureProvider.family<List<MaintenanceRecord>, String>(
        (ref, vehicleId) async {
  ref.keepAlive();
  final repo = ref.watch(maintenanceRepositoryProvider);
  return repo.fetchRecords(vehicleId);
});
