import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../documents/data/document_repository.dart';
import '../../expenses/domain/expense.dart';
import '../../fuel/data/fuel_repository.dart';
import '../../maintenance/data/maintenance_repository.dart';
import '../../vehicles/presentation/vehicles_provider.dart';
import '../domain/activity_entry.dart';

final allActivityProvider = FutureProvider<List<ActivityEntry>>((ref) async {
  ref.keepAlive();

  final vehicles = await ref.watch(vehiclesProvider.future);
  final all = <ActivityEntry>[];

  for (final v in vehicles) {
    final logs = await ref.watch(fuelLogsProvider(v.id).future);
    final records = await ref.watch(maintenanceRecordsProvider(v.id).future);
    final docs = await ref.watch(documentsProvider(v.id).future);

    all.addAll(logs.map((l) => ActivityEntry.fromExpense(Expense.fromFuelLog(l))));
    all.addAll(records.map((r) => ActivityEntry.fromExpense(Expense.fromMaintenance(r))));
    all.addAll(docs.map(ActivityEntry.fromDocument));
  }

  all.sort((a, b) => b.date.compareTo(a.date)); // newest first
  return all;
});
