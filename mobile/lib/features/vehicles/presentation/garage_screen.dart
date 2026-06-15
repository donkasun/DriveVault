import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
            padding: const EdgeInsets.only(top: 0, bottom: 100),
            itemCount: vehicles.length + 2, // header + vehicles + add card
            itemBuilder: (context, index) {
              if (index == 0) {
                return _GarageHeader(count: vehicles.length);
              }
              final vehicleIndex = index - 1;
              if (vehicleIndex < vehicles.length) {
                return VehicleCard(vehicle: vehicles[vehicleIndex]);
              }
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

class _GarageHeader extends StatelessWidget {
  final int count;
  const _GarageHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 66, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your garage',
            style: TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: Color(0xFF13121C),
              height: 1.05,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count ${count == 1 ? 'vehicle' : 'vehicles'}',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF73738A),
            ),
          ),
        ],
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: GestureDetector(
        onTap: onTap,
        child: CustomPaint(
          foregroundPainter: DashedBorderPainter(
            color: const Color(0xFFE6E6EE),
            radius: 18,
            strokeWidth: 2,
          ),
          child: Container(
            height: 66,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, color: Color(0xFF73738A), size: 20),
                const SizedBox(width: 9),
                const Text(
                  'Add vehicle',
                  style: TextStyle(
                    color: Color(0xFF73738A),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
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

