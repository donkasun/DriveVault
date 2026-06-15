// Domain models for the dashboard feature.

class DashboardData {
  final int vehicleCount;
  final int monthlyFuelSpendCents;
  final int totalOwnershipCostCents;
  final CostBreakdown costBreakdown;
  final List<UpcomingRenewal> upcomingRenewals;
  final List<ActivityItem> recentActivity;

  const DashboardData({
    required this.vehicleCount,
    required this.monthlyFuelSpendCents,
    required this.totalOwnershipCostCents,
    required this.costBreakdown,
    required this.upcomingRenewals,
    this.recentActivity = const [],
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final breakdownJson =
        (json['costBreakdown'] as Map<String, dynamic>?) ?? {};
    final renewalsList = (json['upcomingRenewals'] as List<dynamic>? ?? [])
        .map((e) => UpcomingRenewal.fromJson(e as Map<String, dynamic>))
        .toList();
    final activityList = (json['recentActivity'] as List<dynamic>? ?? [])
        .map((e) => ActivityItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return DashboardData(
      vehicleCount: json['vehicleCount'] as int,
      monthlyFuelSpendCents: json['monthlyFuelSpendCents'] as int,
      totalOwnershipCostCents: json['totalOwnershipCostCents'] as int,
      costBreakdown: CostBreakdown.fromJson(breakdownJson),
      upcomingRenewals: renewalsList,
      recentActivity: activityList,
    );
  }
}

class CostBreakdown {
  final int fuelCents;
  final int maintenanceCents;
  final int purchaseCents;

  const CostBreakdown({
    required this.fuelCents,
    required this.maintenanceCents,
    required this.purchaseCents,
  });

  factory CostBreakdown.fromJson(Map<String, dynamic> json) {
    return CostBreakdown(
      fuelCents: (json['fuelCents'] as int?) ?? 0,
      maintenanceCents: (json['maintenanceCents'] as int?) ?? 0,
      purchaseCents: (json['purchaseCents'] as int?) ?? 0,
    );
  }
}

/// Renewal status per the shared status scale:
/// `ok` = > 30 days · `soon` = 0–30 days · `overdue` = already expired.
enum RenewalStatus { ok, soon, overdue }

RenewalStatus _parseRenewalStatus(String? raw) {
  switch (raw) {
    case 'soon':
      return RenewalStatus.soon;
    case 'overdue':
      return RenewalStatus.overdue;
    default:
      return RenewalStatus.ok;
  }
}

class UpcomingRenewal {
  final String vehicleId;
  final String title;
  final String expiryDate; // "YYYY-MM-DD"

  // Fields added in the updated API contract — null-safe defaults for older servers.
  final String? docType;
  final String? vehicleLabel;
  final int? daysRemaining;
  final RenewalStatus? status;

  const UpcomingRenewal({
    required this.vehicleId,
    required this.title,
    required this.expiryDate,
    this.docType,
    this.vehicleLabel,
    this.daysRemaining,
    this.status,
  });

  factory UpcomingRenewal.fromJson(Map<String, dynamic> json) {
    return UpcomingRenewal(
      vehicleId: json['vehicleId'] as String,
      title: json['title'] as String,
      expiryDate: json['expiryDate'] as String,
      docType: json['docType'] as String?,
      vehicleLabel: json['vehicleLabel'] as String?,
      daysRemaining: json['daysRemaining'] as int?,
      status: json.containsKey('status')
          ? _parseRenewalStatus(json['status'] as String?)
          : null,
    );
  }
}

/// Activity type for [ActivityItem].
enum ActivityType { fuel, maintenance, document }

ActivityType _parseActivityType(String raw) {
  switch (raw) {
    case 'maintenance':
      return ActivityType.maintenance;
    case 'document':
      return ActivityType.document;
    default:
      return ActivityType.fuel;
  }
}

/// A single entry in the dashboard's `recentActivity` list.
///
/// `amountCents` is null for document entries.
/// `liters` and `isFull` are set only for fuel entries.
class ActivityItem {
  final ActivityType type;
  final String vehicleId;
  final String vehicleLabel;
  final String date; // "YYYY-MM-DD"
  final int? amountCents;
  final String label;
  final double? liters;
  final bool? isFull;

  const ActivityItem({
    required this.type,
    required this.vehicleId,
    required this.vehicleLabel,
    required this.date,
    required this.amountCents,
    required this.label,
    this.liters,
    this.isFull,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      type: _parseActivityType(json['type'] as String? ?? 'fuel'),
      vehicleId: json['vehicleId'] as String,
      vehicleLabel: json['vehicleLabel'] as String,
      date: json['date'] as String,
      amountCents: json['amountCents'] as int?,
      label: json['label'] as String,
      liters: (json['liters'] as num?)?.toDouble(),
      isFull: json['isFullTank'] as bool?,
    );
  }
}
