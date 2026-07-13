/**
 * Low-level HTTP client. Attaches the Firebase ID token and maps API errors.
 * Parity with Flutter `mobile/lib/core/network/api_client.dart`.
 *
 * Only feature `api.ts` files may call this — see docs/best-practices.md §1.
 */

import { ApiAuthError, ApiError } from './api-errors';

/** Matches Flutter's Dio connect/receive timeouts. */
const TIMEOUT_MS = 10_000;

type HttpMethod = 'GET' | 'POST' | 'PATCH' | 'DELETE';

type RequestOptions = {
  method?: HttpMethod;
  body?: unknown;
  query?: Record<string, string | number | boolean | undefined>;
  /** Skip the Authorization header (e.g. unauthenticated probes). */
  anonymous?: boolean;
};

/**
 * Token provider, injected from the auth layer to avoid a circular import
 * (auth → api-client → auth). Set once at app bootstrap.
 */
type TokenProvider = () => Promise<string | null>;

let getAccessToken: TokenProvider = async () => null;

export function setAccessTokenProvider(provider: TokenProvider): void {
  getAccessToken = provider;
}

function baseUrl(): string {
  const url = process.env.EXPO_PUBLIC_API_BASE_URL;
  if (!url) {
    throw new Error(
      'EXPO_PUBLIC_API_BASE_URL is not set — copy .env.example to .env.local',
    );
  }
  return url.replace(/\/$/, '');
}

function buildUrl(path: string, query?: RequestOptions['query']): string {
  const url = `${baseUrl()}${path}`;
  if (!query) return url;

  const params = new URLSearchParams();
  for (const [key, value] of Object.entries(query)) {
    if (value !== undefined) params.append(key, String(value));
  }
  const qs = params.toString();
  return qs ? `${url}?${qs}` : url;
}

/**
 * Maps a non-OK response to a typed error, mirroring Dio's `mapDioException`:
 * the `{ detail }` body becomes the message; 401 becomes ApiAuthError.
 */
function toApiError(status: number, body: unknown, fallback: string): ApiError {
  let message = fallback;
  if (body && typeof body === 'object' && 'detail' in body) {
    const detail = (body as { detail: unknown }).detail;
    if (detail != null) message = String(detail);
  }
  return status === 401 ? new ApiAuthError(message, body) : new ApiError(status, message, body);
}

async function request<T>(path: string, options: RequestOptions = {}): Promise<T> {
  const headers: Record<string, string> = { 'Content-Type': 'application/json' };

  if (!options.anonymous) {
    const token = await getAccessToken();
    if (token) headers.Authorization = `Bearer ${token}`;
  }

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);

  let response: Response;
  try {
    response = await fetch(buildUrl(path, options.query), {
      method: options.method ?? 'GET',
      headers,
      body: options.body === undefined ? undefined : JSON.stringify(options.body),
      signal: controller.signal,
    });
  } catch (error) {
    // No response at all — Flutter maps this to ApiException(0, message).
    const message = error instanceof Error ? error.message : 'Network error';
    throw new ApiError(0, message);
  } finally {
    clearTimeout(timer);
  }

  const text = await response.text();
  let data: unknown = null;
  if (text) {
    try {
      data = JSON.parse(text);
    } catch {
      data = text;
    }
  }

  if (!response.ok) {
    throw toApiError(response.status, data, `Request failed with status ${response.status}`);
  }

  return data as T;
}

export const apiClient = {
  get: <T>(path: string, query?: RequestOptions['query']) =>
    request<T>(path, { method: 'GET', query }),

  post: <T>(path: string, body: unknown) => request<T>(path, { method: 'POST', body }),

  patch: <T>(path: string, body: unknown) => request<T>(path, { method: 'PATCH', body }),

  /** DELETE returns 204 with no body — resolves to void. */
  delete: async (path: string): Promise<void> => {
    await request<unknown>(path, { method: 'DELETE' });
  },
};
