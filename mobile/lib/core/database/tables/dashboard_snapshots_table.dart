import 'package:drift/drift.dart';

class DashboardSnapshots extends Table {
  // Always a single row with id=1
  IntColumn get id => integer()();
  TextColumn get payload => text()();
  IntColumn get cachedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
