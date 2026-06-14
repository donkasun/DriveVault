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
  _ExpenseSummaryRange _summaryRange = _ExpenseSummaryRange.allTime;

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(allExpensesProvider);
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final userCurrency =
        ref.watch(meProvider).asData?.value.currency ?? kFallbackCurrency;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 60,
        titleSpacing: 16,
        title: const Text(
          'Expenses',
          style: TextStyle(
            fontSize: 29,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.tune_rounded, size: 22),
                color: AppColors.textPrimary,
                tooltip: 'Filter',
              ),
            ),
          ),
        ],
      ),
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

          final summaryExpenses = _summaryRange == _ExpenseSummaryRange.month
              ? filtered.where(_isInCurrentMonth).toList()
              : filtered;

          return Column(
            children: [
              // Header cards: summary + filters
              _HeaderCard(
                expenses: summaryExpenses,
                userCurrency: userCurrency,
                summaryRange: _summaryRange,
                onSummaryRangeChanged: (v) => setState(() => _summaryRange = v),
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

enum _ExpenseSummaryRange { allTime, month }

bool _isInCurrentMonth(Expense expense) {
  final date = DateTime.parse(expense.date);
  final now = DateTime.now();
  return date.year == now.year && date.month == now.month;
}

// ---------------------------------------------------------------------------
// Header card
// ---------------------------------------------------------------------------

class _HeaderCard extends StatelessWidget {
  final List<Expense> expenses;
  final String userCurrency;
  final _ExpenseSummaryRange summaryRange;
  final ValueChanged<_ExpenseSummaryRange> onSummaryRangeChanged;
  final ExpenseKind? kindFilter;
  final String? vehicleIdFilter;
  final AsyncValue<List<Vehicle>> vehiclesAsync;
  final ValueChanged<ExpenseKind?> onKindChanged;
  final ValueChanged<String?> onVehicleChanged;

  const _HeaderCard({
    required this.expenses,
    required this.userCurrency,
    required this.summaryRange,
    required this.onSummaryRangeChanged,
    required this.kindFilter,
    required this.vehicleIdFilter,
    required this.vehiclesAsync,
    required this.onKindChanged,
    required this.onVehicleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final totalCents = expenses.fold<int>(0, (sum, e) => sum + e.costCents);
    final fuelCents = expenses
        .where((e) => e.kind == ExpenseKind.fuel)
        .fold<int>(0, (sum, e) => sum + e.costCents);
    final maintenanceCents = expenses
        .where((e) => e.kind == ExpenseKind.maintenance)
        .fold<int>(0, (sum, e) => sum + e.costCents);
    final totalSegments = fuelCents + maintenanceCents;
    final fuelFraction = totalSegments == 0 ? 0.0 : fuelCents / totalSegments;
    final maintenanceFraction = totalSegments == 0
        ? 0.0
        : maintenanceCents / totalSegments;

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'TOTAL SPENT',
                        style: TextStyle(
                          fontSize: 12,
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
                const SizedBox(height: 12),
                _SummaryAmount(
                  amountText: formatCents(totalCents, currency: userCurrency),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  layoutBuilder: (currentChild, previousChildren) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  transitionBuilder: (child, animation) {
                    return ClipRect(
                      child: SizeTransition(
                        sizeFactor: animation,
                        axisAlignment: -1,
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                    );
                  },
                  child: kindFilter == null
                      ? Column(
                          key: const ValueKey('expense-breakdown'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 14),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: SizedBox(
                                height: 8,
                                child: totalSegments == 0
                                    ? Container(color: AppColors.divider)
                                    : _buildExpenseBar(
                                        fuelCents,
                                        maintenanceCents,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _LegendItem(
                                  color: AppColors.primary,
                                  label:
                                      'Fuel  ${formatCents(fuelCents, currency: userCurrency)}',
                                ),
                                const SizedBox(width: 16),
                                _LegendItem(
                                  color: AppColors.surfaceDark,
                                  label:
                                      'Maintenance  ${formatCents(maintenanceCents, currency: userCurrency)}',
                                ),
                              ],
                            ),
                          ],
                        )
                      : const SizedBox(
                          key: ValueKey('expense-breakdown-hidden'),
                        ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ExpenseKindToggle(value: kindFilter, onChanged: onKindChanged),
              vehiclesAsync.maybeWhen(
                data: (vehicles) {
                  if (vehicles.length <= 1) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _FilterPill(
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
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryAmount extends StatelessWidget {
  final String amountText;

  const _SummaryAmount({required this.amountText});

  @override
  Widget build(BuildContext context) {
    return Text(
      amountText,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.fade,
      style: const TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.05,
      ),
    );
  }
}

class _ExpenseKindToggle extends StatelessWidget {
  final ExpenseKind? value;
  final ValueChanged<ExpenseKind?> onChanged;

  const _ExpenseKindToggle({required this.value, required this.onChanged});

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
              child: Container(
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
                child: _KindToggleSegment(
                  label: 'All',
                  selected: value == null,
                  onTap: () => onChanged(null),
                ),
              ),
              Expanded(
                child: _KindToggleSegment(
                  label: 'Fuel',
                  selected: value == ExpenseKind.fuel,
                  onTap: () => onChanged(
                    value == ExpenseKind.fuel ? null : ExpenseKind.fuel,
                  ),
                ),
              ),
              Expanded(
                child: _KindToggleSegment(
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

class _KindToggleSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _KindToggleSegment({
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
              fontSize: 16,
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

Widget _buildExpenseBar(int fuelCents, int maintenanceCents) {
  if (fuelCents == 0) {
    return Row(
      children: [
        Expanded(
          flex: maintenanceCents,
          child: Container(color: AppColors.surfaceDark),
        ),
      ],
    );
  }
  if (maintenanceCents == 0) {
    return Row(
      children: [
        Expanded(
          flex: fuelCents,
          child: Container(color: AppColors.primary),
        ),
      ],
    );
  }
  return Row(
    children: [
      Expanded(
        flex: fuelCents,
        child: Container(color: AppColors.primary),
      ),
      Expanded(
        flex: maintenanceCents,
        child: Container(color: AppColors.surfaceDark),
      ),
    ],
  );
}

class _SummaryRangeToggle extends StatelessWidget {
  final _ExpenseSummaryRange value;
  final ValueChanged<_ExpenseSummaryRange> onChanged;

  const _SummaryRangeToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 164,
      height: 44,
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
            alignment: value == _ExpenseSummaryRange.month
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: Container(
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
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => onChanged(_ExpenseSummaryRange.allTime),
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: value == _ExpenseSummaryRange.allTime
                              ? Colors.white
                              : AppColors.textMuted,
                        ),
                        child: const Text('All time'),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => onChanged(_ExpenseSummaryRange.month),
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: value == _ExpenseSummaryRange.month
                              ? Colors.white
                              : AppColors.textMuted,
                        ),
                        child: const Text('Month'),
                      ),
                    ),
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

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.textPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textMuted,
                ),
              ),
            ),
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
