import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drivevault/core/network/api_client.dart';
import 'package:drivevault/features/auth/data/auth_repository.dart';
import 'package:drivevault/features/dashboard/data/dashboard_repository.dart';
import 'package:drivevault/features/dashboard/domain/dashboard_data.dart';

Map<String, dynamic> _fakeDashboardResponse() {
  return {
    'vehicleCount': 2,
    'monthlyFuelSpendCents': 23400,
    'totalOwnershipCostCents': 412000,
    'costBreakdown': {
      'fuelCents': 70200,
      'maintenanceCents': 320000,
      'purchaseCents': 0,
    },
    'upcomingRenewals': [
      {
        'vehicleId': 'uuid-1',
        'title': 'Insurance',
        'expiryDate': '2026-01-15',
        'docType': 'insurance',
        'vehicleLabel': '2020 Toyota Hilux',
        'daysRemaining': -5,
        'status': 'overdue',
      },
      {
        'vehicleId': 'uuid-2',
        'title': 'Road Tax',
        'expiryDate': '2026-08-15',
        'docType': 'road_tax',
        'vehicleLabel': '2019 Honda Civic',
        'daysRemaining': 10,
        'status': 'soon',
      },
    ],
    'recentActivity': [
      {
        'type': 'fuel',
        'vehicleId': 'uuid-1',
        'vehicleLabel': '2020 Toyota Hilux',
        'date': '2026-06-14',
        'amountCents': 7800,
        'label': 'Fuel',
      },
      {
        'type': 'maintenance',
        'vehicleId': 'uuid-1',
        'vehicleLabel': '2020 Toyota Hilux',
        'date': '2026-06-10',
        'amountCents': 6500,
        'label': 'Oil Change',
      },
      {
        'type': 'document',
        'vehicleId': 'uuid-1',
        'vehicleLabel': '2020 Toyota Hilux',
        'date': '2026-01-01',
        'amountCents': null,
        'label': '2026 Insurance Policy',
      },
    ],
  };
}

ProviderContainer _makeContainer(Map<String, dynamic> response) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8000/api/v1'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.resolve(
          Response(requestOptions: options, statusCode: 200, data: response),
        );
      },
    ),
  );
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(AuthRepository.testing()),
      apiClientProvider.overrideWith((ref) => ApiClient(ref, dio: dio)),
    ],
  );
}

