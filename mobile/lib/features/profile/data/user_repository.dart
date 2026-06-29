import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

const _kMeCacheKey = 'cached_me_user';

/// Cache-first notifier: returns the locally stored user immediately (so the
/// Dashboard header shows a name on slow networks), then refreshes from the
/// API in the background and updates the cache.
class _MeNotifier extends AsyncNotifier<AppUser> {
  @override
  Future<AppUser> build() async {
    ref.keepAlive();
    final cached = await _readCache();
    if (cached != null) {
      // Serve cache immediately; refresh in background without blocking UI.
      _refreshInBackground();
      return cached;
    }
    // First launch: no cache yet — fetch normally.
    final user = await ref.read(userRepositoryProvider).getMe();
    await _writeCache(user);
    return user;
  }

  void _refreshInBackground() {
    ref.read(userRepositoryProvider).getMe().then((user) async {
      await _writeCache(user);
      if (state.hasValue) state = AsyncData(user);
    }).catchError((_) {
      // Keep showing cached data on network error; don't surface error state.
    });
  }

  Future<AppUser?> _readCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kMeCacheKey);
      if (raw == null) return null;
      return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(AppUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kMeCacheKey, jsonEncode(user.toJson()));
    } catch (_) {}
  }

  /// Call after a successful profile update so the cache stays in sync.
  Future<void> updateAndCache(AppUser user) async {
    await _writeCache(user);
    state = AsyncData(user);
  }
}

/// Current user — cache-first, always fresh. Invalidate to force a re-fetch.
final meProvider = AsyncNotifierProvider<_MeNotifier, AppUser>(_MeNotifier.new);
