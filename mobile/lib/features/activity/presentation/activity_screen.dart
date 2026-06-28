import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exceptions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/constants/currencies.dart';
import '../../../shared/utils/formatting.dart';
import '../../../shared/widgets/activity_entry_card.dart';
import '../../../shared/widgets/fuel_pump_icon.dart';
import '../../../shared/widgets/sheet_close_button.dart';
import '../../documents/data/document_repository.dart';
import '../../documents/presentation/document_viewer_screen.dart';
import '../../fuel/data/fuel_repository.dart';
import '../../fuel/presentation/widgets/quick_fuel_entry_sheet.dart';
import '../../maintenance/data/maintenance_repository.dart';
import '../../maintenance/presentation/maintenance_form_screen.dart';
import '../../profile/data/user_repository.dart';
import '../../vehicles/domain/vehicle.dart';
import '../../vehicles/presentation/vehicles_provider.dart';
import '../data/activity_provider.dart';
import '../domain/activity_entry.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  ActivityKind? _kindFilter;
  String? _vehicleIdFilter;

  void _showFilterSheet(BuildContext context) {
    final vehicles = ref.read(vehiclesProvider).asData?.value ?? [];
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ActivityFilterSheet(
        vehicles: vehicles,
        selectedVehicleId: _vehicleIdFilter,
        onVehicleChanged: (id) => setState(() => _vehicleIdFilter = id),
      ),
    );
  }

  bool get _isFiltered => _vehicleIdFilter != null || _kindFilter != null;

  @override
  Widget build(BuildContext context) {
    final activityAsync = ref.watch(allActivityProvider);
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final userCurrency =
        ref.watch(meProvider).asData?.value.currency ?? kFallbackCurrency;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(
                    child: Text(
                      'Activity',
                      style: TextStyle(
                        fontSize: 29,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: GestureDetector(
                      onTap: () => _showFilterSheet(context),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _isFiltered
                                  ? AppColors.textPrimary
                                  : Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.tune_rounded,
                              size: 22,
                              color: _isFiltered
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (_isFiltered)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: activityAsync.when(
                loading: () => const _LoadingSkeleton(),
                error: (e, st) => _ErrorState(
                  message: e is ApiException
                      ? e.message
                      : 'Could not load activity.',
                  onRetry: () => ref.invalidate(allActivityProvider),
                ),
                data: (entries) {
                  final filtered = filterActivityByVehicle(
                    filterActivityByKind(entries, _kindFilter),
                    _vehicleIdFilter,
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: _KindFilterBar(
                          value: _kindFilter,
                          onChanged: (v) => setState(() => _kindFilter = v),
                        ),
                      ),
                      Expanded(
                        child: vehiclesAsync.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, st) => Center(
                            child: Text(
                              'Could not load vehicles: $e',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          data: (vehicles) {
                            final vehicleMap = {
                              for (final v in vehicles) v.id: v,
                            };

                            if (filtered.isEmpty) {
                              return const _EmptyState();
                            }

                            final groups = groupActivityByMonth(filtered);

                            return ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                120,
                              ),
                              itemCount: groups.fold<int>(
                                0,
                                (count, g) => count + 1 + g.entries.length,
                              ),
                              itemBuilder: (context, index) {
                                int offset = 0;
                                for (final group in groups) {
                                  if (index == offset) {
                                    return _MonthHeader(
                                      month: group.month,
                                      subtotalCents: group.subtotalCents,
                                      currency: userCurrency,
                                    );
                                  }
                                  offset++;
                                  final tileIndex = index - offset;
                                  if (tileIndex < group.entries.length) {
                                    final entry = group.entries[tileIndex];
                                    return _ActivityTile(
                                      entry: entry,
                                      vehicleName:
                                          vehicleMap[entry.vehicleId]
                                              ?.displayName ??
                                          'Unknown vehicle',
                                      totalVehicles: vehicles.length,
                                    );
                                  }
                                  offset += group.entries.length;
                                }
                                return const SizedBox.shrink();
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Kind filter bar (All / Fuel / Maintenance / Documents)
// ---------------------------------------------------------------------------

class _KindFilterBar extends StatelessWidget {
  final ActivityKind? value;
  final ValueChanged<ActivityKind?> onChanged;

  const _KindFilterBar({required this.value, required this.onChanged});

  Alignment get _alignment {
    switch (value) {
      case ActivityKind.fuel:
        return const Alignment(-1 / 3, 0);
      case ActivityKind.maintenance:
        return const Alignment(1 / 3, 0);
      case ActivityKind.document:
        return Alignment.centerRight;
      case null:
        return Alignment.centerLeft;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5FA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: _alignment,
            child: FractionallySizedBox(
              widthFactor: 0.25,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _Segment(
                  label: 'All',
                  selected: value == null,
                  onTap: () => onChanged(null),
                ),
              ),
              Expanded(
                child: _Segment(
                  label: 'Fuel',
                  selected: value == ActivityKind.fuel,
                  onTap: () => onChanged(
                    value == ActivityKind.fuel ? null : ActivityKind.fuel,
                  ),
                ),
              ),
              Expanded(
                child: _Segment(
                  label: 'Service',
                  selected: value == ActivityKind.maintenance,
                  onTap: () => onChanged(
                    value == ActivityKind.maintenance
                        ? null
                        : ActivityKind.maintenance,
                  ),
                ),
              ),
              Expanded(
                child: _Segment(
                  label: 'Docs',
                  selected: value == ActivityKind.document,
                  onTap: () => onChanged(
                    value == ActivityKind.document
                        ? null
                        : ActivityKind.document,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF8A8AA3),
            ),
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter bottom sheet
// ---------------------------------------------------------------------------

class _ActivityFilterSheet extends StatelessWidget {
  final List<Vehicle> vehicles;
  final String? selectedVehicleId;
  final ValueChanged<String?> onVehicleChanged;

  const _ActivityFilterSheet({
    required this.vehicles,
    required this.selectedVehicleId,
    required this.onVehicleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 2),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filter',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  SheetCloseButton(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            if (vehicles.length > 1) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Text(
                  'VEHICLE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              _VehicleFilterRow(
                label: 'All vehicles',
                selected: selectedVehicleId == null,
                onTap: () {
                  onVehicleChanged(null);
                  Navigator.of(context).pop();
                },
              ),
              for (final v in vehicles)
                _VehicleFilterRow(
                  label: v.displayName,
                  subtitle: v.registrationNumber,
                  selected: selectedVehicleId == v.id,
                  onTap: () {
                    onVehicleChanged(v.id);
                    Navigator.of(context).pop();
                  },
                ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _VehicleFilterRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _VehicleFilterRow({
    required this.label,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.divider, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_rounded,
                size: 20,
                color: AppColors.success,
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Month header
// ---------------------------------------------------------------------------

class _MonthHeader extends StatelessWidget {
  final DateTime month;
  final int subtotalCents;
  final String currency;

  const _MonthHeader({
    required this.month,
    required this.subtotalCents,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Row(
        children: [
          Text(
            DateFormat('MMMM yyyy').format(month),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          if (subtotalCents > 0)
            Text(
              formatCents(subtotalCents, currency: currency),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Activity tile
// ---------------------------------------------------------------------------

class _ActivityTile extends ConsumerWidget {
  final ActivityEntry entry;
  final String vehicleName;
  final int totalVehicles;

  const _ActivityTile({
    required this.entry,
    required this.vehicleName,
    required this.totalVehicles,
  });

  String? get _vehicleSubLabel => totalVehicles > 1 ? vehicleName : null;

  String get _dateLine {
    final parsed = DateTime.tryParse(entry.date);
    if (parsed == null) return entry.date;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(parsed.year, parsed.month, parsed.day);
    final diff = today.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('d MMM').format(date);
  }

  String get _title {
    switch (entry.kind) {
      case ActivityKind.fuel:
        return 'Fuel';
      case ActivityKind.maintenance:
        final serviceType = entry.expense?.maintenanceRecord?.serviceType;
        return (serviceType != null && serviceType.isNotEmpty)
            ? serviceType
            : 'Service';
      case ActivityKind.document:
        return entry.document!.title;
    }
  }

  String get _subLabel {
    switch (entry.kind) {
      case ActivityKind.fuel:
        final log = entry.expense!.fuelLog!;
        return '$_dateLine · ${log.liters.toStringAsFixed(1)} L · '
            '${log.isFullTank ? 'Full' : 'Partial'}';
      case ActivityKind.maintenance:
        return _dateLine;
      case ActivityKind.document:
        final doc = entry.document!;
        final typeLabel = _docTypeLabel(doc.docType);
        return '$_dateLine · $typeLabel';
    }
  }

  String _docTypeLabel(String docType) {
    switch (docType) {
      case 'insurance':
        return 'Insurance';
      case 'registration':
        return 'Registration';
      case 'service_record':
        return 'Service record';
      case 'warranty':
        return 'Warranty';
      case 'receipt':
        return 'Receipt';
      default:
        return docType.replaceAll('_', ' ');
    }
  }

  Widget _buildIcon() {
    switch (entry.kind) {
      case ActivityKind.fuel:
        final isFull = entry.expense!.fuelLog!.isFullTank;
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
      case ActivityKind.maintenance:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(
              Icons.build_outlined,
              color: AppColors.surfaceDark,
              size: 20,
            ),
          ),
        );
      case ActivityKind.document:
        final doc = entry.document!;
        final iconData = doc.isImage
            ? Icons.image_outlined
            : doc.mimeType == 'application/pdf'
            ? Icons.picture_as_pdf_outlined
            : Icons.description_outlined;
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFEEEEF5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(iconData, color: AppColors.textMuted, size: 20),
          ),
        );
    }
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    switch (entry.kind) {
      case ActivityKind.fuel:
        await showQuickFuelEntrySheet(
          context,
          existing: entry.expense!.fuelLog,
        );
        ref.invalidate(fuelLogsProvider(entry.vehicleId));
        ref.invalidate(allActivityProvider);
      case ActivityKind.maintenance:
        await Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => MaintenanceFormScreen(
              vehicleId: entry.vehicleId,
              existing: entry.expense!.maintenanceRecord,
            ),
          ),
        );
        ref.invalidate(maintenanceRecordsProvider(entry.vehicleId));
        ref.invalidate(allActivityProvider);
      case ActivityKind.document:
        await Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => DocumentViewerScreen(document: entry.document!),
          ),
        );
    }
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    try {
      switch (entry.kind) {
        case ActivityKind.fuel:
          await ref.read(fuelRepositoryProvider).deleteFuelLog(entry.id);
          ref.invalidate(fuelLogsProvider(entry.vehicleId));
        case ActivityKind.maintenance:
          await ref.read(maintenanceRepositoryProvider).deleteRecord(entry.id);
          ref.invalidate(maintenanceRecordsProvider(entry.vehicleId));
        case ActivityKind.document:
          await ref.read(documentRepositoryProvider).deleteDocument(entry.id);
          ref.invalidate(documentsProvider(entry.vehicleId));
      }
      ref.invalidate(allActivityProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Record deleted')));
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
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Record'),
          content: const Text('Delete this record? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) => _handleDelete(context, ref),
      background: Container(
        alignment: Alignment.centerRight,
        color: AppColors.danger,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: ActivityEntryCard(
          icon: _buildIcon(),
          title: _title,
          titleSub: _vehicleSubLabel,
          subLabel: _subLabel,
          amountCents: entry.costCents,
          currency: entry.currency,
          onTap: () => _handleTap(context, ref),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Async states
// ---------------------------------------------------------------------------

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
      children: [
        const _SkeletonBox(height: 48, radius: 999),
        const SizedBox(height: 16),
        for (var i = 0; i < 8; i++) ...[
          const _SkeletonBox(height: 72, radius: 16),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double height;
  final double radius;

  const _SkeletonBox({required this.height, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.history_rounded, size: 48, color: AppColors.textMuted),
            SizedBox(height: 16),
            Text(
              'No activity yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Fuel fill-ups, service records and documents will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
