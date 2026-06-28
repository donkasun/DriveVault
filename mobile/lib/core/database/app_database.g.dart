// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
mixin _$VehiclesDaoMixin on DatabaseAccessor<AppDatabase> {
  $VehiclesTable get vehicles => attachedDatabase.vehicles;
  VehiclesDaoManager get managers => VehiclesDaoManager(this);
}

class VehiclesDaoManager {
  final _$VehiclesDaoMixin _db;
  VehiclesDaoManager(this._db);
  $$VehiclesTableTableManager get vehicles =>
      $$VehiclesTableTableManager(_db.attachedDatabase, _db.vehicles);
}

mixin _$DashboardDaoMixin on DatabaseAccessor<AppDatabase> {
  $DashboardSnapshotsTable get dashboardSnapshots =>
      attachedDatabase.dashboardSnapshots;
  DashboardDaoManager get managers => DashboardDaoManager(this);
}

class DashboardDaoManager {
  final _$DashboardDaoMixin _db;
  DashboardDaoManager(this._db);
  $$DashboardSnapshotsTableTableManager get dashboardSnapshots =>
      $$DashboardSnapshotsTableTableManager(
        _db.attachedDatabase,
        _db.dashboardSnapshots,
      );
}

class $VehiclesTable extends Vehicles
    with TableInfo<$VehiclesTable, VehicleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VehiclesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _makeMeta = const VerificationMeta('make');
  @override
  late final GeneratedColumn<String> make = GeneratedColumn<String>(
    'make',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _registrationNumberMeta =
      const VerificationMeta('registrationNumber');
  @override
  late final GeneratedColumn<String> registrationNumber =
      GeneratedColumn<String>(
        'registration_number',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _vinMeta = const VerificationMeta('vin');
  @override
  late final GeneratedColumn<String> vin = GeneratedColumn<String>(
    'vin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purchaseDateMeta = const VerificationMeta(
    'purchaseDate',
  );
  @override
  late final GeneratedColumn<String> purchaseDate = GeneratedColumn<String>(
    'purchase_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purchasePriceCentsMeta =
      const VerificationMeta('purchasePriceCents');
  @override
  late final GeneratedColumn<int> purchasePriceCents = GeneratedColumn<int>(
    'purchase_price_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('LKR'),
  );
  static const VerificationMeta _currentMileageMeta = const VerificationMeta(
    'currentMileage',
  );
  @override
  late final GeneratedColumn<int> currentMileage = GeneratedColumn<int>(
    'current_mileage',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vehicleTypeMeta = const VerificationMeta(
    'vehicleType',
  );
  @override
  late final GeneratedColumn<String> vehicleType = GeneratedColumn<String>(
    'vehicle_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fuelTypeMeta = const VerificationMeta(
    'fuelType',
  );
  @override
  late final GeneratedColumn<String> fuelType = GeneratedColumn<String>(
    'fuel_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _distanceUnitMeta = const VerificationMeta(
    'distanceUnit',
  );
  @override
  late final GeneratedColumn<String> distanceUnit = GeneratedColumn<String>(
    'distance_unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoUrlMeta = const VerificationMeta(
    'photoUrl',
  );
  @override
  late final GeneratedColumn<String> photoUrl = GeneratedColumn<String>(
    'photo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoPublicIdMeta = const VerificationMeta(
    'photoPublicId',
  );
  @override
  late final GeneratedColumn<String> photoPublicId = GeneratedColumn<String>(
    'photo_public_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _docsStatusJsonMeta = const VerificationMeta(
    'docsStatusJson',
  );
  @override
  late final GeneratedColumn<String> docsStatusJson = GeneratedColumn<String>(
    'docs_status_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{"state":"none","needsActionCount":0}'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<int> cachedAt = GeneratedColumn<int>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    make,
    model,
    year,
    registrationNumber,
    vin,
    purchaseDate,
    purchasePriceCents,
    currency,
    currentMileage,
    vehicleType,
    fuelType,
    distanceUnit,
    photoUrl,
    photoPublicId,
    docsStatusJson,
    createdAt,
    updatedAt,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vehicles';
  @override
  VerificationContext validateIntegrity(
    Insertable<VehicleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('make')) {
      context.handle(
        _makeMeta,
        make.isAcceptableOrUnknown(data['make']!, _makeMeta),
      );
    } else if (isInserting) {
      context.missing(_makeMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('registration_number')) {
      context.handle(
        _registrationNumberMeta,
        registrationNumber.isAcceptableOrUnknown(
          data['registration_number']!,
          _registrationNumberMeta,
        ),
      );
    }
    if (data.containsKey('vin')) {
      context.handle(
        _vinMeta,
        vin.isAcceptableOrUnknown(data['vin']!, _vinMeta),
      );
    }
    if (data.containsKey('purchase_date')) {
      context.handle(
        _purchaseDateMeta,
        purchaseDate.isAcceptableOrUnknown(
          data['purchase_date']!,
          _purchaseDateMeta,
        ),
      );
    }
    if (data.containsKey('purchase_price_cents')) {
      context.handle(
        _purchasePriceCentsMeta,
        purchasePriceCents.isAcceptableOrUnknown(
          data['purchase_price_cents']!,
          _purchasePriceCentsMeta,
        ),
      );
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('current_mileage')) {
      context.handle(
        _currentMileageMeta,
        currentMileage.isAcceptableOrUnknown(
          data['current_mileage']!,
          _currentMileageMeta,
        ),
      );
    }
    if (data.containsKey('vehicle_type')) {
      context.handle(
        _vehicleTypeMeta,
        vehicleType.isAcceptableOrUnknown(
          data['vehicle_type']!,
          _vehicleTypeMeta,
        ),
      );
    }
    if (data.containsKey('fuel_type')) {
      context.handle(
        _fuelTypeMeta,
        fuelType.isAcceptableOrUnknown(data['fuel_type']!, _fuelTypeMeta),
      );
    }
    if (data.containsKey('distance_unit')) {
      context.handle(
        _distanceUnitMeta,
        distanceUnit.isAcceptableOrUnknown(
          data['distance_unit']!,
          _distanceUnitMeta,
        ),
      );
    }
    if (data.containsKey('photo_url')) {
      context.handle(
        _photoUrlMeta,
        photoUrl.isAcceptableOrUnknown(data['photo_url']!, _photoUrlMeta),
      );
    }
    if (data.containsKey('photo_public_id')) {
      context.handle(
        _photoPublicIdMeta,
        photoPublicId.isAcceptableOrUnknown(
          data['photo_public_id']!,
          _photoPublicIdMeta,
        ),
      );
    }
    if (data.containsKey('docs_status_json')) {
      context.handle(
        _docsStatusJsonMeta,
        docsStatusJson.isAcceptableOrUnknown(
          data['docs_status_json']!,
          _docsStatusJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VehicleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VehicleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      make: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}make'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      registrationNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}registration_number'],
      ),
      vin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vin'],
      ),
      purchaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purchase_date'],
      ),
      purchasePriceCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}purchase_price_cents'],
      ),
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      currentMileage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_mileage'],
      ),
      vehicleType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vehicle_type'],
      ),
      fuelType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fuel_type'],
      ),
      distanceUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}distance_unit'],
      ),
      photoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_url'],
      ),
      photoPublicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_public_id'],
      ),
      docsStatusJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}docs_status_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $VehiclesTable createAlias(String alias) {
    return $VehiclesTable(attachedDatabase, alias);
  }
}

