class MonthlySpend {
  final String month;
  final int spentCents;

  const MonthlySpend({required this.month, required this.spentCents});

  factory MonthlySpend.fromJson(Map<String, dynamic> json) => MonthlySpend(
        month: json['month'] as String,
        spentCents: json['spentCents'] as int,
      );
}

class FuelStats {
  final double? avgConsumptionLPer100Km;
  final int? avgCostPerKmCents;
  final double totalLiters;
  final int totalSpentCents;
  final List<MonthlySpend> monthlySpend;

  const FuelStats({
    this.avgConsumptionLPer100Km,
    this.avgCostPerKmCents,
    required this.totalLiters,
    required this.totalSpentCents,
    required this.monthlySpend,
  });

  factory FuelStats.fromJson(Map<String, dynamic> json) => FuelStats(
        avgConsumptionLPer100Km:
            (json['avgConsumptionLPer100Km'] as num?)?.toDouble(),
        avgCostPerKmCents: json['avgCostPerKmCents'] as int?,
        totalLiters: (json['totalLiters'] as num).toDouble(),
        totalSpentCents: json['totalSpentCents'] as int,
        monthlySpend: (json['monthlySpend'] as List<dynamic>?)
                ?.map((e) =>
                    MonthlySpend.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
