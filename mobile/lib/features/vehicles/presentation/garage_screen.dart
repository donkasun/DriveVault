import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/dashed_border.dart';
import 'vehicles_provider.dart';
import 'widgets/vehicle_card.dart';

class GarageScreen extends ConsumerWidget {
  const GarageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Garage'),
      ),
      body: vehiclesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(vehiclesProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return _EmptyState(
              onAddTap: () => context.push('/garage/add-vehicle'),
            );
          }

          return ListView.builder(
            // Extra top padding so overflow photos aren't clipped by the list
            padding: const EdgeInsets.only(top: 34, bottom: 100),
            itemCount: vehicles.length + 1,
            itemBuilder: (context, index) {
              if (index < vehicles.length) {
                return VehicleCard(vehicle: vehicles[index]);
              }
              // Dashed "Add Vehicle" card at bottom
              return _AddVehicleCard(
                onTap: () => context.push('/garage/add-vehicle'),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddTap;

  const _EmptyState({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.garage_outlined, size: 72, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No vehicles yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first vehicle to get started',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Add your first vehicle',
              onPressed: onAddTap,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddVehicleCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddVehicleCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: onTap,
        child: CustomPaint(
          foregroundPainter: DashedBorderPainter(
            color: AppColors.dashedBorder,
            radius: 18,
            strokeWidth: 1.5,
          ),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFB),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '+',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Add Vehicle',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

