import 'package:flutter_test/flutter_test.dart';
import 'package:drivevault/features/fuel/domain/fuel_log.dart';
import 'package:drivevault/features/fuel/domain/fuel_stats.dart';

void main() {
  group('FuelLog.fromJson', () {
    final sampleJson = {
      'id': 'log-1',
      'vehicleId': 'v-1',
      'date': '2026-06-01',
      'liters': 45.5,
      'priceCents': 7800,
      'currency': 'USD',
      'odometer': 48200,
      'isFullTank': true,
      'notes': null,
      'createdAt': '2026-06-01T10:00:00Z',
    };

    test('maps all required fields', () {
      final log = FuelLog.fromJson(sampleJson);
      expect(log.id, 'log-1');
      expect(log.vehicleId, 'v-1');
      expect(log.date, '2026-06-01');
      expect(log.liters, closeTo(45.5, 0.001));
      expect(log.priceCents, 7800);
      expect(log.currency, 'USD');
      expect(log.odometer, 48200);
      expect(log.isFullTank, true);
      expect(log.notes, isNull);
      expect(log.createdAt, DateTime.parse('2026-06-01T10:00:00Z'));
    });

    test('handles integer liters cast to double', () {
      final json = Map<String, dynamic>.from(sampleJson)
        ..['liters'] = 45;
      final log = FuelLog.fromJson(json);
      expect(log.liters, 45.0);
    });

    test('defaults isFullTank to false when absent', () {
      final json = Map<String, dynamic>.from(sampleJson)
        ..remove('isFullTank');
      final log = FuelLog.fromJson(json);
      expect(log.isFullTank, false);
    });

    test('defaults currency to LKR when absent', () {
      final json = Map<String, dynamic>.from(sampleJson)
        ..remove('currency');
      final log = FuelLog.fromJson(json);
      expect(log.currency, 'LKR');
    });

    test('toJson round-trips', () {
      final log = FuelLog.fromJson(sampleJson);
      final json = log.toJson();
      expect(json['id'], log.id);
      expect(json['priceCents'], log.priceCents);
      expect(json['liters'], log.liters);
    });
  });

  group('FuelStats.fromJson', () {
    final sampleStats = {
      'avgConsumptionLPer100Km': 8.5,
      'avgCostPerKmCents': 12,
      'totalLiters': 200.0,
      'totalSpentCents': 35000,
      'monthlySpend': [
        {'month': '2026-06', 'spentCents': 7800},
        {'month': '2026-05', 'spentCents': 9200},
      ],
    };

    test('maps all fields', () {
      final stats = FuelStats.fromJson(sampleStats);
      expect(stats.avgConsumptionLPer100Km, 8.5);
      expect(stats.avgCostPerKmCents, 12);
      expect(stats.totalLiters, 200.0);
      expect(stats.totalSpentCents, 35000);
      expect(stats.monthlySpend.length, 2);
      expect(stats.monthlySpend.first.month, '2026-06');
      expect(stats.monthlySpend.first.spentCents, 7800);
    });

    test('handles null optional fields', () {
      final json = Map<String, dynamic>.from(sampleStats)
        ..['avgConsumptionLPer100Km'] = null
        ..['avgCostPerKmCents'] = null;
      final stats = FuelStats.fromJson(json);
      expect(stats.avgConsumptionLPer100Km, isNull);
      expect(stats.avgCostPerKmCents, isNull);
    });

    test('handles empty monthlySpend list', () {
      final json = Map<String, dynamic>.from(sampleStats)
        ..['monthlySpend'] = [];
      final stats = FuelStats.fromJson(json);
      expect(stats.monthlySpend, isEmpty);
    });
  });
}
