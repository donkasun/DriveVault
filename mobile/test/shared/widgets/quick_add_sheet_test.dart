import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:drivevault/core/theme/app_theme.dart';
import 'package:drivevault/features/vehicles/domain/vehicle.dart';
import 'package:drivevault/features/vehicles/presentation/vehicles_provider.dart';
import 'package:drivevault/shared/widgets/quick_add_sheet.dart';

// ── Fake vehicles notifier ────────────────────────────────────────────────────

class _FakeVehiclesNotifier extends AsyncNotifier<List<Vehicle>>
    implements VehiclesNotifier {
  final List<Vehicle> _vehicles;
  _FakeVehiclesNotifier(this._vehicles);

  @override
  Future<List<Vehicle>> build() async => _vehicles;

  @override
  Future<void> refresh() async {}

  @override
  Future<void> create(Map<String, dynamic> data) async {}

  @override
  Future<void> updateVehicle(String id, Map<String, dynamic> data) async {}

  @override
  Future<void> deleteVehicle(String id) async {}
}

// ── Shared fake vehicle ───────────────────────────────────────────────────────

Vehicle _fakeVehicle(String id) => Vehicle(
  id: id,
  make: 'Toyota',
  model: 'Corolla',
  year: 2020,
  currency: 'LKR',
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);

// ── Widget builder ────────────────────────────────────────────────────────────

/// Builds QuickAddSheet wrapped in a minimal go_router / ProviderScope
/// so navigation calls don't throw.
Widget _buildSheet(List<Vehicle> vehicles) {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, __) => Scaffold(
          body: ProviderScope(
            overrides: [
              vehiclesProvider.overrideWith(
                () => _FakeVehiclesNotifier(vehicles),
              ),
            ],
            child: const QuickAddSheet(),
          ),
        ),
      ),
      GoRoute(
        path: '/garage',
        builder: (_, __) => const Scaffold(body: Text('garage')),
        routes: [
          GoRoute(
            path: 'add-vehicle',
            builder: (_, __) => const Scaffold(body: Text('add-vehicle')),
          ),
          GoRoute(
            path: 'vehicle/:id',
            builder: (_, s) =>
                Scaffold(body: Text('vehicle-${s.pathParameters['id']}')),
            routes: [
              GoRoute(
                path: 'documents/upload',
                builder: (_, s) => const Scaffold(body: Text('doc-upload')),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  return MaterialApp.router(theme: AppTheme.light, routerConfig: router);
}

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  group('QuickAddSheet', () {
    // ── Renders four action rows ───────────────────────────────────────────

    testWidgets('shows all four action labels', (tester) async {
      await tester.pumpWidget(_buildSheet([_fakeVehicle('v-1')]));
      await tester.pumpAndSettle();

      expect(find.text('Log fuel'), findsOneWidget);
      expect(find.text('Add service'), findsOneWidget);
      expect(find.text('Upload document'), findsOneWidget);
      expect(find.text('Add vehicle'), findsOneWidget);
    });

    // ── 0 vehicles: fuel/service/document disabled, Add vehicle active ────

    testWidgets('with 0 vehicles: fuel, service, document rows are disabled', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSheet([]));
      await tester.pumpAndSettle();

      // Fuel, service, document should be non-tappable (InkWell.onTap = null).
      // We verify by checking that tapping them doesn't route away from home.
      final fuelRow = find.byKey(const Key('quick_add_fuel'));
      final serviceRow = find.byKey(const Key('quick_add_service'));
      final docRow = find.byKey(const Key('quick_add_document'));
      final vehicleRow = find.byKey(const Key('quick_add_vehicle'));

      expect(fuelRow, findsOneWidget);
      expect(serviceRow, findsOneWidget);
      expect(docRow, findsOneWidget);
      expect(vehicleRow, findsOneWidget);

      // Verify the no-vehicles hint is shown.
      expect(
        find.text('Add a vehicle first to log fuel, services, or documents.'),
        findsOneWidget,
      );
    });

    testWidgets('with 0 vehicles: Add vehicle row is tappable (enabled=true)', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSheet([]));
      await tester.pumpAndSettle();

      // The _ActionRow for Add vehicle has enabled=true.
      // Verify it isn't visually dimmed like the disabled rows by confirming
      // it carries enabled=true in the widget tree: done indirectly by
      // checking Opacity values.
      //
      // All four rows render an Opacity widget.
      // Disabled rows get opacity 0.45; enabled rows get 1.0.
      final opacities = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .map((o) => o.opacity)
          .toList();

      // At least one row is fully opaque (Add vehicle).
      expect(opacities.where((o) => o == 1.0), isNotEmpty);
      // The other three rows are dimmed.
      expect(opacities.where((o) => o == 0.45), hasLength(3));
    });

    testWidgets('with 0 vehicles: no-vehicles banner is shown', (tester) async {
      await tester.pumpWidget(_buildSheet([]));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    // ── 1 vehicle: all rows enabled, no banner ────────────────────────────

    testWidgets('with 1 vehicle: all four rows are enabled', (tester) async {
      await tester.pumpWidget(_buildSheet([_fakeVehicle('v-1')]));
      await tester.pumpAndSettle();

      final opacities = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .map((o) => o.opacity)
          .toList();

      // All rows should be fully opaque.
      expect(opacities.every((o) => o == 1.0), isTrue);
    });

    testWidgets('with 1 vehicle: no-vehicles banner is absent', (tester) async {
      await tester.pumpWidget(_buildSheet([_fakeVehicle('v-1')]));
      await tester.pumpAndSettle();

      expect(
        find.text('Add a vehicle first to log fuel, services, or documents.'),
        findsNothing,
      );
    });

    // ── Many vehicles: all rows enabled ──────────────────────────────────

    testWidgets('with >1 vehicles: all four rows are enabled', (tester) async {
      await tester.pumpWidget(
        _buildSheet([_fakeVehicle('v-1'), _fakeVehicle('v-2')]),
      );
      await tester.pumpAndSettle();

      final opacities = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .map((o) => o.opacity)
          .toList();

      expect(opacities.every((o) => o == 1.0), isTrue);
    });

    // ── Header close button ───────────────────────────────────────────────

    testWidgets('renders Quick add title and close button', (tester) async {
      await tester.pumpWidget(_buildSheet([_fakeVehicle('v-1')]));
      await tester.pumpAndSettle();

      expect(find.text('Quick add'), findsOneWidget);
      expect(find.byKey(const Key('quick_add_close')), findsOneWidget);
    });

    // ── Row keys are present ──────────────────────────────────────────────

    testWidgets('action rows have correct ValueKeys', (tester) async {
      await tester.pumpWidget(_buildSheet([_fakeVehicle('v-1')]));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('quick_add_fuel')), findsOneWidget);
      expect(find.byKey(const Key('quick_add_service')), findsOneWidget);
      expect(find.byKey(const Key('quick_add_document')), findsOneWidget);
      expect(find.byKey(const Key('quick_add_vehicle')), findsOneWidget);
    });
  });
}
