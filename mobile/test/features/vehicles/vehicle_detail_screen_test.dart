import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:drivevault/features/vehicles/data/vehicle_repository.dart';
import 'package:drivevault/features/vehicles/domain/vehicle.dart';
import 'package:drivevault/features/fuel/data/fuel_repository.dart';
import 'package:drivevault/features/fuel/domain/fuel_log.dart';
import 'package:drivevault/features/fuel/domain/fuel_stats.dart';
import 'package:drivevault/features/maintenance/data/maintenance_repository.dart';
import 'package:drivevault/features/documents/data/document_repository.dart';
import 'package:drivevault/features/profile/data/user_repository.dart';
import 'package:drivevault/features/profile/domain/user.dart';
import 'package:drivevault/features/vehicles/presentation/vehicle_detail_screen.dart';
import 'package:drivevault/features/vehicles/presentation/vehicle_fuel_records_screen.dart';
import 'package:drivevault/features/fuel/presentation/widgets/fuel_record_card.dart';

final _testVehicle = Vehicle(
  id: 'v-1',
  make: 'Toyota',
  model: 'Corolla',
  year: 2020,
  currency: 'USD',
  createdAt: DateTime(2020, 1, 1),
  updatedAt: DateTime(2020, 1, 1),
);

final _testStats = FuelStats(
  totalLiters: 0,
  totalSpentCents: 0,
  monthlySpend: [],
);

final _testUser = AppUser(
  id: 'u-1',
  firebaseUid: 'uid-1',
  email: 'test@example.com',
  currency: 'USD',
  createdAt: DateTime(2020, 1, 1),
);

FuelLog _fuelLog({
  required String id,
  required String date,
  required double liters,
  required int priceCents,
  required bool isFullTank,
}) {
  return FuelLog(
    id: id,
    vehicleId: 'v-1',
    date: date,
    liters: liters,
    priceCents: priceCents,
    currency: 'USD',
    odometer: 10000,
    isFullTank: isFullTank,
    createdAt: DateTime.parse('${date}T00:00:00'),
  );
}

