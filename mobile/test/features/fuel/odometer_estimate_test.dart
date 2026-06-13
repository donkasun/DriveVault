import 'package:flutter_test/flutter_test.dart';
import 'package:drivevault/features/fuel/domain/odometer_estimate.dart';

void main() {
  group('estimateNextOdometer', () {
    test('returns null for empty list', () {
      expect(estimateNextOdometer([]), isNull);
    });

    test('returns null for single reading', () {
      expect(estimateNextOdometer([50000]), isNull);
    });

    test('two readings: uses the single delta', () {
      // delta = 50500 - 50000 = 500, estimate = 50500 + 500 = 51000
      expect(estimateNextOdometer([50500, 50000]), 51000);
    });

    test('five readings: averages all consecutive deltas', () {
      // Readings (descending): 50400, 50300, 50200, 50100, 50000
      // Deltas: 100, 100, 100, 100 → avg = 100
      // Estimate = 50400 + 100 = 50500 → rounded to 50500
      expect(estimateNextOdometer([50400, 50300, 50200, 50100, 50000]), 50500);
    });

    test('irregular gaps: correct average', () {
      // Readings: 51000, 50700, 50200, 50000
      // Deltas: 300, 500, 200 → avg = 333.3, estimate = 51000 + 333.3 = 51333.3
      // Rounded to nearest 10 → 51330
      final result = estimateNextOdometer([51000, 50700, 50200, 50000]);
      expect(result, 51330);
    });

    test('only uses up to maxSamples (default 5)', () {
      // 6 readings provided; only the first 5 should be used
      // [60000, 59500, 59000, 58500, 58000] → deltas all 500 → avg 500
      // estimate = 60000 + 500 = 60500
      final result = estimateNextOdometer(
        [60000, 59500, 59000, 58500, 58000, 57000],
      );
      expect(result, 60500);
    });

    test('respects custom maxSamples', () {
      // maxSamples = 3: [60000, 59500, 59000] → deltas [500, 500] → avg 500
      // estimate = 60000 + 500 = 60500
      final result = estimateNextOdometer(
        [60000, 59500, 59000, 58500, 58000],
        maxSamples: 3,
      );
      expect(result, 60500);
    });

    test('rounds to nearest 10', () {
      // [50345, 50000] → delta 345 → estimate = 50345 + 345 = 50690
      // Rounded to nearest 10 → 50690
      expect(estimateNextOdometer([50345, 50000]), 50690);
    });

    test('large odometer values handled correctly', () {
      final result = estimateNextOdometer([200500, 200000]);
      // delta = 500 → estimate = 201000
      expect(result, 201000);
    });
  });
}
