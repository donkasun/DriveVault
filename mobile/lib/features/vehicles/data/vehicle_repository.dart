import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/vehicle.dart';

class VehicleRepository {
  final ApiClient _apiClient;

  VehicleRepository(this._apiClient);

  Future<Vehicle> fetchVehicle(String id) async {
    final json = await _apiClient.get('/vehicles/$id');
    return Vehicle.fromJson(json);
  }

  Future<List<Vehicle>> fetchVehicles() async {
    final data = await _apiClient.getList('/vehicles');
    return data.map(Vehicle.fromJson).toList();
  }

  Future<Vehicle> createVehicle(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/vehicles', body: data);
    return Vehicle.fromJson(response);
  }

  Future<Vehicle> updateVehicle(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.patch('/vehicles/$id', body: data);
    return Vehicle.fromJson(response);
  }

  Future<void> deleteVehicle(String id) async {
    await _apiClient.delete('/vehicles/$id');
  }
}

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return VehicleRepository(ref.watch(apiClientProvider));
});

final vehicleProvider =
    FutureProvider.family<Vehicle, String>((ref, id) async {
  final repo = ref.watch(vehicleRepositoryProvider);
  return repo.fetchVehicle(id);
});
