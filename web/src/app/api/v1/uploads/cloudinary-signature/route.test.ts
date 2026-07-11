import { NextRequest } from 'next/server';
import { beforeEach, describe, expect, it, vi } from 'vitest';

import { AppError } from '@/server/lib/errors';

const { requireUser } = vi.hoisted(() => ({ requireUser: vi.fn() }));

vi.mock('@/server/auth/require-user', () => ({ requireUser }));

function postRequest(body: unknown): NextRequest {
  return new NextRequest('http://localhost/api/v1/uploads/cloudinary-signature', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
}

describe('POST /api/v1/uploads/cloudinary-signature', () => {
  beforeEach(() => {
    requireUser.mockReset();
  });

  it('returns 401 when requireUser rejects', async () => {
    requireUser.mockRejectedValue(new AppError(401, 'Not authenticated'));

    const { POST } = await import('./route');
    const response = await POST(
      postRequest({ folder: 'vehicles/vehicle-123/documents' }),
    );

    expect(response.status).toBe(401);
    await expect(response.json()).resolves.toEqual({ detail: 'Not authenticated' });
  });

  it('returns signature payload when authenticated', async () => {
    requireUser.mockResolvedValue({ id: 'user-1' });
    process.env.CLOUDINARY_CLOUD_NAME = 'drivevault';
    process.env.CLOUDINARY_API_KEY = '1234567890';
    process.env.CLOUDINARY_API_SECRET = 'top-secret';

    const { POST } = await import('./route');
    const response = await POST(
      postRequest({ folder: 'vehicles/vehicle-123/documents' }),
    );

    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body).toMatchObject({
      apiKey: '1234567890',
      cloudName: 'drivevault',
      folder: 'vehicles/vehicle-123/documents',
    });
    expect(typeof body.signature).toBe('string');
    expect(typeof body.timestamp).toBe('number');
    expect(JSON.stringify(body)).not.toContain('top-secret');
  });
});
