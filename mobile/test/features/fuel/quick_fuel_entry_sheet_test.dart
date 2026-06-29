import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drivevault/core/network/api_client.dart';
import 'package:drivevault/features/fuel/data/fuel_repository.dart';
import 'package:drivevault/features/fuel/domain/fuel_entry_calc.dart';
import 'package:drivevault/features/fuel/domain/fuel_log.dart';
import 'package:drivevault/features/fuel/domain/fuel_stats.dart';
import 'package:drivevault/features/fuel/presentation/widgets/fuel_numeric_keypad.dart';
import 'package:drivevault/features/fuel/presentation/widgets/quick_fuel_entry_sheet.dart';
import 'package:drivevault/features/profile/data/user_repository.dart';
import 'package:drivevault/features/profile/domain/user.dart';
import 'package:drivevault/features/vehicles/domain/vehicle.dart';
import 'package:drivevault/features/vehicles/presentation/vehicles_provider.dart';

// ─── Seed data ───────────────────────────────────────────────────────────────

// liters 40, priceCents 8000 → per-liter = 8000/100/40 = 2.00
final _latestLog = FuelLog(
  id: 'log-1',
  vehicleId: 'v-1',
  date: '2026-06-01',
  liters: 40.0,
  priceCents: 8000,
  currency: 'LKR',
  odometer: 50000,
  isFullTank: true,
  createdAt: DateTime(2026, 6, 1),
);

final _fakeVehicle = Vehicle(
  id: 'v-1',
  make: 'Toyota',
  model: 'Corolla',
  year: 2020,
  currency: 'LKR',
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

// ─── Fake FuelRepository ──────────────────────────────────────────────────────

/// A FuelRepository that records createFuelLog calls.
class _FakeFuelRepo extends FuelRepository {
  final List<Map<String, dynamic>> calls = [];
  bool shouldThrow = false;

  _FakeFuelRepo._internal(ApiClient client) : super(client);

  factory _FakeFuelRepo() {
    late _FakeFuelRepo instance;
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWith(
          (ref) => ApiClient(
            ref,
            dio: Dio(BaseOptions(baseUrl: 'http://localhost')),
          ),
        ),
      ],
    );
    final client = container.read(apiClientProvider);
    instance = _FakeFuelRepo._internal(client);
    return instance;
  }

  @override
  Future<List<FuelLog>> fetchFuelLogs(String vehicleId) async => [_latestLog];

  @override
  Future<FuelStats> fetchFuelStats(String vehicleId) async => FuelStats(
    avgConsumptionLPer100Km: null,
    avgCostPerKmCents: null,
    totalLiters: 40.0,
    totalSpentCents: 8000,
    monthlySpend: [],
  );

  @override
  Future<FuelLog> createFuelLog(
    String vehicleId,
    Map<String, dynamic> data,
  ) async {
    if (shouldThrow) throw Exception('network error');
    calls.add({...data, '_vehicleId': vehicleId});
    return _latestLog;
  }
}

