import { NextRequest } from 'next/server';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

const { processReminders } = vi.hoisted(() => ({ processReminders: vi.fn() }));

vi.mock('@/server/services/reminder-processing', () => ({ processReminders }));

const FIXED_RESULT = { processed: 3, sent: 2, skipped: 1 };

function postRequest(headers: Record<string, string> = {}): NextRequest {
  return new NextRequest('http://localhost/api/v1/internal/process-reminders', {
    method: 'POST',
    headers,
  });
}

describe('POST /api/v1/internal/process-reminders', () => {
  const originalInternalSecret = process.env.INTERNAL_SECRET;

  beforeEach(() => {
    processReminders.mockReset();
    processReminders.mockResolvedValue(FIXED_RESULT);
  });

  afterEach(() => {
    process.env.INTERNAL_SECRET = originalInternalSecret;
  });

  it('returns 401 without x-internal-secret header', async () => {
    process.env.INTERNAL_SECRET = 'shh';
    const { POST } = await import('./route');
    const response = await POST(postRequest());

    expect(response.status).toBe(401);
    await expect(response.json()).resolves.toEqual({ detail: 'Unauthorized' });
    expect(processReminders).not.toHaveBeenCalled();
  });

  it('returns 401 with wrong x-internal-secret', async () => {
    process.env.INTERNAL_SECRET = 'shh';
    const { POST } = await import('./route');
    const response = await POST(postRequest({ 'x-internal-secret': 'wrong' }));

    expect(response.status).toBe(401);
    await expect(response.json()).resolves.toEqual({ detail: 'Unauthorized' });
  });

  it('returns 401 when INTERNAL_SECRET is unset', async () => {
    delete process.env.INTERNAL_SECRET;
    const { POST } = await import('./route');
    const response = await POST(postRequest({ 'x-internal-secret': '' }));

    expect(response.status).toBe(401);
  });

  it('returns 200 + processReminders result with correct secret', async () => {
    process.env.INTERNAL_SECRET = 'shh';
    const { POST } = await import('./route');
    const response = await POST(postRequest({ 'x-internal-secret': 'shh' }));

    expect(response.status).toBe(200);
    await expect(response.json()).resolves.toEqual(FIXED_RESULT);
    expect(processReminders).toHaveBeenCalledTimes(1);
  });
});
