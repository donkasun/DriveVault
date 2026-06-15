import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drivevault/core/network/api_client.dart';
import 'package:drivevault/features/maintenance/data/maintenance_repository.dart';
import 'package:drivevault/features/maintenance/domain/maintenance_record.dart';
import 'package:drivevault/features/maintenance/presentation/widgets/quick_maintenance_sheet.dart';
import 'package:drivevault/features/profile/data/user_repository.dart';
import 'package:drivevault/features/profile/domain/user.dart';
import 'package:drivevault/features/vehicles/domain/vehicle.dart';
import 'package:drivevault/features/vehicles/presentation/vehicles_provider.dart';

final _fakeVehicle = Vehicle(
  id: 'v-1',
  make: 'Toyota',
  model: 'Corolla',
  year: 2020,
  currency: 'LKR',
  currentMileage: 50000,
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);

final _fakeUser = AppUser(
  id: 'u-1',
  firebaseUid: 'uid-1',
  email: 'test@test.com',
  currency: 'LKR',
  distanceUnit: 'km',
  createdAt: DateTime(2025),
);

final _fakeRecord = MaintenanceRecord(
  id: 'm-1',
  vehicleId: 'v-1',
  date: '2026-06-10',
  serviceType: 'Oil Change',
  source: 'manual',
  createdAt: DateTime(2026, 6, 10),
);

/// A MaintenanceRepository that records createRecord calls.
class _FakeMaintenanceRepo extends MaintenanceRepository {
  final List<Map<String, dynamic>> calls = [];

  _FakeMaintenanceRepo._internal(ApiClient client) : super(client);

  factory _FakeMaintenanceRepo() {
    final container = ProviderContainer(overrides: [
      apiClientProvider.overrideWith(
        (ref) => ApiClient(ref, dio: Dio(BaseOptions(baseUrl: 'http://localhost'))),
      ),
    ]);
    final client = container.read(apiClientProvider);
    return _FakeMaintenanceRepo._internal(client);
  }

  @override
  Future<List<MaintenanceRecord>> fetchRecords(String vehicleId) async => [];

  @override
  Future<MaintenanceRecord> createRecord(
      String vehicleId, Map<String, dynamic> data) async {
    calls.add({...data, '_vehicleId': vehicleId});
    return _fakeRecord;
  }
}

class _FakeVehiclesNotifier extends VehiclesNotifier {
  @override
  Future<List<Vehicle>> build() async => [_fakeVehicle];
  @override
  Future<void> refresh() async {}
  @override
  Future<void> create(Map<String, dynamic> data) async {}
  @override
  Future<void> updateVehicle(String id, Map<String, dynamic> data) async {}
  @override
  Future<void> deleteVehicle(String id) async {}
}

Widget _buildSheet(_FakeMaintenanceRepo repo) {
  return ProviderScope(
    overrides: [
      maintenanceRepositoryProvider.overrideWithValue(repo),
      meProvider.overrideWith((_) async => _fakeUser),
      vehiclesProvider.overrideWith(() => _FakeVehiclesNotifier()),
    ],
    child: const MaterialApp(
      home: Scaffold(body: QuickMaintenanceSheet(vehicleId: 'v-1')),
    ),
  );
}

void main() {
  group('QuickMaintenanceSheet', () {
    testWidgets('chip fills the service-type field', (tester) async {
      await tester.pumpWidget(_buildSheet(_FakeMaintenanceRepo()));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ActionChip, 'Oil Change'));
      await tester.pump();

      expect(find.widgetWithText(TextField, 'Oil Change'), findsOneWidget);
    });

    testWidgets('blocks save when service type is empty', (tester) async {
      final repo = _FakeMaintenanceRepo();
      await tester.pumpWidget(_buildSheet(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(repo.calls, isEmpty);
      expect(find.text('Enter a service type'), findsOneWidget);
    });

    testWidgets('saves serviceType + costCents + odometer, omits currency',
        (tester) async {
      final repo = _FakeMaintenanceRepo();
      await tester.pumpWidget(_buildSheet(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ActionChip, 'Oil Change'));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('qm-cost')), '50.00');
      await tester.enterText(find.byKey(const Key('qm-odometer')), '1000');
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(repo.calls, hasLength(1));
      final call = repo.calls.first;
      expect(call['serviceType'], 'Oil Change');
      expect(call['costCents'], 5000);
      expect(call['odometer'], 1000);
      expect(call.containsKey('currency'), isFalse);
    });
  });
}