void main() {
  late ProviderContainer container;

  tearDown(() => container.dispose());

  group('DashboardRepository.fetchDashboard — existing fields', () {
    test('maps JSON response to DashboardData correctly', () async {
      container = _makeContainer(_fakeDashboardResponse());

      final data = await container
          .read(dashboardRepositoryProvider)
          .fetchDashboard();

      expect(data.vehicleCount, 2);
      expect(data.monthlyFuelSpendCents, 23400);
      expect(data.totalOwnershipCostCents, 412000);
      expect(data.costBreakdown.fuelCents, 70200);
      expect(data.costBreakdown.maintenanceCents, 320000);
      expect(data.costBreakdown.purchaseCents, 0);
      expect(data.upcomingRenewals.length, 2);
      expect(data.upcomingRenewals[0].title, 'Insurance');
      expect(data.upcomingRenewals[0].vehicleId, 'uuid-1');
      expect(data.upcomingRenewals[0].expiryDate, '2026-01-15');
      expect(data.upcomingRenewals[1].title, 'Road Tax');
    });

    test('maps zero-renewal response correctly', () async {
      final response = Map<String, dynamic>.from(_fakeDashboardResponse());
      response['upcomingRenewals'] = <dynamic>[];
      response['vehicleCount'] = 0;

      container = _makeContainer(response);

      final data = await container
          .read(dashboardRepositoryProvider)
          .fetchDashboard();

      expect(data.vehicleCount, 0);
      expect(data.upcomingRenewals, isEmpty);
    });
  });

  group('DashboardRepository.fetchDashboard — new upcomingRenewals fields', () {
    test(
      'maps docType, vehicleLabel, daysRemaining, status for overdue entry',
      () async {
        container = _makeContainer(_fakeDashboardResponse());

        final data = await container
            .read(dashboardRepositoryProvider)
            .fetchDashboard();

        final overdue = data.upcomingRenewals[0];
        expect(overdue.docType, 'insurance');
        expect(overdue.vehicleLabel, '2020 Toyota Hilux');
        expect(overdue.daysRemaining, -5);
        expect(overdue.status, RenewalStatus.overdue);
      },
    );

    test('maps status=soon for soon entry', () async {
      container = _makeContainer(_fakeDashboardResponse());

      final data = await container
          .read(dashboardRepositoryProvider)
          .fetchDashboard();

      final soon = data.upcomingRenewals[1];
      expect(soon.daysRemaining, 10);
      expect(soon.status, RenewalStatus.soon);
    });

    test(
      'new renewal fields default to null when absent (backward compat)',
      () async {
        final response = Map<String, dynamic>.from(_fakeDashboardResponse());
        response['upcomingRenewals'] = [
          {
            'vehicleId': 'uuid-old',
            'title': 'Old Renewal',
            'expiryDate': '2026-09-01',
          },
        ];

        container = _makeContainer(response);

        final data = await container
            .read(dashboardRepositoryProvider)
            .fetchDashboard();

        final renewal = data.upcomingRenewals[0];
        expect(renewal.docType, isNull);
        expect(renewal.vehicleLabel, isNull);
        expect(renewal.daysRemaining, isNull);
        expect(renewal.status, isNull);
      },
    );
  });

  group('DashboardRepository.fetchDashboard — recentActivity', () {
    test('maps all three activity types correctly', () async {
      container = _makeContainer(_fakeDashboardResponse());

      final data = await container
          .read(dashboardRepositoryProvider)
          .fetchDashboard();

      expect(data.recentActivity.length, 3);

      final fuel = data.recentActivity[0];
      expect(fuel.type, ActivityType.fuel);
      expect(fuel.vehicleId, 'uuid-1');
      expect(fuel.vehicleLabel, '2020 Toyota Hilux');
      expect(fuel.date, '2026-06-14');
      expect(fuel.amountCents, 7800);
      expect(fuel.label, 'Fuel');

      final maintenance = data.recentActivity[1];
      expect(maintenance.type, ActivityType.maintenance);
      expect(maintenance.amountCents, 6500);
      expect(maintenance.label, 'Oil Change');

      final document = data.recentActivity[2];
      expect(document.type, ActivityType.document);
      expect(document.amountCents, isNull);
      expect(document.label, '2026 Insurance Policy');
    });

    test('recentActivity defaults to empty list when key is absent', () async {
      final response = Map<String, dynamic>.from(_fakeDashboardResponse());
      response.remove('recentActivity');

      container = _makeContainer(response);

      final data = await container
          .read(dashboardRepositoryProvider)
          .fetchDashboard();

      expect(data.recentActivity, isEmpty);
    });

    test('recentActivity defaults to empty list when value is empty', () async {
      final response = Map<String, dynamic>.from(_fakeDashboardResponse());
      response['recentActivity'] = <dynamic>[];

      container = _makeContainer(response);

      final data = await container
          .read(dashboardRepositoryProvider)
          .fetchDashboard();

      expect(data.recentActivity, isEmpty);
    });
  });

  group('DashboardData — model-only parsing (no network)', () {
    test('UpcomingRenewal.fromJson parses all new fields', () {
      final renewal = UpcomingRenewal.fromJson({
        'vehicleId': 'v-1',
        'title': 'Insurance',
        'expiryDate': '2026-01-15',
        'docType': 'insurance',
        'vehicleLabel': '2020 Toyota Hilux',
        'daysRemaining': -5,
        'status': 'overdue',
      });

      expect(renewal.vehicleId, 'v-1');
      expect(renewal.docType, 'insurance');
      expect(renewal.vehicleLabel, '2020 Toyota Hilux');
      expect(renewal.daysRemaining, -5);
      expect(renewal.status, RenewalStatus.overdue);
    });

    test('UpcomingRenewal.fromJson status=ok when value is "ok"', () {
      final renewal = UpcomingRenewal.fromJson({
        'vehicleId': 'v-1',
        'title': 'T',
        'expiryDate': '2026-12-31',
        'status': 'ok',
      });
      expect(renewal.status, RenewalStatus.ok);
    });

    test('ActivityItem.fromJson parses fuel type', () {
      final item = ActivityItem.fromJson({
        'type': 'fuel',
        'vehicleId': 'v-1',
        'vehicleLabel': '2020 Toyota Hilux',
        'date': '2026-06-14',
        'amountCents': 7800,
        'label': 'Fuel',
      });

      expect(item.type, ActivityType.fuel);
      expect(item.vehicleId, 'v-1');
      expect(item.vehicleLabel, '2020 Toyota Hilux');
      expect(item.date, '2026-06-14');
      expect(item.amountCents, 7800);
      expect(item.label, 'Fuel');
    });

    test(
      'ActivityItem.fromJson parses document type with null amountCents',
      () {
        final item = ActivityItem.fromJson({
          'type': 'document',
          'vehicleId': 'v-2',
          'vehicleLabel': 'ABC-1234',
          'date': '2026-01-01',
          'amountCents': null,
          'label': 'Insurance Policy',
        });

        expect(item.type, ActivityType.document);
        expect(item.amountCents, isNull);
      },
    );

    test('ActivityItem.fromJson defaults type to fuel for unknown value', () {
      final item = ActivityItem.fromJson({
        'type': 'unknown_future_type',
        'vehicleId': 'v-1',
        'vehicleLabel': 'Test',
        'date': '2026-06-01',
        'amountCents': null,
        'label': 'X',
      });

      expect(item.type, ActivityType.fuel);
    });

    test(
      'DashboardData.fromJson recentActivity defaults to empty when absent',
      () {
        final data = DashboardData.fromJson({
          'vehicleCount': 1,
          'monthlyFuelSpendCents': 0,
          'totalOwnershipCostCents': 0,
          'costBreakdown': {
            'fuelCents': 0,
            'maintenanceCents': 0,
            'purchaseCents': 0,
          },
          'upcomingRenewals': [],
          // recentActivity intentionally absent
        });

        expect(data.recentActivity, isEmpty);
      },
    );
  });
}
