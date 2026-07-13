/**
 * Typed failures surfaced by the API client.
 * Parity with Flutter `mobile/lib/core/network/api_exceptions.dart`.
 */

export class ApiError extends Error {
  readonly statusCode: number;
  readonly details: unknown;

  constructor(statusCode: number, message: string, details?: unknown) {
    super(message);
    this.name = 'ApiError';
    this.statusCode = statusCode;
    this.details = details;
  }
}

/** Missing, invalid, or expired Firebase token (HTTP 401). */
export class ApiAuthError extends ApiError {
  constructor(message: string, details?: unknown) {
    super(401, message, details);
    this.name = 'ApiAuthError';
  }
}

/**
 * Ownership convention (CLAUDE.md): another user's resource returns 404, never 403.
 * This helper exists so repositories can express "not found or not mine" without
 * re-checking the status code inline.
 */
export function isNotFound(error: unknown): boolean {
  return error instanceof ApiError && error.statusCode === 404;
}