class _FakeVehiclesNotifier extends AsyncNotifier<List<Vehicle>>
    implements VehiclesNotifier {
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

// ─── Widget builder ──────────────────────────────────────────────────────────

Widget _buildSheet(_FakeFuelRepo fakeRepo) {
  return ProviderScope(
    overrides: [
      fuelRepositoryProvider.overrideWithValue(fakeRepo),
      meProvider.overrideWith((_) async => _fakeUser),
      vehiclesProvider.overrideWith(() => _FakeVehiclesNotifier()),
      fuelLogsProvider.overrideWith((ref, id) async => [_latestLog]),
      fuelStatsProvider.overrideWith(
        (ref, id) async => FuelStats(
          avgConsumptionLPer100Km: null,
          avgCostPerKmCents: null,
          totalLiters: 40.0,
          totalSpentCents: 8000,
          monthlySpend: [],
        ),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(body: QuickFuelEntrySheet(vehicleId: 'v-1')),
    ),
  );
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Taps a field in the sheet identified by its [ValueKey] label.
/// Use the label as passed to _buildTappableField (e.g. 'Odometer (km)').
Future<void> _tapField(WidgetTester tester, String fieldLabel) async {
  await tester.tap(find.byKey(ValueKey('fuel_field_$fieldLabel')));
  await tester.pump();
}

/// Taps a keypad key. For '⌫' uses the ValueKey; for digits/dot uses the
/// Text widget inside FuelNumericKeypad.
Future<void> _tapKey(WidgetTester tester, String key) async {
  final Finder keyFinder;
  if (key == '⌫') {
    keyFinder = find.byKey(const ValueKey('keypad_backspace'));
  } else {
    keyFinder = find.descendant(
      of: find.byType(FuelNumericKeypad),
      matching: find.text(key),
    );
  }
  await tester.tap(keyFinder);
  await tester.pump();
}

/// Types a sequence of keypad keys into the focused field.
Future<void> _typeKeys(WidgetTester tester, String digits) async {
  for (final ch in digits.split('')) {
    await _tapKey(tester, ch == '.' ? '.' : ch);
  }
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('QuickFuelEntrySheet', () {
    // ── Rendering ───────────────────────────────────────────────────────────

    testWidgets('renders all four tappable fields', (tester) async {
      await tester.pumpWidget(_buildSheet(_FakeFuelRepo()));
      await tester.pumpAndSettle();

      // Each field has a ValueKey set in _buildTappableField.
      expect(
        find.byKey(const ValueKey('fuel_field_Odometer (km)')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('fuel_field_Liters')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('fuel_field_Total paid')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('fuel_field_Price/L')), findsOneWidget);
    });

    testWidgets('renders Full / Partial segmented toggle', (tester) async {
      await tester.pumpWidget(_buildSheet(_FakeFuelRepo()));
      await tester.pumpAndSettle();

      expect(find.text('Full tank'), findsOneWidget);
      expect(find.text('Partial'), findsOneWidget);
    });

    testWidgets('renders numeric keypad with all expected keys', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSheet(_FakeFuelRepo()));
      await tester.pumpAndSettle();

      for (final key in ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']) {
        expect(
          find.descendant(
            of: find.byType(FuelNumericKeypad),
            matching: find.text(key),
          ),
          findsOneWidget,
          reason: 'Keypad should have digit $key',
        );
      }
    });

    // ── Save disabled until valid ────────────────────────────────────────────

    testWidgets('Save button is disabled when no data entered', (tester) async {
      await tester.pumpWidget(_buildSheet(_FakeFuelRepo()));
      await tester.pumpAndSettle();

      final saveBtn = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(
        saveBtn.onPressed,
        isNull,
        reason: 'Save must be disabled when calc is incomplete',
      );
    });

    testWidgets('Save is disabled with only odometer entered', (tester) async {
      await tester.pumpWidget(_buildSheet(_FakeFuelRepo()));
      await tester.pumpAndSettle();

      // Type odometer: 1000
      await _tapField(tester, 'Odometer (km)');
      await _typeKeys(tester, '1000');
      await tester.pump();

      final saveBtn = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(
        saveBtn.onPressed,
        isNull,
        reason: 'Save must be disabled without calc fields',
      );
    });

    // ── AUTO tagging ─────────────────────────────────────────────────────────

    testWidgets('Price/L shows AUTO when liters + total are both entered', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSheet(_FakeFuelRepo()));
      await tester.pumpAndSettle();

      // Enter odometer
      await _tapField(tester, 'Odometer (km)');
      await _typeKeys(tester, '1000');

      // Enter Liters: 40
      await _tapField(tester, 'Liters');
      await _typeKeys(tester, '40');

      // Enter Total: 100
      await _tapField(tester, 'Total paid');
      await _typeKeys(tester, '100');

      await tester.pump();

      // Price/L should now show AUTO badge
      expect(
        find.text('AUTO'),
        findsOneWidget,
        reason: 'Price/L should be tagged AUTO when derived from liters+total',
      );
    });

    testWidgets('Liters shows AUTO when total + per-liter entered', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSheet(_FakeFuelRepo()));
      await tester.pumpAndSettle();

      // Enter odometer
      await _tapField(tester, 'Odometer (km)');
      await _typeKeys(tester, '1000');

      // Enter Total: 100
      await _tapField(tester, 'Total paid');
      await _typeKeys(tester, '100');

      // Enter Price/L: 2 (clear seeded value first via backspace then retype)
      await _tapField(tester, 'Price/L');
      // Clear existing seeded value (up to 5 backspaces)
      for (var i = 0; i < 5; i++) {
        await _tapKey(tester, '⌫');
      }
      await _typeKeys(tester, '2');

      await tester.pump();

      expect(
        find.text('AUTO'),
        findsOneWidget,
        reason: 'Liters should be tagged AUTO when derived from total+perLiter',
      );
    });

    testWidgets('Save is enabled when liters + price/L are entered', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSheet(_FakeFuelRepo()));
      await tester.pumpAndSettle();

      await _tapField(tester, 'Odometer (km)');
      await _typeKeys(tester, '1000');

      await _tapField(tester, 'Liters');
      await _typeKeys(tester, '40');

      await _tapField(tester, 'Price/L');
      for (var i = 0; i < 5; i++) {
        await _tapKey(tester, '⌫');
      }
      await _typeKeys(tester, '2');
      await tester.pump();

      expect(find.text('AUTO'), findsOneWidget);

      final saveBtn = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(
        saveBtn.onPressed,
        isNotNull,
        reason: 'Save must be enabled once the calc triple is complete',
      );
    });

    // ── Save payload ─────────────────────────────────────────────────────────

    testWidgets(
      'saves with isFullTank=true, correct priceCents, derived liters',
      (tester) async {
        final fakeRepo = _FakeFuelRepo();

        await tester.pumpWidget(_buildSheet(fakeRepo));
        await tester.pumpAndSettle();

        // Enter odometer: 51000
        await _tapField(tester, 'Odometer (km)');
        await _typeKeys(tester, '51000');

        // Enter Total: 100.00 → per-liter seeded at 2.00 → liters = 50
        await _tapField(tester, 'Total paid');
        await _typeKeys(tester, '100');

        await tester.pump();

        // Save should now be enabled
        final saveBtn = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(saveBtn.onPressed, isNotNull, reason: 'Save must be enabled');

        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        expect(
          fakeRepo.calls,
          hasLength(1),
          reason: 'createFuelLog should be called exactly once',
        );
        final call = fakeRepo.calls.first;
        expect(call['isFullTank'], isTrue);
        expect((call['liters'] as double), closeTo(50.0, 0.01));
        expect(call['priceCents'], equals(10000));
      },
    );

    // ── Double-submit guard ──────────────────────────────────────────────────

    testWidgets('tapping Save twice does not send duplicate requests', (
      tester,
    ) async {
      final fakeRepo = _FakeFuelRepo();

      await tester.pumpWidget(_buildSheet(fakeRepo));
      await tester.pumpAndSettle();

      // Fill in valid data
      await _tapField(tester, 'Odometer (km)');
      await _typeKeys(tester, '51000');
      await _tapField(tester, 'Total paid');
      await _typeKeys(tester, '100');
      await tester.pump();

      // Tap Save twice in quick succession (no pumpAndSettle between)
      await tester.tap(find.byType(FilledButton));
      await tester.pump(); // one frame — _saving = true, button disabled
      await tester.tap(find.byType(FilledButton)); // should be no-op
      await tester.pumpAndSettle();

      expect(
        fakeRepo.calls,
        hasLength(1),
        reason: 'Double-tap must send only one createFuelLog call',
      );
    });

    // ── Partial tank ─────────────────────────────────────────────────────────

    testWidgets('switching to Partial sets isFullTank=false in payload', (
      tester,
    ) async {
      final fakeRepo = _FakeFuelRepo();

      await tester.pumpWidget(_buildSheet(fakeRepo));
      await tester.pumpAndSettle();

      // Switch to Partial
      await tester.tap(find.text('Partial'));
      await tester.pump();

      // Fill in valid data
      await _tapField(tester, 'Odometer (km)');
      await _typeKeys(tester, '51000');
      await _tapField(tester, 'Total paid');
      await _typeKeys(tester, '80');
      await tester.pump();

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(fakeRepo.calls, hasLength(1));
      expect(fakeRepo.calls.first['isFullTank'], isFalse);
    });

    // ── Running total on Save button ─────────────────────────────────────────

    testWidgets('Save button shows running total when calc is complete', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSheet(_FakeFuelRepo()));
      await tester.pumpAndSettle();

      await _tapField(tester, 'Odometer (km)');
      await _typeKeys(tester, '51000');

      // per-liter seeded at 2.00, enter total = 100 → Save · Rs 100
      await _tapField(tester, 'Total paid');
      await _typeKeys(tester, '100');
      await tester.pump();

      // Save button label should contain the running total
      expect(
        find.textContaining('Save · Rs'),
        findsOneWidget,
        reason: 'Save button should show running total',
      );
    });
  });

  // ── Additional FuelEntryCalc tests ──────────────────────────────────────────

  group('FuelEntryCalc — extended coverage', () {
    test('no initialPerLiter: liters + total → derive perLiter', () {
      // All three permutations without sticky default
      final calc = FuelEntryCalc();
      calc.setField(FuelField.liters, 50.0);
      calc.setField(FuelField.total, 100.0);
      expect(calc.pricePerLiter, closeTo(2.0, 1e-9));
      expect(calc.isComplete, isTrue);
    });

    test('no initialPerLiter: total + perLiter → derive liters', () {
      final calc = FuelEntryCalc();
      calc.setField(FuelField.total, 100.0);
      calc.setField(FuelField.perLiter, 2.5);
      expect(calc.liters, closeTo(40.0, 1e-9));
      expect(calc.isComplete, isTrue);
    });

    test('no initialPerLiter: liters + perLiter → derive total', () {
      final calc = FuelEntryCalc();
      calc.setField(FuelField.liters, 30.0);
      calc.setField(FuelField.perLiter, 3.0);
      expect(calc.total, closeTo(90.0, 1e-9));
      expect(calc.isComplete, isTrue);
    });

    test('zero liters input → isComplete stays false', () {
      final calc = FuelEntryCalc(initialPerLiter: 2.0);
      calc.setField(FuelField.liters, 0.0);
      calc.setField(FuelField.total, 100.0);
      // isComplete requires liters > 0
      expect(calc.isComplete, isFalse);
    });

    test('zero perLiter does not cause divide-by-zero', () {
      final calc = FuelEntryCalc();
      calc.setField(FuelField.total, 100.0);
      // Setting perLiter = 0 should not throw; liters should remain undefined
      calc.setField(FuelField.perLiter, 0.0);
      // calc cannot complete derivation with zero perLiter
      expect(calc.isComplete, isFalse);
    });

    test(
      're-derive: editing previously-derived field switches derived target',
      () {
        // Start: total + perLiter → AUTO liters
        final calc = FuelEntryCalc();
        calc.setField(FuelField.total, 100.0);
        calc.setField(FuelField.perLiter, 2.0);
        expect(calc.derivedField, FuelField.liters);
        expect(calc.liters, closeTo(50.0, 1e-9));

        // Now user edits the derived liters field → total becomes AUTO
        calc.setField(FuelField.liters, 40.0);
        expect(calc.derivedField, FuelField.total);
        expect(calc.total, closeTo(80.0, 1e-9));
      },
    );

    test('null (cleared) input removes field from locked pair', () {
      final calc = FuelEntryCalc(initialPerLiter: 2.0);
      calc.setField(FuelField.total, 100.0);
      expect(calc.isComplete, isTrue); // liters derived

      calc.setField(FuelField.total, null);
      expect(calc.isComplete, isFalse);
      expect(calc.derivedField, isNull);
    });

    test('invalid (null from tryParse) clears the field gracefully', () {
      final calc = FuelEntryCalc(initialPerLiter: 2.0);
      calc.setField(FuelField.liters, 40.0);
      expect(calc.isComplete, isTrue);

      // Simulate user typing invalid text → parsed as null
      calc.setField(FuelField.liters, double.tryParse('abc'));
      expect(calc.isComplete, isFalse);
    });

    test('derivedField is null when fewer than two fields are locked', () {
      final calc = FuelEntryCalc();
      expect(calc.derivedField, isNull);
      calc.setField(FuelField.liters, 10.0);
      expect(calc.derivedField, isNull);
    });
  });
}
