import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/perf_log.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_data.dart';

class DashboardNotifier extends AsyncNotifier<DashboardData> {
  @override
  Future<DashboardData> build() async {
    PerfLog.start('dashboard');
    final db = ref.read(appDatabaseProvider);
    final cached = await db.dashboardDao.get();

    if (cached != null) {
      PerfLog.mark('dashboard', 'cache');
      _refreshInBackground();
      return DashboardData.fromJson(
        jsonDecode(cached.payload) as Map<String, dynamic>,
      );
    }

    // First launch — no cache; hit the network.
    final data = await ref.read(dashboardRepositoryProvider).fetchDashboard();
    await db.dashboardDao.upsert(jsonEncode(data.toJson()));
    PerfLog.mark('dashboard', 'network');
    return data;
  }

  void _refreshInBackground() {
    ref.read(dashboardRepositoryProvider).fetchDashboard().then((data) async {
      final db = ref.read(appDatabaseProvider);
      await db.dashboardDao.upsert(jsonEncode(data.toJson()));
      PerfLog.mark('dashboard', 'network');
      if (state.hasValue) state = AsyncData(data);
    }).catchError((_) {});
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(dashboardRepositoryProvider).fetchDashboard(),
    );
  }
}

final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardData>(
      DashboardNotifier.new,
    );
