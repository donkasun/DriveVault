import 'package:flutter_test/flutter_test.dart';
import 'package:drivevault/core/config/app_config.dart';

void main() {
  group('AppConfig.assertConfigured', () {
    const localhostUrl = 'http://localhost:8000';
    const prodUrl = 'https://drivevault-backend-250609806849.us-central1.run.app';

    test('does NOT throw in debug/profile mode even with localhost URL', () {
      expect(
        () => AppConfig.assertConfigured(isRelease: false, url: localhostUrl),
        returnsNormally,
      );
    });

    test('does NOT throw in release mode when a real URL is provided', () {
      expect(
        () => AppConfig.assertConfigured(isRelease: true, url: prodUrl),
        returnsNormally,
      );
    });

    test('throws StateError in release mode when URL is localhost default', () {
      expect(
        () => AppConfig.assertConfigured(isRelease: true, url: localhostUrl),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('API_BASE_URL not configured'),
          ),
        ),
      );
    });

    test('does NOT throw in release mode for any non-localhost URL', () {
      expect(
        () => AppConfig.assertConfigured(
          isRelease: true,
          url: 'https://api.example.com',
        ),
        returnsNormally,
      );
    });
  });
}
