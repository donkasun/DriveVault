import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../network/api_client.dart';

// generateUuidV4 is defined here and imported by fuel_repository.dart and
// maintenance_repository.dart — the two files that produce optimistic writes.
// If a third write site emerges, move this to core/utils/uuid.dart instead.
String generateUuidV4() {
  final r = Random.secure();
  final bytes = List<int>.generate(16, (_) => r.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

class SyncService {
  static const _maxRetries = 3;

  final AppDatabase _db;
  final ApiClient _api;

  SyncService(this._db, this._api);

  Future<void> pushPending() async {
    await _pushPendingFuelLogs();
    await _pushPendingMaintenance();
  }

  Future<void> _pushPendingFuelLogs() async {
    final pending = await _db.fuelLogsDao.getPending();
    for (final row in pending) {
      bool success = false;
      for (int attempt = 0; attempt < _maxRetries; attempt++) {
        try {
          await _api.post(
            '/vehicles/${row.vehicleId}/fuel-logs',
            body: {
              'id': row.id,
              'date': row.date,
              'liters': row.liters,
              'priceCents': row.priceCents,
              'odometer': row.odometer,
              'isFullTank': row.isFullTank,
              if (row.notes != null) 'notes': row.notes,
            },
          );
          success = true;
          break;
        } catch (_) {
          // linear retry: try again on next iteration
        }
      }
      await _db.fuelLogsDao.updateSyncStatus(
        row.id,
        success ? 'synced' : 'failed',
      );
    }
  }

  Future<void> _pushPendingMaintenance() async {
    final pending = await _db.maintenanceDao.getPending();
    for (final row in pending) {
      bool success = false;
      for (int attempt = 0; attempt < _maxRetries; attempt++) {
        try {
          await _api.post(
            '/vehicles/${row.vehicleId}/maintenance',
            body: {
              'id': row.id,
              'date': row.date,
              'serviceType': row.serviceType,
              if (row.category != null) 'category': row.category,
              if (row.costCents != null) 'costCents': row.costCents,
              if (row.odometer != null) 'odometer': row.odometer,
              if (row.workshop != null) 'workshop': row.workshop,
              if (row.notes != null) 'notes': row.notes,
            },
          );
          success = true;
          break;
        } catch (_) {
          // linear retry: try again on next iteration
        }
      }
      await _db.maintenanceDao.updateSyncStatus(
        row.id,
        success ? 'synced' : 'failed',
      );
    }
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    ref.read(appDatabaseProvider),
    ref.read(apiClientProvider),
  );
});
