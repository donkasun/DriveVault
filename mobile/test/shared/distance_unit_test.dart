import 'package:flutter_test/flutter_test.dart';
import 'package:drivevault/shared/utils/distance_unit.dart';

void main() {
  // -------------------------------------------------------------------------
  // DistanceUnit.fromString
  // -------------------------------------------------------------------------
  group('DistanceUnit.fromString', () {
    test('parses "km"', () {
      expect(DistanceUnit.fromString('km'), DistanceUnit.km);
    });

    test('parses "mi"', () {
      expect(DistanceUnit.fromString('mi'), DistanceUnit.mi);
    });

    test('is case-insensitive', () {
      expect(DistanceUnit.fromString('KM'), DistanceUnit.km);
      expect(DistanceUnit.fromString('MI'), DistanceUnit.mi);
    });

    test('throws for unknown value', () {
      expect(() => DistanceUnit.fromString('miles'), throwsArgumentError);
    });
  });

  // -------------------------------------------------------------------------
  // effectiveUnit – vehicle-override-falls-back-to-user resolution
  // -------------------------------------------------------------------------
  group('effectiveUnit', () {
    test('returns vehicleUnit when it is set', () {
      expect(effectiveUnit(vehicleUnit: 'mi', userUnit: 'km'), DistanceUnit.mi);
    });

    test('falls back to userUnit when vehicleUnit is null', () {
      expect(effectiveUnit(vehicleUnit: null, userUnit: 'km'), DistanceUnit.km);
    });

    test('falls back to userUnit "mi" when vehicleUnit is null', () {
      expect(effectiveUnit(vehicleUnit: null, userUnit: 'mi'), DistanceUnit.mi);
    });

    test('vehicleUnit "km" overrides userUnit "mi"', () {
      expect(effectiveUnit(vehicleUnit: 'km', userUnit: 'mi'), DistanceUnit.km);
    });
  });

  // -------------------------------------------------------------------------
  // kmToDisplay – km → display unit conversion
  // -------------------------------------------------------------------------
  group('kmToDisplay', () {
    test('km unit returns same value as double', () {
      expect(kmToDisplay(100, DistanceUnit.km), 100.0);
    });

    test('mi unit converts correctly (100 km → ~62.1371 mi)', () {
      expect(kmToDisplay(100, DistanceUnit.mi), closeTo(62.1371, 0.0001));
    });

    test('0 km → 0.0 for both units', () {
      expect(kmToDisplay(0, DistanceUnit.km), 0.0);
      expect(kmToDisplay(0, DistanceUnit.mi), 0.0);
    });

    test('48200 km → ~29950 mi (within rounding)', () {
      final mi = kmToDisplay(48200, DistanceUnit.mi);
      expect(mi.round(), 29950);
    });
  });

  // -------------------------------------------------------------------------
  // displayToKm – display → stored integer km conversion
  // -------------------------------------------------------------------------
  group('displayToKm', () {
    test('km unit returns rounded int unchanged', () {
      expect(displayToKm(100.0, DistanceUnit.km), 100);
    });

    test('km input with decimal is rounded to nearest int', () {
      expect(displayToKm(100.6, DistanceUnit.km), 101);
      expect(displayToKm(100.4, DistanceUnit.km), 100);
    });

    test('mi → km conversion (1 mi → 2 km rounded)', () {
      // 1 × 1.609344 = 1.609344 → rounds to 2
      expect(displayToKm(1.0, DistanceUnit.mi), 2);
    });

    test('mi → km (100 mi → 161 km)', () {
      // 100 × 1.609344 = 160.9344 → rounds to 161
      expect(displayToKm(100.0, DistanceUnit.mi), 161);
    });

    test('round-trip: km → display(mi) → back to km is within ±1 km', () {
      const original = 48200;
      final inMiles = kmToDisplay(original, DistanceUnit.mi);
      final backToKm = displayToKm(inMiles, DistanceUnit.mi);
      expect((backToKm - original).abs(), lessThanOrEqualTo(1));
    });

    test('0.0 mi → 0 km', () {
      expect(displayToKm(0.0, DistanceUnit.mi), 0);
    });
  });

  // -------------------------------------------------------------------------
  // formatDistance – formatting with unit suffix
  // -------------------------------------------------------------------------
  group('formatDistance', () {
    test('formats km with thousands separator', () {
      expect(formatDistance(48200, DistanceUnit.km), '48,200 km');
    });

    test('formats mi with thousands separator and correct conversion', () {
      // 48200 km × 0.621371 = 29950.08… → rounds to 29,950 mi
      expect(formatDistance(48200, DistanceUnit.mi), '29,950 mi');
    });

    test('formats 0 km', () {
      expect(formatDistance(0, DistanceUnit.km), '0 km');
    });

    test('formats 0 mi', () {
      expect(formatDistance(0, DistanceUnit.mi), '0 mi');
    });

    test('formats values under 1000 without separator', () {
      expect(formatDistance(500, DistanceUnit.km), '500 km');
    });

    test('formats large value correctly', () {
      expect(formatDistance(1000000, DistanceUnit.km), '1,000,000 km');
    });
  });
}
