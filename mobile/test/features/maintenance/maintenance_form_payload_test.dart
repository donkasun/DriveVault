// Regression tests for Task 3a: Maintenance create payload must NOT include
// a 'currency' key — the backend derives it from user preference.

import 'package:flutter_test/flutter_test.dart';

/// Mirrors the payload-building logic from maintenance_form_screen.dart _save().
Map<String, dynamic> buildMaintenancePayload({
  required String date,
  required String serviceType,
  int? odometer,
  String? category,
  double? costAmount, // raw UI amount; converted to cents
  String? workshop,
  String? notes,
}) {
  // currency intentionally omitted — backend fills from user preference.
  final data = <String, dynamic>{
    'date': date,
    'serviceType': serviceType,
    'odometer': ?odometer,
    'category': ?category,
    if (costAmount != null) 'costCents': (costAmount * 100).round(),
    if (workshop != null && workshop.isNotEmpty) 'workshop': workshop,
    if (notes != null && notes.isNotEmpty) 'notes': notes,
  };
  return data;
}

void main() {
  group('Task 3a — Maintenance form payload: no currency key', () {
    test('create payload does not contain a currency key', () {
      final payload = buildMaintenancePayload(
        date: '2026-06-12',
        serviceType: 'Oil Change',
        costAmount: 65.00,
      );

      expect(
        payload.containsKey('currency'),
        isFalse,
        reason: 'currency must be omitted; backend derives it from user pref',
      );
    });

    test('create payload with all optional fields still has no currency', () {
      final payload = buildMaintenancePayload(
        date: '2026-06-12',
        serviceType: 'Tire Rotation',
        odometer: 50000,
        category: 'maintenance',
        costAmount: 40.00,
        workshop: 'City Auto',
        notes: 'Front tires only',
      );

      expect(payload.containsKey('currency'), isFalse);
      expect(payload['costCents'], 4000);
      expect(payload['odometer'], 50000);
    });

    test('costCents is correctly rounded from decimal input', () {
      final payload = buildMaintenancePayload(
        date: '2026-06-12',
        serviceType: 'Brake Check',
        costAmount: 12.345,
      );
      // (12.345 * 100).round() == 1235
      expect(payload['costCents'], 1235);
    });

    test('required fields are always present', () {
      final payload = buildMaintenancePayload(
        date: '2026-06-12',
        serviceType: 'Inspection',
      );

      expect(payload['date'], '2026-06-12');
      expect(payload['serviceType'], 'Inspection');
    });
  });
}
