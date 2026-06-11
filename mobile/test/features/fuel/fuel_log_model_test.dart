import 'package:flutter_test/flutter_test.dart';

import 'package:drivevault/features/fuel/domain/fuel_log.dart';

void main() {
  Map<String, dynamic> baseJson() => {
    'id': 'fl-1',
    'vehicleId': 'v-1',
    'date': '2026-06-01',
    'liters': 45.5,
    'priceCents': 7800,
    'currency': 'USD',
    'odometer': 48200,
    'isFullTank': true,
    'createdAt': '2026-06-08T10:00:00Z',
  };

  group('FuelLog liters parsing', () {
    test('fromJson parses liters as a JSON number', () {
      final log = FuelLog.fromJson(baseJson()..['liters'] = 25.0);
      expect(log.liters, 25.0);
    });

    test('fromJson parses liters as a numeric string (Pydantic Decimal)', () {
      final log = FuelLog.fromJson(baseJson()..['liters'] = '25.000');
      expect(log.liters, 25.0);
    });

    test('fromJson parses liters string with no trailing zeros', () {
      final log = FuelLog.fromJson(baseJson()..['liters'] = '45.5');
      expect(log.liters, 45.5);
    });
  });

}
