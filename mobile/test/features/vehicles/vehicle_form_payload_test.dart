// Regression tests for Task 1: Vehicle edit PATCH null-clobber fix.
//
// These are pure unit tests that exercise the payload-building logic
// extracted from _VehicleFormScreenState._save().  They do not require
// a running Flutter widget tree.

import 'package:flutter_test/flutter_test.dart';

import 'package:drivevault/features/vehicles/domain/vehicle.dart';

// ---------------------------------------------------------------------------
// Helper – mirrors the payload-building logic from vehicle_form_screen.dart
// so that the test is kept independent of the widget.
// ---------------------------------------------------------------------------

/// Builds the PATCH / POST payload the same way _save() does.
///
/// [isEditMode]     true → PATCH; false → POST
/// [original]       the vehicle being edited (required when isEditMode)
/// [make], [model]  required string fields
/// [year]           optional int
/// [reg]            optional registration number
/// [mileage]        optional current mileage
/// [vehicleType]    optional string
/// [fuelType]       nullable — edit: include only when changed; create: include only when non-null
/// [distanceUnit]   nullable — same rules
/// [photoUrl]       optional
/// [photoPublicId]  optional
Map<String, dynamic> buildPayload({
  required bool isEditMode,
  Vehicle? original,
  required String make,
  required String model,
  int? year,
  String? reg,
  int? mileage,
  String? vehicleType,
  String? fuelType,
  String? distanceUnit,
  String? photoUrl,
  String? photoPublicId,
}) {
  final data = <String, dynamic>{
    'make': make,
    'model': model,
  };
  if (year != null) data['year'] = year;
  if (reg != null && reg.isNotEmpty) data['registrationNumber'] = reg;
  if (mileage != null) data['currentMileage'] = mileage;
  if (vehicleType != null) data['vehicleType'] = vehicleType;

  if (isEditMode) {
    assert(original != null, 'original required in edit mode');
    if (fuelType != original!.fuelType) data['fuelType'] = fuelType;
    if (distanceUnit != original.distanceUnit) {
      data['distanceUnit'] = distanceUnit;
    }
  } else {
    if (fuelType != null) data['fuelType'] = fuelType;
    if (distanceUnit != null) data['distanceUnit'] = distanceUnit;
  }

  if (photoUrl != null) data['photoUrl'] = photoUrl;
  if (photoPublicId != null) data['photoPublicId'] = photoPublicId;
  return data;
}

// ---------------------------------------------------------------------------
// Convenience factory for a minimal Vehicle
// ---------------------------------------------------------------------------

Vehicle _vehicle({
  String? fuelType,
  String? distanceUnit,
  int year = 2020,
}) {
  return Vehicle(
    id: 'v-1',
    make: 'Toyota',
    model: 'Hilux',
    year: year,
    currency: 'USD',
    fuelType: fuelType,
    distanceUnit: distanceUnit,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

void main() {
  group('Task 1 — Vehicle form payload: edit mode null-clobber fix', () {
    test(
        'editing only year on a vehicle with fuelType=petrol '
        'produces a payload WITHOUT fuelType key', () {
      final original = _vehicle(fuelType: 'petrol', distanceUnit: 'km');

      final payload = buildPayload(
        isEditMode: true,
        original: original,
        make: original.make,
        model: original.model,
        year: 2021, // the only changed field
        fuelType: original.fuelType, // unchanged
        distanceUnit: original.distanceUnit, // unchanged
        vehicleType: 'car',
      );

      expect(payload['year'], 2021);
      expect(payload.containsKey('fuelType'), isFalse,
          reason: 'fuelType was not changed — must be omitted from PATCH body');
      expect(payload.containsKey('distanceUnit'), isFalse,
          reason:
              'distanceUnit was not changed — must be omitted from PATCH body');
    });

    test('editing fuelType includes it in the payload', () {
      final original = _vehicle(fuelType: 'petrol', distanceUnit: 'km');

      final payload = buildPayload(
        isEditMode: true,
        original: original,
        make: original.make,
        model: original.model,
        fuelType: 'diesel', // changed
        distanceUnit: original.distanceUnit, // unchanged
        vehicleType: 'car',
      );

      expect(payload['fuelType'], 'diesel');
      expect(payload.containsKey('distanceUnit'), isFalse);
    });

    test('editing distanceUnit includes it but not unchanged fuelType', () {
      final original = _vehicle(fuelType: 'petrol', distanceUnit: 'km');

      final payload = buildPayload(
        isEditMode: true,
        original: original,
        make: original.make,
        model: original.model,
        fuelType: original.fuelType, // unchanged
        distanceUnit: 'mi', // changed
        vehicleType: 'car',
      );

      expect(payload.containsKey('fuelType'), isFalse);
      expect(payload['distanceUnit'], 'mi');
    });

    test('clearing fuelType (null) when original had a value includes the key',
        () {
      final original = _vehicle(fuelType: 'petrol');

      final payload = buildPayload(
        isEditMode: true,
        original: original,
        make: original.make,
        model: original.model,
        fuelType: null, // user cleared it
        distanceUnit: original.distanceUnit,
        vehicleType: 'car',
      );

      // null != 'petrol' — the change must reach the server
      expect(payload.containsKey('fuelType'), isTrue);
      expect(payload['fuelType'], isNull);
    });
  });

  group('Task 1 — Vehicle form payload: create mode', () {
    test('create with null fuelType/distanceUnit omits both keys', () {
      final payload = buildPayload(
        isEditMode: false,
        make: 'Honda',
        model: 'Civic',
        year: 2023,
        fuelType: null,
        distanceUnit: null,
        vehicleType: 'car',
      );

      expect(payload.containsKey('fuelType'), isFalse);
      expect(payload.containsKey('distanceUnit'), isFalse);
    });

    test('create with non-null fuelType/distanceUnit includes both', () {
      final payload = buildPayload(
        isEditMode: false,
        make: 'Honda',
        model: 'Civic',
        fuelType: 'electric',
        distanceUnit: 'mi',
        vehicleType: 'car',
      );

      expect(payload['fuelType'], 'electric');
      expect(payload['distanceUnit'], 'mi');
    });
  });
}
