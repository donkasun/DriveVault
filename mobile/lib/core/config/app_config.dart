import 'package:flutter/foundation.dart';

/// App configuration. The API base URL is injected at build time and must never be
/// hard-coded (see CLAUDE.md): pass `--dart-define=API_BASE_URL=...`.
class AppConfig {
  /// The default (dev) base URL. Used as a sentinel to detect unconfigured
  /// release builds.
  static const String _localhostDefault = 'http://localhost:8000';

  /// Backend base URL. Defaults to the local FastAPI dev server.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _localhostDefault,
  );

  /// Versioned API prefix (matches docs/03-api-contract.md).
  static const String apiV1Prefix = '/api/v1';

  static String get apiV1BaseUrl => '$apiBaseUrl$apiV1Prefix';

  /// Guards against shipping a release build without a real API_BASE_URL.
  ///
  /// Call this once from [main] before [runApp]. Throws [StateError] in release
  /// mode when [apiBaseUrl] is still the localhost default.
  ///
  /// The optional [isRelease] and [url] parameters exist solely to allow unit
  /// tests to exercise the guard without relying on [kReleaseMode].
  static void assertConfigured({bool? isRelease, String? url}) {
    final release = isRelease ?? kReleaseMode;
    final baseUrl = url ?? apiBaseUrl;
    if (release && baseUrl == _localhostDefault) {
      throw StateError(
        'API_BASE_URL not configured — pass --dart-define=API_BASE_URL=...',
      );
    }
  }
}
