// Domain models for the dashboard feature.

class DashboardData {
  final int vehicleCount;
  final int monthlyFuelSpendCents;
  final int totalOwnershipCostCents;
  final CostBreakdown costBreakdown;
  final List<UpcomingRenewal> upcomingRenewals;

  const DashboardData({
    required this.vehicleCount,
    required this.monthlyFuelSpendCents,
    required this.totalOwnershipCostCents,
    required this.costBreakdown,
    required this.upcomingRenewals,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final breakdownJson = json['costBreakdown'] as Map<String, dynamic>;
    final renewalsList = (json['upcomingRenewals'] as List<dynamic>)
        .map((e) => UpcomingRenewal.fromJson(e as Map<String, dynamic>))
        .toList();

    return DashboardData(
      vehicleCount: json['vehicleCount'] as int,
      monthlyFuelSpendCents: json['monthlyFuelSpendCents'] as int,
      totalOwnershipCostCents: json['totalOwnershipCostCents'] as int,
      costBreakdown: CostBreakdown.fromJson(breakdownJson),
      upcomingRenewals: renewalsList,
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
      fuelCents: json['fuelCents'] as int,
      maintenanceCents: json['maintenanceCents'] as int,
      purchaseCents: json['purchaseCents'] as int,
    );
  }
}

class UpcomingRenewal {
  final String vehicleId;
  final String title;
  final String expiryDate; // "YYYY-MM-DD"

  const UpcomingRenewal({
    required this.vehicleId,
    required this.title,
    required this.expiryDate,
  });

  factory UpcomingRenewal.fromJson(Map<String, dynamic> json) {
    return UpcomingRenewal(
      vehicleId: json['vehicleId'] as String,
      title: json['title'] as String,
      expiryDate: json['expiryDate'] as String,
    );
  }
}
