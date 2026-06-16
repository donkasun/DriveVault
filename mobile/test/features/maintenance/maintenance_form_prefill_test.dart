import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drivevault/features/maintenance/presentation/maintenance_form_screen.dart';
import 'package:drivevault/features/profile/data/user_repository.dart';
import 'package:drivevault/features/profile/domain/user.dart';
import 'package:drivevault/features/vehicles/domain/vehicle.dart';
import 'package:drivevault/features/vehicles/presentation/vehicles_provider.dart';

final _fakeUser = AppUser(
  id: 'u-1',
  firebaseUid: 'uid-1',
  email: 'test@test.com',
  currency: 'LKR',
  distanceUnit: 'km',
  createdAt: DateTime(2025),
);

final _fakeVehicle = Vehicle(
  id: 'v-1',
  make: 'Toyota',
  model: 'Corolla',
  year: 2020,
  currency: 'LKR',
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
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
  testWidgets('pre-fills service type / cost / odometer from initial params',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        meProvider.overrideWith((_) async => _fakeUser),
        vehiclesProvider.overrideWith(() => _FakeVehiclesNotifier()),
      ],
      child: const MaterialApp(
        home: MaintenanceFormScreen(
          vehicleId: 'v-1',
          initialServiceType: 'Oil Change',
          initialCost: '50.00',
          initialOdometer: '1000',
          initialDate: '2026-06-10',
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Oil Change'), findsWidgets);
    expect(find.text('50.00'), findsOneWidget);
    expect(find.text('1000'), findsOneWidget);
    expect(find.text('2026-06-10'), findsOneWidget);
  });
}
