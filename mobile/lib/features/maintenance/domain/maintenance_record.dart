class MaintenanceRecord {
  final String id;
  final String vehicleId;
  final String date;
  final String serviceType;
  final String? category;
  final int? costCents;
  final String? currency;
  final int? odometer;
  final String? workshop;
  final String? notes;
  final String source;
  final DateTime createdAt;

  const MaintenanceRecord({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.serviceType,
    this.category,
    this.costCents,
    this.currency,
    this.odometer,
    this.workshop,
    this.notes,
    required this.source,
    required this.createdAt,
  });

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) =>
      MaintenanceRecord(
        id: json['id'] as String,
        vehicleId: json['vehicleId'] as String,
        date: json['date'] as String,
        serviceType: json['serviceType'] as String,
        category: json['category'] as String?,
        costCents: json['costCents'] as int?,
        currency: json['currency'] as String?,
        odometer: json['odometer'] as int?,
        workshop: json['workshop'] as String?,
        notes: json['notes'] as String?,
        source: json['source'] as String? ?? 'manual',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleId': vehicleId,
        'date': date,
        'serviceType': serviceType,
        if (category != null) 'category': category,
        if (costCents != null) 'costCents': costCents,
        if (currency != null) 'currency': currency,
        if (odometer != null) 'odometer': odometer,
        if (workshop != null) 'workshop': workshop,
        if (notes != null) 'notes': notes,
        'source': source,
        'createdAt': createdAt.toIso8601String(),
      };
}
