import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drivevault/features/expenses/data/expenses_provider.dart';
import 'package:drivevault/features/expenses/domain/expense.dart';
import 'package:drivevault/features/expenses/domain/expense_filters.dart';
import 'package:drivevault/features/expenses/presentation/expense_history_screen.dart';
import 'package:drivevault/features/fuel/domain/fuel_log.dart';
import 'package:drivevault/features/maintenance/domain/maintenance_record.dart';
import 'package:drivevault/features/profile/data/user_repository.dart';
import 'package:drivevault/features/profile/domain/user.dart';
import 'package:drivevault/features/vehicles/domain/vehicle.dart';
import 'package:drivevault/features/vehicles/presentation/vehicles_provider.dart';

// ---------------------------------------------------------------------------
// Shared test fixtures
// ---------------------------------------------------------------------------

final _testUser = AppUser(
  id: 'u-1',
  firebaseUid: 'uid-1',
  email: 'test@example.com',
  currency: 'USD',
  createdAt: DateTime(2020, 1, 1),
);

final _vehicle1 = Vehicle(
  id: 'v-1',
  make: 'Toyota',
  model: 'Hilux',
  year: 2020,
  currency: 'USD',
  createdAt: DateTime(2020, 1, 1),
  updatedAt: DateTime(2020, 1, 1),
);

final _vehicle2 = Vehicle(
  id: 'v-2',
  make: 'Honda',
  model: 'Civic',
  year: 2019,
  currency: 'USD',
  createdAt: DateTime(2020, 1, 1),
  updatedAt: DateTime(2020, 1, 1),
);

// Notifier returning only one vehicle (single-vehicle user).
class _SingleVehicleNotifier extends VehiclesNotifier {
  @override
  Future<List<Vehicle>> build() async => [_vehicle1];
}

// Notifier returning two vehicles (multi-vehicle user).
class _TwoVehicleNotifier extends VehiclesNotifier {
  @override
  Future<List<Vehicle>> build() async => [_vehicle1, _vehicle2];
}

FuelLog _fuelLog(
  String id,
  String date,
  int cents, {
  String vehicleId = 'v-1',
}) {
  return FuelLog(
    id: id,
    vehicleId: vehicleId,
    date: date,
    liters: 20,
    priceCents: cents,
    currency: 'USD',
    odometer: 12000,
    isFullTank: true,
    createdAt: DateTime.parse('${date}T00:00:00'),
  );
}

MaintenanceRecord _maintenance(
  String id,
  String date,
  int cents, {
  String vehicleId = 'v-1',
}) {
  return MaintenanceRecord(
    id: id,
    vehicleId: vehicleId,
    date: date,
    serviceType: 'Service',
    costCents: cents,
    currency: 'USD',
    source: 'manual',
    createdAt: DateTime.parse('${date}T00:00:00'),
  );
}

// ---------------------------------------------------------------------------
// Widget test helpers
// ---------------------------------------------------------------------------

Widget _buildScreen({
  required List<Expense> expenses,
  VehiclesNotifier Function()? vehicleNotifier,
}) {
  return ProviderScope(
    overrides: [
      allExpensesProvider.overrideWith((ref) async => expenses),
      meProvider.overrideWith((ref) async => _testUser),
      vehiclesProvider.overrideWith(
        vehicleNotifier ?? () => _SingleVehicleNotifier(),
      ),
    ],
    child: const MaterialApp(home: ExpenseHistoryScreen()),
  );
}

// ---------------------------------------------------------------------------
// Widget tests
// ---------------------------------------------------------------------------

