/// Vehicle domain model matching Doc 2 schema and Doc 3 API contract.
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
  final String? fuelType;
  final String? defaultFuelVariant;

  /// Per-vehicle distance-unit override ("km" / "mi" / null).
  /// null means inherit the user's account-level default.
  final String? distanceUnit;
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
    this.fuelType,
    this.defaultFuelVariant,
    this.distanceUnit,
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
    fuelType: json['fuelType'] as String?,
    defaultFuelVariant: json['defaultFuelVariant'] as String?,
    distanceUnit: json['distanceUnit'] as String?,
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
    if (registrationNumber != null) 'registrationNumber': registrationNumber,
    if (vin != null) 'vin': vin,
    if (purchaseDate != null) 'purchaseDate': purchaseDate,
    if (purchasePriceCents != null) 'purchasePriceCents': purchasePriceCents,
    'currency': currency,
    if (currentMileage != null) 'currentMileage': currentMileage,
    if (vehicleType != null) 'vehicleType': vehicleType,
    if (fuelType != null) 'fuelType': fuelType,
    if (defaultFuelVariant != null) 'defaultFuelVariant': defaultFuelVariant,
    if (distanceUnit != null) 'distanceUnit': distanceUnit,
    if (photoUrl != null) 'photoUrl': photoUrl,
    if (photoPublicId != null) 'photoPublicId': photoPublicId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  String get displayName =>
      '${year != null ? '$year ' : ''}$make $model'.trim();

  Vehicle copyWith({
    String? id,
    String? make,
    String? model,
    int? year,
    String? registrationNumber,
    String? vin,
    String? purchaseDate,
    int? purchasePriceCents,
    String? currency,
    int? currentMileage,
    String? vehicleType,
    String? fuelType,
    String? defaultFuelVariant,
    String? distanceUnit,
    String? photoUrl,
    String? photoPublicId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      vin: vin ?? this.vin,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchasePriceCents: purchasePriceCents ?? this.purchasePriceCents,
      currency: currency ?? this.currency,
      currentMileage: currentMileage ?? this.currentMileage,
      vehicleType: vehicleType ?? this.vehicleType,
      fuelType: fuelType ?? this.fuelType,
      defaultFuelVariant: defaultFuelVariant ?? this.defaultFuelVariant,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      photoUrl: photoUrl ?? this.photoUrl,
      photoPublicId: photoPublicId ?? this.photoPublicId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
