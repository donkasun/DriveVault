import 'package:flutter_test/flutter_test.dart';
import 'package:drivevault/features/maintenance/domain/maintenance_record.dart';

void main() {
  group('MaintenanceRecord.fromJson', () {
    final fullJson = {
      'id': 'rec-1',
      'vehicleId': 'v-1',
      'date': '2026-05-20',
      'serviceType': 'Oil Change',
      'category': 'maintenance',
      'costCents': 6500,
      'currency': 'USD',
      'odometer': 47800,
      'workshop': 'City Auto',
      'notes': 'Synthetic oil used',
      'source': 'manual',
      'createdAt': '2026-05-20T09:00:00Z',
    };

    test('maps all fields', () {
      final record = MaintenanceRecord.fromJson(fullJson);
      expect(record.id, 'rec-1');
      expect(record.vehicleId, 'v-1');
      expect(record.date, '2026-05-20');
      expect(record.serviceType, 'Oil Change');
      expect(record.category, 'maintenance');
      expect(record.costCents, 6500);
      expect(record.currency, 'USD');
      expect(record.odometer, 47800);
      expect(record.workshop, 'City Auto');
      expect(record.notes, 'Synthetic oil used');
      expect(record.source, 'manual');
      expect(record.createdAt, DateTime.parse('2026-05-20T09:00:00Z'));
    });

    test('handles minimal required fields (nullable fields absent)', () {
      final json = {
        'id': 'rec-2',
        'vehicleId': 'v-1',
        'date': '2026-05-20',
        'serviceType': 'Tire Rotation',
        'createdAt': '2026-05-20T09:00:00Z',
      };
      final record = MaintenanceRecord.fromJson(json);
      expect(record.category, isNull);
      expect(record.costCents, isNull);
      expect(record.currency, isNull);
      expect(record.odometer, isNull);
      expect(record.workshop, isNull);
      expect(record.notes, isNull);
      expect(record.source, 'manual');
    });

    test('defaults source to manual when absent', () {
      final json = Map<String, dynamic>.from(fullJson)..remove('source');
      final record = MaintenanceRecord.fromJson(json);
      expect(record.source, 'manual');
    });

    test('toJson includes only non-null optional fields', () {
      final json = {
        'id': 'rec-3',
        'vehicleId': 'v-1',
        'date': '2026-06-01',
        'serviceType': 'Inspection',
        'createdAt': '2026-06-01T00:00:00Z',
      };
      final record = MaintenanceRecord.fromJson(json);
      final out = record.toJson();
      expect(out.containsKey('category'), false);
      expect(out.containsKey('costCents'), false);
      expect(out['serviceType'], 'Inspection');
    });
  });
}
