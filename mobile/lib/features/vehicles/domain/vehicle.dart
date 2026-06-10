class Vehicle {
  final String id;
  final String make;
  final String model;
  final int? year;
  final String? registrationNumber;
  final String? vin;
  final String? purchaseDate;
  final int? purchasePriceCents;
  final String currency;
  final int? currentMileage;
  final String? vehicleType;
  final String? photoUrl;
  final String? photoPublicId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Vehicle({
    required this.id,
    required this.make,
    required this.model,
    this.year,
    this.registrationNumber,
    this.vin,
    this.purchaseDate,
    this.purchasePriceCents,
    required this.currency,
    this.currentMileage,
    this.vehicleType,
    this.photoUrl,
    this.photoPublicId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'] as String,
        make: json['make'] as String,
        model: json['model'] as String,
        year: json['year'] as int?,
        registrationNumber: json['registrationNumber'] as String?,
        vin: json['vin'] as String?,
        purchaseDate: json['purchaseDate'] as String?,
        purchasePriceCents: json['purchasePriceCents'] as int?,
        currency: json['currency'] as String? ?? 'USD',
        currentMileage: json['currentMileage'] as int?,
        vehicleType: json['vehicleType'] as String?,
        photoUrl: json['photoUrl'] as String?,
        photoPublicId: json['photoPublicId'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'make': make,
        'model': model,
        if (year != null) 'year': year,
        if (registrationNumber != null)
          'registrationNumber': registrationNumber,
        if (vin != null) 'vin': vin,
        if (purchaseDate != null) 'purchaseDate': purchaseDate,
        if (purchasePriceCents != null)
          'purchasePriceCents': purchasePriceCents,
        'currency': currency,
        if (currentMileage != null) 'currentMileage': currentMileage,
        if (vehicleType != null) 'vehicleType': vehicleType,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (photoPublicId != null) 'photoPublicId': photoPublicId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  String get displayName => '$year $make $model'.trim();
}
