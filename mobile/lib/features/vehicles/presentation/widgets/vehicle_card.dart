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
/// v2 redesign (Phase 4):
/// - Photo is a **contained banner** at the top of the card (no floating overhang).
/// - Three stats: mileage · economy (km/L or mpg via [formatEconomyFromStats]) · total spent.
/// - Docs status replaced the dead "Docs 0" stat — shows [StatusPill.fromDocsStatus].
/// - Two actions: "Log Fuel" quick-action + a clear "Open" affordance.
/// - Tap anywhere on the card body navigates to the vehicle detail.
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

    return GestureDetector(
      onTap: () => context.push('/garage/vehicle/${vehicle.id}'),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Contained photo banner ────────────────────────────────────
            _PhotoBanner(photoUrl: vehicle.photoUrl),

            // ── Card body ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Name + docs pill row ──────────────────────────────
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
                              const SizedBox(height: 3),
                              Text(
                                vehicle.registrationNumber!,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Docs status replaces the dead "Docs 0" chip
                      StatusPill.fromDocsStatus(vehicle.docsStatus),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Stats row ─────────────────────────────────────────
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
                        icon: Icons.receipt_long,
                        value: totalSpentStr,
                        label: 'Total spent',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Divider ───────────────────────────────────────────
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 12),

                  // ── Actions: Log Fuel + Open ──────────────────────────
                  Row(
                    children: [
                      // "Log Fuel" quick action
                      _ActionButton(
                        icon: Icons.local_gas_station,
                        label: 'Log Fuel',
                        onTap: () => showQuickFuelEntrySheet(
                          context,
                          vehicleId: vehicle.id,
                        ),
                      ),
                      const Spacer(),
                      // "Open" affordance → detail
                      GestureDetector(
                        onTap: () =>
                            context.push('/garage/vehicle/${vehicle.id}'),
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
                              Icons.chevron_right,
                              color: Colors.white.withValues(alpha: 0.5),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private widgets ──────────────────────────────────────────────────────────

/// Contained photo banner — sits flush inside the card, no overhang.
class _PhotoBanner extends StatelessWidget {
  final String? photoUrl;

  const _PhotoBanner({this.photoUrl});

  @override
  Widget build(BuildContext context) {
    if (photoUrl == null) {
      return Container(
        height: 100,
        color: Colors.white.withValues(alpha: 0.05),
        child: const Center(
          child: Icon(Icons.directions_car, color: Colors.white24, size: 40),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: photoUrl!,
      height: 100,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (_, _) => Container(
        height: 100,
        color: Colors.white.withValues(alpha: 0.05),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white24,
            ),
          ),
        ),
      ),
      errorWidget: (_, _, _) => Container(
        height: 100,
        color: Colors.white.withValues(alpha: 0.05),
        child: const Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: Colors.white24,
            size: 32,
          ),
        ),
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
          Icon(icon, color: AppColors.primary, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            // softWrap: false avoids truncation; money never clips
            overflow: TextOverflow.visible,
            softWrap: false,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
