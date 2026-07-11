import { NextRequest } from 'next/server';
import { beforeEach, describe, expect, it, vi } from 'vitest';

import { AppError } from '@/server/lib/errors';

const { requireUser } = vi.hoisted(() => ({ requireUser: vi.fn() }));

vi.mock('@/server/auth/require-user', () => ({ requireUser }));

describe('GET /api/v1/_auth-check', () => {
  beforeEach(() => {
    requireUser.mockReset();
  });

  it('returns 200 with the firebase uid when authenticated', async () => {
    requireUser.mockResolvedValue({ firebaseUid: 'firebase-test-uid' });

    const { GET } = await import('./route');
    const response = await GET(new NextRequest('http://localhost/api/v1/_auth-check'));

    expect(response.status).toBe(200);
    await expect(response.json()).resolves.toEqual({ uid: 'firebase-test-uid' });
  });

  it('returns 401 when requireUser rejects with an AppError', async () => {
    requireUser.mockRejectedValue(new AppError(401, 'Missing authorization token'));

    const { GET } = await import('./route');
    const response = await GET(new NextRequest('http://localhost/api/v1/_auth-check'));

    expect(response.status).toBe(401);
    await expect(response.json()).resolves.toEqual({ detail: 'Missing authorization token' });
  });
});
