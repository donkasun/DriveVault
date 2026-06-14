import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/distance_unit.dart';
import '../../../../shared/utils/formatting.dart';
import '../../../documents/data/document_repository.dart';
import '../../../fuel/data/fuel_repository.dart';
import '../../../fuel/presentation/widgets/quick_fuel_entry_sheet.dart';
import '../../../maintenance/data/maintenance_repository.dart';
import '../../../maintenance/presentation/widgets/quick_maintenance_sheet.dart';
import '../../../profile/data/user_repository.dart';
import '../../domain/vehicle.dart';

// Photo dimensions and overhang
const double _photoWidth = 118.0;
const double _photoHeight = 62.0;
const double _photoOverhang = 26.0; // extends above card top edge
const double _photoRadius = 10.0;

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

    // Photo widget — either a real image or a placeholder
    final photoWidget = vehicle.photoUrl != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(_photoRadius),
            child: CachedNetworkImage(
              imageUrl: vehicle.photoUrl!,
              width: _photoWidth,
              height: _photoHeight,
              fit: BoxFit.cover,
              placeholder: (context, url) => const _CarPlaceholder(),
              errorWidget: (context, url, error) => const _CarPlaceholder(),
            ),
          )
        : const _CarPlaceholder();

    // Stack: card body underneath, photo overhanging at top-right.
    // clipBehavior: Clip.none so the photo can extend above the card.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── Card body ──────────────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.cardGradientStart, AppColors.cardGradientEnd],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            // Extra top padding so text content clears the overhanging photo area
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Row ───────────────────────────────────────────
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
                    // Reserve space so the header text doesn't run under the photo
                    SizedBox(width: _photoWidth + 12),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Stats Row ─────────────────────────────────────────────
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

                // ── Divider ───────────────────────────────────────────────
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 12),

                // ── Quick-Action Row ──────────────────────────────────────
                Row(
                  children: [
                    _ActionButton(
                      icon: Icons.add_circle,
                      label: 'Add Fuel',
                      onTap: () =>
                          showQuickFuelEntrySheet(context, vehicleId: vehicle.id),
                    ),
                    _ActionButton(
                      icon: Icons.build,
                      label: 'Service',
                      onTap: () => showQuickMaintenanceSheet(context, vehicleId: vehicle.id),
                    ),
                    _ActionButton(
                      icon: Icons.description,
                      label: 'Docs',
                      onTap: () => context.push(
                          '/garage/vehicle/${vehicle.id}/documents/upload'),
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
        ),

        // ── Overhanging photo — positioned top-right of the card ──────────
        Positioned(
          top: 8 - _photoOverhang, // card margin top (8) minus overhang
          right: 16 + 12, // card margin right (16) + inner padding (12)
          child: photoWidget,
        ),
      ],
    );
  }
}

// ── Private widgets ──────────────────────────────────────────────────────────

class _CarPlaceholder extends StatelessWidget {
  const _CarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _photoWidth,
      height: _photoHeight,
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(_photoRadius),
      ),
      child: const Icon(
        Icons.directions_car,
        color: Colors.white38,
        size: 32,
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
