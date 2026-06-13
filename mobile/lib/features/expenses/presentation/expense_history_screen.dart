import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exceptions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/constants/currencies.dart';
import '../../../shared/utils/formatting.dart';
import '../../../shared/widgets/fuel_pump_icon.dart';
import '../../fuel/data/fuel_repository.dart';
import '../../fuel/presentation/fuel_log_form_screen.dart';
import '../../maintenance/data/maintenance_repository.dart';
import '../../maintenance/presentation/maintenance_form_screen.dart';
import '../../profile/data/user_repository.dart';
import '../../vehicles/domain/vehicle.dart';
import '../../vehicles/presentation/vehicles_provider.dart';
import '../data/expenses_provider.dart';
import '../domain/expense.dart';

class ExpenseHistoryScreen extends ConsumerStatefulWidget {
  const ExpenseHistoryScreen({super.key});

  @override
  ConsumerState<ExpenseHistoryScreen> createState() =>
      _ExpenseHistoryScreenState();
}

class _ExpenseHistoryScreenState extends ConsumerState<ExpenseHistoryScreen> {
  ExpenseKind? _kindFilter; // null = All
  String? _vehicleIdFilter; // null = All vehicles

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(allExpensesProvider);
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final userCurrency = ref.watch(meProvider).asData?.value.currency ?? kFallbackCurrency;

