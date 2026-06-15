import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/distance_unit.dart';
import '../../../shared/utils/formatting.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../dashboard/domain/dashboard_data.dart';
import '../../dashboard/presentation/dashboard_provider.dart';
import '../../documents/data/document_repository.dart';
import '../../documents/domain/document.dart';
import '../../documents/presentation/document_viewer_screen.dart';
import '../../fuel/data/fuel_repository.dart';
import '../../fuel/domain/fuel_stats.dart';
import '../../fuel/presentation/widgets/fuel_record_card.dart';
import '../../fuel/presentation/widgets/quick_fuel_entry_sheet.dart';
import '../../maintenance/data/maintenance_repository.dart';
import '../../maintenance/domain/maintenance_record.dart';
import '../../profile/data/user_repository.dart';
import '../data/vehicle_repository.dart';
import '../domain/vehicle.dart';
import '../presentation/vehicles_provider.dart';

class VehicleDetailScreen extends ConsumerWidget {
  final String vehicleId;

  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleAsync = ref.watch(vehicleProvider(vehicleId));

    return vehicleAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Failed to load vehicle: $e')),
      ),
      data: (vehicle) => _VehicleDetailBody(vehicle: vehicle),
    );
  }
}

class _VehicleDetailBody extends ConsumerWidget {
  final Vehicle vehicle;

  const _VehicleDetailBody({required this.vehicle});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Delete "${vehicle.make} ${vehicle.model}"?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'All fuel logs, maintenance records, and documents for this vehicle will be permanently deleted.',
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(ctx, rootNavigator: true).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: const Text('Delete Vehicle'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    Navigator.of(ctx, rootNavigator: true).pop(false),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirm != true) return;

