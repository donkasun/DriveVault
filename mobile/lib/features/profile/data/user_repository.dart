import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/user.dart';

class UserRepository {
  final ApiClient _apiClient;

  UserRepository(this._apiClient);

  Future<AppUser> getMe() async {
    final data = await _apiClient.get('/me');
    return AppUser.fromJson(data);
  }

  /// Update account preferences via `PATCH /api/v1/me`. Only non-null fields
  /// are sent. Returns the updated user.
  Future<AppUser> updatePreferences({
    String? currency,
    String? distanceUnit,
    bool? renewalRemindersEnabled,
  }) async {
    final body = <String, dynamic>{
      'currency': currency,
      'distanceUnit': distanceUnit,
      'renewalRemindersEnabled': renewalRemindersEnabled,
    }..removeWhere((_, v) => v == null);
    final data = await _apiClient.patch('/me', body: body);
    return AppUser.fromJson(data);
  }

  /// Update display name via `PATCH /api/v1/me`. Returns the updated user.
  Future<AppUser> updateProfile({String? displayName}) async {
    final body = <String, dynamic>{
      'displayName': displayName,
    }..removeWhere((_, v) => v == null);
    final data = await _apiClient.patch('/me', body: body);
    return AppUser.fromJson(data);
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(apiClientProvider));
});

/// Current user from `GET /api/v1/me`. Invalidate to refresh after an update.
final meProvider = FutureProvider<AppUser>((ref) async {
  ref.keepAlive();
  return ref.watch(userRepositoryProvider).getMe();
});
