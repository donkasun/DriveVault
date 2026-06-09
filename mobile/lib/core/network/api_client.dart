import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../../features/auth/data/auth_repository.dart';
import 'api_exceptions.dart';

/// Low-level HTTP client. Attaches the Firebase ID token and maps API errors.
class ApiClient {
  final Dio _dio;
  final Ref _ref;

  ApiClient(this._ref, {Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.apiV1BaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: const {'Content-Type': 'application/json'},
            ),
          ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final authRepo = _ref.read(authRepositoryProvider);
          final user = authRepo.currentUser;
          if (user != null) {
            final idToken = await user.getIdToken();
            options.headers['Authorization'] = 'Bearer $idToken';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: mapDioException(error),
            ),
          );
        },
      ),
    );
  }

  /// Maps a [DioException] to a typed [ApiException] (or [ApiAuthException] for 401).
  static ApiException mapDioException(DioException error) {
    final response = error.response;
    if (response == null) {
      return ApiException(0, error.message ?? 'Network error');
    }

    final statusCode = response.statusCode ?? 0;
    var message = error.message ?? 'Request failed';

    final data = response.data;
    if (data is Map && data['detail'] != null) {
      message = data['detail'].toString();
    }

    if (statusCode == 401) {
      return ApiAuthException(message, data);
    }

    return ApiException(statusCode, message, data);
  }

  Future<Map<String, dynamic>> get(String path) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(path);
      final data = response.data;
      if (data == null) {
        throw ApiException(response.statusCode ?? 0, 'Empty response body');
      }
      return data;
    } on DioException catch (error) {
      final mapped = error.error;
      if (mapped is ApiException) throw mapped;
      throw mapDioException(error);
    }
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(path, data: body);
      final data = response.data;
      if (data == null) {
        throw ApiException(response.statusCode ?? 0, 'Empty response body');
      }
      return data;
    } on DioException catch (error) {
      final mapped = error.error;
      if (mapped is ApiException) throw mapped;
      throw mapDioException(error);
    }
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref));
