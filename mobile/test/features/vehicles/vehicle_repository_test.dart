import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:drivevault/core/network/api_client.dart';
import 'package:drivevault/features/vehicles/data/vehicle_repository.dart';

@GenerateMocks([ApiClient])
import 'vehicle_repository_test.mocks.dart';

void main() {
  late MockApiClient mockApiClient;
  late VehicleRepository repository;

  setUp(() {
    mockApiClient = MockApiClient();
    repository = VehicleRepository(mockApiClient);
  });

  final vehicleJson = {
    'id': 'abc-123',
    'make': 'Toyota',
    'model': 'Hilux',
    'year': 2020,
    'registrationNumber': 'ABC-1234',
    'vin': null,
    'purchaseDate': '2020-03-15',
    'purchasePriceCents': 3500000,
    'currency': 'USD',
    'currentMileage': 48000,
    'vehicleType': 'pickup',
    'photoUrl': null,
    'photoPublicId': null,
    'createdAt': '2026-06-08T10:00:00Z',
    'updatedAt': '2026-06-08T10:00:00Z',
  };

  group('fetchVehicles', () {
    test('maps JSON correctly to Vehicle list', () async {
      when(mockApiClient.getList('/vehicles', queryParams: null))
          .thenAnswer((_) async => [vehicleJson]);

      final vehicles = await repository.fetchVehicles();

      expect(vehicles.length, 1);
      final v = vehicles.first;
      expect(v.id, 'abc-123');
      expect(v.make, 'Toyota');
      expect(v.model, 'Hilux');
      expect(v.year, 2020);
      expect(v.registrationNumber, 'ABC-1234');
      expect(v.vin, isNull);
      expect(v.purchasePriceCents, 3500000);
      expect(v.currency, 'USD');
      expect(v.currentMileage, 48000);
      expect(v.vehicleType, 'pickup');
      expect(v.photoUrl, isNull);
      expect(v.createdAt, DateTime.parse('2026-06-08T10:00:00Z'));
    });

    test('returns empty list when API returns empty array', () async {
      when(mockApiClient.getList('/vehicles', queryParams: null))
          .thenAnswer((_) async => []);

      final vehicles = await repository.fetchVehicles();
      expect(vehicles, isEmpty);
    });
  });

  group('createVehicle', () {
    test('posts data and returns Vehicle', () async {
      final postBody = {'make': 'Toyota', 'model': 'Hilux'};
      when(mockApiClient.post('/vehicles', body: postBody))
          .thenAnswer((_) async => vehicleJson);

      final vehicle = await repository.createVehicle(postBody);
      expect(vehicle.id, 'abc-123');
      expect(vehicle.make, 'Toyota');
    });
  });

  group('updateVehicle', () {
    test('patches vehicle and returns updated Vehicle', () async {
      final patchBody = {'currentMileage': 50000};
      final updatedJson = Map<String, dynamic>.from(vehicleJson)
        ..['currentMileage'] = 50000;
      when(mockApiClient.patch('/vehicles/abc-123', body: patchBody))
          .thenAnswer((_) async => updatedJson);

      final vehicle = await repository.updateVehicle('abc-123', patchBody);
      expect(vehicle.currentMileage, 50000);
    });
  });

  group('deleteVehicle', () {
    test('calls delete endpoint', () async {
      when(mockApiClient.delete('/vehicles/abc-123'))
          .thenAnswer((_) async {});

      await repository.deleteVehicle('abc-123');
      verify(mockApiClient.delete('/vehicles/abc-123')).called(1);
    });
  });
}
