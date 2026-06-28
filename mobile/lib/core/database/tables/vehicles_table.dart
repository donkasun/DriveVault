import 'package:drift/drift.dart';

@DataClassName('VehicleRow')
class Vehicles extends Table {
  TextColumn get id => text()();
  TextColumn get make => text()();
  TextColumn get model => text()();
  IntColumn get year => integer().nullable()();
  TextColumn get registrationNumber => text().nullable()();
  TextColumn get vin => text().nullable()();
  TextColumn get purchaseDate => text().nullable()();
  IntColumn get purchasePriceCents => integer().nullable()();
  TextColumn get currency => text().withDefault(const Constant('LKR'))();
  IntColumn get currentMileage => integer().nullable()();
  TextColumn get vehicleType => text().nullable()();
  TextColumn get fuelType => text().nullable()();
  TextColumn get distanceUnit => text().nullable()();
  TextColumn get photoUrl => text().nullable()();
  TextColumn get photoPublicId => text().nullable()();
  TextColumn get docsStatusJson =>
      text().withDefault(const Constant('{"state":"none","needsActionCount":0}'))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  IntColumn get cachedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
