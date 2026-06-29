import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/activity_entry.dart';

class ActivityRepository {
  final ApiClient _apiClient;

  ActivityRepository(this._apiClient);

  Future<List<ActivityEntry>> fetchActivity({int limit = 50}) async {
    final list = await _apiClient.getList(
      '/activity',
      queryParams: {'limit': limit},
    );
    return list.map(ActivityEntry.fromApi).toList();
  }
}

final activityRepositoryProvider = Provider<ActivityRepository>(
  (ref) => ActivityRepository(ref.watch(apiClientProvider)),
);
