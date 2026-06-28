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

mixin _$FuelLogsDaoMixin on DatabaseAccessor<AppDatabase> {
  $FuelLogsTable get fuelLogs => attachedDatabase.fuelLogs;
  FuelLogsDaoManager get managers => FuelLogsDaoManager(this);
}

class FuelLogsDaoManager {
  final _$FuelLogsDaoMixin _db;
  FuelLogsDaoManager(this._db);
  $$FuelLogsTableTableManager get fuelLogs =>
      $$FuelLogsTableTableManager(_db.attachedDatabase, _db.fuelLogs);
}

mixin _$MaintenanceDaoMixin on DatabaseAccessor<AppDatabase> {
  $MaintenanceRecordsTable get maintenanceRecords =>
      attachedDatabase.maintenanceRecords;
  MaintenanceDaoManager get managers => MaintenanceDaoManager(this);
}

class MaintenanceDaoManager {
  final _$MaintenanceDaoMixin _db;
  MaintenanceDaoManager(this._db);
  $$MaintenanceRecordsTableTableManager get maintenanceRecords =>
      $$MaintenanceRecordsTableTableManager(
        _db.attachedDatabase,
        _db.maintenanceRecords,
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

class $FuelLogsTable extends FuelLogs
    with TableInfo<$FuelLogsTable, FuelLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FuelLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vehicleIdMeta = const VerificationMeta(
    'vehicleId',
  );
  @override
  late final GeneratedColumn<String> vehicleId = GeneratedColumn<String>(
    'vehicle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _litersMeta = const VerificationMeta('liters');
  @override
  late final GeneratedColumn<double> liters = GeneratedColumn<double>(
    'liters',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceCentsMeta = const VerificationMeta(
    'priceCents',
  );
  @override
  late final GeneratedColumn<int> priceCents = GeneratedColumn<int>(
    'price_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  static const VerificationMeta _odometerMeta = const VerificationMeta(
    'odometer',
  );
  @override
  late final GeneratedColumn<int> odometer = GeneratedColumn<int>(
    'odometer',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isFullTankMeta = const VerificationMeta(
    'isFullTank',
  );
  @override
  late final GeneratedColumn<bool> isFullTank = GeneratedColumn<bool>(
    'is_full_tank',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_full_tank" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
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
    vehicleId,
    date,
    liters,
    priceCents,
    currency,
    odometer,
    isFullTank,
    notes,
    syncStatus,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fuel_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<FuelLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('vehicle_id')) {
      context.handle(
        _vehicleIdMeta,
        vehicleId.isAcceptableOrUnknown(data['vehicle_id']!, _vehicleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_vehicleIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('liters')) {
      context.handle(
        _litersMeta,
        liters.isAcceptableOrUnknown(data['liters']!, _litersMeta),
      );
    } else if (isInserting) {
      context.missing(_litersMeta);
    }
    if (data.containsKey('price_cents')) {
      context.handle(
        _priceCentsMeta,
        priceCents.isAcceptableOrUnknown(data['price_cents']!, _priceCentsMeta),
      );
    } else if (isInserting) {
      context.missing(_priceCentsMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('odometer')) {
      context.handle(
        _odometerMeta,
        odometer.isAcceptableOrUnknown(data['odometer']!, _odometerMeta),
      );
    } else if (isInserting) {
      context.missing(_odometerMeta);
    }
    if (data.containsKey('is_full_tank')) {
      context.handle(
        _isFullTankMeta,
        isFullTank.isAcceptableOrUnknown(
          data['is_full_tank']!,
          _isFullTankMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
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
  FuelLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FuelLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      vehicleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vehicle_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      liters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}liters'],
      )!,
      priceCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_cents'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      odometer: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}odometer'],
      )!,
      isFullTank: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_full_tank'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $FuelLogsTable createAlias(String alias) {
    return $FuelLogsTable(attachedDatabase, alias);
  }
}

class FuelLogRow extends DataClass implements Insertable<FuelLogRow> {
  final String id;
  final String vehicleId;
  final String date;
  final double liters;
  final int priceCents;
  final String currency;
  final int odometer;
  final bool isFullTank;
  final String? notes;
  final String syncStatus;
  final int cachedAt;
  const FuelLogRow({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.liters,
    required this.priceCents,
    required this.currency,
    required this.odometer,
    required this.isFullTank,
    this.notes,
    required this.syncStatus,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['vehicle_id'] = Variable<String>(vehicleId);
    map['date'] = Variable<String>(date);
    map['liters'] = Variable<double>(liters);
    map['price_cents'] = Variable<int>(priceCents);
    map['currency'] = Variable<String>(currency);
    map['odometer'] = Variable<int>(odometer);
    map['is_full_tank'] = Variable<bool>(isFullTank);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['cached_at'] = Variable<int>(cachedAt);
    return map;
  }

  FuelLogsCompanion toCompanion(bool nullToAbsent) {
    return FuelLogsCompanion(
      id: Value(id),
      vehicleId: Value(vehicleId),
      date: Value(date),
      liters: Value(liters),
      priceCents: Value(priceCents),
      currency: Value(currency),
      odometer: Value(odometer),
      isFullTank: Value(isFullTank),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      syncStatus: Value(syncStatus),
      cachedAt: Value(cachedAt),
    );
  }

  factory FuelLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FuelLogRow(
      id: serializer.fromJson<String>(json['id']),
      vehicleId: serializer.fromJson<String>(json['vehicleId']),
      date: serializer.fromJson<String>(json['date']),
      liters: serializer.fromJson<double>(json['liters']),
      priceCents: serializer.fromJson<int>(json['priceCents']),
      currency: serializer.fromJson<String>(json['currency']),
      odometer: serializer.fromJson<int>(json['odometer']),
      isFullTank: serializer.fromJson<bool>(json['isFullTank']),
      notes: serializer.fromJson<String?>(json['notes']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      cachedAt: serializer.fromJson<int>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'vehicleId': serializer.toJson<String>(vehicleId),
      'date': serializer.toJson<String>(date),
      'liters': serializer.toJson<double>(liters),
      'priceCents': serializer.toJson<int>(priceCents),
      'currency': serializer.toJson<String>(currency),
      'odometer': serializer.toJson<int>(odometer),
      'isFullTank': serializer.toJson<bool>(isFullTank),
      'notes': serializer.toJson<String?>(notes),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'cachedAt': serializer.toJson<int>(cachedAt),
    };
  }

  FuelLogRow copyWith({
    String? id,
    String? vehicleId,
    String? date,
    double? liters,
    int? priceCents,
    String? currency,
    int? odometer,
    bool? isFullTank,
    Value<String?> notes = const Value.absent(),
    String? syncStatus,
    int? cachedAt,
  }) => FuelLogRow(
    id: id ?? this.id,
    vehicleId: vehicleId ?? this.vehicleId,
    date: date ?? this.date,
    liters: liters ?? this.liters,
    priceCents: priceCents ?? this.priceCents,
    currency: currency ?? this.currency,
    odometer: odometer ?? this.odometer,
    isFullTank: isFullTank ?? this.isFullTank,
    notes: notes.present ? notes.value : this.notes,
    syncStatus: syncStatus ?? this.syncStatus,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  FuelLogRow copyWithCompanion(FuelLogsCompanion data) {
    return FuelLogRow(
      id: data.id.present ? data.id.value : this.id,
      vehicleId: data.vehicleId.present ? data.vehicleId.value : this.vehicleId,
      date: data.date.present ? data.date.value : this.date,
      liters: data.liters.present ? data.liters.value : this.liters,
      priceCents: data.priceCents.present
          ? data.priceCents.value
          : this.priceCents,
      currency: data.currency.present ? data.currency.value : this.currency,
      odometer: data.odometer.present ? data.odometer.value : this.odometer,
      isFullTank: data.isFullTank.present
          ? data.isFullTank.value
          : this.isFullTank,
      notes: data.notes.present ? data.notes.value : this.notes,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FuelLogRow(')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('date: $date, ')
          ..write('liters: $liters, ')
          ..write('priceCents: $priceCents, ')
          ..write('currency: $currency, ')
          ..write('odometer: $odometer, ')
          ..write('isFullTank: $isFullTank, ')
          ..write('notes: $notes, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    vehicleId,
    date,
    liters,
    priceCents,
    currency,
    odometer,
    isFullTank,
    notes,
    syncStatus,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FuelLogRow &&
          other.id == this.id &&
          other.vehicleId == this.vehicleId &&
          other.date == this.date &&
          other.liters == this.liters &&
          other.priceCents == this.priceCents &&
          other.currency == this.currency &&
          other.odometer == this.odometer &&
          other.isFullTank == this.isFullTank &&
          other.notes == this.notes &&
          other.syncStatus == this.syncStatus &&
          other.cachedAt == this.cachedAt);
}

class FuelLogsCompanion extends UpdateCompanion<FuelLogRow> {
  final Value<String> id;
  final Value<String> vehicleId;
  final Value<String> date;
  final Value<double> liters;
  final Value<int> priceCents;
  final Value<String> currency;
  final Value<int> odometer;
  final Value<bool> isFullTank;
  final Value<String?> notes;
  final Value<String> syncStatus;
  final Value<int> cachedAt;
  final Value<int> rowid;
  const FuelLogsCompanion({
    this.id = const Value.absent(),
    this.vehicleId = const Value.absent(),
    this.date = const Value.absent(),
    this.liters = const Value.absent(),
    this.priceCents = const Value.absent(),
    this.currency = const Value.absent(),
    this.odometer = const Value.absent(),
    this.isFullTank = const Value.absent(),
    this.notes = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FuelLogsCompanion.insert({
    required String id,
    required String vehicleId,
    required String date,
    required double liters,
    required int priceCents,
    this.currency = const Value.absent(),
    required int odometer,
    this.isFullTank = const Value.absent(),
    this.notes = const Value.absent(),
    this.syncStatus = const Value.absent(),
    required int cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       vehicleId = Value(vehicleId),
       date = Value(date),
       liters = Value(liters),
       priceCents = Value(priceCents),
       odometer = Value(odometer),
       cachedAt = Value(cachedAt);
  static Insertable<FuelLogRow> custom({
    Expression<String>? id,
    Expression<String>? vehicleId,
    Expression<String>? date,
    Expression<double>? liters,
    Expression<int>? priceCents,
    Expression<String>? currency,
    Expression<int>? odometer,
    Expression<bool>? isFullTank,
    Expression<String>? notes,
    Expression<String>? syncStatus,
    Expression<int>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (date != null) 'date': date,
      if (liters != null) 'liters': liters,
      if (priceCents != null) 'price_cents': priceCents,
      if (currency != null) 'currency': currency,
      if (odometer != null) 'odometer': odometer,
      if (isFullTank != null) 'is_full_tank': isFullTank,
      if (notes != null) 'notes': notes,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FuelLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? vehicleId,
    Value<String>? date,
    Value<double>? liters,
    Value<int>? priceCents,
    Value<String>? currency,
    Value<int>? odometer,
    Value<bool>? isFullTank,
    Value<String?>? notes,
    Value<String>? syncStatus,
    Value<int>? cachedAt,
    Value<int>? rowid,
  }) {
    return FuelLogsCompanion(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      date: date ?? this.date,
      liters: liters ?? this.liters,
      priceCents: priceCents ?? this.priceCents,
      currency: currency ?? this.currency,
      odometer: odometer ?? this.odometer,
      isFullTank: isFullTank ?? this.isFullTank,
      notes: notes ?? this.notes,
      syncStatus: syncStatus ?? this.syncStatus,
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
    if (vehicleId.present) {
      map['vehicle_id'] = Variable<String>(vehicleId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (liters.present) {
      map['liters'] = Variable<double>(liters.value);
    }
    if (priceCents.present) {
      map['price_cents'] = Variable<int>(priceCents.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (odometer.present) {
      map['odometer'] = Variable<int>(odometer.value);
    }
    if (isFullTank.present) {
      map['is_full_tank'] = Variable<bool>(isFullTank.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
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
    return (StringBuffer('FuelLogsCompanion(')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('date: $date, ')
          ..write('liters: $liters, ')
          ..write('priceCents: $priceCents, ')
          ..write('currency: $currency, ')
          ..write('odometer: $odometer, ')
          ..write('isFullTank: $isFullTank, ')
          ..write('notes: $notes, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MaintenanceRecordsTable extends MaintenanceRecords
    with TableInfo<$MaintenanceRecordsTable, MaintenanceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MaintenanceRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vehicleIdMeta = const VerificationMeta(
    'vehicleId',
  );
  @override
  late final GeneratedColumn<String> vehicleId = GeneratedColumn<String>(
    'vehicle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serviceTypeMeta = const VerificationMeta(
    'serviceType',
  );
  @override
  late final GeneratedColumn<String> serviceType = GeneratedColumn<String>(
    'service_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _costCentsMeta = const VerificationMeta(
    'costCents',
  );
  @override
  late final GeneratedColumn<int> costCents = GeneratedColumn<int>(
    'cost_cents',
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
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _odometerMeta = const VerificationMeta(
    'odometer',
  );
  @override
  late final GeneratedColumn<int> odometer = GeneratedColumn<int>(
    'odometer',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _workshopMeta = const VerificationMeta(
    'workshop',
  );
  @override
  late final GeneratedColumn<String> workshop = GeneratedColumn<String>(
    'workshop',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
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
    vehicleId,
    date,
    serviceType,
    category,
    costCents,
    currency,
    odometer,
    workshop,
    notes,
    source,
    syncStatus,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'maintenance_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<MaintenanceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('vehicle_id')) {
      context.handle(
        _vehicleIdMeta,
        vehicleId.isAcceptableOrUnknown(data['vehicle_id']!, _vehicleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_vehicleIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('service_type')) {
      context.handle(
        _serviceTypeMeta,
        serviceType.isAcceptableOrUnknown(
          data['service_type']!,
          _serviceTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_serviceTypeMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('cost_cents')) {
      context.handle(
        _costCentsMeta,
        costCents.isAcceptableOrUnknown(data['cost_cents']!, _costCentsMeta),
      );
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('odometer')) {
      context.handle(
        _odometerMeta,
        odometer.isAcceptableOrUnknown(data['odometer']!, _odometerMeta),
      );
    }
    if (data.containsKey('workshop')) {
      context.handle(
        _workshopMeta,
        workshop.isAcceptableOrUnknown(data['workshop']!, _workshopMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
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
  MaintenanceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MaintenanceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      vehicleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vehicle_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      serviceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}service_type'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      costCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cost_cents'],
      ),
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      ),
      odometer: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}odometer'],
      ),
      workshop: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workshop'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $MaintenanceRecordsTable createAlias(String alias) {
    return $MaintenanceRecordsTable(attachedDatabase, alias);
  }
}

class MaintenanceRow extends DataClass implements Insertable<MaintenanceRow> {
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
  final String syncStatus;
  final int cachedAt;
  const MaintenanceRow({
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
    required this.syncStatus,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['vehicle_id'] = Variable<String>(vehicleId);
    map['date'] = Variable<String>(date);
    map['service_type'] = Variable<String>(serviceType);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || costCents != null) {
      map['cost_cents'] = Variable<int>(costCents);
    }
    if (!nullToAbsent || currency != null) {
      map['currency'] = Variable<String>(currency);
    }
    if (!nullToAbsent || odometer != null) {
      map['odometer'] = Variable<int>(odometer);
    }
    if (!nullToAbsent || workshop != null) {
      map['workshop'] = Variable<String>(workshop);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['source'] = Variable<String>(source);
    map['sync_status'] = Variable<String>(syncStatus);
    map['cached_at'] = Variable<int>(cachedAt);
    return map;
  }

  MaintenanceRecordsCompanion toCompanion(bool nullToAbsent) {
    return MaintenanceRecordsCompanion(
      id: Value(id),
      vehicleId: Value(vehicleId),
      date: Value(date),
      serviceType: Value(serviceType),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      costCents: costCents == null && nullToAbsent
          ? const Value.absent()
          : Value(costCents),
      currency: currency == null && nullToAbsent
          ? const Value.absent()
          : Value(currency),
      odometer: odometer == null && nullToAbsent
          ? const Value.absent()
          : Value(odometer),
      workshop: workshop == null && nullToAbsent
          ? const Value.absent()
          : Value(workshop),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      source: Value(source),
      syncStatus: Value(syncStatus),
      cachedAt: Value(cachedAt),
    );
  }

  factory MaintenanceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MaintenanceRow(
      id: serializer.fromJson<String>(json['id']),
      vehicleId: serializer.fromJson<String>(json['vehicleId']),
      date: serializer.fromJson<String>(json['date']),
      serviceType: serializer.fromJson<String>(json['serviceType']),
      category: serializer.fromJson<String?>(json['category']),
      costCents: serializer.fromJson<int?>(json['costCents']),
      currency: serializer.fromJson<String?>(json['currency']),
      odometer: serializer.fromJson<int?>(json['odometer']),
      workshop: serializer.fromJson<String?>(json['workshop']),
      notes: serializer.fromJson<String?>(json['notes']),
      source: serializer.fromJson<String>(json['source']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      cachedAt: serializer.fromJson<int>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'vehicleId': serializer.toJson<String>(vehicleId),
      'date': serializer.toJson<String>(date),
      'serviceType': serializer.toJson<String>(serviceType),
      'category': serializer.toJson<String?>(category),
      'costCents': serializer.toJson<int?>(costCents),
      'currency': serializer.toJson<String?>(currency),
      'odometer': serializer.toJson<int?>(odometer),
      'workshop': serializer.toJson<String?>(workshop),
      'notes': serializer.toJson<String?>(notes),
      'source': serializer.toJson<String>(source),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'cachedAt': serializer.toJson<int>(cachedAt),
    };
  }

  MaintenanceRow copyWith({
    String? id,
    String? vehicleId,
    String? date,
    String? serviceType,
    Value<String?> category = const Value.absent(),
    Value<int?> costCents = const Value.absent(),
    Value<String?> currency = const Value.absent(),
    Value<int?> odometer = const Value.absent(),
    Value<String?> workshop = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    String? source,
    String? syncStatus,
    int? cachedAt,
  }) => MaintenanceRow(
    id: id ?? this.id,
    vehicleId: vehicleId ?? this.vehicleId,
    date: date ?? this.date,
    serviceType: serviceType ?? this.serviceType,
    category: category.present ? category.value : this.category,
    costCents: costCents.present ? costCents.value : this.costCents,
    currency: currency.present ? currency.value : this.currency,
    odometer: odometer.present ? odometer.value : this.odometer,
    workshop: workshop.present ? workshop.value : this.workshop,
    notes: notes.present ? notes.value : this.notes,
    source: source ?? this.source,
    syncStatus: syncStatus ?? this.syncStatus,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  MaintenanceRow copyWithCompanion(MaintenanceRecordsCompanion data) {
    return MaintenanceRow(
      id: data.id.present ? data.id.value : this.id,
      vehicleId: data.vehicleId.present ? data.vehicleId.value : this.vehicleId,
      date: data.date.present ? data.date.value : this.date,
      serviceType: data.serviceType.present
          ? data.serviceType.value
          : this.serviceType,
      category: data.category.present ? data.category.value : this.category,
      costCents: data.costCents.present ? data.costCents.value : this.costCents,
      currency: data.currency.present ? data.currency.value : this.currency,
      odometer: data.odometer.present ? data.odometer.value : this.odometer,
      workshop: data.workshop.present ? data.workshop.value : this.workshop,
      notes: data.notes.present ? data.notes.value : this.notes,
      source: data.source.present ? data.source.value : this.source,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MaintenanceRow(')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('date: $date, ')
          ..write('serviceType: $serviceType, ')
          ..write('category: $category, ')
          ..write('costCents: $costCents, ')
          ..write('currency: $currency, ')
          ..write('odometer: $odometer, ')
          ..write('workshop: $workshop, ')
          ..write('notes: $notes, ')
          ..write('source: $source, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    vehicleId,
    date,
    serviceType,
    category,
    costCents,
    currency,
    odometer,
    workshop,
    notes,
    source,
    syncStatus,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MaintenanceRow &&
          other.id == this.id &&
          other.vehicleId == this.vehicleId &&
          other.date == this.date &&
          other.serviceType == this.serviceType &&
          other.category == this.category &&
          other.costCents == this.costCents &&
          other.currency == this.currency &&
          other.odometer == this.odometer &&
          other.workshop == this.workshop &&
          other.notes == this.notes &&
          other.source == this.source &&
          other.syncStatus == this.syncStatus &&
          other.cachedAt == this.cachedAt);
}

class MaintenanceRecordsCompanion extends UpdateCompanion<MaintenanceRow> {
  final Value<String> id;
  final Value<String> vehicleId;
  final Value<String> date;
  final Value<String> serviceType;
  final Value<String?> category;
  final Value<int?> costCents;
  final Value<String?> currency;
  final Value<int?> odometer;
  final Value<String?> workshop;
  final Value<String?> notes;
  final Value<String> source;
  final Value<String> syncStatus;
  final Value<int> cachedAt;
  final Value<int> rowid;
  const MaintenanceRecordsCompanion({
    this.id = const Value.absent(),
    this.vehicleId = const Value.absent(),
    this.date = const Value.absent(),
    this.serviceType = const Value.absent(),
    this.category = const Value.absent(),
    this.costCents = const Value.absent(),
    this.currency = const Value.absent(),
    this.odometer = const Value.absent(),
    this.workshop = const Value.absent(),
    this.notes = const Value.absent(),
    this.source = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MaintenanceRecordsCompanion.insert({
    required String id,
    required String vehicleId,
    required String date,
    required String serviceType,
    this.category = const Value.absent(),
    this.costCents = const Value.absent(),
    this.currency = const Value.absent(),
    this.odometer = const Value.absent(),
    this.workshop = const Value.absent(),
    this.notes = const Value.absent(),
    this.source = const Value.absent(),
    this.syncStatus = const Value.absent(),
    required int cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       vehicleId = Value(vehicleId),
       date = Value(date),
       serviceType = Value(serviceType),
       cachedAt = Value(cachedAt);
  static Insertable<MaintenanceRow> custom({
    Expression<String>? id,
    Expression<String>? vehicleId,
    Expression<String>? date,
    Expression<String>? serviceType,
    Expression<String>? category,
    Expression<int>? costCents,
    Expression<String>? currency,
    Expression<int>? odometer,
    Expression<String>? workshop,
    Expression<String>? notes,
    Expression<String>? source,
    Expression<String>? syncStatus,
    Expression<int>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (date != null) 'date': date,
      if (serviceType != null) 'service_type': serviceType,
      if (category != null) 'category': category,
      if (costCents != null) 'cost_cents': costCents,
      if (currency != null) 'currency': currency,
      if (odometer != null) 'odometer': odometer,
      if (workshop != null) 'workshop': workshop,
      if (notes != null) 'notes': notes,
      if (source != null) 'source': source,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MaintenanceRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? vehicleId,
    Value<String>? date,
    Value<String>? serviceType,
    Value<String?>? category,
    Value<int?>? costCents,
    Value<String?>? currency,
    Value<int?>? odometer,
    Value<String?>? workshop,
    Value<String?>? notes,
    Value<String>? source,
    Value<String>? syncStatus,
    Value<int>? cachedAt,
    Value<int>? rowid,
  }) {
    return MaintenanceRecordsCompanion(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      date: date ?? this.date,
      serviceType: serviceType ?? this.serviceType,
      category: category ?? this.category,
      costCents: costCents ?? this.costCents,
      currency: currency ?? this.currency,
      odometer: odometer ?? this.odometer,
      workshop: workshop ?? this.workshop,
      notes: notes ?? this.notes,
      source: source ?? this.source,
      syncStatus: syncStatus ?? this.syncStatus,
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
    if (vehicleId.present) {
      map['vehicle_id'] = Variable<String>(vehicleId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (serviceType.present) {
      map['service_type'] = Variable<String>(serviceType.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (costCents.present) {
      map['cost_cents'] = Variable<int>(costCents.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (odometer.present) {
      map['odometer'] = Variable<int>(odometer.value);
    }
    if (workshop.present) {
      map['workshop'] = Variable<String>(workshop.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
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
    return (StringBuffer('MaintenanceRecordsCompanion(')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('date: $date, ')
          ..write('serviceType: $serviceType, ')
          ..write('category: $category, ')
          ..write('costCents: $costCents, ')
          ..write('currency: $currency, ')
          ..write('odometer: $odometer, ')
          ..write('workshop: $workshop, ')
          ..write('notes: $notes, ')
          ..write('source: $source, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
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
  late final $FuelLogsTable fuelLogs = $FuelLogsTable(this);
  late final $MaintenanceRecordsTable maintenanceRecords =
      $MaintenanceRecordsTable(this);
  late final VehiclesDao vehiclesDao = VehiclesDao(this as AppDatabase);
  late final DashboardDao dashboardDao = DashboardDao(this as AppDatabase);
  late final FuelLogsDao fuelLogsDao = FuelLogsDao(this as AppDatabase);
  late final MaintenanceDao maintenanceDao = MaintenanceDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    vehicles,
    dashboardSnapshots,
    fuelLogs,
    maintenanceRecords,
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
typedef $$FuelLogsTableCreateCompanionBuilder =
    FuelLogsCompanion Function({
      required String id,
      required String vehicleId,
      required String date,
      required double liters,
      required int priceCents,
      Value<String> currency,
      required int odometer,
      Value<bool> isFullTank,
      Value<String?> notes,
      Value<String> syncStatus,
      required int cachedAt,
      Value<int> rowid,
    });
typedef $$FuelLogsTableUpdateCompanionBuilder =
    FuelLogsCompanion Function({
      Value<String> id,
      Value<String> vehicleId,
      Value<String> date,
      Value<double> liters,
      Value<int> priceCents,
      Value<String> currency,
      Value<int> odometer,
      Value<bool> isFullTank,
      Value<String?> notes,
      Value<String> syncStatus,
      Value<int> cachedAt,
      Value<int> rowid,
    });

class $$FuelLogsTableFilterComposer
    extends Composer<_$AppDatabase, $FuelLogsTable> {
  $$FuelLogsTableFilterComposer({
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

  ColumnFilters<String> get vehicleId => $composableBuilder(
    column: $table.vehicleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get liters => $composableBuilder(
    column: $table.liters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priceCents => $composableBuilder(
    column: $table.priceCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get odometer => $composableBuilder(
    column: $table.odometer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFullTank => $composableBuilder(
    column: $table.isFullTank,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FuelLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $FuelLogsTable> {
  $$FuelLogsTableOrderingComposer({
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

  ColumnOrderings<String> get vehicleId => $composableBuilder(
    column: $table.vehicleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get liters => $composableBuilder(
    column: $table.liters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priceCents => $composableBuilder(
    column: $table.priceCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get odometer => $composableBuilder(
    column: $table.odometer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFullTank => $composableBuilder(
    column: $table.isFullTank,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FuelLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FuelLogsTable> {
  $$FuelLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get vehicleId =>
      $composableBuilder(column: $table.vehicleId, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get liters =>
      $composableBuilder(column: $table.liters, builder: (column) => column);

  GeneratedColumn<int> get priceCents => $composableBuilder(
    column: $table.priceCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<int> get odometer =>
      $composableBuilder(column: $table.odometer, builder: (column) => column);

  GeneratedColumn<bool> get isFullTank => $composableBuilder(
    column: $table.isFullTank,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$FuelLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FuelLogsTable,
          FuelLogRow,
          $$FuelLogsTableFilterComposer,
          $$FuelLogsTableOrderingComposer,
          $$FuelLogsTableAnnotationComposer,
          $$FuelLogsTableCreateCompanionBuilder,
          $$FuelLogsTableUpdateCompanionBuilder,
          (
            FuelLogRow,
            BaseReferences<_$AppDatabase, $FuelLogsTable, FuelLogRow>,
          ),
          FuelLogRow,
          PrefetchHooks Function()
        > {
  $$FuelLogsTableTableManager(_$AppDatabase db, $FuelLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FuelLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FuelLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FuelLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> vehicleId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<double> liters = const Value.absent(),
                Value<int> priceCents = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<int> odometer = const Value.absent(),
                Value<bool> isFullTank = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FuelLogsCompanion(
                id: id,
                vehicleId: vehicleId,
                date: date,
                liters: liters,
                priceCents: priceCents,
                currency: currency,
                odometer: odometer,
                isFullTank: isFullTank,
                notes: notes,
                syncStatus: syncStatus,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String vehicleId,
                required String date,
                required double liters,
                required int priceCents,
                Value<String> currency = const Value.absent(),
                required int odometer,
                Value<bool> isFullTank = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                required int cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => FuelLogsCompanion.insert(
                id: id,
                vehicleId: vehicleId,
                date: date,
                liters: liters,
                priceCents: priceCents,
                currency: currency,
                odometer: odometer,
                isFullTank: isFullTank,
                notes: notes,
                syncStatus: syncStatus,
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

typedef $$FuelLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FuelLogsTable,
      FuelLogRow,
      $$FuelLogsTableFilterComposer,
      $$FuelLogsTableOrderingComposer,
      $$FuelLogsTableAnnotationComposer,
      $$FuelLogsTableCreateCompanionBuilder,
      $$FuelLogsTableUpdateCompanionBuilder,
      (FuelLogRow, BaseReferences<_$AppDatabase, $FuelLogsTable, FuelLogRow>),
      FuelLogRow,
      PrefetchHooks Function()
    >;
typedef $$MaintenanceRecordsTableCreateCompanionBuilder =
    MaintenanceRecordsCompanion Function({
      required String id,
      required String vehicleId,
      required String date,
      required String serviceType,
      Value<String?> category,
      Value<int?> costCents,
      Value<String?> currency,
      Value<int?> odometer,
      Value<String?> workshop,
      Value<String?> notes,
      Value<String> source,
      Value<String> syncStatus,
      required int cachedAt,
      Value<int> rowid,
    });
typedef $$MaintenanceRecordsTableUpdateCompanionBuilder =
    MaintenanceRecordsCompanion Function({
      Value<String> id,
      Value<String> vehicleId,
      Value<String> date,
      Value<String> serviceType,
      Value<String?> category,
      Value<int?> costCents,
      Value<String?> currency,
      Value<int?> odometer,
      Value<String?> workshop,
      Value<String?> notes,
      Value<String> source,
      Value<String> syncStatus,
      Value<int> cachedAt,
      Value<int> rowid,
    });

class $$MaintenanceRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $MaintenanceRecordsTable> {
  $$MaintenanceRecordsTableFilterComposer({
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

  ColumnFilters<String> get vehicleId => $composableBuilder(
    column: $table.vehicleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serviceType => $composableBuilder(
    column: $table.serviceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get costCents => $composableBuilder(
    column: $table.costCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get odometer => $composableBuilder(
    column: $table.odometer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workshop => $composableBuilder(
    column: $table.workshop,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MaintenanceRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $MaintenanceRecordsTable> {
  $$MaintenanceRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get vehicleId => $composableBuilder(
    column: $table.vehicleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serviceType => $composableBuilder(
    column: $table.serviceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get costCents => $composableBuilder(
    column: $table.costCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get odometer => $composableBuilder(
    column: $table.odometer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workshop => $composableBuilder(
    column: $table.workshop,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MaintenanceRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MaintenanceRecordsTable> {
  $$MaintenanceRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get vehicleId =>
      $composableBuilder(column: $table.vehicleId, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get serviceType => $composableBuilder(
    column: $table.serviceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get costCents =>
      $composableBuilder(column: $table.costCents, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<int> get odometer =>
      $composableBuilder(column: $table.odometer, builder: (column) => column);

  GeneratedColumn<String> get workshop =>
      $composableBuilder(column: $table.workshop, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$MaintenanceRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MaintenanceRecordsTable,
          MaintenanceRow,
          $$MaintenanceRecordsTableFilterComposer,
          $$MaintenanceRecordsTableOrderingComposer,
          $$MaintenanceRecordsTableAnnotationComposer,
          $$MaintenanceRecordsTableCreateCompanionBuilder,
          $$MaintenanceRecordsTableUpdateCompanionBuilder,
          (
            MaintenanceRow,
            BaseReferences<
              _$AppDatabase,
              $MaintenanceRecordsTable,
              MaintenanceRow
            >,
          ),
          MaintenanceRow,
          PrefetchHooks Function()
        > {
  $$MaintenanceRecordsTableTableManager(
    _$AppDatabase db,
    $MaintenanceRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MaintenanceRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MaintenanceRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MaintenanceRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> vehicleId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> serviceType = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<int?> costCents = const Value.absent(),
                Value<String?> currency = const Value.absent(),
                Value<int?> odometer = const Value.absent(),
                Value<String?> workshop = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MaintenanceRecordsCompanion(
                id: id,
                vehicleId: vehicleId,
                date: date,
                serviceType: serviceType,
                category: category,
                costCents: costCents,
                currency: currency,
                odometer: odometer,
                workshop: workshop,
                notes: notes,
                source: source,
                syncStatus: syncStatus,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String vehicleId,
                required String date,
                required String serviceType,
                Value<String?> category = const Value.absent(),
                Value<int?> costCents = const Value.absent(),
                Value<String?> currency = const Value.absent(),
                Value<int?> odometer = const Value.absent(),
                Value<String?> workshop = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                required int cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => MaintenanceRecordsCompanion.insert(
                id: id,
                vehicleId: vehicleId,
                date: date,
                serviceType: serviceType,
                category: category,
                costCents: costCents,
                currency: currency,
                odometer: odometer,
                workshop: workshop,
                notes: notes,
                source: source,
                syncStatus: syncStatus,
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

typedef $$MaintenanceRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MaintenanceRecordsTable,
      MaintenanceRow,
      $$MaintenanceRecordsTableFilterComposer,
      $$MaintenanceRecordsTableOrderingComposer,
      $$MaintenanceRecordsTableAnnotationComposer,
      $$MaintenanceRecordsTableCreateCompanionBuilder,
      $$MaintenanceRecordsTableUpdateCompanionBuilder,
      (
        MaintenanceRow,
        BaseReferences<_$AppDatabase, $MaintenanceRecordsTable, MaintenanceRow>,
      ),
      MaintenanceRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VehiclesTableTableManager get vehicles =>
      $$VehiclesTableTableManager(_db, _db.vehicles);
  $$DashboardSnapshotsTableTableManager get dashboardSnapshots =>
      $$DashboardSnapshotsTableTableManager(_db, _db.dashboardSnapshots);
  $$FuelLogsTableTableManager get fuelLogs =>
      $$FuelLogsTableTableManager(_db, _db.fuelLogs);
  $$MaintenanceRecordsTableTableManager get maintenanceRecords =>
      $$MaintenanceRecordsTableTableManager(_db, _db.maintenanceRecords);
}
