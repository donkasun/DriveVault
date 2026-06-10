import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../documents/data/document_repository.dart';
import '../../documents/domain/document.dart';
import '../../documents/presentation/document_upload_screen.dart';
import '../../documents/presentation/document_viewer_screen.dart';
import '../../fuel/data/fuel_repository.dart';
import '../../fuel/domain/fuel_log.dart';
import '../../fuel/domain/fuel_stats.dart';
import '../../fuel/presentation/fuel_log_form_screen.dart';
import '../../maintenance/data/maintenance_repository.dart';
import '../../maintenance/domain/maintenance_record.dart';
import '../../maintenance/presentation/maintenance_form_screen.dart';
import '../data/vehicle_repository.dart';
import '../domain/vehicle.dart';

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

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text(
            'Delete "${vehicle.make} ${vehicle.model}"? All data will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final repo = ref.read(vehicleRepositoryProvider);
      await repo.deleteVehicle(vehicle.id);
      if (context.mounted) context.go('/garage');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _openEditVehicle(BuildContext context, WidgetRef ref) {
    // Edit vehicle modal — placeholder for now; full vehicle form
    // is a separate task. Show a snackbar indicating intent.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit vehicle — coming soon')),
    );
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
              _FuelSection(vehicleId: vehicle.id),
              _MaintenanceSection(vehicleId: vehicle.id),
              _DocumentsSection(vehicleId: vehicle.id),
              const SizedBox(height: 100),
            ]),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero App Bar with stat overlay
// ---------------------------------------------------------------------------

class _HeroAppBar extends ConsumerWidget {
  final Vehicle vehicle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HeroAppBar({
    required this.vehicle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fuelStatsAsync = ref.watch(fuelStatsProvider(vehicle.id));

    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: AppTheme.darkBg,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.go('/garage'),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.white),
          onPressed: onEdit,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.white),
          onPressed: onDelete,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Photo or dark background
            if (vehicle.photoUrl != null)
              CachedNetworkImage(
                imageUrl: vehicle.photoUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, url, err) =>
                    Container(color: AppTheme.darkCardBg),
              )
            else
              Container(color: AppTheme.darkCardBg),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withAlpha(200),
                  ],
                ),
              ),
            ),
            // Vehicle name + stats row
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${vehicle.year ?? ''} ${vehicle.make} ${vehicle.model}'
                        .trim(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (vehicle.registrationNumber != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      vehicle.registrationNumber!,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 12),
                  fuelStatsAsync.when(
                    loading: () => const _StatRow(
                      mileage: '—',
                      economy: '—',
                      spent: '—',
                      docs: '—',
                    ),
                    error: (e, st) => const _StatRow(
                      mileage: '—',
                      economy: '—',
                      spent: '—',
                      docs: '—',
                    ),
                    data: (stats) {
                      final mileage = vehicle.currentMileage != null
                          ? '${vehicle.currentMileage} km'
                          : '—';
                      final economy = stats.avgConsumptionLPer100Km != null
                          ? '${stats.avgConsumptionLPer100Km!.toStringAsFixed(1)} L/100'
                          : '—';
                      final spent = stats.totalSpentCents > 0
                          ? '\$${(stats.totalSpentCents / 100).toStringAsFixed(0)}'
                          : '\$0';
                      return _StatRow(
                        mileage: mileage,
                        economy: economy,
                        spent: spent,
                        docs: '—',
                      );
                    },
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

class _StatRow extends StatelessWidget {
  final String mileage;
  final String economy;
  final String spent;
  final String docs;

  const _StatRow({
    required this.mileage,
    required this.economy,
    required this.spent,
    required this.docs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(label: 'Mileage', value: mileage),
        const SizedBox(width: 8),
        _StatChip(label: 'Economy', value: economy),
        const SizedBox(width: 8),
        _StatChip(label: 'Spent', value: spent),
        const SizedBox(width: 8),
        _StatChip(label: 'Docs', value: docs),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 10)),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  final String buttonLabel;
  final VoidCallback onAdd;

  const _SectionHeader({
    required this.title,
    required this.buttonLabel,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const Spacer(),
          TextButton.icon(
            icon: const Text('＋', style: TextStyle(fontSize: 16)),
            label: Text(buttonLabel),
            style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryGreen),
            onPressed: onAdd,
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

  const _FuelSection({required this.vehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(fuelLogsProvider(vehicleId));
    final statsAsync = ref.watch(fuelStatsProvider(vehicleId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Fuel',
          buttonLabel: 'Add Fuel',
          onAdd: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => FuelLogFormScreen(vehicleId: vehicleId),
              ),
            );
          },
        ),
        // Stats card
        statsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(),
          ),
          error: (e, st) => const SizedBox.shrink(),
          data: (stats) => _FuelStatsCard(stats: stats),
        ),
        // Logs list
        logsAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error: $e'),
          ),
          data: (logs) {
            if (logs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No fuel logs yet.',
                    style: TextStyle(color: Colors.grey)),
              );
            }
            final sorted = [...logs]
              ..sort((a, b) => b.date.compareTo(a.date));
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sorted.length,
              itemBuilder: (_, i) => _FuelLogTile(
                log: sorted[i],
                vehicleId: vehicleId,
                onRefresh: () {
                  ref.invalidate(fuelLogsProvider(vehicleId));
                  ref.invalidate(fuelStatsProvider(vehicleId));
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _FuelStatsCard extends StatelessWidget {
  final FuelStats stats;

  const _FuelStatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              label: 'Avg L/100km',
              value: stats.avgConsumptionLPer100Km != null
                  ? stats.avgConsumptionLPer100Km!.toStringAsFixed(1)
                  : '—',
            ),
            _StatItem(
              label: 'Cost/km',
              value: stats.avgCostPerKmCents != null
                  ? '\$${(stats.avgCostPerKmCents! / 100).toStringAsFixed(2)}'
                  : '—',
            ),
            _StatItem(
              label: 'Total Spent',
              value:
                  '\$${(stats.totalSpentCents / 100).toStringAsFixed(2)}',
            ),
          ],
        ),
      ),
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
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

