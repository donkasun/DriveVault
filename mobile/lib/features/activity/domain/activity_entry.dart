import '../../documents/domain/document.dart';
import '../../expenses/domain/expense.dart';

enum ActivityKind { fuel, maintenance, document }

/// Unified activity entry covering fuel logs, maintenance records, and documents.
class ActivityEntry {
  final ActivityKind kind;
  final String id;
  final String vehicleId;
  final String date; // YYYY-MM-DD
  final int? costCents;
  final String currency;
  final Expense? expense;
  final Document? document;

  const ActivityEntry._({
    required this.kind,
    required this.id,
    required this.vehicleId,
    required this.date,
    this.costCents,
    this.currency = 'USD',
    this.expense,
    this.document,
  });

  factory ActivityEntry.fromExpense(Expense e) => ActivityEntry._(
        kind: e.kind == ExpenseKind.fuel
            ? ActivityKind.fuel
            : ActivityKind.maintenance,
        id: e.id,
        vehicleId: e.vehicleId,
        date: e.date,
        costCents: e.costCents > 0 ? e.costCents : null,
        currency: e.currency,
        expense: e,
      );

  factory ActivityEntry.fromDocument(Document d) => ActivityEntry._(
        kind: ActivityKind.document,
        id: d.id,
        vehicleId: d.vehicleId,
        date: d.issueDate ?? d.createdAt.toIso8601String().substring(0, 10),
        document: d,
      );
}

// ---------------------------------------------------------------------------
// Grouping helpers
// ---------------------------------------------------------------------------

class ActivityMonthGroup {
  final DateTime month;
  final List<ActivityEntry> entries;
  final int subtotalCents;

  const ActivityMonthGroup({
    required this.month,
    required this.entries,
    required this.subtotalCents,
  });
}

List<ActivityMonthGroup> groupActivityByMonth(List<ActivityEntry> entries) {
  final Map<String, List<ActivityEntry>> byMonth = {};
  for (final e in entries) {
    final parts = e.date.split('-');
    if (parts.length < 2) continue;
    final key = '${parts[0]}-${parts[1]}';
    byMonth.putIfAbsent(key, () => []).add(e);
  }
  final keys = byMonth.keys.toList()..sort((a, b) => b.compareTo(a));
  return keys.map((key) {
    final group = byMonth[key]!;
    final subtotal = group.fold<int>(0, (s, e) => s + (e.costCents ?? 0));
    final parts = key.split('-');
    final month = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    return ActivityMonthGroup(month: month, entries: group, subtotalCents: subtotal);
  }).toList();
}

List<ActivityEntry> filterActivityByKind(
    List<ActivityEntry> entries, ActivityKind? kind) {
  if (kind == null) return entries;
  return entries.where((e) => e.kind == kind).toList();
}

List<ActivityEntry> filterActivityByVehicle(
    List<ActivityEntry> entries, String? vehicleId) {
  if (vehicleId == null) return entries;
  return entries.where((e) => e.vehicleId == vehicleId).toList();
}
