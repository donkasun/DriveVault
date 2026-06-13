import 'package:flutter_test/flutter_test.dart';
import 'package:drivevault/features/fuel/domain/fuel_entry_calc.dart';

void main() {
  group('FuelEntryCalc', () {
    test('rule 2: total only, with sticky per-liter, derives liters', () {
      final calc = FuelEntryCalc(initialPerLiter: 2.0);
      calc.setField(FuelField.total, 100.0);
      expect(calc.liters, closeTo(50.0, 1e-9));
      expect(calc.pricePerLiter, 2.0);
      expect(calc.isComplete, isTrue);
    });
    test('rule 3: liters only, with sticky per-liter, derives total', () {
      final calc = FuelEntryCalc(initialPerLiter: 2.0);
      calc.setField(FuelField.liters, 40.0);
      expect(calc.total, closeTo(80.0, 1e-9));
      expect(calc.isComplete, isTrue);
    });
    test('rule 1: liters + total derive per-liter (overriding default)', () {
      final calc = FuelEntryCalc(initialPerLiter: 2.0);
      calc.setField(FuelField.liters, 40.0);
      calc.setField(FuelField.total, 100.0);
      expect(calc.pricePerLiter, closeTo(2.5, 1e-9));
      expect(calc.isComplete, isTrue);
    });
    test('rule 4: editing per-liter with liters present recomputes total', () {
      final calc = FuelEntryCalc(initialPerLiter: 2.0);
      calc.setField(FuelField.liters, 40.0);
      calc.setField(FuelField.total, 100.0); // per-liter now 2.5
      calc.setField(FuelField.perLiter, 3.0);
      expect(calc.liters, 40.0);
      expect(calc.total, closeTo(120.0, 1e-9));
    });
    test('incomplete when only per-liter is known', () {
      final calc = FuelEntryCalc(initialPerLiter: 2.0);
      expect(calc.isComplete, isFalse);
    });
    test('clearing a field drops it from the authoritative pair', () {
      final calc = FuelEntryCalc(initialPerLiter: 2.0);
      calc.setField(FuelField.total, 100.0);
      calc.setField(FuelField.total, null);
      expect(calc.isComplete, isFalse);
    });
  });
}
