import { apiClient, setAccessTokenProvider } from './api-client';
import { ApiAuthError, ApiError, isNotFound } from './api-errors';

const BASE = 'http://localhost:8000/api/v1';

function mockFetch(status: number, body: unknown, ok?: boolean) {
  const fn = jest.fn().mockResolvedValue({
    ok: ok ?? (status >= 200 && status < 300),
    status,
    text: async () => (body === undefined ? '' : JSON.stringify(body)),
  });
  globalThis.fetch = fn as unknown as typeof fetch;
  return fn;
}

/** Narrows a caught value to ApiError so assertions can read statusCode. */
async function catchApiError(promise: Promise<unknown>): Promise<ApiError> {
  try {
    await promise;
    throw new Error('expected the request to reject, but it resolved');
  } catch (error) {
    if (error instanceof ApiError) return error;
    throw error;
  }
}

beforeEach(() => {
  process.env.EXPO_PUBLIC_API_BASE_URL = BASE;
  setAccessTokenProvider(async () => null);
});

describe('apiClient success', () => {
  it('returns the parsed JSON body', async () => {
    mockFetch(200, { id: 'v1', make: 'Toyota' });
    await expect(apiClient.get('/vehicles/v1')).resolves.toEqual({
      id: 'v1',
      make: 'Toyota',
    });
  });

  it('builds the URL from the base URL and path', async () => {
    const fetchMock = mockFetch(200, {});
    await apiClient.get('/me');
    expect(fetchMock).toHaveBeenCalledWith(`${BASE}/me`, expect.anything());
  });

  it('appends query params and omits undefined ones', async () => {
    const fetchMock = mockFetch(200, []);
    await apiClient.get('/activity', { limit: 20, cursor: undefined });
    expect(fetchMock).toHaveBeenCalledWith(`${BASE}/activity?limit=20`, expect.anything());
  });

  it('serializes the body on POST', async () => {
    const fetchMock = mockFetch(201, { id: 'x' });
    await apiClient.post('/vehicles', { make: 'Toyota' });
    expect(fetchMock.mock.calls[0][1]).toMatchObject({
      method: 'POST',
      body: JSON.stringify({ make: 'Toyota' }),
    });
  });

  it('resolves DELETE with an empty body', async () => {
    mockFetch(204, undefined);
    await expect(apiClient.delete('/vehicles/v1')).resolves.toBeUndefined();
  });
});

describe('auth token injection', () => {
  it('attaches the Firebase bearer token when signed in', async () => {
    setAccessTokenProvider(async () => 'fake-id-token');
    const fetchMock = mockFetch(200, {});
    await apiClient.get('/me');

    const headers = fetchMock.mock.calls[0][1].headers;
    expect(headers.Authorization).toBe('Bearer fake-id-token');
  });

  it('omits the header when signed out', async () => {
    const fetchMock = mockFetch(200, {});
    await apiClient.get('/me');

    const headers = fetchMock.mock.calls[0][1].headers;
    expect(headers.Authorization).toBeUndefined();
  });
});

describe('error mapping', () => {
  it('maps 401 to ApiAuthError and uses the {detail} body as the message', async () => {
    mockFetch(401, { detail: 'Invalid authentication credentials' });

    await expect(apiClient.get('/me')).rejects.toBeInstanceOf(ApiAuthError);
    await expect(apiClient.get('/me')).rejects.toMatchObject({
      statusCode: 401,
      message: 'Invalid authentication credentials',
    });
  });

  it("keeps another user's resource as 404 — never remapped to 403", async () => {
    mockFetch(404, { detail: 'Vehicle not found' });

    const err = await catchApiError(apiClient.get('/vehicles/someone-elses'));
    expect(err.statusCode).toBe(404);
    expect(err.statusCode).not.toBe(403);
    expect(isNotFound(err)).toBe(true);
  });

  it('maps other non-OK statuses to ApiError with the detail message', async () => {
    mockFetch(422, { detail: 'odometerKm must be positive' });

    await expect(apiClient.post('/vehicles', {})).rejects.toMatchObject({
      statusCode: 422,
      message: 'odometerKm must be positive',
    });
  });

  it('falls back to a status message when the body has no detail', async () => {
    mockFetch(500, { oops: true });

    await expect(apiClient.get('/me')).rejects.toMatchObject({
      statusCode: 500,
      message: 'Request failed with status 500',
    });
  });

  it('maps a transport failure to statusCode 0', async () => {
    globalThis.fetch = jest
      .fn()
      .mockRejectedValue(new Error('Network request failed')) as unknown as typeof fetch;

    const err = await catchApiError(apiClient.get('/me'));
    expect(err.statusCode).toBe(0);
    expect(err.message).toBe('Network request failed');
  });
});

describe('configuration', () => {
  it('throws a helpful error when the base URL is not set', async () => {
    delete process.env.EXPO_PUBLIC_API_BASE_URL;
    mockFetch(200, {});

    await expect(apiClient.get('/me')).rejects.toThrow(/EXPO_PUBLIC_API_BASE_URL/);
  });
});
