// Regression tests for Task 4: Fuel liters validator rejects values <= 0.

import 'package:flutter_test/flutter_test.dart';

/// Mirrors the validator logic from FuelLogFormScreen._buildNumberField()
/// when [isDecimal] is true and [label] starts with 'Liters'.
String? litersValidator(String? v) {
  if (v == null || v.isEmpty) return 'Required';
  final parsed = double.tryParse(v);
  if (parsed == null) return 'Invalid number';
  if (parsed <= 0) return 'Enter a value greater than 0';
  return null;
}

void main() {
  group('Task 4 — Fuel liters validator', () {
    test('null input → Required', () {
      expect(litersValidator(null), 'Required');
    });

    test('empty string → Required', () {
      expect(litersValidator(''), 'Required');
    });

    test('non-numeric string → Invalid number', () {
      expect(litersValidator('abc'), 'Invalid number');
    });

    test('zero → Enter a value greater than 0', () {
      expect(litersValidator('0'), 'Enter a value greater than 0');
    });

    test('negative value → Enter a value greater than 0', () {
      expect(litersValidator('-5'), 'Enter a value greater than 0');
    });

    test('positive decimal → valid (null)', () {
      expect(litersValidator('45.5'), isNull);
    });

    test('very small positive → valid (null)', () {
      expect(litersValidator('0.1'), isNull);
    });

    test('integer positive → valid (null)', () {
      expect(litersValidator('50'), isNull);
    });
  });
}
