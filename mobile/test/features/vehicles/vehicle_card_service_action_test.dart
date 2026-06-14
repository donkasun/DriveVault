import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drivevault/features/maintenance/data/maintenance_repository.dart';
import 'package:drivevault/features/maintenance/domain/maintenance_record.dart';
import 'package:drivevault/features/fuel/data/fuel_repository.dart';
import 'package:drivevault/features/fuel/domain/fuel_stats.dart';
import 'package:drivevault/features/profile/data/user_repository.dart';
import 'package:drivevault/features/profile/domain/user.dart';
import 'package:drivevault/features/documents/data/document_repository.dart';
import 'package:drivevault/features/vehicles/domain/vehicle.dart';
import 'package:drivevault/features/vehicles/presentation/vehicles_provider.dart';
import 'package:drivevault/features/vehicles/presentation/widgets/vehicle_card.dart';

final _fakeVehicle = Vehicle(
  id: 'v-1',
  make: 'Toyota',
  model: 'Corolla',
  year: 2020,
  currency: 'LKR',
  currentMileage: 50000,
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);

final _fakeUser = AppUser(
  id: 'u-1',
  firebaseUid: 'uid-1',
  email: 'test@test.com',
  currency: 'LKR',
  distanceUnit: 'km',
  createdAt: DateTime(2025),
);

class _FakeVehiclesNotifier extends VehiclesNotifier {
  @override
  Future<List<Vehicle>> build() async => [_fakeVehicle];
  @override
  Future<void> refresh() async {}
  @override
  Future<void> create(Map<String, dynamic> data) async {}
  @override
  Future<void> updateVehicle(String id, Map<String, dynamic> data) async {}
  @override
  Future<void> deleteVehicle(String id) async {}
}

void main() {
  testWidgets('tapping Service opens the quick maintenance sheet',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        meProvider.overrideWith((_) async => _fakeUser),
        vehiclesProvider.overrideWith(() => _FakeVehiclesNotifier()),
        maintenanceRecordsProvider
            .overrideWith((ref, id) async => <MaintenanceRecord>[]),
        fuelStatsProvider.overrideWith((ref, id) async => FuelStats(
              avgConsumptionLPer100Km: null,
              avgCostPerKmCents: null,
              totalLiters: 0,
              totalSpentCents: 0,
              monthlySpend: [],
            )),
        documentsProvider.overrideWith((ref, id) async => []),
      ],
      child: MaterialApp(
        home: Scaffold(body: VehicleCard(vehicle: _fakeVehicle)),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Service'));
    await tester.pumpAndSettle();

    expect(find.text('Log service'), findsOneWidget);
  });
}
