import 'package:flutter_test/flutter_test.dart';

import 'package:drivevault/features/vehicles/domain/vehicle.dart';

void main() {
  Map<String, dynamic> baseJson() => {
    'id': 'abc-123',
    'make': 'Toyota',
    'model': 'Hilux',
    'year': 2020,
    'currency': 'USD',
    'createdAt': '2026-06-08T10:00:00Z',
    'updatedAt': '2026-06-08T10:00:00Z',
  };

  // ---------------------------------------------------------------------------
  // DocsStatus model
  // ---------------------------------------------------------------------------
  group('DocsStatus', () {
    test('fromJson parses needs_action state', () {
      final ds = DocsStatus.fromJson({
        'state': 'needs_action',
        'needsActionCount': 3,
      });
      expect(ds.state, 'needs_action');
      expect(ds.needsActionCount, 3);
    });

    test('fromJson parses valid state', () {
      final ds = DocsStatus.fromJson({'state': 'valid', 'needsActionCount': 0});
      expect(ds.state, 'valid');
      expect(ds.needsActionCount, 0);
    });

    test('fromJson defaults to none / 0 when keys are absent', () {
      final ds = DocsStatus.fromJson({});
      expect(ds.state, 'none');
      expect(ds.needsActionCount, 0);
    });

    test('sentinel DocsStatus.none has state=none and count=0', () {
      expect(DocsStatus.none.state, 'none');
      expect(DocsStatus.none.needsActionCount, 0);
    });

    test('toJson round-trips correctly', () {
      const ds = DocsStatus(state: 'needs_action', needsActionCount: 2);
      final json = ds.toJson();
      expect(json['state'], 'needs_action');
      expect(json['needsActionCount'], 2);
    });
  });

  // ---------------------------------------------------------------------------
  // Vehicle.docsStatus field
  // ---------------------------------------------------------------------------
  group('Vehicle.docsStatus', () {
    test('fromJson maps docsStatus when present', () {
      final v = Vehicle.fromJson(
        baseJson()..addAll({
          'docsStatus': {'state': 'needs_action', 'needsActionCount': 2},
        }),
      );
      expect(v.docsStatus.state, 'needs_action');
      expect(v.docsStatus.needsActionCount, 2);
    });

    test('fromJson defaults to DocsStatus.none when key is absent', () {
      final v = Vehicle.fromJson(baseJson());
      expect(v.docsStatus.state, 'none');
      expect(v.docsStatus.needsActionCount, 0);
    });

    test('fromJson with valid state', () {
      final v = Vehicle.fromJson(
        baseJson()..addAll({
          'docsStatus': {'state': 'valid', 'needsActionCount': 0},
        }),
      );
      expect(v.docsStatus.state, 'valid');
    });

    test('toJson includes docsStatus', () {
      final v = Vehicle.fromJson(
        baseJson()..addAll({
          'docsStatus': {'state': 'needs_action', 'needsActionCount': 1},
        }),
      );
      final json = v.toJson();
      expect(json['docsStatus'], isA<Map<String, dynamic>>());
      expect(
        (json['docsStatus'] as Map<String, dynamic>)['state'],
        'needs_action',
      );
      expect(
        (json['docsStatus'] as Map<String, dynamic>)['needsActionCount'],
        1,
      );
    });

    test('copyWith preserves docsStatus when not overridden', () {
      final v = Vehicle.fromJson(
        baseJson()..addAll({
          'docsStatus': {'state': 'needs_action', 'needsActionCount': 3},
        }),
      );
      final copy = v.copyWith(make: 'Honda');
      expect(copy.docsStatus.state, 'needs_action');
      expect(copy.docsStatus.needsActionCount, 3);
    });

    test('copyWith replaces docsStatus when provided', () {
      final v = Vehicle.fromJson(baseJson());
      const updated = DocsStatus(state: 'valid', needsActionCount: 0);
      final copy = v.copyWith(docsStatus: updated);
      expect(copy.docsStatus.state, 'valid');
    });
  });

  group('Vehicle fuel & unit fields (F7)', () {
    test('fromJson maps fuelType and distanceUnit', () {
      final v = Vehicle.fromJson(
        baseJson()..addAll({'fuelType': 'petrol', 'distanceUnit': 'mi'}),
      );

      expect(v.fuelType, 'petrol');
      expect(v.distanceUnit, 'mi');
    });

    test('fromJson tolerates missing fuel/unit fields (all null)', () {
      final v = Vehicle.fromJson(baseJson());
      expect(v.fuelType, isNull);
      expect(v.distanceUnit, isNull);
    });

    test('toJson includes set fields and omits null distanceUnit', () {
      final v = Vehicle.fromJson(
        baseJson()..addAll({
          'fuelType': 'diesel',
          // distanceUnit intentionally absent -> null (inherit)
        }),
      );

      final json = v.toJson();
      expect(json['fuelType'], 'diesel');
      expect(json.containsKey('distanceUnit'), isFalse);
    });

    test('round-trips fuelType/unit through fromJson->toJson', () {
      final json = baseJson()
        ..addAll({'fuelType': 'hybrid', 'distanceUnit': 'km'});
      final out = Vehicle.fromJson(json).toJson();
      expect(out['fuelType'], 'hybrid');
      expect(out['distanceUnit'], 'km');
    });
  });
}
