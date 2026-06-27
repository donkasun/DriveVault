import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exceptions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/constants/currencies.dart';
import '../../../shared/utils/formatting.dart';
import '../../../shared/widgets/activity_entry_card.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/breakdown_bar.dart';
import '../../../shared/widgets/fuel_pump_icon.dart';
import '../../../shared/widgets/sheet_close_button.dart';
import '../../fuel/data/fuel_repository.dart';
import '../../fuel/presentation/widgets/quick_fuel_entry_sheet.dart';
import '../../maintenance/data/maintenance_repository.dart';
import '../../maintenance/presentation/maintenance_form_screen.dart';
import '../../profile/data/user_repository.dart';
import '../../vehicles/domain/vehicle.dart';
import '../../vehicles/presentation/vehicles_provider.dart';
import '../data/expenses_provider.dart';
import '../domain/expense.dart';
import '../domain/expense_filters.dart';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ExpenseHistoryScreen extends ConsumerStatefulWidget {
  const ExpenseHistoryScreen({super.key});

  @override
  ConsumerState<ExpenseHistoryScreen> createState() =>
      _ExpenseHistoryScreenState();
}

class _ExpenseHistoryScreenState extends ConsumerState<ExpenseHistoryScreen> {
  ExpenseKind? _kindFilter; // null = All
  String? _vehicleIdFilter; // null = All vehicles
  _SummaryRange _summaryRange = _SummaryRange.allTime;

