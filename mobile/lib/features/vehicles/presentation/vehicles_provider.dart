import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/vehicle_repository.dart';
import '../domain/vehicle.dart';

class VehiclesNotifier extends AsyncNotifier<List<Vehicle>> {
  @override
  Future<List<Vehicle>> build() async {
    return _repo.fetchVehicles();
  }

  VehicleRepository get _repo => ref.read(vehicleRepositoryProvider);

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.fetchVehicles());
  }

  Future<void> create(Map<String, dynamic> data) async {
    final vehicle = await _repo.createVehicle(data);
    state = state.whenData((vehicles) => [...vehicles, vehicle]);
  }

  Future<void> updateVehicle(String id, Map<String, dynamic> data) async {
    final updated = await _repo.updateVehicle(id, data);
    state = state.whenData(
      (vehicles) =>
          vehicles.map((v) => v.id == id ? updated : v).toList(),
    );
  }

  Future<void> deleteVehicle(String id) async {
    await _repo.deleteVehicle(id);
    state = state.whenData(
      (vehicles) => vehicles.where((v) => v.id != id).toList(),
    );
  }
}

final vehiclesProvider =
    AsyncNotifierProvider<VehiclesNotifier, List<Vehicle>>(
      VehiclesNotifier.new,
    );
