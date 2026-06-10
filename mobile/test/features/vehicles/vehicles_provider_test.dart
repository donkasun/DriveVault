import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:drivevault/features/vehicles/data/vehicle_repository.dart';
import 'package:drivevault/features/vehicles/domain/vehicle.dart';
import 'package:drivevault/features/vehicles/presentation/vehicles_provider.dart';

@GenerateMocks([VehicleRepository])
import 'vehicles_provider_test.mocks.dart';

Vehicle _makeVehicle(String id, {String make = 'Toyota'}) {
  final now = DateTime(2026, 6, 8);
  return Vehicle(
    id: id,
    make: make,
    model: 'Hilux',
    currency: 'USD',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late MockVehicleRepository mockRepo;

  setUp(() {
    mockRepo = MockVehicleRepository();
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        vehicleRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  }

  test('initial state transitions loading → loaded', () async {
    final v = _makeVehicle('v1');
    when(mockRepo.fetchVehicles()).thenAnswer((_) async => [v]);

    final container = makeContainer();
    addTearDown(container.dispose);

    // Initially loading
    expect(
      container.read(vehiclesProvider),
      const TypeMatcher<AsyncLoading<List<Vehicle>>>(),
    );

    // Wait for build to complete
    final vehicles = await container.read(vehiclesProvider.future);
    expect(vehicles.length, 1);
    expect(vehicles.first.id, 'v1');
  });

  test('create adds vehicle to state', () async {
    final v1 = _makeVehicle('v1');
    final v2 = _makeVehicle('v2', make: 'Honda');
    when(mockRepo.fetchVehicles()).thenAnswer((_) async => [v1]);
    when(mockRepo.createVehicle(any)).thenAnswer((_) async => v2);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(vehiclesProvider.future);

    await container.read(vehiclesProvider.notifier).create({'make': 'Honda', 'model': 'Civic'});

    final vehicles = await container.read(vehiclesProvider.future);
    expect(vehicles.length, 2);
    expect(vehicles.last.id, 'v2');
  });

  test('delete removes vehicle from state', () async {
    final v1 = _makeVehicle('v1');
    final v2 = _makeVehicle('v2');
    when(mockRepo.fetchVehicles()).thenAnswer((_) async => [v1, v2]);
    when(mockRepo.deleteVehicle('v1')).thenAnswer((_) async {});

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(vehiclesProvider.future);
    await container.read(vehiclesProvider.notifier).deleteVehicle('v1');

    final vehicles = await container.read(vehiclesProvider.future);
    expect(vehicles.length, 1);
    expect(vehicles.first.id, 'v2');
  });

  test('update replaces vehicle in state', () async {
    final v1 = _makeVehicle('v1');
    final updated = v1.copyWith(make: 'Mitsubishi');
    when(mockRepo.fetchVehicles()).thenAnswer((_) async => [v1]);
    when(mockRepo.updateVehicle('v1', any)).thenAnswer((_) async => updated);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(vehiclesProvider.future);
    await container.read(vehiclesProvider.notifier).updateVehicle('v1', {'make': 'Mitsubishi'});

    final vehicles = await container.read(vehiclesProvider.future);
    expect(vehicles.first.make, 'Mitsubishi');
  });
}