    try {
      await ref.read(vehiclesProvider.notifier).deleteVehicle(vehicle.id);
      if (context.mounted) context.go('/garage');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _openEditVehicle(BuildContext context, WidgetRef ref) async {
    await context.push(
      '/garage/edit-vehicle/${vehicle.id}',
      extra: {'vehicle': vehicle},
    );
    ref.invalidate(vehicleProvider(vehicle.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _HeroAppBar(
            vehicle: vehicle,
            onEdit: () => _openEditVehicle(context, ref),
            onDelete: () => _confirmDelete(context, ref),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _StatsCard(vehicle: vehicle),
              _FuelSection(
                vehicleId: vehicle.id,
                vehicleDistanceUnit: vehicle.distanceUnit,
              ),
              _MaintenanceSection(vehicleId: vehicle.id),
              _DocumentsSection(vehicleId: vehicle.id, docsStatus: vehicle.docsStatus),
              const SizedBox(height: 120),
            ]),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero photo area — clean, no overlaid text
// ---------------------------------------------------------------------------

class _HeroAppBar extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HeroAppBar({
    required this.vehicle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: AppColors.surfaceDark,
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Center(
          child: _CircleNavButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => context.go('/garage'),
          ),
        ),
      ),
      actions: [
        _CircleNavButton(icon: Icons.edit_outlined, onTap: onEdit),
        const SizedBox(width: 8),
        _CircleNavButton(icon: Icons.delete_outline, onTap: onDelete),
        const SizedBox(width: 12),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (vehicle.photoUrl != null)
              CachedNetworkImage(
                imageUrl: vehicle.photoUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, url, err) =>
                    Container(color: AppColors.surfaceDark),
              )
            else
              Container(color: AppColors.surfaceDark),
            // Top gradient for button readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [
                    Colors.black.withAlpha(100),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Bottom gradient so name/meta text is readable over photo
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                  colors: [
                    Colors.black.withAlpha(180),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Photo placeholder icon (no photo case)
            if (vehicle.photoUrl == null)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.directions_car_rounded,
                      color: Colors.white.withAlpha(50),
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'VEHICLE PHOTO',
                      style: TextStyle(
                        color: Colors.white.withAlpha(50),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            // Vehicle name + meta overlaid at the bottom
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _VehicleHeroInfo(vehicle: vehicle),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Vehicle name + metadata overlaid at the bottom of the hero image
// ---------------------------------------------------------------------------

class _VehicleHeroInfo extends StatelessWidget {
  final Vehicle vehicle;
  const _VehicleHeroInfo({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final reg = vehicle.registrationNumber;
    final year = vehicle.year;
    final rawFuel = vehicle.fuelType;
    final fuelLabel = rawFuel != null
        ? rawFuel[0].toUpperCase() + rawFuel.substring(1)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${vehicle.make} ${vehicle.model}',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.4,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            if (year != null)
              Text(
                '$year',
                style: TextStyle(
                  color: Colors.white.withAlpha(200),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (year != null && fuelLabel != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Text(
                  '·',
                  style: TextStyle(
                    color: Colors.white.withAlpha(150),
                    fontSize: 13,
                  ),
                ),
              ),
            if (fuelLabel != null)
              Text(
                fuelLabel,
                style: TextStyle(
                  color: Colors.white.withAlpha(200),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (reg != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(45),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  reg,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 4-column stats card (mileage / economy / spent / docs)
// ---------------------------------------------------------------------------

class _StatsCard extends ConsumerWidget {
  final Vehicle vehicle;

  const _StatsCard({required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fuelStatsAsync = ref.watch(fuelStatsProvider(vehicle.id));
    final me = ref.watch(meProvider).asData?.value;
    final currency = me?.currency ?? 'USD';
    final unit = effectiveUnit(
      vehicleUnit: vehicle.distanceUnit,
      userUnit: me?.distanceUnit ?? 'km',
    );

    final mileage = vehicle.currentMileage != null
        ? formatDistance(vehicle.currentMileage!, unit)
        : '—';

    final stats = fuelStatsAsync.asData?.value;
    final economy = formatEconomyFromStats(
      stats?.avgConsumptionLPer100Km,
      unit,
    );
    final spent = formatCents(stats?.totalSpentCents ?? 0, currency: currency);

    // Split "78,855 km" → number="78,855", suffix="km"
    (String, String?) splitSuffix(String v) {
      if (v == '—') return ('—', null);
      final i = v.lastIndexOf(' ');
      return i == -1 ? (v, null) : (v.substring(0, i), v.substring(i + 1));
    }

    // Split "Rs 19,393" → prefix="Rs", number="19,393"
    (String?, String) splitPrefix(String v) {
      final i = v.indexOf(' ');
      return i == -1 ? (null, v) : (v.substring(0, i), v.substring(i + 1));
    }

    final (mileageNum, mileageUnit) = splitSuffix(mileage);
    final (economyNum, economyUnit) = splitSuffix(economy);
    final (spentPrefix, spentNum) = splitPrefix(spent);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: appCardDecoration,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatCol(number: mileageNum, unitSuffix: mileageUnit, label: 'MILEAGE'),
            _VDivider(),
            _StatCol(number: economyNum, unitSuffix: economyUnit, label: 'ECONOMY'),
            _VDivider(),
            _StatCol(number: spentNum, unitPrefix: spentPrefix, label: 'SPENT'),
            _VDivider(),
            _DocsStatCol(docsStatus: vehicle.docsStatus),
          ],
        ),
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String number;
  final String? unitPrefix;
  final String? unitSuffix;
  final String label;

  const _StatCol({
    required this.number,
    required this.label,
    this.unitPrefix,
    this.unitSuffix,
  });

  static const _unitStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  static const _numberStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  if (unitPrefix != null)
                    TextSpan(text: '$unitPrefix ', style: _unitStyle),
                  TextSpan(text: number, style: _numberStyle),
                  if (unitSuffix != null)
                    TextSpan(text: ' $unitSuffix', style: _unitStyle),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocsStatCol extends StatelessWidget {
  final DocsStatus docsStatus;

  const _DocsStatCol({required this.docsStatus});

  @override
  Widget build(BuildContext context) {
    final isOk = docsStatus.state == 'valid';
    final icon = isOk ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded;
    final color = isOk ? AppColors.success : AppColors.danger;
    final label = isOk ? 'Done' : '${docsStatus.needsActionCount}';

    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            const Text(
              'DOCS',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VDivider extends StatelessWidget {
  const _VDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(width: 1, color: AppColors.divider),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header with dark pill button and optional item count
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final String buttonLabel;
  final VoidCallback onAdd;

  const _SectionHeader({
    required this.title,
    this.count,
    required this.buttonLabel,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 6),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w400,
                color: AppColors.textMuted,
              ),
            ),
          ],
          const Spacer(),
          TextButton(
            onPressed: onAdd,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.onPrimary,
              foregroundColor: AppColors.primary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            child: Text('+ $buttonLabel'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fuel Section
// ---------------------------------------------------------------------------

class _FuelSection extends ConsumerWidget {
  final String vehicleId;
  final String? vehicleDistanceUnit;

  const _FuelSection({
    required this.vehicleId,
    this.vehicleDistanceUnit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(fuelLogsProvider(vehicleId));
    final statsAsync = ref.watch(fuelStatsProvider(vehicleId));
    final me = ref.watch(meProvider).asData?.value;
    final currency = me?.currency ?? 'USD';
    final unit = effectiveUnit(
      vehicleUnit: vehicleDistanceUnit,
      userUnit: me?.distanceUnit ?? 'km',
    );

    void refresh() {
      ref.invalidate(fuelLogsProvider(vehicleId));
      ref.invalidate(fuelStatsProvider(vehicleId));
      ref.invalidate(vehicleProvider(vehicleId));
      ref.invalidate(vehiclesProvider);
      ref.invalidate(dashboardProvider);
    }

    final logCount = logsAsync.asData?.value.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Fuel',
          count: logCount,
          buttonLabel: 'Add fuel',
          onAdd: () async {
            await showQuickFuelEntrySheet(context, vehicleId: vehicleId);
          },
        ),
        // Stats card
        statsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(),
          ),
          error: (e, st) => const SizedBox.shrink(),
          data: (stats) => _FuelStatsCard(
            stats: stats,
            currency: currency,
            unit: unit,
          ),
        ),
        // Logs list
        logsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error: $e'),
          ),
          data: (logs) {
            if (logs.isEmpty) {
              return _EmptyCard(label: 'No fuel logs yet.');
            }
            final sorted = [...logs]..sort((a, b) => b.date.compareTo(a.date));
            final recent = sorted.take(3).toList();
            return Column(
              children: [
                for (final log in recent)
                  FuelRecordCard(
                    log: log,
                    vehicleId: vehicleId,
                    onRefresh: refresh,
                  ),
                if (sorted.length > recent.length)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => context.push(
                          '/garage/vehicle/$vehicleId/fuel-records',
                        ),
                        child: const Text('View more'),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _FuelStatsCard extends StatelessWidget {
  final FuelStats stats;
  final String currency;
  final DistanceUnit unit;

  const _FuelStatsCard({
    required this.stats,
    required this.currency,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final economyLabel =
        unit == DistanceUnit.km ? 'KM / L' : 'MPG';
    final costLabel =
        unit == DistanceUnit.km ? 'COST / KM' : 'COST / MI';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: appCardDecoration,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _FuelStatItem(
              label: economyLabel,
              value: formatEconomyFromStats(stats.avgConsumptionLPer100Km, unit),
            ),
            _FuelStatItem(
              label: costLabel,
              value: stats.avgCostPerKmCents != null
                  ? formatCents(stats.avgCostPerKmCents!, currency: currency)
                  : '—',
            ),
            _FuelStatItem(
              label: 'TOTAL FUEL',
              value: formatCents(stats.totalSpentCents, currency: currency),
            ),
          ],
        ),
      ),
    );
  }
}

class _FuelStatItem extends StatelessWidget {
  final String label;
  final String value;

  const _FuelStatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Maintenance Section
// ---------------------------------------------------------------------------

class _MaintenanceSection extends ConsumerWidget {
  final String vehicleId;

  const _MaintenanceSection({required this.vehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(maintenanceRecordsProvider(vehicleId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Maintenance',
          buttonLabel: 'Add service',
          onAdd: () async {
            await context.push('/garage/vehicle/$vehicleId/maintenance/add');
          },
        ),
        recordsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error: $e'),
          ),
          data: (records) {
            if (records.isEmpty) {
              return _EmptyCard(label: 'No maintenance records yet.');
            }
            final sorted = [...records]
              ..sort((a, b) => b.date.compareTo(a.date));
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sorted.length,
              itemBuilder: (_, i) => _MaintenanceTile(
                record: sorted[i],
                vehicleId: vehicleId,
                onRefresh: () =>
                    ref.invalidate(maintenanceRecordsProvider(vehicleId)),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MaintenanceTile extends ConsumerWidget {
  final MaintenanceRecord record;
  final String vehicleId;
  final VoidCallback onRefresh;

  const _MaintenanceTile({
    required this.record,
    required this.vehicleId,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(meProvider).asData?.value.currency ?? 'USD';
    return ListTile(
      leading: const Icon(Icons.build_outlined),
      title: Text(record.serviceType),
      subtitle: Text(
        '${record.date}'
        '${record.workshop != null ? ' • ${record.workshop}' : ''}'
        '${record.costCents != null ? ' • ${formatCents(record.costCents!, currency: currency)}' : ''}',
      ),
      onTap: () async {
        await context.push(
          '/garage/vehicle/$vehicleId/maintenance/edit',
          extra: record,
        );
        onRefresh();
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Documents Section
// ---------------------------------------------------------------------------

class _DocumentsSection extends ConsumerWidget {
  final String vehicleId;
  final DocsStatus docsStatus;

  const _DocumentsSection({required this.vehicleId, required this.docsStatus});

  /// Sort: overdue first, then soon (fewest days first), then ok, then no expiry.
  List<Document> _sorted(List<Document> docs) {
    return [...docs]..sort((a, b) {
        final da = a.daysUntilExpiry();
        final db = b.daysUntilExpiry();
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(documentsProvider(vehicleId));
    final docCount = docsAsync.asData?.value.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Documents',
          count: docCount,
          buttonLabel: 'Upload',
          onAdd: () async {
            await context.push('/garage/vehicle/$vehicleId/documents/upload');
          },
        ),
        _DocsStatusBanner(docsStatus: docsStatus),
        docsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error: $e'),
          ),
          data: (docs) {
            if (docs.isEmpty) {
              return _EmptyCard(label: 'No documents yet.');
            }
            return Column(
              children: _sorted(docs).map((doc) => _DocumentCard(
                doc: doc,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DocumentViewerScreen(document: doc),
                  ),
                ),
              )).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _DocsStatusBanner extends StatelessWidget {
  final DocsStatus docsStatus;

  const _DocsStatusBanner({required this.docsStatus});

  @override
  Widget build(BuildContext context) {
    final (icon, label, iconColor, bgColor) = switch (docsStatus.state) {
      'valid' => (
        Icons.check_circle_outline_rounded,
        'All Good',
        AppColors.success,
        AppColors.successBg,
      ),
      'needs_action' => (
        Icons.warning_amber_rounded,
        '${docsStatus.needsActionCount} ${docsStatus.needsActionCount == 1 ? 'doc' : 'docs'} need attention',
        const Color(0xFFB45309),
        const Color(0xFFFCF1DC),
      ),
      _ => (
        Icons.info_outline_rounded,
        'No documents',
        AppColors.textMuted,
        AppColors.divider,
      ),
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final Document doc;
  final VoidCallback onTap;

  const _DocumentCard({required this.doc, required this.onTap});

  /// Doc-type → (icon, bgColor, iconColor)
  (IconData, Color, Color) get _iconStyle {
    return switch (doc.docType.toLowerCase()) {
      'insurance' => (
        Icons.shield_outlined,
        const Color(0xFFFCF1DC),
        const Color(0xFFB45309),
      ),
      'revenue_license' => (
        Icons.receipt_long_outlined,
        const Color(0xFFFCEBEB),
        const Color(0xFFDC2626),
      ),
      'emission_test' => (
        Icons.science_outlined,
        const Color(0xFFE8F1FD),
        const Color(0xFF2563EB),
      ),
      _ => (
        Icons.description_outlined,
        AppColors.divider,
        AppColors.textMuted,
      ),
    };
  }

  String get _expirySubLabel {
    if (doc.expiryDate == null) return 'No expiry date';
    final expiry = DateTime.tryParse(doc.expiryDate!);
    if (expiry == null) return 'No expiry date';
    return 'Expires ${DateFormat('d MMM').format(expiry)}';
  }

  StatusPill? _statusPill() {
    final days = doc.daysUntilExpiry();
    if (days == null) return null;
    if (days < 0) {
      return StatusPill.fromRenewalStatus(
        RenewalStatus.overdue,
        daysRemaining: days.abs(),
      );
    }
    if (days <= 30) {
      return StatusPill.fromRenewalStatus(
        RenewalStatus.soon,
        daysRemaining: days,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final (icon, bg, fg) = _iconStyle;
    final pill = _statusPill();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: appCardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: fg, size: 20),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _expirySubLabel,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (pill != null) ...[
                  const SizedBox(width: 8),
                  pill,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Generic empty-state card (white rounded card, centered muted text)
// ---------------------------------------------------------------------------

class _EmptyCard extends StatelessWidget {
  final String label;

  const _EmptyCard({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: appCardDecoration,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Circular nav button used in the hero app bar
// ---------------------------------------------------------------------------

class _CircleNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleNavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(220),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
      ),
    );
  }
}