void main() {
  // ---- Existing test: header cards + kind filter ----
  testWidgets('shows redesigned expense header cards', (tester) async {
    final expenses = <Expense>[
      Expense.fromFuelLog(_fuelLog('f-1', '2026-06-04', 18000)),
      Expense.fromMaintenance(_maintenance('m-1', '2026-06-02', 25000)),
    ];

    await tester.pumpWidget(_buildScreen(expenses: expenses));
    await tester.pumpAndSettle();

    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('TOTAL SPENT'), findsOneWidget);
    expect(find.text('All time'), findsOneWidget);
    expect(find.text('Month'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    // 'Fuel' appears in the kind filter AND in the tile primary label.
    expect(find.text('Fuel'), findsWidgets);
    // 'Maintenance' appears in the kind filter toggle AND in the tile.
    expect(find.text('Maintenance'), findsWidgets);

    // Tap Maintenance filter — legend text (legend shows formatted amounts).
    await tester.tap(find.text('Maintenance').first);
    await tester.pumpAndSettle();

    // After filtering to Maintenance only, fuel legend row is hidden.
    expect(find.text('Fuel  \$180.00'), findsNothing);
    expect(find.text('Maintenance  \$250.00'), findsNothing);
  });

  // ---- Existing test: month grouping with 2 vehicles so vehicle name shows ----
  testWidgets('groups combined expenses by month', (tester) async {
    final expenses = <Expense>[
      Expense.fromFuelLog(
        _fuelLog('f-1', '2026-06-04', 18000, vehicleId: 'v-1'),
      ),
      Expense.fromMaintenance(
        _maintenance('m-1', '2026-06-02', 25000, vehicleId: 'v-2'),
      ),
      Expense.fromFuelLog(
        _fuelLog('f-2', '2026-05-21', 16000, vehicleId: 'v-1'),
      ),
      Expense.fromMaintenance(
        _maintenance('m-2', '2026-05-03', 12000, vehicleId: 'v-2'),
      ),
    ];

    await tester.pumpWidget(
      _buildScreen(
        expenses: expenses,
        vehicleNotifier: () => _TwoVehicleNotifier(),
      ),
    );
    await tester.pumpAndSettle();

    // Month headers appear.
    expect(find.text('June 2026'), findsOneWidget);
    expect(find.text('May 2026'), findsOneWidget);

    // Vehicle names appear because there are 2 vehicles.
    expect(find.text(_vehicle1.displayName), findsWidgets);

    // June is rendered above May.
    final juneTop = tester.getTopLeft(find.text('June 2026'));
    final mayTop = tester.getTopLeft(find.text('May 2026'));
    expect(juneTop.dy, lessThan(mayTop.dy));
  });

  // ---- New: vehicle name hidden for single-vehicle users ----
  testWidgets('hides vehicle name when user has only one vehicle', (
    tester,
  ) async {
    final expenses = <Expense>[
      Expense.fromFuelLog(_fuelLog('f-1', '2026-06-04', 18000)),
      Expense.fromMaintenance(_maintenance('m-1', '2026-06-02', 25000)),
    ];

    await tester.pumpWidget(_buildScreen(expenses: expenses));
    await tester.pumpAndSettle();

    // The vehicle's display name must NOT appear in the list.
    expect(find.text(_vehicle1.displayName), findsNothing);
  });

  // ---- New: All-time vs Month toggle filters in-memory ----
  testWidgets('Month toggle filters to current-month expenses only', (
    tester,
  ) async {
    final now = DateTime.now();
    final thisMonthDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
    final lastYear = now.year - 1;
    final oldDate = '$lastYear-01-15';

    final expenses = <Expense>[
      Expense.fromFuelLog(_fuelLog('f-new', thisMonthDate, 10000)),
      Expense.fromFuelLog(_fuelLog('f-old', oldDate, 50000)),
    ];

    await tester.pumpWidget(_buildScreen(expenses: expenses));
    await tester.pumpAndSettle();

    // All-time: both expenses should be visible.
    expect(find.text('Fuel'), findsWidgets); // appears in filter + tiles

    // Tap Month toggle.
    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();

    // Old-year entry must not be visible as a tile (date text contains the old year).
    expect(find.textContaining(oldDate), findsNothing);
  });

  // ---- New: empty-per-filter state when Month has no expenses ----
  testWidgets('shows "No expenses this month" when Month filter has no data', (
    tester,
  ) async {
    // Only an old expense — nothing in the current month.
    final oldDate = '${DateTime.now().year - 1}-06-15';
    final expenses = <Expense>[
      Expense.fromFuelLog(_fuelLog('f-old', oldDate, 5000)),
    ];

    await tester.pumpWidget(_buildScreen(expenses: expenses));
    await tester.pumpAndSettle();

    // Switch to Month filter.
    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();

    expect(find.text('No expenses this month'), findsOneWidget);
  });

  // ---- New: empty state when no expenses at all ----
  testWidgets('shows "No expenses yet" when all-time list is empty', (
    tester,
  ) async {
    await tester.pumpWidget(_buildScreen(expenses: []));
    await tester.pumpAndSettle();

    expect(find.text('No expenses yet'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Pure-unit tests for expense_filters.dart (no Flutter required)
  // ---------------------------------------------------------------------------

  group('filterToCurrentMonth', () {
    test('keeps only expenses in the current calendar month', () {
      final now = DateTime.now();
      final thisMonthDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-10';
      final lastYear = now.year - 1;

      final expenses = [
        Expense.fromFuelLog(_fuelLog('f-in', thisMonthDate, 1000)),
        Expense.fromFuelLog(_fuelLog('f-out', '$lastYear-06-01', 2000)),
      ];

      final result = filterToCurrentMonth(expenses);

      expect(result, hasLength(1));
      expect(result.first.id, 'f-in');
    });
  });

  group('filterByKind', () {
    final mixed = [
      Expense.fromFuelLog(_fuelLog('f-1', '2026-06-01', 100)),
      Expense.fromMaintenance(_maintenance('m-1', '2026-06-01', 200)),
    ];

    test('returns all when kind is null', () {
      expect(filterByKind(mixed, null), hasLength(2));
    });

    test('returns only fuel expenses', () {
      final result = filterByKind(mixed, ExpenseKind.fuel);
      expect(result, hasLength(1));
      expect(result.first.kind, ExpenseKind.fuel);
    });

    test('returns only maintenance expenses', () {
      final result = filterByKind(mixed, ExpenseKind.maintenance);
      expect(result, hasLength(1));
      expect(result.first.kind, ExpenseKind.maintenance);
    });
  });

  group('filterByVehicle', () {
    final expenses = [
      Expense.fromFuelLog(_fuelLog('f-1', '2026-06-01', 100, vehicleId: 'v-1')),
      Expense.fromFuelLog(_fuelLog('f-2', '2026-06-02', 200, vehicleId: 'v-2')),
    ];

    test('returns all when vehicleId is null', () {
      expect(filterByVehicle(expenses, null), hasLength(2));
    });

    test('filters to the specified vehicle', () {
      final result = filterByVehicle(expenses, 'v-2');
      expect(result, hasLength(1));
      expect(result.first.vehicleId, 'v-2');
    });
  });

  group('groupExpensesByMonth', () {
    final expenses = [
      Expense.fromFuelLog(_fuelLog('f-1', '2026-06-04', 18000)),
      Expense.fromMaintenance(_maintenance('m-1', '2026-06-02', 25000)),
      Expense.fromFuelLog(_fuelLog('f-2', '2026-05-21', 16000)),
      Expense.fromMaintenance(_maintenance('m-2', '2026-05-03', 12000)),
    ];

    late List<ExpenseMonthGroup> groups;
    setUpAll(() => groups = groupExpensesByMonth(expenses));

    test('produces two month groups', () {
      expect(groups, hasLength(2));
    });

    test('newest month (June) is first', () {
      expect(groups.first.month.month, 6);
      expect(groups.first.month.year, 2026);
    });

    test('older month (May) is second', () {
      expect(groups.last.month.month, 5);
      expect(groups.last.month.year, 2026);
    });

    test('June subtotal = 18000 + 25000 = 43000', () {
      expect(groups.first.subtotalCents, 43000);
    });

    test('May subtotal = 16000 + 12000 = 28000', () {
      expect(groups.last.subtotalCents, 28000);
    });

    test('each group is sorted newest-date first', () {
      final juneExpenses = groups.first.expenses;
      expect(juneExpenses.first.date, '2026-06-04');
      expect(juneExpenses.last.date, '2026-06-02');
    });

    test('empty input returns empty list', () {
      expect(groupExpensesByMonth([]), isEmpty);
    });
  });

  group('summary helpers', () {
    final expenses = [
      Expense.fromFuelLog(_fuelLog('f-1', '2026-06-01', 5000)),
      Expense.fromFuelLog(_fuelLog('f-2', '2026-06-02', 3000)),
      Expense.fromMaintenance(_maintenance('m-1', '2026-06-01', 2000)),
    ];

    test('totalCents sums all expenses', () {
      expect(totalCents(expenses), 10000);
    });

    test('fuelCents sums only fuel', () {
      expect(fuelCents(expenses), 8000);
    });

    test('maintenanceCents sums only maintenance', () {
      expect(maintenanceCents(expenses), 2000);
    });

    test('all helpers return 0 for empty list', () {
      expect(totalCents([]), 0);
      expect(fuelCents([]), 0);
      expect(maintenanceCents([]), 0);
    });
  });
}
