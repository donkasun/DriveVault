import '../domain/expense.dart';

/// Pure, side-effect-free helpers for filtering and grouping [Expense] lists.
/// All functions are top-level so they can be unit-tested without Flutter.

// ---------------------------------------------------------------------------
// Month-group data class
// ---------------------------------------------------------------------------

class ExpenseMonthGroup {
  final DateTime month; // normalised to the first day of the month
  final List<Expense> expenses;
  final int subtotalCents;

  const ExpenseMonthGroup({
    required this.month,
    required this.expenses,
    required this.subtotalCents,
  });
}

// ---------------------------------------------------------------------------
// Filters
// ---------------------------------------------------------------------------

/// Returns only expenses whose date falls within the current calendar month.
List<Expense> filterToCurrentMonth(List<Expense> expenses) {
  final now = DateTime.now();
  return expenses.where((e) {
    final date = DateTime.parse(e.date);
    return date.year == now.year && date.month == now.month;
  }).toList();
}

/// Returns only expenses matching [kind]. If [kind] is null, all are returned.
List<Expense> filterByKind(List<Expense> expenses, ExpenseKind? kind) {
  if (kind == null) return expenses;
  return expenses.where((e) => e.kind == kind).toList();
}

/// Returns only expenses matching [vehicleId]. If null, all are returned.
List<Expense> filterByVehicle(List<Expense> expenses, String? vehicleId) {
  if (vehicleId == null) return expenses;
  return expenses.where((e) => e.vehicleId == vehicleId).toList();
}

// ---------------------------------------------------------------------------
// Grouping
// ---------------------------------------------------------------------------

/// Groups [expenses] by calendar month, newest month first. Within each month
/// expenses are sorted newest-date first. The running [subtotalCents] is
/// pre-computed for each group.
List<ExpenseMonthGroup> groupExpensesByMonth(List<Expense> expenses) {
  final buckets = <String, List<Expense>>{};

  for (final expense in expenses) {
    final date = DateTime.parse(expense.date);
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    buckets.putIfAbsent(key, () => []).add(expense);
  }

  final groups = buckets.entries.map((entry) {
    final parts = entry.key.split('-');
    final month = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    final sorted = [...entry.value]..sort((a, b) => b.date.compareTo(a.date));
    final subtotal = sorted.fold<int>(0, (sum, e) => sum + e.costCents);
    return ExpenseMonthGroup(
      month: month,
      expenses: sorted,
      subtotalCents: subtotal,
    );
  }).toList()..sort((a, b) => b.month.compareTo(a.month));

  return groups;
}

// ---------------------------------------------------------------------------
// Summary helpers
// ---------------------------------------------------------------------------

/// Total cents across all [expenses].
int totalCents(List<Expense> expenses) =>
    expenses.fold(0, (sum, e) => sum + e.costCents);

/// Fuel-only cents.
int fuelCents(List<Expense> expenses) => expenses
    .where((e) => e.kind == ExpenseKind.fuel)
    .fold(0, (sum, e) => sum + e.costCents);

/// Maintenance-only cents.
int maintenanceCents(List<Expense> expenses) => expenses
    .where((e) => e.kind == ExpenseKind.maintenance)
    .fold(0, (sum, e) => sum + e.costCents);
