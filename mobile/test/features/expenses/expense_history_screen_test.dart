import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drivevault/features/expenses/data/expenses_provider.dart';
import 'package:drivevault/features/expenses/domain/expense.dart';
import 'package:drivevault/features/expenses/presentation/expense_history_screen.dart';
import 'package:drivevault/features/fuel/domain/fuel_log.dart';
import 'package:drivevault/features/maintenance/domain/maintenance_record.dart';
import 'package:drivevault/features/profile/data/user_repository.dart';
import 'package:drivevault/features/profile/domain/user.dart';
import 'package:drivevault/features/vehicles/domain/vehicle.dart';
import 'package:drivevault/features/vehicles/presentation/vehicles_provider.dart';

final _testUser = AppUser(
  id: 'u-1',
  firebaseUid: 'uid-1',
  email: 'test@example.com',
  currency: 'USD',
  createdAt: DateTime(2020, 1, 1),
);

final _vehicle = Vehicle(
  id: 'v-1',
  make: 'Toyota',
  model: 'Hilux',
  year: 2020,
  currency: 'USD',
  createdAt: DateTime(2020, 1, 1),
  updatedAt: DateTime(2020, 1, 1),
);

class _FakeVehiclesNotifier extends VehiclesNotifier {
  @override
  Future<List<Vehicle>> build() async => [_vehicle];
}

FuelLog _fuelLog(String id, String date, int cents) {
  return FuelLog(
    id: id,
    vehicleId: _vehicle.id,
    date: date,
    liters: 20,
    priceCents: cents,
    currency: 'USD',
    odometer: 12000,
    isFullTank: true,
    createdAt: DateTime.parse('${date}T00:00:00'),
  );
}

MaintenanceRecord _maintenance(String id, String date, int cents) {
  return MaintenanceRecord(
    id: id,
    vehicleId: _vehicle.id,
    date: date,
    serviceType: 'Service',
    costCents: cents,
    currency: 'USD',
    source: 'manual',
    createdAt: DateTime.parse('${date}T00:00:00'),
  );
}

void main() {
  testWidgets('shows redesigned expense header cards', (tester) async {
    final expenses = <Expense>[
      Expense.fromFuelLog(_fuelLog('f-1', '2026-06-04', 18000)),
      Expense.fromMaintenance(_maintenance('m-1', '2026-06-02', 25000)),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allExpensesProvider.overrideWith((ref) async => expenses),
          meProvider.overrideWith((ref) async => _testUser),
          vehiclesProvider.overrideWith(() => _FakeVehiclesNotifier()),
        ],
        child: const MaterialApp(home: ExpenseHistoryScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('TOTAL SPENT'), findsOneWidget);
    expect(find.text('All time'), findsOneWidget);
    expect(find.text('Month'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Fuel'), findsWidgets);
    expect(find.text('Maintenance'), findsOneWidget);

    await tester.tap(find.text('Maintenance').last);
    await tester.pumpAndSettle();

    expect(find.text('Fuel  Rs 18,000.00'), findsNothing);
    expect(find.text('Maintenance  Rs 25,000.00'), findsNothing);
  });

  testWidgets('groups combined expenses by month', (tester) async {
    final expenses = <Expense>[
      Expense.fromFuelLog(_fuelLog('f-1', '2026-06-04', 18000)),
      Expense.fromMaintenance(_maintenance('m-1', '2026-06-02', 25000)),
      Expense.fromFuelLog(_fuelLog('f-2', '2026-05-21', 16000)),
      Expense.fromMaintenance(_maintenance('m-2', '2026-05-03', 12000)),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allExpensesProvider.overrideWith((ref) async => expenses),
          meProvider.overrideWith((ref) async => _testUser),
          vehiclesProvider.overrideWith(() => _FakeVehiclesNotifier()),
        ],
        child: const MaterialApp(home: ExpenseHistoryScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('June 2026'), findsOneWidget);
    expect(find.text('May 2026'), findsOneWidget);
    expect(find.text(_vehicle.displayName), findsWidgets);

    final juneTop = tester.getTopLeft(find.text('June 2026'));
    final mayTop = tester.getTopLeft(find.text('May 2026'));
    expect(juneTop.dy, lessThan(mayTop.dy));
  });
}
