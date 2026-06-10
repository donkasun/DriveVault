import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drivevault/features/vehicles/data/vehicle_repository.dart';
import 'package:drivevault/features/vehicles/domain/vehicle.dart';
import 'package:drivevault/features/fuel/data/fuel_repository.dart';
import 'package:drivevault/features/fuel/domain/fuel_stats.dart';
import 'package:drivevault/features/maintenance/data/maintenance_repository.dart';
import 'package:drivevault/features/documents/data/document_repository.dart';
import 'package:drivevault/features/vehicles/presentation/vehicle_detail_screen.dart';

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

void main() {
  Widget buildSubject({AsyncValue<Vehicle>? vehicleOverride}) {
    return ProviderScope(
      overrides: [
        vehicleProvider('v-1').overrideWith(
          (ref) async => vehicleOverride != null
              ? vehicleOverride.when(
                  data: (v) => v,
                  loading: () => throw UnimplementedError(),
                  error: (e, _) => throw e,
                )
              : _testVehicle,
        ),
        fuelLogsProvider('v-1').overrideWith((ref) async => []),
        fuelStatsProvider('v-1').overrideWith((ref) async => _testStats),
        maintenanceRecordsProvider('v-1').overrideWith((ref) async => []),
        documentsProvider('v-1').overrideWith((ref) async => []),
        groupedDocumentsProvider('v-1').overrideWith((ref) async => {}),
      ],
      child: const MaterialApp(
        home: VehicleDetailScreen(vehicleId: 'v-1'),
      ),
    );
  }

  testWidgets('shows loading indicator while vehicle is loading',
      (tester) async {
    // Use a Completer so the future stays pending without a timer
    final completer = Completer<Vehicle>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vehicleProvider('v-1').overrideWith((ref) => completer.future),
          fuelLogsProvider('v-1').overrideWith((ref) async => []),
          fuelStatsProvider('v-1').overrideWith((ref) async => _testStats),
          maintenanceRecordsProvider('v-1').overrideWith((ref) async => []),
          documentsProvider('v-1').overrideWith((ref) async => []),
          groupedDocumentsProvider('v-1').overrideWith((ref) async => {}),
        ],
        child: const MaterialApp(
          home: VehicleDetailScreen(vehicleId: 'v-1'),
        ),
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
          vehicleProvider('v-1').overrideWith(
            (ref) async => throw Exception('not found'),
          ),
          fuelLogsProvider('v-1').overrideWith((ref) async => []),
          fuelStatsProvider('v-1').overrideWith((ref) async => _testStats),
          maintenanceRecordsProvider('v-1').overrideWith((ref) async => []),
          documentsProvider('v-1').overrideWith((ref) async => []),
          groupedDocumentsProvider('v-1').overrideWith((ref) async => {}),
        ],
        child: const MaterialApp(
          home: VehicleDetailScreen(vehicleId: 'v-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Failed to load vehicle'), findsOneWidget);
  });
}
