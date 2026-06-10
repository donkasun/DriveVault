import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drivevault/core/network/api_client.dart';
import 'package:drivevault/features/auth/data/auth_repository.dart';
import 'package:drivevault/features/dashboard/data/dashboard_repository.dart';

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
        'expiryDate': '2026-12-31',
      },
      {
        'vehicleId': 'uuid-2',
        'title': 'Road Tax',
        'expiryDate': '2026-08-15',
      },
    ],
  };
}

void main() {
  late ProviderContainer container;

  tearDown(() => container.dispose());

  group('DashboardRepository.fetchDashboard', () {
    test('maps JSON response to DashboardData correctly', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8000/api/v1'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: _fakeDashboardResponse(),
              ),
            );
          },
        ),
      );

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(AuthRepository.testing()),
          apiClientProvider.overrideWith((ref) => ApiClient(ref, dio: dio)),
        ],
      );

      final repo = container.read(dashboardRepositoryProvider);
      final data = await repo.fetchDashboard();

      expect(data.vehicleCount, 2);
      expect(data.monthlyFuelSpendCents, 23400);
      expect(data.totalOwnershipCostCents, 412000);
      expect(data.costBreakdown.fuelCents, 70200);
      expect(data.costBreakdown.maintenanceCents, 320000);
      expect(data.costBreakdown.purchaseCents, 0);
      expect(data.upcomingRenewals.length, 2);
      expect(data.upcomingRenewals[0].title, 'Insurance');
      expect(data.upcomingRenewals[0].vehicleId, 'uuid-1');
      expect(data.upcomingRenewals[0].expiryDate, '2026-12-31');
      expect(data.upcomingRenewals[1].title, 'Road Tax');
    });

    test('maps zero-renewal response correctly', () async {
      final response = Map<String, dynamic>.from(_fakeDashboardResponse());
      response['upcomingRenewals'] = <dynamic>[];
      response['vehicleCount'] = 0;

      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8000/api/v1'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: response,
              ),
            );
          },
        ),
      );

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(AuthRepository.testing()),
          apiClientProvider.overrideWith((ref) => ApiClient(ref, dio: dio)),
        ],
      );

      final repo = container.read(dashboardRepositoryProvider);
      final data = await repo.fetchDashboard();

      expect(data.vehicleCount, 0);
      expect(data.upcomingRenewals, isEmpty);
    });
  });
}
