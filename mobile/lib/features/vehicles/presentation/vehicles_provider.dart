import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/perf_log.dart';
import '../data/vehicle_repository.dart';
import '../domain/vehicle.dart';

class VehiclesNotifier extends AsyncNotifier<List<Vehicle>> {
  @override
  Future<List<Vehicle>> build() async {
    ref.keepAlive();
    PerfLog.start('vehicles');
    final db = ref.read(appDatabaseProvider);
    final cached = await db.vehiclesDao.getAll();

    if (cached.isNotEmpty) {
      PerfLog.mark('vehicles', 'cache');
      _refreshInBackground();
      return cached.map(vehicleFromDriftRow).toList();
    }

    // First launch — no cache yet.
    final vehicles = await _repo.fetchVehicles();
    await db.vehiclesDao.upsertAll(vehicles.map((v) => v.toDrift()).toList());
    PerfLog.mark('vehicles', 'network');
    return vehicles;
  }

  void _refreshInBackground() {
    _repo.fetchVehicles().then((vehicles) async {
      final db = ref.read(appDatabaseProvider);
      await db.vehiclesDao.upsertAll(vehicles.map((v) => v.toDrift()).toList());
      PerfLog.mark('vehicles', 'network');
      if (state.hasValue) state = AsyncData(vehicles);
    }).onError<Exception>((e, _) {
      // Network failure — keep showing cached data silently.
    });
  }

  VehicleRepository get _repo => ref.read(vehicleRepositoryProvider);

  Future<void> refresh() async {
    _refreshInBackground();
  }

  Future<void> create(Map<String, dynamic> data) async {
    final vehicle = await _repo.createVehicle(data);
    final db = ref.read(appDatabaseProvider);
    await db.vehiclesDao.upsertOne(vehicle.toDrift());
    state = state.whenData((vehicles) => [...vehicles, vehicle]);
  }

  Future<void> updateVehicle(String id, Map<String, dynamic> data) async {
    final updated = await _repo.updateVehicle(id, data);
    final db = ref.read(appDatabaseProvider);
    await db.vehiclesDao.upsertOne(updated.toDrift());
    state = state.whenData(
      (vehicles) => vehicles.map((v) => v.id == id ? updated : v).toList(),
    );
  }

  Future<void> deleteVehicle(String id) async {
    await _repo.deleteVehicle(id);
    final db = ref.read(appDatabaseProvider);
    await db.vehiclesDao.deleteById(id);
    state = state.whenData(
      (vehicles) => vehicles.where((v) => v.id != id).toList(),
    );
  }
}

final vehiclesProvider =
    AsyncNotifierProvider<VehiclesNotifier, List<Vehicle>>(
      VehiclesNotifier.new,
    );
