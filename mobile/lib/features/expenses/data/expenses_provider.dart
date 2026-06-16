import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../fuel/data/fuel_repository.dart';
import '../../maintenance/data/maintenance_repository.dart';
import '../../vehicles/presentation/vehicles_provider.dart';
import '../domain/expense.dart';

final allExpensesProvider = FutureProvider<List<Expense>>((ref) async {
  // keepAlive so the fan-out result is cached across tab switches.
  // The per-vehicle sub-providers (fuelLogsProvider, maintenanceRecordsProvider)
  // are themselves keepAlive and invalidated on every mutation, so this
  // provider will be correctly re-evaluated when ref.invalidate(allExpensesProvider)
  // is called from expense_history_screen.dart and maintenance_form_screen.dart.
  ref.keepAlive();

  final vehicles = await ref.watch(vehiclesProvider.future);
  final all = <Expense>[];
  for (final v in vehicles) {
    final logs = await ref.watch(fuelLogsProvider(v.id).future);
    final records = await ref.watch(maintenanceRecordsProvider(v.id).future);
    all.addAll(logs.map(Expense.fromFuelLog));
    all.addAll(records.map(Expense.fromMaintenance));
  }
  all.sort((a, b) => b.date.compareTo(a.date)); // newest first
  return all;
});
