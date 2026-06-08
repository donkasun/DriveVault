import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:drivevault/features/auth/data/auth_repository.dart';

/// Custom exception for API errors.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic details;

  ApiException(this.statusCode, this.message, [this.details]);

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message, details: $details)';
}

/// A singleton API client using Dio.
class ApiClient {
  final Dio _dio;
  final Ref _ref;

  ApiClient(this._ref) : _dio = Dio(BaseOptions(
    baseUrl: const String.fromEnvironment('BASE_URL', defaultValue: 'http://localhost:8000'),
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  )) {
    // Attach interceptor to inject Firebase ID token into every request.
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final authRepo = _ref.read(authRepositoryProvider);
        final user = authRepo.currentUser;
        if (user != null) {
          // getIdToken forces a refresh if needed.
          final idToken = await user.getIdToken();
          options.headers['Authorization'] = 'Bearer $idToken';
        }
        handler.next(options);
      },
      onError: (DioError err, handler) {
        // Convert error response to ApiException for easier handling.
        final response = err.response;
        if (response != null) {
          final message = response.data is Map && response.data['error'] != null
              ? response.data['error'].toString()
              : err.message;
          handler.reject(DioError(
            requestOptions: err.requestOptions,
            response: response,
            type: err.type,
            error: ApiException(response.statusCode ?? err.type.index, message, response.data),
          ));
        } else {
          handler.next(err);
        }
      },
    ));
  }

  /// Example GET request for the current user profile.
  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/api/v1/me');
    return response.data as Map<String, dynamic>;
  }

  // Additional helper methods (GET, POST, PATCH, DELETE) can be added here.
}

/// Riverpod provider for the ApiClient. It is a simple Provider because the client has no mutable state.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref));
