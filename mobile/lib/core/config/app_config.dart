/// App configuration. The API base URL is injected at build time and must never be
/// hard-coded (see CLAUDE.md): pass `--dart-define=API_BASE_URL=...`.
class AppConfig {
  /// Backend base URL. Defaults to the local FastAPI dev server.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// Versioned API prefix (matches docs/03-api-contract.md).
  static const String apiV1Prefix = '/api/v1';

  static String get apiV1BaseUrl => '$apiBaseUrl$apiV1Prefix';
}
