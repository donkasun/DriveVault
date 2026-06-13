import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/formatting.dart';
import '../../../../shared/widgets/fuel_pump_icon.dart';
import '../../data/fuel_repository.dart';
import '../../domain/fuel_log.dart';
import '../../../profile/data/user_repository.dart';

class FuelRecordCard extends ConsumerWidget {
  final FuelLog log;
  final String vehicleId;
  final VoidCallback onRefresh;

  const FuelRecordCard({
    super.key,
    required this.log,
    required this.vehicleId,
    required this.onRefresh,
  });

  Future<void> _deleteFuelLog(BuildContext context, WidgetRef ref) async {
    try {
      final repo = ref.read(fuelRepositoryProvider);
      await repo.deleteFuelLog(log.id);
      onRefresh();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Fuel log deleted')));
      }
    } catch (e) {
      if (context.mounted) {
        final msg = e is ApiException ? e.message : 'Delete failed';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(meProvider).asData?.value.currency ?? 'USD';

    return Dismissible(
      key: ValueKey(log.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Fuel Log'),
          content: Text(
            'Delete the fuel log for ${log.date}? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
      onDismissed: (_) => _deleteFuelLog(context, ref),
      background: Container(
        alignment: Alignment.centerRight,
        color: Colors.red,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: appCardDecoration.copyWith(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              await context.push(
                '/garage/vehicle/$vehicleId/fuel/edit',
                extra: log,
              );
              onRefresh();
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FuelPumpIcon(isFullTank: log.isFullTank, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.date,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${log.liters.toStringAsFixed(1)} L',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatCents(log.priceCents, currency: currency),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        log.isFullTank ? 'Full tank' : 'Partial',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
