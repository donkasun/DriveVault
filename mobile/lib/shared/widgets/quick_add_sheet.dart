import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../features/fuel/presentation/widgets/quick_fuel_entry_sheet.dart';
import '../../features/maintenance/presentation/widgets/quick_maintenance_sheet.dart';
import '../../features/vehicles/presentation/vehicles_provider.dart';
import '../../features/vehicles/domain/vehicle.dart';

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

/// Opens the global quick-add bottom sheet that covers the floating tab bar.
///
/// Returns a [Future] that completes when the sheet is dismissed (useful for
/// callers that need to know when to reset their "open" guard).
Future<void> showQuickAddSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true, // cover the floating tab bar
    backgroundColor: Colors.transparent,
    builder: (_) => const QuickAddSheet(),
  );
}

// ---------------------------------------------------------------------------
// Sheet widget
// ---------------------------------------------------------------------------

class QuickAddSheet extends ConsumerWidget {
  const QuickAddSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: vehiclesAsync.when(
          loading: () => const _LoadingBody(),
          error: (e, _) => _ErrorBody(message: 'Could not load vehicles: $e'),
          data: (vehicles) => _SheetBody(vehicles: vehicles),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sheet body
// ---------------------------------------------------------------------------

class _SheetBody extends StatelessWidget {
  final List<Vehicle> vehicles;

  const _SheetBody({required this.vehicles});

  @override
  Widget build(BuildContext context) {
    final hasVehicles = vehicles.isNotEmpty;
    // Preselect the sole vehicle when there is exactly one.
    final soleVehicleId = vehicles.length == 1 ? vehicles.first.id : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Quick add',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  key: const Key('quick_add_close'),
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // ── No-vehicles hint ─────────────────────────────────────────────
          if (!hasVehicles)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Add a vehicle first to log fuel, services, or documents.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Action rows ──────────────────────────────────────────────────
          _ActionRow(
            key: const Key('quick_add_fuel'),
            icon: Icons.local_gas_station_rounded,
            label: 'Log fuel',
            description: 'Record a fill-up',
            enabled: hasVehicles,
            onTap: () => _onFuel(context, soleVehicleId),
          ),
          const SizedBox(height: 8),
          _ActionRow(
            key: const Key('quick_add_service'),
            icon: Icons.build_rounded,
            label: 'Add service',
            description: 'Log a maintenance record',
            enabled: hasVehicles,
            onTap: () => _onService(context, soleVehicleId),
          ),
          const SizedBox(height: 8),
          _ActionRow(
            key: const Key('quick_add_document'),
            icon: Icons.upload_file_rounded,
            label: 'Upload document',
            description: 'Insurance, registration, etc.',
            enabled: hasVehicles,
            onTap: () => _onDocument(context, soleVehicleId, vehicles),
          ),
          const SizedBox(height: 8),
          _ActionRow(
            key: const Key('quick_add_vehicle'),
            icon: Icons.directions_car_rounded,
            label: 'Add vehicle',
            description: 'Register a new vehicle',
            enabled: true,
            onTap: () => _onAddVehicle(context),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── Action handlers ──────────────────────────────────────────────────────

  void _onFuel(BuildContext context, String? vehicleId) {
    Navigator.of(context).pop();
    showQuickFuelEntrySheet(context, vehicleId: vehicleId);
  }

  void _onService(BuildContext context, String? vehicleId) {
    Navigator.of(context).pop();
    showQuickMaintenanceSheet(context, vehicleId: vehicleId);
  }

  void _onDocument(
    BuildContext context,
    String? vehicleId,
    List<Vehicle> vehicles,
  ) {
    Navigator.of(context).pop();

    if (vehicles.length == 1) {
      // Exactly one vehicle — push directly to the upload screen.
      context.push('/garage/vehicle/${vehicles.first.id}/documents/upload');
      return;
    }

    // Many vehicles — send the user to the Garage tab so they can pick a
    // vehicle and tap Upload from its detail screen. DocumentUploadScreen
    // requires a vehicleId and has no built-in vehicle picker, so routing
    // to Garage is the lightest approach with no duplication.
    context.go('/garage');
  }

  void _onAddVehicle(BuildContext context) {
    Navigator.of(context).pop();
    context.push('/garage/add-vehicle');
  }
}

// ---------------------------------------------------------------------------
// Action row widget
// ---------------------------------------------------------------------------

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.description,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled
        ? AppColors.textPrimary
        : AppColors.textMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.45,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                // Yellow icon badge
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.onPrimary),
                ),
                const SizedBox(width: 14),
                // Label + description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: effectiveColor,
                        ),
                      ),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: enabled
                              ? AppColors.textMuted
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Chevron
                Icon(
                  Icons.chevron_right_rounded,
                  color: enabled ? AppColors.textMuted : AppColors.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper states
// ---------------------------------------------------------------------------

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 160,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  const _ErrorBody({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, style: const TextStyle(color: AppColors.danger)),
    );
  }
}
