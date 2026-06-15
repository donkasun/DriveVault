import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/distance_unit.dart';
import '../../../../shared/utils/formatting.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../../fuel/data/fuel_repository.dart';
import '../../../fuel/presentation/widgets/quick_fuel_entry_sheet.dart';
import '../../../profile/data/user_repository.dart';
import '../../domain/vehicle.dart';

/// Dark vehicle card used in the Garage list.
///
/// v3 redesign:
/// - No full-width photo banner. Instead, a small 72×72 rounded thumbnail sits
///   in the top-right of the card body.
/// - Name + year·reg + docs status pill stacked on the left.
/// - Three stats (no icons): Mileage · Economy · Spent.
/// - Two actions split by a vertical divider: Log fuel (primary) / Open (ghost).
class VehicleCard extends ConsumerWidget {
  final Vehicle vehicle;

  const VehicleCard({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meAsync = ref.watch(meProvider);
    final fuelStatsAsync = ref.watch(fuelStatsProvider(vehicle.id));

    final user = meAsync.asData?.value;
    final stats = fuelStatsAsync.asData?.value;

    // Resolve display unit
    final unit = effectiveUnit(
      vehicleUnit: vehicle.distanceUnit,
      userUnit: user?.distanceUnit ?? 'km',
    );
    final currency = user?.currency ?? 'USD';

    // Compute display strings
    final mileageStr = vehicle.currentMileage != null
        ? formatDistance(vehicle.currentMileage!, unit)
        : '—';

    // Single shared economy formatter — identical to what vehicle_detail shows
    final economyStr = formatEconomyFromStats(
      stats?.avgConsumptionLPer100Km,
      unit,
    );

    final totalSpentCents = (stats?.totalSpentCents ?? 0);
    final totalSpentStr = formatCents(totalSpentCents, currency: currency);

    final name = vehicle.displayName;
    final year = vehicle.year?.toString();
    final reg = vehicle.registrationNumber;

    // Build "year · reg" subtitle — show whatever is available
    String? subtitle;
    if (year != null && reg != null) {
      subtitle = '$year · $reg';
    } else if (year != null) {
      subtitle = year;
    } else if (reg != null) {
      subtitle = reg;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.cardGradientStart, AppColors.cardGradientEnd],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: name/reg/pill  +  thumbnail ─────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: name stack
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      StatusPill.fromDocsStatus(vehicle.docsStatus),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Right: thumbnail
                _Thumbnail(photoUrl: vehicle.photoUrl),
              ],
            ),
            const SizedBox(height: 14),

            // ── Stats row (no icons) ──────────────────────────────────────
            Row(
              children: [
                _StatItem(value: mileageStr, label: 'MILEAGE'),
                _StatItem(value: economyStr, label: 'ECONOMY'),
                _StatItem(value: totalSpentStr, label: 'SPENT'),
              ],
            ),
            const SizedBox(height: 12),

            // ── Divider ───────────────────────────────────────────────────
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 12),

            // ── Actions row ───────────────────────────────────────────────
            Row(
              children: [
                // Log fuel
                Expanded(
                  child: GestureDetector(
                    onTap: () => showQuickFuelEntrySheet(
                      context,
                      vehicleId: vehicle.id,
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_gas_station,
                            color: AppColors.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Log fuel',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Vertical divider
                Container(
                  width: 1,
                  height: 20,
                  color: Colors.white12,
                ),
                // Open
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        context.push('/garage/vehicle/${vehicle.id}'),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Open',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
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

/// Small rounded-square vehicle thumbnail (72×72).
class _Thumbnail extends StatelessWidget {
  final String? photoUrl;

  const _Thumbnail({this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: photoUrl != null
          ? CachedNetworkImage(
              imageUrl: photoUrl!,
              fit: BoxFit.cover,
              placeholder: (_, _) => const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white24,
                  ),
                ),
              ),
              errorWidget: (_, _, _) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white24,
                size: 28,
              ),
            )
          : const Icon(
              Icons.directions_car_outlined,
              color: Colors.white24,
              size: 32,
            ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
