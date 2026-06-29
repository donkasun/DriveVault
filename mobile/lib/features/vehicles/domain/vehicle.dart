import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../../../core/database/app_database.dart';
import '../../../shared/constants/currencies.dart';

/// Derived docs-status for a vehicle — computed server-side from its documents.
///
/// `state` values: `"valid"` | `"needs_action"` | `"none"`.
class DocsStatus {
  final String state; // "valid" | "needs_action" | "none"
  final int needsActionCount;

  const DocsStatus({required this.state, required this.needsActionCount});

  /// Backward-compatible: missing key → state "none", count 0.
  factory DocsStatus.fromJson(Map<String, dynamic> json) {
    return DocsStatus(
      state: (json['state'] as String?) ?? 'none',
      needsActionCount: (json['needsActionCount'] as int?) ?? 0,
    );
  }

  /// Sentinel used when the backend omits the `docsStatus` key entirely.
  static const DocsStatus none = DocsStatus(state: 'none', needsActionCount: 0);

  Map<String, dynamic> toJson() => {
    'state': state,
    'needsActionCount': needsActionCount,
  };
}

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

  /// Per-vehicle distance-unit override ("km" / "mi" / null).
  /// null means inherit the user's account-level default.
  final String? distanceUnit;
  final String? photoUrl;
  final String? photoPublicId;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Derived docs-status. Defaults to [DocsStatus.none] when absent from JSON.
  final DocsStatus docsStatus;

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
    this.distanceUnit,
    this.photoUrl,
    this.photoPublicId,
    required this.createdAt,
    required this.updatedAt,
    this.docsStatus = DocsStatus.none,
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
    currency: json['currency'] as String? ?? kFallbackCurrency,
    currentMileage: json['currentMileage'] as int?,
    vehicleType: json['vehicleType'] as String?,
    fuelType: json['fuelType'] as String?,
    distanceUnit: json['distanceUnit'] as String?,
    photoUrl: json['photoUrl'] as String?,
    photoPublicId: json['photoPublicId'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    docsStatus: json['docsStatus'] != null
        ? DocsStatus.fromJson(json['docsStatus'] as Map<String, dynamic>)
        : DocsStatus.none,
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
    if (distanceUnit != null) 'distanceUnit': distanceUnit,
    if (photoUrl != null) 'photoUrl': photoUrl,
    if (photoPublicId != null) 'photoPublicId': photoPublicId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'docsStatus': docsStatus.toJson(),
  };

  String get displayName =>
      '${year != null ? '$year ' : ''}$make $model'.trim();

  VehiclesCompanion toDrift() => VehiclesCompanion.insert(
        id: id,
        make: make,
        model: model,
        year: Value(year),
        registrationNumber: Value(registrationNumber),
        vin: Value(vin),
        purchaseDate: Value(purchaseDate),
        purchasePriceCents: Value(purchasePriceCents),
        currency: Value(currency),
        currentMileage: Value(currentMileage),
        vehicleType: Value(vehicleType),
        fuelType: Value(fuelType),
        distanceUnit: Value(distanceUnit),
        photoUrl: Value(photoUrl),
        photoPublicId: Value(photoPublicId),
        docsStatusJson: Value(jsonEncode(docsStatus.toJson())),
        createdAt: createdAt.toIso8601String(),
        updatedAt: updatedAt.toIso8601String(),
        cachedAt: DateTime.now().millisecondsSinceEpoch,
      );

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
    String? distanceUnit,
    String? photoUrl,
    String? photoPublicId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DocsStatus? docsStatus,
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
      distanceUnit: distanceUnit ?? this.distanceUnit,
      photoUrl: photoUrl ?? this.photoUrl,
      photoPublicId: photoPublicId ?? this.photoPublicId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      docsStatus: docsStatus ?? this.docsStatus,
    );
  }
}

/// Maps a Drift [VehicleRow] back to the domain [Vehicle].
Vehicle vehicleFromDriftRow(VehicleRow row) => Vehicle(
      id: row.id,
      make: row.make,
      model: row.model,
      year: row.year,
      registrationNumber: row.registrationNumber,
      vin: row.vin,
      purchaseDate: row.purchaseDate,
      purchasePriceCents: row.purchasePriceCents,
      currency: row.currency,
      currentMileage: row.currentMileage,
      vehicleType: row.vehicleType,
      fuelType: row.fuelType,
      distanceUnit: row.distanceUnit,
      photoUrl: row.photoUrl,
      photoPublicId: row.photoPublicId,
      createdAt: DateTime.parse(row.createdAt),
      updatedAt: DateTime.parse(row.updatedAt),
      docsStatus: DocsStatus.fromJson(
        jsonDecode(row.docsStatusJson) as Map<String, dynamic>,
      ),
    );
