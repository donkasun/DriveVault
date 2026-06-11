import 'package:flutter_test/flutter_test.dart';

import 'package:drivevault/features/vehicles/domain/vehicle.dart';

void main() {
  Map<String, dynamic> baseJson() => {
    'id': 'abc-123',
    'make': 'Toyota',
    'model': 'Hilux',
    'year': 2020,
    'currency': 'USD',
    'createdAt': '2026-06-08T10:00:00Z',
    'updatedAt': '2026-06-08T10:00:00Z',
  };

  group('Vehicle fuel & unit fields (F7)', () {
    test('fromJson maps fuelType, defaultFuelVariant, distanceUnit', () {
      final v = Vehicle.fromJson(
        baseJson()..addAll({
          'fuelType': 'petrol',
          'defaultFuelVariant': '95 Octane',
          'distanceUnit': 'mi',
        }),
      );

      expect(v.fuelType, 'petrol');
      expect(v.defaultFuelVariant, '95 Octane');
      expect(v.distanceUnit, 'mi');
    });

    test('fromJson tolerates missing fuel/unit fields (all null)', () {
      final v = Vehicle.fromJson(baseJson());
      expect(v.fuelType, isNull);
      expect(v.defaultFuelVariant, isNull);
      expect(v.distanceUnit, isNull);
    });

    test('toJson includes set fields and omits null distanceUnit', () {
      final v = Vehicle.fromJson(
        baseJson()..addAll({
          'fuelType': 'diesel',
          'defaultFuelVariant': 'Premium',
          // distanceUnit intentionally absent -> null (inherit)
        }),
      );

      final json = v.toJson();
      expect(json['fuelType'], 'diesel');
      expect(json['defaultFuelVariant'], 'Premium');
      expect(json.containsKey('distanceUnit'), isFalse);
    });

    test('round-trips fuelType/variant/unit through fromJson->toJson', () {
      final json = baseJson()
        ..addAll({
          'fuelType': 'hybrid',
          'defaultFuelVariant': '92 Octane',
          'distanceUnit': 'km',
        });
      final out = Vehicle.fromJson(json).toJson();
      expect(out['fuelType'], 'hybrid');
      expect(out['defaultFuelVariant'], '92 Octane');
      expect(out['distanceUnit'], 'km');
    });
  });
}