class VehicleRow extends DataClass implements Insertable<VehicleRow> {
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
  final String? distanceUnit;
  final String? photoUrl;
  final String? photoPublicId;
  final String docsStatusJson;
  final String createdAt;
  final String updatedAt;
  final int cachedAt;
  const VehicleRow({
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
    required this.docsStatusJson,
    required this.createdAt,
    required this.updatedAt,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['make'] = Variable<String>(make);
    map['model'] = Variable<String>(model);
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    if (!nullToAbsent || registrationNumber != null) {
      map['registration_number'] = Variable<String>(registrationNumber);
    }
    if (!nullToAbsent || vin != null) {
      map['vin'] = Variable<String>(vin);
    }
    if (!nullToAbsent || purchaseDate != null) {
      map['purchase_date'] = Variable<String>(purchaseDate);
    }
    if (!nullToAbsent || purchasePriceCents != null) {
      map['purchase_price_cents'] = Variable<int>(purchasePriceCents);
    }
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || currentMileage != null) {
      map['current_mileage'] = Variable<int>(currentMileage);
    }
    if (!nullToAbsent || vehicleType != null) {
      map['vehicle_type'] = Variable<String>(vehicleType);
    }
    if (!nullToAbsent || fuelType != null) {
      map['fuel_type'] = Variable<String>(fuelType);
    }
    if (!nullToAbsent || distanceUnit != null) {
      map['distance_unit'] = Variable<String>(distanceUnit);
    }
    if (!nullToAbsent || photoUrl != null) {
      map['photo_url'] = Variable<String>(photoUrl);
    }
    if (!nullToAbsent || photoPublicId != null) {
      map['photo_public_id'] = Variable<String>(photoPublicId);
    }
    map['docs_status_json'] = Variable<String>(docsStatusJson);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['cached_at'] = Variable<int>(cachedAt);
    return map;
  }

