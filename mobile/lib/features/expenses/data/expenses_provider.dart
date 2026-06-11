import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../fuel/data/fuel_repository.dart';
import '../../maintenance/data/maintenance_repository.dart';
import '../../vehicles/presentation/vehicles_provider.dart';
import '../domain/expense.dart';

final allExpensesProvider = FutureProvider<List<Expense>>((ref) async {
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
