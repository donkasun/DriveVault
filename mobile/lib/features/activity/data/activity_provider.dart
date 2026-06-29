import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/activity_entry.dart';
import 'activity_repository.dart';

final allActivityProvider = FutureProvider<List<ActivityEntry>>((ref) async {
  ref.keepAlive();
  return ref.read(activityRepositoryProvider).fetchActivity();
});
