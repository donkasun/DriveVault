import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:drivevault/features/documents/data/document_repository.dart';
import 'package:drivevault/features/documents/domain/document.dart';
import 'package:drivevault/features/fuel/data/fuel_repository.dart';
import 'package:drivevault/features/fuel/domain/fuel_stats.dart';
import 'package:drivevault/features/maintenance/data/maintenance_repository.dart';
import 'package:drivevault/features/maintenance/domain/maintenance_record.dart';
import 'package:drivevault/features/profile/data/user_repository.dart';
import 'package:drivevault/features/profile/domain/user.dart';
import 'package:drivevault/features/vehicles/domain/vehicle.dart';
import 'package:drivevault/features/vehicles/presentation/garage_screen.dart';
import 'package:drivevault/features/vehicles/presentation/vehicles_provider.dart';

final _fakeUser = AppUser(
  id: 'u1',
  firebaseUid: 'uid1',
  email: 'test@example.com',
  currency: 'USD',
  distanceUnit: 'km',
  createdAt: DateTime(2026, 1, 1),
);

const _fakeFuelStats = FuelStats(
  totalLiters: 0,
  totalSpentCents: 0,
  monthlySpend: [],
);

Vehicle _makeVehicle({
  String id = 'v1',
  String make = 'Toyota',
  String model = 'Hilux',
  int? year = 2020,
  String? registrationNumber = 'ABC-1234',
  int? currentMileage = 48000,
}) {
  final now = DateTime(2026, 6, 8);
  return Vehicle(
    id: id,
    make: make,
    model: model,
    year: year,
    registrationNumber: registrationNumber,
    currency: 'USD',
    currentMileage: currentMileage,
    createdAt: now,
    updatedAt: now,
  );
}

/// Wraps a widget with providers and minimal router needed for testing.
Widget _wrapWithProvider(
  Widget child,
  List<Vehicle> vehicles,
) {
  final router = GoRouter(
    initialLocation: '/test',
    routes: [
      GoRoute(path: '/test', builder: (_, _) => child),
      GoRoute(
        path: '/garage/add-vehicle',
        builder: (_, _) => const Scaffold(body: Text('Add Vehicle')),
      ),
      GoRoute(
        path: '/garage/vehicle/:id',
        builder: (_, state) =>
            Scaffold(body: Text('Detail ${state.pathParameters["id"]}')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      vehiclesProvider.overrideWith(
        () => _FakeVehiclesNotifier(vehicles),
      ),
      meProvider.overrideWith((ref) async => _fakeUser),
      fuelStatsProvider('v1').overrideWith((ref) async => _fakeFuelStats),
      maintenanceRecordsProvider('v1').overrideWith(
        (ref) async => <MaintenanceRecord>[],
      ),
      documentsProvider('v1').overrideWith(
        (ref) async => <Document>[],
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('loaded state: shows VehicleCard with vehicle name',
      (tester) async {
    final vehicle = _makeVehicle();

    await tester.pumpWidget(_wrapWithProvider(const GarageScreen(), [vehicle]));
    await tester.pumpAndSettle();

    expect(find.text('Toyota Hilux 2020'), findsOneWidget);
    expect(find.text('ABC-1234'), findsOneWidget);
  });

  testWidgets('empty state: shows add-vehicle prompt', (tester) async {
    await tester.pumpWidget(_wrapWithProvider(const GarageScreen(), []));
    await tester.pumpAndSettle();

    expect(find.text('No vehicles yet'), findsOneWidget);
    expect(find.text('Add your first vehicle'), findsOneWidget);
  });

  testWidgets('loaded state: shows dashed Add Vehicle card', (tester) async {
    final vehicle = _makeVehicle();

    await tester.pumpWidget(_wrapWithProvider(const GarageScreen(), [vehicle]));
    await tester.pumpAndSettle();

    expect(find.text('Add Vehicle'), findsOneWidget);
  });
}

class _FakeVehiclesNotifier extends VehiclesNotifier {
  final List<Vehicle> _vehicles;

  _FakeVehiclesNotifier(this._vehicles);

  @override
  Future<List<Vehicle>> build() async => _vehicles;
}
