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

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.cardGradientStart, AppColors.cardGradientEnd],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top section: name/reg/pill + thumbnail ─────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
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
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (year != null || reg != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (year != null)
                              Text(
                                year,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.62),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (year != null && reg != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 3,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.38),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (reg != null)
                              Text(
                                reg,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.62),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                  letterSpacing: 0.5,
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      StatusPill.fromDocsStatus(vehicle.docsStatus, onDark: true),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _Thumbnail(photoUrl: vehicle.photoUrl),
              ],
            ),
          ),

          // ── Divider ───────────────────────────────────────────────────
          const Divider(color: Color(0xFF34333F), height: 1, thickness: 1),

          // ── Stats section ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                _StatItem(value: mileageStr, label: 'MILEAGE'),
                _StatItem(value: economyStr, label: 'ECONOMY'),
                _StatItem(value: totalSpentStr, label: 'SPENT'),
              ],
            ),
          ),

          // ── Divider ───────────────────────────────────────────────────
          const Divider(color: Color(0xFF34333F), height: 1, thickness: 1),

          // ── Actions row ───────────────────────────────────────────────
          SizedBox(
            height: 50,
            child: Row(
              children: [
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
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Log fuel',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(width: 1, color: const Color(0xFF34333F)),
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.push('/garage/vehicle/${vehicle.id}'),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_forward,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Open',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
      width: 88,
      height: 64,
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