  VehiclesCompanion toCompanion(bool nullToAbsent) {
    return VehiclesCompanion(
      id: Value(id),
      make: Value(make),
      model: Value(model),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      registrationNumber: registrationNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(registrationNumber),
      vin: vin == null && nullToAbsent ? const Value.absent() : Value(vin),
      purchaseDate: purchaseDate == null && nullToAbsent
          ? const Value.absent()
          : Value(purchaseDate),
      purchasePriceCents: purchasePriceCents == null && nullToAbsent
          ? const Value.absent()
          : Value(purchasePriceCents),
      currency: Value(currency),
      currentMileage: currentMileage == null && nullToAbsent
          ? const Value.absent()
          : Value(currentMileage),
      vehicleType: vehicleType == null && nullToAbsent
          ? const Value.absent()
          : Value(vehicleType),
      fuelType: fuelType == null && nullToAbsent
          ? const Value.absent()
          : Value(fuelType),
      distanceUnit: distanceUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(distanceUnit),
      photoUrl: photoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(photoUrl),
      photoPublicId: photoPublicId == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPublicId),
      docsStatusJson: Value(docsStatusJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory VehicleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VehicleRow(
      id: serializer.fromJson<String>(json['id']),
      make: serializer.fromJson<String>(json['make']),
      model: serializer.fromJson<String>(json['model']),
      year: serializer.fromJson<int?>(json['year']),
      registrationNumber: serializer.fromJson<String?>(
        json['registrationNumber'],
      ),
      vin: serializer.fromJson<String?>(json['vin']),
      purchaseDate: serializer.fromJson<String?>(json['purchaseDate']),
      purchasePriceCents: serializer.fromJson<int?>(json['purchasePriceCents']),
      currency: serializer.fromJson<String>(json['currency']),
      currentMileage: serializer.fromJson<int?>(json['currentMileage']),
      vehicleType: serializer.fromJson<String?>(json['vehicleType']),
      fuelType: serializer.fromJson<String?>(json['fuelType']),
      distanceUnit: serializer.fromJson<String?>(json['distanceUnit']),
      photoUrl: serializer.fromJson<String?>(json['photoUrl']),
      photoPublicId: serializer.fromJson<String?>(json['photoPublicId']),
      docsStatusJson: serializer.fromJson<String>(json['docsStatusJson']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      cachedAt: serializer.fromJson<int>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'make': serializer.toJson<String>(make),
      'model': serializer.toJson<String>(model),
      'year': serializer.toJson<int?>(year),
      'registrationNumber': serializer.toJson<String?>(registrationNumber),
      'vin': serializer.toJson<String?>(vin),
      'purchaseDate': serializer.toJson<String?>(purchaseDate),
      'purchasePriceCents': serializer.toJson<int?>(purchasePriceCents),
      'currency': serializer.toJson<String>(currency),
      'currentMileage': serializer.toJson<int?>(currentMileage),
      'vehicleType': serializer.toJson<String?>(vehicleType),
      'fuelType': serializer.toJson<String?>(fuelType),
      'distanceUnit': serializer.toJson<String?>(distanceUnit),
      'photoUrl': serializer.toJson<String?>(photoUrl),
      'photoPublicId': serializer.toJson<String?>(photoPublicId),
      'docsStatusJson': serializer.toJson<String>(docsStatusJson),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'cachedAt': serializer.toJson<int>(cachedAt),
    };
  }

  VehicleRow copyWith({
    String? id,
    String? make,
    String? model,
    Value<int?> year = const Value.absent(),
    Value<String?> registrationNumber = const Value.absent(),
    Value<String?> vin = const Value.absent(),
    Value<String?> purchaseDate = const Value.absent(),
    Value<int?> purchasePriceCents = const Value.absent(),
    String? currency,
    Value<int?> currentMileage = const Value.absent(),
    Value<String?> vehicleType = const Value.absent(),
    Value<String?> fuelType = const Value.absent(),
    Value<String?> distanceUnit = const Value.absent(),
    Value<String?> photoUrl = const Value.absent(),
    Value<String?> photoPublicId = const Value.absent(),
    String? docsStatusJson,
    String? createdAt,
    String? updatedAt,
    int? cachedAt,
  }) => VehicleRow(
    id: id ?? this.id,
    make: make ?? this.make,
    model: model ?? this.model,
    year: year.present ? year.value : this.year,
    registrationNumber: registrationNumber.present
        ? registrationNumber.value
        : this.registrationNumber,
    vin: vin.present ? vin.value : this.vin,
    purchaseDate: purchaseDate.present ? purchaseDate.value : this.purchaseDate,
    purchasePriceCents: purchasePriceCents.present
        ? purchasePriceCents.value
        : this.purchasePriceCents,
    currency: currency ?? this.currency,
    currentMileage: currentMileage.present
        ? currentMileage.value
        : this.currentMileage,
    vehicleType: vehicleType.present ? vehicleType.value : this.vehicleType,
    fuelType: fuelType.present ? fuelType.value : this.fuelType,
    distanceUnit: distanceUnit.present ? distanceUnit.value : this.distanceUnit,
    photoUrl: photoUrl.present ? photoUrl.value : this.photoUrl,
    photoPublicId: photoPublicId.present
        ? photoPublicId.value
        : this.photoPublicId,
    docsStatusJson: docsStatusJson ?? this.docsStatusJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  VehicleRow copyWithCompanion(VehiclesCompanion data) {
    return VehicleRow(
      id: data.id.present ? data.id.value : this.id,
      make: data.make.present ? data.make.value : this.make,
      model: data.model.present ? data.model.value : this.model,
      year: data.year.present ? data.year.value : this.year,
      registrationNumber: data.registrationNumber.present
          ? data.registrationNumber.value
          : this.registrationNumber,
      vin: data.vin.present ? data.vin.value : this.vin,
      purchaseDate: data.purchaseDate.present
          ? data.purchaseDate.value
          : this.purchaseDate,
      purchasePriceCents: data.purchasePriceCents.present
          ? data.purchasePriceCents.value
          : this.purchasePriceCents,
      currency: data.currency.present ? data.currency.value : this.currency,
      currentMileage: data.currentMileage.present
          ? data.currentMileage.value
          : this.currentMileage,
      vehicleType: data.vehicleType.present
          ? data.vehicleType.value
          : this.vehicleType,
      fuelType: data.fuelType.present ? data.fuelType.value : this.fuelType,
      distanceUnit: data.distanceUnit.present
          ? data.distanceUnit.value
          : this.distanceUnit,
      photoUrl: data.photoUrl.present ? data.photoUrl.value : this.photoUrl,
      photoPublicId: data.photoPublicId.present
          ? data.photoPublicId.value
          : this.photoPublicId,
      docsStatusJson: data.docsStatusJson.present
          ? data.docsStatusJson.value
          : this.docsStatusJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VehicleRow(')
          ..write('id: $id, ')
          ..write('make: $make, ')
          ..write('model: $model, ')
          ..write('year: $year, ')
          ..write('registrationNumber: $registrationNumber, ')
          ..write('vin: $vin, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('purchasePriceCents: $purchasePriceCents, ')
          ..write('currency: $currency, ')
          ..write('currentMileage: $currentMileage, ')
          ..write('vehicleType: $vehicleType, ')
          ..write('fuelType: $fuelType, ')
          ..write('distanceUnit: $distanceUnit, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('photoPublicId: $photoPublicId, ')
          ..write('docsStatusJson: $docsStatusJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    make,
    model,
    year,
    registrationNumber,
    vin,
    purchaseDate,
    purchasePriceCents,
    currency,
    currentMileage,
    vehicleType,
    fuelType,
    distanceUnit,
    photoUrl,
    photoPublicId,
    docsStatusJson,
    createdAt,
    updatedAt,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VehicleRow &&
          other.id == this.id &&
          other.make == this.make &&
          other.model == this.model &&
          other.year == this.year &&
          other.registrationNumber == this.registrationNumber &&
          other.vin == this.vin &&
          other.purchaseDate == this.purchaseDate &&
          other.purchasePriceCents == this.purchasePriceCents &&
          other.currency == this.currency &&
          other.currentMileage == this.currentMileage &&
          other.vehicleType == this.vehicleType &&
          other.fuelType == this.fuelType &&
          other.distanceUnit == this.distanceUnit &&
          other.photoUrl == this.photoUrl &&
          other.photoPublicId == this.photoPublicId &&
          other.docsStatusJson == this.docsStatusJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.cachedAt == this.cachedAt);
}

class VehiclesCompanion extends UpdateCompanion<VehicleRow> {
  final Value<String> id;
  final Value<String> make;
  final Value<String> model;
  final Value<int?> year;
  final Value<String?> registrationNumber;
  final Value<String?> vin;
  final Value<String?> purchaseDate;
  final Value<int?> purchasePriceCents;
  final Value<String> currency;
  final Value<int?> currentMileage;
  final Value<String?> vehicleType;
  final Value<String?> fuelType;
  final Value<String?> distanceUnit;
  final Value<String?> photoUrl;
  final Value<String?> photoPublicId;
  final Value<String> docsStatusJson;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> cachedAt;
  final Value<int> rowid;
  const VehiclesCompanion({
    this.id = const Value.absent(),
    this.make = const Value.absent(),
    this.model = const Value.absent(),
    this.year = const Value.absent(),
    this.registrationNumber = const Value.absent(),
    this.vin = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.purchasePriceCents = const Value.absent(),
    this.currency = const Value.absent(),
    this.currentMileage = const Value.absent(),
    this.vehicleType = const Value.absent(),
    this.fuelType = const Value.absent(),
    this.distanceUnit = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.photoPublicId = const Value.absent(),
    this.docsStatusJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VehiclesCompanion.insert({
    required String id,
    required String make,
    required String model,
    this.year = const Value.absent(),
    this.registrationNumber = const Value.absent(),
    this.vin = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.purchasePriceCents = const Value.absent(),
    this.currency = const Value.absent(),
    this.currentMileage = const Value.absent(),
    this.vehicleType = const Value.absent(),
    this.fuelType = const Value.absent(),
    this.distanceUnit = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.photoPublicId = const Value.absent(),
    this.docsStatusJson = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    required int cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       make = Value(make),
       model = Value(model),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       cachedAt = Value(cachedAt);
  static Insertable<VehicleRow> custom({
    Expression<String>? id,
    Expression<String>? make,
    Expression<String>? model,
    Expression<int>? year,
    Expression<String>? registrationNumber,
    Expression<String>? vin,
    Expression<String>? purchaseDate,
    Expression<int>? purchasePriceCents,
    Expression<String>? currency,
    Expression<int>? currentMileage,
    Expression<String>? vehicleType,
    Expression<String>? fuelType,
    Expression<String>? distanceUnit,
    Expression<String>? photoUrl,
    Expression<String>? photoPublicId,
    Expression<String>? docsStatusJson,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (make != null) 'make': make,
      if (model != null) 'model': model,
      if (year != null) 'year': year,
      if (registrationNumber != null) 'registration_number': registrationNumber,
      if (vin != null) 'vin': vin,
      if (purchaseDate != null) 'purchase_date': purchaseDate,
      if (purchasePriceCents != null)
        'purchase_price_cents': purchasePriceCents,
      if (currency != null) 'currency': currency,
      if (currentMileage != null) 'current_mileage': currentMileage,
      if (vehicleType != null) 'vehicle_type': vehicleType,
      if (fuelType != null) 'fuel_type': fuelType,
      if (distanceUnit != null) 'distance_unit': distanceUnit,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (photoPublicId != null) 'photo_public_id': photoPublicId,
      if (docsStatusJson != null) 'docs_status_json': docsStatusJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VehiclesCompanion copyWith({
    Value<String>? id,
    Value<String>? make,
    Value<String>? model,
    Value<int?>? year,
    Value<String?>? registrationNumber,
    Value<String?>? vin,
    Value<String?>? purchaseDate,
    Value<int?>? purchasePriceCents,
    Value<String>? currency,
    Value<int?>? currentMileage,
    Value<String?>? vehicleType,
    Value<String?>? fuelType,
    Value<String?>? distanceUnit,
    Value<String?>? photoUrl,
    Value<String?>? photoPublicId,
    Value<String>? docsStatusJson,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<int>? cachedAt,
    Value<int>? rowid,
  }) {
    return VehiclesCompanion(
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
      docsStatusJson: docsStatusJson ?? this.docsStatusJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (make.present) {
      map['make'] = Variable<String>(make.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (registrationNumber.present) {
      map['registration_number'] = Variable<String>(registrationNumber.value);
    }
    if (vin.present) {
      map['vin'] = Variable<String>(vin.value);
    }
    if (purchaseDate.present) {
      map['purchase_date'] = Variable<String>(purchaseDate.value);
    }
    if (purchasePriceCents.present) {
      map['purchase_price_cents'] = Variable<int>(purchasePriceCents.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (currentMileage.present) {
      map['current_mileage'] = Variable<int>(currentMileage.value);
    }
    if (vehicleType.present) {
      map['vehicle_type'] = Variable<String>(vehicleType.value);
    }
    if (fuelType.present) {
      map['fuel_type'] = Variable<String>(fuelType.value);
    }
    if (distanceUnit.present) {
      map['distance_unit'] = Variable<String>(distanceUnit.value);
    }
    if (photoUrl.present) {
      map['photo_url'] = Variable<String>(photoUrl.value);
    }
    if (photoPublicId.present) {
      map['photo_public_id'] = Variable<String>(photoPublicId.value);
    }
    if (docsStatusJson.present) {
      map['docs_status_json'] = Variable<String>(docsStatusJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<int>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VehiclesCompanion(')
          ..write('id: $id, ')
          ..write('make: $make, ')
          ..write('model: $model, ')
          ..write('year: $year, ')
          ..write('registrationNumber: $registrationNumber, ')
          ..write('vin: $vin, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('purchasePriceCents: $purchasePriceCents, ')
          ..write('currency: $currency, ')
          ..write('currentMileage: $currentMileage, ')
          ..write('vehicleType: $vehicleType, ')
          ..write('fuelType: $fuelType, ')
          ..write('distanceUnit: $distanceUnit, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('photoPublicId: $photoPublicId, ')
          ..write('docsStatusJson: $docsStatusJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DashboardSnapshotsTable extends DashboardSnapshots
    with TableInfo<$DashboardSnapshotsTable, DashboardSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DashboardSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<int> cachedAt = GeneratedColumn<int>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, payload, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dashboard_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<DashboardSnapshot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DashboardSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DashboardSnapshot(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $DashboardSnapshotsTable createAlias(String alias) {
    return $DashboardSnapshotsTable(attachedDatabase, alias);
  }
}

class DashboardSnapshot extends DataClass
    implements Insertable<DashboardSnapshot> {
  final int id;
  final String payload;
  final int cachedAt;
  const DashboardSnapshot({
    required this.id,
    required this.payload,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['payload'] = Variable<String>(payload);
    map['cached_at'] = Variable<int>(cachedAt);
    return map;
  }

  DashboardSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return DashboardSnapshotsCompanion(
      id: Value(id),
      payload: Value(payload),
      cachedAt: Value(cachedAt),
    );
  }

  factory DashboardSnapshot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DashboardSnapshot(
      id: serializer.fromJson<int>(json['id']),
      payload: serializer.fromJson<String>(json['payload']),
      cachedAt: serializer.fromJson<int>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'payload': serializer.toJson<String>(payload),
      'cachedAt': serializer.toJson<int>(cachedAt),
    };
  }

  DashboardSnapshot copyWith({int? id, String? payload, int? cachedAt}) =>
      DashboardSnapshot(
        id: id ?? this.id,
        payload: payload ?? this.payload,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  DashboardSnapshot copyWithCompanion(DashboardSnapshotsCompanion data) {
    return DashboardSnapshot(
      id: data.id.present ? data.id.value : this.id,
      payload: data.payload.present ? data.payload.value : this.payload,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DashboardSnapshot(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, payload, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DashboardSnapshot &&
          other.id == this.id &&
          other.payload == this.payload &&
          other.cachedAt == this.cachedAt);
}

class DashboardSnapshotsCompanion extends UpdateCompanion<DashboardSnapshot> {
  final Value<int> id;
  final Value<String> payload;
  final Value<int> cachedAt;
  const DashboardSnapshotsCompanion({
    this.id = const Value.absent(),
    this.payload = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  DashboardSnapshotsCompanion.insert({
    this.id = const Value.absent(),
    required String payload,
    required int cachedAt,
  }) : payload = Value(payload),
       cachedAt = Value(cachedAt);
  static Insertable<DashboardSnapshot> custom({
    Expression<int>? id,
    Expression<String>? payload,
    Expression<int>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  DashboardSnapshotsCompanion copyWith({
    Value<int>? id,
    Value<String>? payload,
    Value<int>? cachedAt,
  }) {
    return DashboardSnapshotsCompanion(
      id: id ?? this.id,
      payload: payload ?? this.payload,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<int>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DashboardSnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VehiclesTable vehicles = $VehiclesTable(this);
  late final $DashboardSnapshotsTable dashboardSnapshots =
      $DashboardSnapshotsTable(this);
  late final VehiclesDao vehiclesDao = VehiclesDao(this as AppDatabase);
  late final DashboardDao dashboardDao = DashboardDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    vehicles,
    dashboardSnapshots,
  ];
}

typedef $$VehiclesTableCreateCompanionBuilder =
    VehiclesCompanion Function({
      required String id,
      required String make,
      required String model,
      Value<int?> year,
      Value<String?> registrationNumber,
      Value<String?> vin,
      Value<String?> purchaseDate,
      Value<int?> purchasePriceCents,
      Value<String> currency,
      Value<int?> currentMileage,
      Value<String?> vehicleType,
      Value<String?> fuelType,
      Value<String?> distanceUnit,
      Value<String?> photoUrl,
      Value<String?> photoPublicId,
      Value<String> docsStatusJson,
      required String createdAt,
      required String updatedAt,
      required int cachedAt,
      Value<int> rowid,
    });
typedef $$VehiclesTableUpdateCompanionBuilder =
    VehiclesCompanion Function({
      Value<String> id,
      Value<String> make,
      Value<String> model,
      Value<int?> year,
      Value<String?> registrationNumber,
      Value<String?> vin,
      Value<String?> purchaseDate,
      Value<int?> purchasePriceCents,
      Value<String> currency,
      Value<int?> currentMileage,
      Value<String?> vehicleType,
      Value<String?> fuelType,
      Value<String?> distanceUnit,
      Value<String?> photoUrl,
      Value<String?> photoPublicId,
      Value<String> docsStatusJson,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> cachedAt,
      Value<int> rowid,
    });

class $$VehiclesTableFilterComposer
    extends Composer<_$AppDatabase, $VehiclesTable> {
  $$VehiclesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get make => $composableBuilder(
    column: $table.make,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get registrationNumber => $composableBuilder(
    column: $table.registrationNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vin => $composableBuilder(
    column: $table.vin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get purchasePriceCents => $composableBuilder(
    column: $table.purchasePriceCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentMileage => $composableBuilder(
    column: $table.currentMileage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vehicleType => $composableBuilder(
    column: $table.vehicleType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fuelType => $composableBuilder(
    column: $table.fuelType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get distanceUnit => $composableBuilder(
    column: $table.distanceUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPublicId => $composableBuilder(
    column: $table.photoPublicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get docsStatusJson => $composableBuilder(
    column: $table.docsStatusJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VehiclesTableOrderingComposer
    extends Composer<_$AppDatabase, $VehiclesTable> {
  $$VehiclesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get make => $composableBuilder(
    column: $table.make,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get registrationNumber => $composableBuilder(
    column: $table.registrationNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vin => $composableBuilder(
    column: $table.vin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get purchasePriceCents => $composableBuilder(
    column: $table.purchasePriceCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentMileage => $composableBuilder(
    column: $table.currentMileage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vehicleType => $composableBuilder(
    column: $table.vehicleType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fuelType => $composableBuilder(
    column: $table.fuelType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get distanceUnit => $composableBuilder(
    column: $table.distanceUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPublicId => $composableBuilder(
    column: $table.photoPublicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get docsStatusJson => $composableBuilder(
    column: $table.docsStatusJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VehiclesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VehiclesTable> {
  $$VehiclesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get make =>
      $composableBuilder(column: $table.make, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get registrationNumber => $composableBuilder(
    column: $table.registrationNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get vin =>
      $composableBuilder(column: $table.vin, builder: (column) => column);

  GeneratedColumn<String> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get purchasePriceCents => $composableBuilder(
    column: $table.purchasePriceCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<int> get currentMileage => $composableBuilder(
    column: $table.currentMileage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get vehicleType => $composableBuilder(
    column: $table.vehicleType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fuelType =>
      $composableBuilder(column: $table.fuelType, builder: (column) => column);

  GeneratedColumn<String> get distanceUnit => $composableBuilder(
    column: $table.distanceUnit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get photoUrl =>
      $composableBuilder(column: $table.photoUrl, builder: (column) => column);

  GeneratedColumn<String> get photoPublicId => $composableBuilder(
    column: $table.photoPublicId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get docsStatusJson => $composableBuilder(
    column: $table.docsStatusJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$VehiclesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VehiclesTable,
          VehicleRow,
          $$VehiclesTableFilterComposer,
          $$VehiclesTableOrderingComposer,
          $$VehiclesTableAnnotationComposer,
          $$VehiclesTableCreateCompanionBuilder,
          $$VehiclesTableUpdateCompanionBuilder,
          (
            VehicleRow,
            BaseReferences<_$AppDatabase, $VehiclesTable, VehicleRow>,
          ),
          VehicleRow,
          PrefetchHooks Function()
        > {
  $$VehiclesTableTableManager(_$AppDatabase db, $VehiclesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VehiclesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VehiclesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VehiclesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> make = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> registrationNumber = const Value.absent(),
                Value<String?> vin = const Value.absent(),
                Value<String?> purchaseDate = const Value.absent(),
                Value<int?> purchasePriceCents = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<int?> currentMileage = const Value.absent(),
                Value<String?> vehicleType = const Value.absent(),
                Value<String?> fuelType = const Value.absent(),
                Value<String?> distanceUnit = const Value.absent(),
                Value<String?> photoUrl = const Value.absent(),
                Value<String?> photoPublicId = const Value.absent(),
                Value<String> docsStatusJson = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VehiclesCompanion(
                id: id,
                make: make,
                model: model,
                year: year,
                registrationNumber: registrationNumber,
                vin: vin,
                purchaseDate: purchaseDate,
                purchasePriceCents: purchasePriceCents,
                currency: currency,
                currentMileage: currentMileage,
                vehicleType: vehicleType,
                fuelType: fuelType,
                distanceUnit: distanceUnit,
                photoUrl: photoUrl,
                photoPublicId: photoPublicId,
                docsStatusJson: docsStatusJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String make,
                required String model,
                Value<int?> year = const Value.absent(),
                Value<String?> registrationNumber = const Value.absent(),
                Value<String?> vin = const Value.absent(),
                Value<String?> purchaseDate = const Value.absent(),
                Value<int?> purchasePriceCents = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<int?> currentMileage = const Value.absent(),
                Value<String?> vehicleType = const Value.absent(),
                Value<String?> fuelType = const Value.absent(),
                Value<String?> distanceUnit = const Value.absent(),
                Value<String?> photoUrl = const Value.absent(),
                Value<String?> photoPublicId = const Value.absent(),
                Value<String> docsStatusJson = const Value.absent(),
                required String createdAt,
                required String updatedAt,
                required int cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => VehiclesCompanion.insert(
                id: id,
                make: make,
                model: model,
                year: year,
                registrationNumber: registrationNumber,
                vin: vin,
                purchaseDate: purchaseDate,
                purchasePriceCents: purchasePriceCents,
                currency: currency,
                currentMileage: currentMileage,
                vehicleType: vehicleType,
                fuelType: fuelType,
                distanceUnit: distanceUnit,
                photoUrl: photoUrl,
                photoPublicId: photoPublicId,
                docsStatusJson: docsStatusJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VehiclesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VehiclesTable,
      VehicleRow,
      $$VehiclesTableFilterComposer,
      $$VehiclesTableOrderingComposer,
      $$VehiclesTableAnnotationComposer,
      $$VehiclesTableCreateCompanionBuilder,
      $$VehiclesTableUpdateCompanionBuilder,
      (VehicleRow, BaseReferences<_$AppDatabase, $VehiclesTable, VehicleRow>),
      VehicleRow,
      PrefetchHooks Function()
    >;
typedef $$DashboardSnapshotsTableCreateCompanionBuilder =
    DashboardSnapshotsCompanion Function({
      Value<int> id,
      required String payload,
      required int cachedAt,
    });
typedef $$DashboardSnapshotsTableUpdateCompanionBuilder =
    DashboardSnapshotsCompanion Function({
      Value<int> id,
      Value<String> payload,
      Value<int> cachedAt,
    });

class $$DashboardSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $DashboardSnapshotsTable> {
  $$DashboardSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DashboardSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $DashboardSnapshotsTable> {
  $$DashboardSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DashboardSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DashboardSnapshotsTable> {
  $$DashboardSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$DashboardSnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DashboardSnapshotsTable,
          DashboardSnapshot,
          $$DashboardSnapshotsTableFilterComposer,
          $$DashboardSnapshotsTableOrderingComposer,
          $$DashboardSnapshotsTableAnnotationComposer,
          $$DashboardSnapshotsTableCreateCompanionBuilder,
          $$DashboardSnapshotsTableUpdateCompanionBuilder,
          (
            DashboardSnapshot,
            BaseReferences<
              _$AppDatabase,
              $DashboardSnapshotsTable,
              DashboardSnapshot
            >,
          ),
          DashboardSnapshot,
          PrefetchHooks Function()
        > {
  $$DashboardSnapshotsTableTableManager(
    _$AppDatabase db,
    $DashboardSnapshotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DashboardSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DashboardSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DashboardSnapshotsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> cachedAt = const Value.absent(),
              }) => DashboardSnapshotsCompanion(
                id: id,
                payload: payload,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String payload,
                required int cachedAt,
              }) => DashboardSnapshotsCompanion.insert(
                id: id,
                payload: payload,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DashboardSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DashboardSnapshotsTable,
      DashboardSnapshot,
      $$DashboardSnapshotsTableFilterComposer,
      $$DashboardSnapshotsTableOrderingComposer,
      $$DashboardSnapshotsTableAnnotationComposer,
      $$DashboardSnapshotsTableCreateCompanionBuilder,
      $$DashboardSnapshotsTableUpdateCompanionBuilder,
      (
        DashboardSnapshot,
        BaseReferences<
          _$AppDatabase,
          $DashboardSnapshotsTable,
          DashboardSnapshot
        >,
      ),
      DashboardSnapshot,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VehiclesTableTableManager get vehicles =>
      $$VehiclesTableTableManager(_db, _db.vehicles);
  $$DashboardSnapshotsTableTableManager get dashboardSnapshots =>
      $$DashboardSnapshotsTableTableManager(_db, _db.dashboardSnapshots);
}
