import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drivevault/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('DashboardDao returns null when empty', () async {
    final row = await db.dashboardDao.get();
    expect(row, isNull);
  });

  test('DashboardDao upsert and get round-trips JSON', () async {
    final payload = jsonEncode({'vehicleCount': 2, 'monthlyFuelSpendCents': 5000});
    await db.dashboardDao.upsert(payload);
    final row = await db.dashboardDao.get();
    expect(row, isNotNull);
    final decoded = jsonDecode(row!.payload) as Map<String, dynamic>;
    expect(decoded['vehicleCount'], 2);
  });

  test('DashboardDao upsert is idempotent', () async {
    await db.dashboardDao.upsert('{"vehicleCount":1}');
    await db.dashboardDao.upsert('{"vehicleCount":2}');
    final row = await db.dashboardDao.get();
    final decoded = jsonDecode(row!.payload) as Map<String, dynamic>;
    expect(decoded['vehicleCount'], 2);
  });
}
