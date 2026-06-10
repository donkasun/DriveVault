class FuelLog {
  final String id;
  final String vehicleId;
  final String date;
  final double liters;
  final int priceCents;
  final String currency;
  final int odometer;
  final bool isFullTank;
  final String? notes;
  final DateTime createdAt;

  const FuelLog({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.liters,
    required this.priceCents,
    required this.currency,
    required this.odometer,
    required this.isFullTank,
    this.notes,
    required this.createdAt,
  });

  factory FuelLog.fromJson(Map<String, dynamic> json) => FuelLog(
        id: json['id'] as String,
        vehicleId: json['vehicleId'] as String,
        date: json['date'] as String,
        liters: (json['liters'] as num).toDouble(),
        priceCents: json['priceCents'] as int,
        currency: json['currency'] as String? ?? 'USD',
        odometer: json['odometer'] as int,
        isFullTank: json['isFullTank'] as bool? ?? false,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleId': vehicleId,
        'date': date,
        'liters': liters,
        'priceCents': priceCents,
        'currency': currency,
        'odometer': odometer,
        'isFullTank': isFullTank,
        if (notes != null) 'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };
}