    return Scaffold(
      appBar: AppBar(title: const Text('Expenses'), centerTitle: true),
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading expenses: $e')),
        data: (expenses) {
          // Apply filters
          final filtered = expenses.where((e) {
            final kindOk = _kindFilter == null || e.kind == _kindFilter;
            final vehicleOk =
                _vehicleIdFilter == null || e.vehicleId == _vehicleIdFilter;
            return kindOk && vehicleOk;
          }).toList();

          final totalCents = filtered.fold<int>(
            0,
            (sum, e) => sum + e.costCents,
          );

          return Column(
            children: [
              // Header card: total + filter chips
              _HeaderCard(
                totalCents: totalCents,
                userCurrency: userCurrency,
                kindFilter: _kindFilter,
                vehicleIdFilter: _vehicleIdFilter,
                vehiclesAsync: vehiclesAsync,
                onKindChanged: (v) => setState(() => _kindFilter = v),
                onVehicleChanged: (v) => setState(() => _vehicleIdFilter = v),
              ),
              // List
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'No expenses yet.',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : _vehiclesAsync(
                        context,
                        vehiclesAsync,
                        filtered,
                        userCurrency,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _vehiclesAsync(
    BuildContext context,
    AsyncValue<List<Vehicle>> vehiclesAsync,
    List<Expense> filtered,
    String userCurrency,
  ) {
    return vehiclesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (vehicles) {
        final vehicleMap = {for (final v in vehicles) v.id: v};
        final groups = _groupExpensesByMonth(filtered);
        return ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            for (final group in groups) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Row(
                  children: [
                    Text(
                      DateFormat('MMMM yyyy').format(group.month),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatCents(
                        group.expenses.fold<int>(
                          0,
                          (sum, expense) => sum + expense.costCents,
                        ),
                        currency: userCurrency,
                      ),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              for (final expense in group.expenses)
                _ExpenseTile(
                  expense: expense,
                  vehicleName:
                      vehicleMap[expense.vehicleId]?.displayName ??
                      'Unknown vehicle',
                ),
            ],
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Header card
// ---------------------------------------------------------------------------

class _HeaderCard extends StatelessWidget {
  final int totalCents;
  final String userCurrency;
  final ExpenseKind? kindFilter;
  final String? vehicleIdFilter;
  final AsyncValue<List<Vehicle>> vehiclesAsync;
  final ValueChanged<ExpenseKind?> onKindChanged;
  final ValueChanged<String?> onVehicleChanged;

  const _HeaderCard({
    required this.totalCents,
    required this.userCurrency,
    required this.kindFilter,
    required this.vehicleIdFilter,
    required this.vehiclesAsync,
    required this.onKindChanged,
    required this.onVehicleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Spent',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: Colors.grey),
                ),
                Text(
                  formatCents(totalCents, currency: userCurrency),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Type filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: kindFilter == null,
                    onTap: () => onKindChanged(null),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Fuel',
                    selected: kindFilter == ExpenseKind.fuel,
                    onTap: () => onKindChanged(
                      kindFilter == ExpenseKind.fuel ? null : ExpenseKind.fuel,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Maintenance',
                    selected: kindFilter == ExpenseKind.maintenance,
                    onTap: () => onKindChanged(
                      kindFilter == ExpenseKind.maintenance
                          ? null
                          : ExpenseKind.maintenance,
                    ),
                  ),
                  // Vehicle filter
                  vehiclesAsync.maybeWhen(
                    data: (vehicles) {
                      if (vehicles.length <= 1) return const SizedBox.shrink();
                      return Row(
                        children: [
                          const SizedBox(width: 8),
                          const VerticalDivider(width: 1),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: vehicleIdFilter == null
                                ? 'All vehicles'
                                : vehicles
                                      .firstWhere(
                                        (v) => v.id == vehicleIdFilter,
                                        orElse: () => vehicles.first,
                                      )
                                      .displayName,
                            selected: vehicleIdFilter != null,
                            onTap: () {
                              // cycle through vehicles
                              if (vehicleIdFilter == null) {
                                onVehicleChanged(vehicles.first.id);
                              } else {
                                final idx = vehicles.indexWhere(
                                  (v) => v.id == vehicleIdFilter,
                                );
                                if (idx < vehicles.length - 1) {
                                  onVehicleChanged(vehicles[idx + 1].id);
                                } else {
                                  onVehicleChanged(null);
                                }
                              }
                            },
                          ),
                        ],
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Expense tile
// ---------------------------------------------------------------------------

class _ExpenseTile extends ConsumerWidget {
  final Expense expense;
  final String vehicleName;

  const _ExpenseTile({required this.expense, required this.vehicleName});

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    try {
      if (expense.kind == ExpenseKind.fuel) {
        await ref.read(fuelRepositoryProvider).deleteFuelLog(expense.id);
        ref.invalidate(fuelLogsProvider(expense.vehicleId));
      } else {
        await ref.read(maintenanceRepositoryProvider).deleteRecord(expense.id);
        ref.invalidate(maintenanceRecordsProvider(expense.vehicleId));
      }
      ref.invalidate(allExpensesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Expense deleted')));
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

  String get _subtitle {
    if (expense.kind == ExpenseKind.fuel) {
      final log = expense.fuelLog!;
      return '${expense.date} • ${log.liters.toStringAsFixed(1)} L • '
          '${log.isFullTank ? 'Full' : 'Partial'}';
    } else {
      final record = expense.maintenanceRecord!;
      return '${expense.date} • ${record.serviceType}';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Expense'),
          content: const Text('Delete this expense? This cannot be undone.'),
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
      onDismissed: (_) => _delete(context, ref),
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
              await Navigator.of(context).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => expense.kind == ExpenseKind.fuel
                      ? FuelLogFormScreen(
                          vehicleId: expense.vehicleId,
                          existing: expense.fuelLog,
                        )
                      : MaintenanceFormScreen(
                          vehicleId: expense.vehicleId,
                          existing: expense.maintenanceRecord,
                        ),
                ),
              );
              // Invalidate affected providers after returning from edit
              if (expense.kind == ExpenseKind.fuel) {
                ref.invalidate(fuelLogsProvider(expense.vehicleId));
              } else {
                ref.invalidate(maintenanceRecordsProvider(expense.vehicleId));
              }
              ref.invalidate(allExpensesProvider);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (expense.kind == ExpenseKind.fuel)
                    FuelPumpIcon(
                      isFullTank: expense.fuelLog?.isFullTank ?? false,
                      size: 24,
                    )
                  else
                    const Icon(
                      Icons.build_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicleName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    formatCents(expense.costCents, currency: expense.currency),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
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

class _ExpenseMonthGroup {
  final DateTime month;
  final List<Expense> expenses;

  const _ExpenseMonthGroup({required this.month, required this.expenses});
}

List<_ExpenseMonthGroup> _groupExpensesByMonth(List<Expense> expenses) {
  final buckets = <String, List<Expense>>{};
  final monthDates = <String, DateTime>{};

  for (final expense in expenses) {
    final date = DateTime.parse(expense.date);
    final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    buckets.putIfAbsent(monthKey, () => []).add(expense);
    monthDates[monthKey] = DateTime(date.year, date.month);
  }

  final groups = buckets.entries.map((entry) {
    final month = monthDates[entry.key]!;
    final monthExpenses = [...entry.value]
      ..sort((a, b) => b.date.compareTo(a.date));
    return _ExpenseMonthGroup(month: month, expenses: monthExpenses);
  }).toList();

  groups.sort((a, b) => b.month.compareTo(a.month));
  return groups;
}
