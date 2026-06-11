import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/distance_unit.dart';
import '../../../../shared/utils/formatting.dart';
import '../../../documents/data/document_repository.dart';
import '../../../documents/presentation/document_upload_screen.dart';
import '../../../fuel/data/fuel_repository.dart';
import '../../../fuel/presentation/fuel_log_form_screen.dart';
import '../../../maintenance/data/maintenance_repository.dart';
import '../../../maintenance/presentation/maintenance_form_screen.dart';
import '../../../profile/data/user_repository.dart';
import '../../domain/vehicle.dart';

class VehicleCard extends ConsumerWidget {
  final Vehicle vehicle;

  const VehicleCard({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meAsync = ref.watch(meProvider);
    final fuelStatsAsync = ref.watch(fuelStatsProvider(vehicle.id));
    final maintenanceAsync = ref.watch(maintenanceRecordsProvider(vehicle.id));
    final docsAsync = ref.watch(documentsProvider(vehicle.id));

    final user = meAsync.asData?.value;
    final stats = fuelStatsAsync.asData?.value;
    final maintenanceRecords = maintenanceAsync.asData?.value;
    final docs = docsAsync.asData?.value;

    // Resolve display unit
    final unit = effectiveUnit(
      vehicleUnit: vehicle.distanceUnit,
      userUnit: user?.distanceUnit ?? 'km',
    );
    final currency = user?.currency ?? 'USD';

    // Compute stats
    final mileageStr = vehicle.currentMileage != null
        ? formatDistance(vehicle.currentMileage!, unit)
        : '—';

    final economyStr = formatEconomy(stats?.avgConsumptionLPer100Km, unit);

    final fuelSpent = stats?.totalSpentCents ?? 0;
    final maintenanceSpent = maintenanceRecords
            ?.fold<int>(0, (sum, r) => sum + (r.costCents ?? 0)) ??
        0;
    final totalSpentStr = formatCents(fuelSpent + maintenanceSpent, currency: currency);

    final docsCount = (docs?.length ?? 0).toString();

    // Vehicle name
    final name = [vehicle.make, vehicle.model, vehicle.year?.toString()]
        .where((s) => s != null && s.isNotEmpty)
        .join(' ');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Row ──────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (vehicle.registrationNumber != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          vehicle.registrationNumber!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Photo box (contained in row, no overhang)
                vehicle.photoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: vehicle.photoUrl!,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const _CarPlaceholder(),
                          errorWidget: (context, url, error) =>
                              const _CarPlaceholder(),
                        ),
                      )
                    : const _CarPlaceholder(),
              ],
            ),
            const SizedBox(height: 16),

            // ── Stats Row ────────────────────────────────────────────────────
            Row(
              children: [
                _StatItem(
                  icon: Icons.speed,
                  value: mileageStr,
                  label: 'Mileage',
                ),
                _StatItem(
                  icon: Icons.local_gas_station,
                  value: economyStr,
                  label: 'Economy',
                ),
                _StatItem(
                  icon: Icons.attach_money,
                  value: totalSpentStr,
                  label: 'Spent',
                ),
                _StatItem(
                  icon: Icons.description_outlined,
                  value: docsCount,
                  label: 'Docs',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Divider ──────────────────────────────────────────────────────
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 12),

            // ── Quick-Action Row ─────────────────────────────────────────────
            Row(
              children: [
                _ActionButton(
                  icon: Icons.add_circle,
                  label: 'Add Fuel',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) =>
                          FuelLogFormScreen(vehicleId: vehicle.id),
                    ),
                  ),
                ),
                _ActionButton(
                  icon: Icons.build,
                  label: 'Service',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) =>
                          MaintenanceFormScreen(vehicleId: vehicle.id),
                    ),
                  ),
                ),
                _ActionButton(
                  icon: Icons.description,
                  label: 'Docs',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) =>
                          DocumentUploadScreen(vehicleId: vehicle.id),
                    ),
                  ),
                ),
                _ActionButton(
                  icon: Icons.arrow_forward,
                  label: 'Details',
                  onTap: () => context.push('/garage/vehicle/${vehicle.id}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private widgets ──────────────────────────────────────────────────────────

class _CarPlaceholder extends StatelessWidget {
  const _CarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.directions_car,
        color: Colors.white38,
        size: 36,
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
