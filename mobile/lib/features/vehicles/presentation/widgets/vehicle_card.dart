import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/vehicle.dart';

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;

  const VehicleCard({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final name = [vehicle.make, vehicle.model, vehicle.year?.toString()]
        .where((s) => s != null && s.isNotEmpty)
        .join(' ');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vehicle name and registration
                Padding(
                  padding: EdgeInsets.only(
                    right: vehicle.photoUrl != null ? 80 : 0,
                  ),
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
                const SizedBox(height: 16),
                // Stat row
                _StatRow(vehicle: vehicle),
                const SizedBox(height: 12),
                // Details button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () =>
                        context.push('/garage/vehicle/${vehicle.id}'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'DETAILS →',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Vehicle photo overlapping top-right edge
          if (vehicle.photoUrl != null)
            Positioned(
              top: -8,
              right: 12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: vehicle.photoUrl!,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 72,
                    height: 72,
                    color: Colors.white12,
                    child: const Icon(
                      Icons.directions_car,
                      color: Colors.white38,
                      size: 36,
                    ),
                  ),
                  errorWidget: (context, url, error) => _CarPlaceholder(),
                ),
              ),
            )
          else
            Positioned(
              top: -8,
              right: 12,
              child: _CarPlaceholder(),
            ),
        ],
      ),
    );
  }
}

class _CarPlaceholder extends StatelessWidget {
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

class _StatRow extends StatelessWidget {
  final Vehicle vehicle;

  const _StatRow({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatItem(
          label: 'Mileage',
          value: vehicle.currentMileage != null
              ? '${vehicle.currentMileage} km'
              : '—',
        ),
        const SizedBox(width: 16),
        const _StatItem(label: 'Economy', value: '—'),
        const SizedBox(width: 16),
        const _StatItem(label: 'Spent', value: '—'),
        const SizedBox(width: 16),
        const _StatItem(label: 'Docs', value: '—'),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
