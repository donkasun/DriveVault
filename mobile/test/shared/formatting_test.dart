import 'package:flutter_test/flutter_test.dart';

import 'package:drivevault/shared/utils/formatting.dart';

void main() {
  group('formatCents honors the currency code', () {
    test('defaults to USD (dollar sign)', () {
      expect(formatCents(412000), startsWith(r'$'));
      expect(formatCents(412000), contains('4,120.00'));
    });

    test('uses the given currency symbol', () {
      expect(formatCents(412000, currency: 'EUR'), contains('€'));
      expect(formatCents(412000, currency: 'GBP'), contains('£'));
    });

    test('unknown currency code falls back to the code as a prefix', () {
      final out = formatCents(100000, currency: 'ZZZ');
      expect(out, contains('ZZZ'));
      expect(out, contains('1,000.00'));
    });
  });
}