  void _showFilterSheet(BuildContext context) {
    final vehicles = ref.read(vehiclesProvider).asData?.value ?? [];
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExpenseFilterSheet(
        vehicles: vehicles,
        selectedVehicleId: _vehicleIdFilter,
        onVehicleChanged: (id) => setState(() => _vehicleIdFilter = id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(allExpensesProvider);
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final userCurrency =
        ref.watch(meProvider).asData?.value.currency ?? kFallbackCurrency;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---- Title row with All-time / Month toggle ----
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(
                    child: Text(
                      'Expenses',
                      style: TextStyle(
                        fontSize: 29,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if ((vehiclesAsync.asData?.value.length ?? 0) > 1)
                  GestureDetector(
                    key: const Key('expense-filter-button'),
                    onTap: () => _showFilterSheet(context),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _vehicleIdFilter != null
                                ? AppColors.textPrimary
                                : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            size: 22,
                            color: _vehicleIdFilter != null
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        if (_vehicleIdFilter != null)
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
                ],
              ),
            ),

            // ---- Body ----
            Expanded(
              child: expensesAsync.when(
                loading: () => const _LoadingSkeleton(),
                error: (e, _) => _ErrorState(
                  message: e is ApiException
                      ? e.message
                      : 'Could not load expenses.',
                  onRetry: () => ref.invalidate(allExpensesProvider),
                ),
                data: (expenses) {
                  // Apply kind + vehicle filters (client-side, no new network call).
                  final filtered = filterByVehicle(
                    filterByKind(expenses, _kindFilter),
                    _vehicleIdFilter,
                  );

                  // Summary card uses the time-scoped subset.
                  final summaryExpenses = _summaryRange == _SummaryRange.month
                      ? filterToCurrentMonth(filtered)
                      : filtered;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ---- Summary card ----
                      _SummaryCard(
                        expenses: summaryExpenses,
                        userCurrency: userCurrency,
                        kindFilter: _kindFilter,
                        summaryRange: _summaryRange,
                        onSummaryRangeChanged: (v) =>
                            setState(() => _summaryRange = v),
                      ),

                      // ---- Kind filter bar ----
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: _KindFilterBar(
                          value: _kindFilter,
                          onChanged: (v) => setState(() => _kindFilter = v),
                        ),
                      ),

                      // ---- List ----
                      Expanded(
                        child: vehiclesAsync.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(
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

                            // Use time-scoped list for the list as well when
                            // Month filter is active — so empty-state is per-filter.
                            final listExpenses =
                                _summaryRange == _SummaryRange.month
                                ? filterToCurrentMonth(filtered)
                                : filtered;

                            if (listExpenses.isEmpty) {
                              return _EmptyState(
                                isMonthFilter:
                                    _summaryRange == _SummaryRange.month,
                                onLogFillUp: () async {
                                  await showQuickFuelEntrySheet(context);
                                  ref.invalidate(allExpensesProvider);
                                },
                              );
                            }

                            final groups = groupExpensesByMonth(listExpenses);

                            return ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                              itemCount: groups.fold<int>(
                                0,
                                (count, g) => count + 1 + g.expenses.length,
                              ),
                              itemBuilder: (context, index) {
                                // Flatten groups into (header | tile) items.
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
                                  if (tileIndex < group.expenses.length) {
                                    final expense = group.expenses[tileIndex];
                                    return _ExpenseTile(
                                      expense: expense,
                                      vehicleName:
                                          vehicleMap[expense.vehicleId]
                                              ?.displayName ??
                                          'Unknown vehicle',
                                      totalVehicles: vehicles.length,
                                    );
                                  }
                                  offset += group.expenses.length;
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
// Time range enum
// ---------------------------------------------------------------------------

enum _SummaryRange { allTime, month }

// ---------------------------------------------------------------------------
// Summary card (total + BreakdownBar)
// ---------------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  final List<Expense> expenses;
  final String userCurrency;
  final ExpenseKind? kindFilter;
  final _SummaryRange summaryRange;
  final ValueChanged<_SummaryRange> onSummaryRangeChanged;

  const _SummaryCard({
    required this.expenses,
    required this.userCurrency,
    required this.kindFilter,
    required this.summaryRange,
    required this.onSummaryRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final total = totalCents(expenses);
    final fuel = fuelCents(expenses);
    final maintenance = maintenanceCents(expenses);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: DecoratedBox(
        decoration: appCardDecoration,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(
                    child: Text(
                      'TOTAL SPENT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  _SummaryRangeToggle(
                    value: summaryRange,
                    onChanged: onSummaryRangeChanged,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                formatCents(total, currency: userCurrency),
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.05,
                ),
              ),
              if (kindFilter == null) ...[
                const SizedBox(height: 14),
                BreakdownBarWithLegend(
                  segments: [
                    BreakdownSegment(
                      label: 'Fuel',
                      valueCents: fuel,
                      color: AppColors.primary,
                    ),
                    BreakdownSegment(
                      label: 'Maintenance',
                      valueCents: maintenance,
                      color: AppColors.surfaceDark,
                    ),
                  ],
                  formatAmount: (c) => formatCents(c, currency: userCurrency),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// All-time / Month toggle (compact pill)
// ---------------------------------------------------------------------------

class _SummaryRangeToggle extends StatelessWidget {
  final _SummaryRange value;
  final ValueChanged<_SummaryRange> onChanged;

  const _SummaryRangeToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5FA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: value == _SummaryRange.month
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
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
                child: _RangeSegment(
                  label: 'All time',
                  selected: value == _SummaryRange.allTime,
                  onTap: () => onChanged(_SummaryRange.allTime),
                ),
              ),
              Expanded(
                child: _RangeSegment(
                  label: 'Month',
                  selected: value == _SummaryRange.month,
                  onTap: () => onChanged(_SummaryRange.month),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RangeSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RangeSegment({
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
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.textMuted,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Kind filter bar (All / Fuel / Maintenance)
// ---------------------------------------------------------------------------

class _KindFilterBar extends StatelessWidget {
  final ExpenseKind? value;
  final ValueChanged<ExpenseKind?> onChanged;

  const _KindFilterBar({required this.value, required this.onChanged});

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
            alignment: _alignmentFor(value),
            child: FractionallySizedBox(
              widthFactor: 1 / 3,
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
                child: _KindSegment(
                  label: 'All',
                  selected: value == null,
                  onTap: () => onChanged(null),
                ),
              ),
              Expanded(
                child: _KindSegment(
                  label: 'Fuel',
                  selected: value == ExpenseKind.fuel,
                  onTap: () => onChanged(
                    value == ExpenseKind.fuel ? null : ExpenseKind.fuel,
                  ),
                ),
              ),
              Expanded(
                child: _KindSegment(
                  label: 'Maintenance',
                  selected: value == ExpenseKind.maintenance,
                  onTap: () => onChanged(
                    value == ExpenseKind.maintenance
                        ? null
                        : ExpenseKind.maintenance,
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

Alignment _alignmentFor(ExpenseKind? value) {
  switch (value) {
    case ExpenseKind.fuel:
      return Alignment.center;
    case ExpenseKind.maintenance:
      return Alignment.centerRight;
    case null:
      return Alignment.centerLeft;
  }
}

class _KindSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _KindSegment({
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
              fontSize: 13,
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

class _ExpenseFilterSheet extends StatelessWidget {
  final List<Vehicle> vehicles;
  final String? selectedVehicleId;
  final ValueChanged<String?> onVehicleChanged;

  const _ExpenseFilterSheet({
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
            // Drag handle
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
            // Header
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
                  SheetCloseButton(onPressed: () => Navigator.of(context).pop()),
                ],
              ),
            ),
            if (vehicles.length > 1) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
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
              // All vehicles row
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
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textPrimary,
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
              const Icon(Icons.check_rounded, size: 20, color: AppColors.success),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Month header row
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
// Expense tile — category-led; vehicle name conditional
// ---------------------------------------------------------------------------

class _ExpenseTile extends ConsumerWidget {
  final Expense expense;
  final String vehicleName;
  final int totalVehicles;

  const _ExpenseTile({
    required this.expense,
    required this.vehicleName,
    required this.totalVehicles,
  });

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

  String get _categoryLabel {
    if (expense.kind == ExpenseKind.fuel) return 'Fuel';
    final serviceType = expense.maintenanceRecord?.serviceType;
    return (serviceType != null && serviceType.isNotEmpty)
        ? serviceType
        : 'Maintenance';
  }

  String get _title => _categoryLabel;

  String? get _vehicleSubLabel => totalVehicles > 1 ? vehicleName : null;

  String get _dateLine {
    final parsed = DateTime.tryParse(expense.date);
    if (parsed == null) return expense.date;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(parsed.year, parsed.month, parsed.day);
    final diff = today.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('d MMM').format(date);
  }

  String get _subLabel {
    if (expense.kind == ExpenseKind.fuel) {
      final log = expense.fuelLog!;
      return '$_dateLine · ${log.liters.toStringAsFixed(1)} L · '
          '${log.isFullTank ? 'Full' : 'Partial'}';
    }
    return _dateLine;
  }

  Widget _buildIcon() {
    final isFull = expense.fuelLog?.isFullTank ?? false;
    final bgColor = expense.kind == ExpenseKind.fuel
        ? (isFull ? AppColors.successBg : AppColors.primary.withValues(alpha: 0.12))
        : AppColors.surfaceDark.withValues(alpha: 0.08);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: expense.kind == ExpenseKind.fuel
            ? FuelPumpIcon(isFullTank: isFull, size: 20, darkInk: !isFull)
            : const Icon(Icons.build_outlined, color: AppColors.surfaceDark, size: 20),
      ),
    );
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
              child: const Text(
                'Delete',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) => _delete(context, ref),
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
          amountCents: expense.costCents,
          currency: expense.currency,
          onTap: () async {
            if (expense.kind == ExpenseKind.fuel) {
              await showQuickFuelEntrySheet(
                context,
                existing: expense.fuelLog,
              );
              ref.invalidate(fuelLogsProvider(expense.vehicleId));
            } else {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => MaintenanceFormScreen(
                    vehicleId: expense.vehicleId,
                    existing: expense.maintenanceRecord,
                  ),
                ),
              );
              ref.invalidate(maintenanceRecordsProvider(expense.vehicleId));
            }
            ref.invalidate(allExpensesProvider);
          },
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
        // Summary card skeleton
        _SkeletonBox(height: 110, radius: 16),
        const SizedBox(height: 12),
        // Filter bar skeleton
        _SkeletonBox(height: 48, radius: 999),
        const SizedBox(height: 20),
        // Tile skeletons
        for (var i = 0; i < 6; i++) ...[
          _SkeletonBox(height: 72, radius: 16),
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

class _EmptyState extends StatelessWidget {
  final bool isMonthFilter;
  final VoidCallback? onLogFillUp;

  const _EmptyState({
    required this.isMonthFilter,
    this.onLogFillUp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 34,
                color: Color(0xFF73738A),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isMonthFilter ? 'No expenses this month' : 'No expenses yet',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isMonthFilter
                  ? 'Fuel and maintenance costs will appear here once logged.'
                  : 'Your fuel and service costs will show up here as you log them.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textMuted,
                height: 1.45,
              ),
            ),
            if (!isMonthFilter && onLogFillUp != null) ...[
              const SizedBox(height: 24),
              AppButton(
                label: 'Log a fill-up',
                icon: const Icon(Icons.add),
                onPressed: onLogFillUp!,
              ),
            ],
          ],
        ),
        ),
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
