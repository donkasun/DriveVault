/// Tests that reproduce the exact logic in _syncCalcFromControllers and
/// _canSave to find why the Save button stays disabled.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:drivevault/features/fuel/domain/fuel_entry_calc.dart';

// ── Mirror of _syncCalcFromControllers from quick_fuel_entry_sheet.dart ──────
//
// We replicate the function here so we can call it in isolation without any
// widget infrastructure.  Keep in sync if the production version changes.

FuelEntryCalc syncCalcFromControllers({
  required FuelField activeField,
  required double? liters,
  required double? total,
  required double? perLiter,
}) {
  final calc = FuelEntryCalc(
    initialPerLiter: perLiter != null && perLiter > 0 ? perLiter : null,
  );

  for (final field in const [
    FuelField.liters,
    FuelField.total,
    FuelField.perLiter,
  ]) {
    if (field == activeField) continue;
    calc.setField(field, switch (field) {
      FuelField.liters => liters,
      FuelField.total => total,
      FuelField.perLiter => perLiter,
    });
  }

  calc.setField(activeField, switch (activeField) {
    FuelField.liters => liters,
    FuelField.total => total,
    FuelField.perLiter => perLiter,
  });

  return calc;
}

// ── Mirror of _canSave (current version after latest fix) ────────────────────

bool canSave({
  required bool saving,
  required String? selectedVehicleId,
  required String odoText,
  required int? latestOdometerKm,
  required FuelEntryCalc calc,
}) {
  if (saving) return false;
  if (selectedVehicleId == null) return false;
  final trimmed = odoText.trim();
  if (trimmed.isNotEmpty && int.tryParse(trimmed) == null) return false;
  if (trimmed.isEmpty && latestOdometerKm == null) return false;
  return calc.isComplete;
}

void main() {
  // ── SCENARIO 1: Sheet just opened, only perLiter seeded from last log ──────
  group('Scenario 1 — sheet opened, perLiter seeded, no user input yet', () {
    late FuelEntryCalc calc;

    setUp(() {
      // This is what _seedFromLatest does:
      calc = FuelEntryCalc(initialPerLiter: 434.0);
    });

    test('isComplete is FALSE — liters and total are null', () {
      expect(calc.isComplete, isFalse);
    });

    test('canSave is FALSE even when odometer fallback is available', () {
      expect(
        canSave(
          saving: false,
          selectedVehicleId: 'vehicle-1',
          odoText: '',
          latestOdometerKm: 150466, // fallback available
          calc: calc,
        ),
        isFalse,
        reason:
            'Save must stay disabled when neither liters nor total has been entered',
      );
    });
  });

  // ── SCENARIO 2: User types liters=12 (activeField=liters) ─────────────────
  group('Scenario 2 — user types liters=12, perLiter=434 pre-seeded', () {
    late FuelEntryCalc calc;

    setUp(() {
      // Simulate _syncCalcFromControllers when user types 12 in liters field.
      // Controllers: liters="12", total="", perLiter="434.00"
      calc = syncCalcFromControllers(
        activeField: FuelField.liters,
        liters: 12.0,
        total: null,
        perLiter: 434.0,
      );
    });

    test('total is derived as 12 × 434 = 5208', () {
      expect(calc.total, closeTo(5208.0, 0.01));
    });

    test('isComplete is TRUE', () {
      expect(calc.isComplete, isTrue);
    });

    test('canSave is TRUE when odometer is empty but fallback exists', () {
      expect(
        canSave(
          saving: false,
          selectedVehicleId: 'vehicle-1',
          odoText: '',
          latestOdometerKm: 150466,
          calc: calc,
        ),
        isTrue,
      );
    });

    test('canSave is TRUE when odometer is typed explicitly', () {
      expect(
        canSave(
          saving: false,
          selectedVehicleId: 'vehicle-1',
          odoText: '150470',
          latestOdometerKm: 150466,
          calc: calc,
        ),
        isTrue,
      );
    });
  });

  // ── SCENARIO 3: User edits perLiter only (taps the pre-filled field) ───────
  group('Scenario 3 — user edits perLiter field only, no liters typed yet', () {
    late FuelEntryCalc calc;

    setUp(() {
      // Controllers: liters="", total="", perLiter="434"
      calc = syncCalcFromControllers(
        activeField: FuelField.perLiter,
        liters: null,
        total: null,
        perLiter: 434.0,
      );
    });

    test('isComplete is FALSE — cannot save with price only', () {
      expect(calc.isComplete, isFalse);
    });
  });

  // ── SCENARIO 4: User typed liters=12, total auto-filled=5208, then taps
  //                Price/L field (screenshot scenario) ───────────────────────
  group('Scenario 4 — all three fields have values, activeField=perLiter', () {
    late FuelEntryCalc calc;

    setUp(() {
      // Controllers: liters="12.00", total="5208.00", perLiter="434"
      calc = syncCalcFromControllers(
        activeField: FuelField.perLiter,
        liters: 12.0,
        total: 5208.0,
        perLiter: 434.0,
      );
    });

    test('isComplete is TRUE', () {
      expect(calc.isComplete, isTrue);
    });

    test('canSave is TRUE', () {
      expect(
        canSave(
          saving: false,
          selectedVehicleId: 'vehicle-1',
          odoText: '',
          latestOdometerKm: 150466,
          calc: calc,
        ),
        isTrue,
      );
    });
  });

  // ── SCENARIO 5: Odometer typed as invalid text (e.g. "abc") ────────────────
  group('Scenario 5 — odometer field has non-numeric text', () {
    late FuelEntryCalc calc;

    setUp(() {
      calc = syncCalcFromControllers(
        activeField: FuelField.liters,
        liters: 12.0,
        total: null,
        perLiter: 434.0,
      );
    });

    test('canSave is FALSE when odometer text is invalid', () {
      expect(
        canSave(
          saving: false,
          selectedVehicleId: 'vehicle-1',
          odoText: 'abc',
          latestOdometerKm: 150466,
          calc: calc,
        ),
        isFalse,
      );
    });
  });

  // ── SCENARIO 6: No vehicle selected ────────────────────────────────────────
  group('Scenario 6 — no vehicle selected', () {
    late FuelEntryCalc calc;

    setUp(() {
      calc = syncCalcFromControllers(
        activeField: FuelField.liters,
        liters: 12.0,
        total: null,
        perLiter: 434.0,
      );
    });

    test('canSave is FALSE when selectedVehicleId is null', () {
      expect(
        canSave(
          saving: false,
          selectedVehicleId: null,
          odoText: '',
          latestOdometerKm: 150466,
          calc: calc,
        ),
        isFalse,
      );
    });
  });

  // ── SCENARIO 7: No odometer fallback and empty odo field ───────────────────
  group('Scenario 7 — odo field empty AND no fallback (brand-new vehicle)', () {
    late FuelEntryCalc calc;

    setUp(() {
      calc = syncCalcFromControllers(
        activeField: FuelField.liters,
        liters: 12.0,
        total: null,
        perLiter: 434.0,
      );
    });

    test('canSave is FALSE — no way to determine odometer', () {
      expect(
        canSave(
          saving: false,
          selectedVehicleId: 'vehicle-1',
          odoText: '',
          latestOdometerKm: null,
          calc: calc,
        ),
        isFalse,
      );
    });
  });
}
