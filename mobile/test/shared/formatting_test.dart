import 'package:flutter_test/flutter_test.dart';

import 'package:drivevault/shared/utils/formatting.dart';

void main() {
  group('formatCents honors the currency code', () {
    test('defaults to LKR (Rs prefix)', () {
      expect(formatCents(412000), startsWith('Rs'));
      expect(formatCents(412000), contains('4,120'));
    });

    test('uses the given currency symbol', () {
      expect(formatCents(412000, currency: 'EUR'), contains('€'));
      expect(formatCents(412000, currency: 'GBP'), contains('£'));
    });

    test('unknown currency code falls back to the code as a prefix', () {
      final out = formatCents(100000, currency: 'ZZZ');
      expect(out, contains('ZZZ'));
      // 100000 cents = 1000.00 but whole-number → .00 stripped
      expect(out, contains('1,000'));
    });

    test('LKR inserts space between Rs and the amount', () {
      // 0 cents → "Rs 0" (whole-rupee, .00 stripped per LKR convention)
      expect(formatCents(0, currency: 'LKR'), 'Rs 0');
      expect(formatCents(12345, currency: 'LKR'), 'Rs 123.45');
      expect(formatCents(-12345, currency: 'LKR'), '-Rs 123.45');
    });
  });
}