class _FuelLogTile extends ConsumerWidget {
  final FuelLog log;
  final String vehicleId;
  final VoidCallback onRefresh;

  const _FuelLogTile({
    required this.log,
    required this.vehicleId,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.local_gas_station),
      title: Text(log.date),
      subtitle: Text(
        '${log.liters.toStringAsFixed(1)} L • '
        '\$${(log.priceCents / 100).toStringAsFixed(2)}',
      ),
      trailing: log.isFullTank
          ? const Chip(
              label: Text('Full',
                  style: TextStyle(fontSize: 11)),
              padding: EdgeInsets.zero,
            )
          : null,
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => FuelLogFormScreen(
              vehicleId: vehicleId,
              existing: log,
            ),
          ),
        );
        onRefresh();
      },
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
          buttonLabel: 'Add Service',
          onAdd: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) =>
                    MaintenanceFormScreen(vehicleId: vehicleId),
              ),
            );
          },
        ),
        recordsAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error: $e'),
          ),
          data: (records) {
            if (records.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No maintenance records yet.',
                    style: TextStyle(color: Colors.grey)),
              );
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
    return ListTile(
      leading: const Icon(Icons.build_outlined),
      title: Text(record.serviceType),
      subtitle: Text(
        '${record.date}'
        '${record.workshop != null ? ' • ${record.workshop}' : ''}'
        '${record.costCents != null ? ' • \$${(record.costCents! / 100).toStringAsFixed(2)}' : ''}',
      ),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => MaintenanceFormScreen(
              vehicleId: vehicleId,
              existing: record,
            ),
          ),
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

  const _DocumentsSection({required this.vehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedAsync = ref.watch(groupedDocumentsProvider(vehicleId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Documents',
          buttonLabel: 'Upload',
          onAdd: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) =>
                    DocumentUploadScreen(vehicleId: vehicleId),
              ),
            );
          },
        ),
        groupedAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error: $e'),
          ),
          data: (grouped) {
            if (grouped.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No documents yet.',
                    style: TextStyle(color: Colors.grey)),
              );
            }
            return Column(
              children: grouped.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        entry.key.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    ...entry.value.map((doc) => _DocumentTile(doc: doc)),
                  ],
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _DocumentTile extends ConsumerWidget {
  final Document doc;

  const _DocumentTile({required this.doc});

  Color _expiryColor() {
    final days = doc.daysUntilExpiry();
    if (days == null) return Colors.grey;
    if (days < 0) return Colors.red;
    if (days <= 30) return Colors.red;
    if (days <= 60) return Colors.amber;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = doc.daysUntilExpiry();

    return ListTile(
      leading: const Icon(Icons.insert_drive_file_outlined),
      title: Text(doc.title),
      subtitle: Text(doc.docType),
      trailing: days != null
          ? Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _expiryColor().withAlpha(30),
                border: Border.all(color: _expiryColor()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                days < 0
                    ? 'Expired'
                    : days == 0
                        ? 'Today'
                        : '${days}d',
                style: TextStyle(
                    color: _expiryColor(),
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            )
          : null,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DocumentViewerScreen(document: doc),
          ),
        );
      },
    );
  }
}
