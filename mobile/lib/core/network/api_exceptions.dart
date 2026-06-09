/// Typed failures surfaced by [ApiClient] from FastAPI error responses.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic details;

  const ApiException(this.statusCode, this.message, [this.details]);

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message, details: $details)';
}

/// Missing, invalid, or expired Firebase token (HTTP 401).
class ApiAuthException extends ApiException {
  const ApiAuthException(String message, [dynamic details])
    : super(401, message, details);

  @override
  String toString() => 'ApiAuthException(message: $message, details: $details)';
}