void main() {
  Widget buildSubject({
    AsyncValue<Vehicle>? vehicleOverride,
    List<FuelLog> fuelLogs = const [],
  }) {
    return ProviderScope(
      overrides: [
        meProvider.overrideWith((ref) async => _testUser),
        vehicleProvider('v-1').overrideWith(
          (ref) async => vehicleOverride != null
              ? vehicleOverride.when(
                  data: (v) => v,
                  loading: () => throw UnimplementedError(),
                  error: (e, _) => throw e,
                )
              : _testVehicle,
        ),
        fuelLogsProvider('v-1').overrideWith((ref) async => fuelLogs),
        fuelStatsProvider('v-1').overrideWith((ref) async => _testStats),
        maintenanceRecordsProvider('v-1').overrideWith((ref) async => []),
        documentsProvider('v-1').overrideWith((ref) async => []),
        groupedDocumentsProvider('v-1').overrideWith((ref) async => {}),
      ],
      child: const MaterialApp(home: VehicleDetailScreen(vehicleId: 'v-1')),
    );
  }

  Widget buildSubjectWithRouter({List<FuelLog> fuelLogs = const []}) {
    final router = GoRouter(
      initialLocation: '/garage/vehicle/v-1',
      routes: [
        GoRoute(
          path: '/garage/vehicle/:id',
          builder: (_, state) =>
              VehicleDetailScreen(vehicleId: state.pathParameters['id']!),
          routes: [
            GoRoute(
              path: 'fuel-records',
              builder: (_, state) => VehicleFuelRecordsScreen(
                vehicleId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        meProvider.overrideWith((ref) async => _testUser),
        vehicleProvider('v-1').overrideWith((ref) async => _testVehicle),
        fuelLogsProvider('v-1').overrideWith((ref) async => fuelLogs),
        fuelStatsProvider('v-1').overrideWith((ref) async => _testStats),
        maintenanceRecordsProvider('v-1').overrideWith((ref) async => []),
        documentsProvider('v-1').overrideWith((ref) async => []),
        groupedDocumentsProvider('v-1').overrideWith((ref) async => {}),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('shows loading indicator while vehicle is loading', (
    tester,
  ) async {
    // Use a Completer so the future stays pending without a timer
    final completer = Completer<Vehicle>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          meProvider.overrideWith((ref) async => _testUser),
          vehicleProvider('v-1').overrideWith((ref) => completer.future),
          fuelLogsProvider('v-1').overrideWith((ref) async => []),
          fuelStatsProvider('v-1').overrideWith((ref) async => _testStats),
          maintenanceRecordsProvider('v-1').overrideWith((ref) async => []),
          documentsProvider('v-1').overrideWith((ref) async => []),
          groupedDocumentsProvider('v-1').overrideWith((ref) async => {}),
        ],
        child: const MaterialApp(home: VehicleDetailScreen(vehicleId: 'v-1')),
      ),
    );

    // Single pump — provider is still pending
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Complete the future to clean up
    completer.complete(_testVehicle);
    await tester.pumpAndSettle();
  });

  testWidgets('shows all 3 sections after vehicle loads', (tester) async {
    await tester.pumpWidget(buildSubject());
    // Settle all futures
    await tester.pumpAndSettle();

    expect(find.text('Fuel'), findsOneWidget);
    expect(find.text('Maintenance'), findsOneWidget);
    expect(find.text('Documents'), findsOneWidget);
  });

  testWidgets('shows vehicle name in hero area', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.textContaining('Toyota'), findsWidgets);
    expect(find.textContaining('Corolla'), findsWidgets);
  });

  testWidgets('shows empty state messages when no data', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('No fuel logs yet.'), findsOneWidget);
    expect(find.text('No maintenance records yet.'), findsOneWidget);
    expect(find.text('No documents yet.'), findsOneWidget);
  });

  testWidgets('shows error state when vehicle fails to load', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          meProvider.overrideWith((ref) async => _testUser),
          vehicleProvider(
            'v-1',
          ).overrideWith((ref) async => throw Exception('not found')),
          fuelLogsProvider('v-1').overrideWith((ref) async => []),
          fuelStatsProvider('v-1').overrideWith((ref) async => _testStats),
          maintenanceRecordsProvider('v-1').overrideWith((ref) async => []),
          documentsProvider('v-1').overrideWith((ref) async => []),
          groupedDocumentsProvider('v-1').overrideWith((ref) async => {}),
        ],
        child: const MaterialApp(home: VehicleDetailScreen(vehicleId: 'v-1')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Failed to load vehicle'), findsOneWidget);
  });

  testWidgets('shows at most three recent fuel records and View more', (
    tester,
  ) async {
    final logs = [
      _fuelLog(
        id: 'f-4',
        date: '2026-06-04',
        liters: 18,
        priceCents: 18000,
        isFullTank: true,
      ),
      _fuelLog(
        id: 'f-3',
        date: '2026-06-03',
        liters: 17,
        priceCents: 17000,
        isFullTank: false,
      ),
      _fuelLog(
        id: 'f-2',
        date: '2026-06-02',
        liters: 16,
        priceCents: 16000,
        isFullTank: false,
      ),
      _fuelLog(
        id: 'f-1',
        date: '2026-06-01',
        liters: 15,
        priceCents: 15000,
        isFullTank: false,
      ),
    ];

    await tester.pumpWidget(buildSubjectWithRouter(fuelLogs: logs));
    await tester.pumpAndSettle();

    expect(find.text('Fuel'), findsOneWidget);
    expect(find.byType(FuelRecordCard), findsNWidgets(3));
    expect(find.text('View more'), findsOneWidget);
  });

  testWidgets('View more opens the nested fuel records screen', (tester) async {
    final logs = [
      _fuelLog(
        id: 'f-4',
        date: '2026-06-04',
        liters: 18,
        priceCents: 18000,
        isFullTank: true,
      ),
      _fuelLog(
        id: 'f-3',
        date: '2026-06-03',
        liters: 17,
        priceCents: 17000,
        isFullTank: false,
      ),
      _fuelLog(
        id: 'f-2',
        date: '2026-06-02',
        liters: 16,
        priceCents: 16000,
        isFullTank: false,
      ),
      _fuelLog(
        id: 'f-1',
        date: '2026-06-01',
        liters: 15,
        priceCents: 15000,
        isFullTank: false,
      ),
    ];

    await tester.pumpWidget(buildSubjectWithRouter(fuelLogs: logs));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('View more'),
      find.byType(CustomScrollView),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('View more'));
    await tester.pumpAndSettle();

    expect(find.text('Fuel records'), findsOneWidget);
    expect(find.byType(FuelRecordCard), findsNWidgets(4));
  });
}
