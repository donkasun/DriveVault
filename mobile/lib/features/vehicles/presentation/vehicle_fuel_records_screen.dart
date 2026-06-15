import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/presentation/dashboard_provider.dart';
import '../../fuel/data/fuel_repository.dart';
import '../../fuel/presentation/widgets/fuel_record_card.dart';
import '../../fuel/presentation/widgets/quick_fuel_entry_sheet.dart';
import '../data/vehicle_repository.dart';
import 'vehicles_provider.dart';

class VehicleFuelRecordsScreen extends ConsumerWidget {
  final String vehicleId;

  const VehicleFuelRecordsScreen({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(fuelLogsProvider(vehicleId));
    void refresh() {
      ref.invalidate(fuelLogsProvider(vehicleId));
      ref.invalidate(fuelStatsProvider(vehicleId));
      ref.invalidate(vehicleProvider(vehicleId));
      ref.invalidate(vehiclesProvider);
      ref.invalidate(dashboardProvider);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuel records'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () =>
                showQuickFuelEntrySheet(context, vehicleId: vehicleId),
            child: const Text('Add fuel'),
          ),
        ],
      ),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(
              child: Text(
                'No fuel records yet.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final sorted = [...logs]..sort((a, b) => b.date.compareTo(a.date));
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: sorted.length,
            itemBuilder: (_, i) => FuelRecordCard(
              log: sorted[i],
              vehicleId: vehicleId,
              onRefresh: refresh,
            ),
          );
        },
      ),
    );
  }
}
