import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/constants/currencies.dart';
import '../../../../shared/utils/distance_unit.dart';
import '../../../../shared/widgets/activity_entry_card.dart';
import '../../../../shared/widgets/fuel_pump_icon.dart';
import '../../data/fuel_repository.dart';
import '../../domain/fuel_log.dart';
import '../../../profile/data/user_repository.dart';
import '../../../vehicles/data/vehicle_repository.dart';
import 'quick_fuel_entry_sheet.dart';

String _relativeDate(String dateStr) {
  final date = DateTime.tryParse(dateStr);
  if (date == null) return dateStr;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(date.year, date.month, date.day);
  final diff = today.difference(d).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return DateFormat('d MMM').format(date);
}

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

  Widget _buildIcon() {
    final isFull = log.isFullTank;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isFull
            ? AppColors.successBg
            : AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: FuelPumpIcon(isFullTank: isFull, size: 20, darkInk: !isFull),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider).asData?.value;
    final currency = me?.currency ?? kFallbackCurrency;
    final vehicleAsync = ref.watch(vehicleProvider(vehicleId));
    final vehicle = vehicleAsync.asData?.value;
    final unit = effectiveUnit(
      vehicleUnit: vehicle?.distanceUnit,
      userUnit: me?.distanceUnit ?? 'km',
    );
    final subLabel =
        '${log.liters.toStringAsFixed(1)} L · ${formatDistance(log.odometer, unit)} · ${log.isFullTank ? 'Full' : 'Partial'}';

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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: ActivityEntryCard(
          icon: _buildIcon(),
          title: _relativeDate(log.date),
          subLabel: subLabel,
          amountCents: log.priceCents,
          currency: currency,
          onTap: () async {
            await showQuickFuelEntrySheet(context, existing: log);
            onRefresh();
          },
        ),
      ),
    );
  }
}
