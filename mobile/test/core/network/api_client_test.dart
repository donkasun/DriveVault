import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drivevault/core/network/api_client.dart';
import 'package:drivevault/core/network/api_exceptions.dart';
import 'package:drivevault/features/auth/data/auth_repository.dart';
import 'package:drivevault/features/profile/data/user_repository.dart';

void main() {
  group('ApiClient', () {
    test('mapDioException surfaces detail from FastAPI error JSON', () {
      final exception = ApiClient.mapDioException(
        DioException(
          requestOptions: RequestOptions(path: '/me'),
          response: Response(
            requestOptions: RequestOptions(path: '/me'),
            statusCode: 400,
            data: {'detail': 'Invalid request'},
          ),
        ),
      );

      expect(exception, isA<ApiException>());
      expect(exception.statusCode, 400);
      expect(exception.message, 'Invalid request');
    });

    test('mapDioException returns ApiAuthException for 401', () {
      final exception = ApiClient.mapDioException(
        DioException(
          requestOptions: RequestOptions(path: '/me'),
          response: Response(
            requestOptions: RequestOptions(path: '/me'),
            statusCode: 401,
            data: {'detail': 'Invalid or expired token'},
          ),
        ),
      );

      expect(exception, isA<ApiAuthException>());
      expect(exception.message, 'Invalid or expired token');
    });
  });

  group('UserRepository.getMe', () {
    late ProviderContainer container;

    tearDown(() {
      container.dispose();
    });

    test('returns user on successful GET /me', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8000/api/v1'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'id': 'user-uuid',
                  'firebaseUid': 'firebase-uid',
                  'email': 'user@example.com',
                  'displayName': 'Kasun',
                  'photoUrl': null,
                  'createdAt': '2026-06-08T10:00:00Z',
                },
              ),
            );
          },
        ),
      );

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(AuthRepository.testing()),
          apiClientProvider.overrideWith((ref) => ApiClient(ref, dio: dio)),
        ],
      );

      final user = await container.read(userRepositoryProvider).getMe();

      expect(user.id, 'user-uuid');
      expect(user.firebaseUid, 'firebase-uid');
      expect(user.email, 'user@example.com');
      expect(user.displayName, 'Kasun');
    });

    test('throws ApiAuthException on 401', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8000/api/v1'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 401,
                  data: {'detail': 'Missing authorization header'},
                ),
              ),
            );
          },
        ),
      );

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(AuthRepository.testing()),
          apiClientProvider.overrideWith((ref) => ApiClient(ref, dio: dio)),
        ],
      );

      await expectLater(
        container.read(userRepositoryProvider).getMe(),
        throwsA(isA<ApiAuthException>()),
      );
    });
  });
}
