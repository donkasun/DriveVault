import { NextRequest, NextResponse } from 'next/server';

import { AppError, toErrorResponse } from '@/server/lib/errors';
import { processReminders } from '@/server/services/reminder-processing';

export const dynamic = 'force-dynamic';

/** Internal endpoint called by Cloud Scheduler — not for public use. */

/** POST — FastAPI parity: guarded by the x-internal-secret header. */
export async function POST(request: NextRequest): Promise<NextResponse> {
  try {
    const expected = process.env.INTERNAL_SECRET ?? '';
    const provided = request.headers.get('x-internal-secret') ?? '';
    if (!expected || provided !== expected) {
      throw new AppError(401, 'Unauthorized');
    }

    const result = await processReminders();
    return NextResponse.json(result);
  } catch (err) {
    return toErrorResponse(err);
  }
}

/**
 * GET — Vercel Cron entry point. Vercel Cron always sends a GET request with an
 * `Authorization: Bearer <CRON_SECRET>` header (it cannot send POST or a custom
 * X-Internal-Secret header), so this mirrors the same guard for that trigger.
 */
export async function GET(request: NextRequest): Promise<NextResponse> {
  try {
    const expected = process.env.CRON_SECRET ?? process.env.INTERNAL_SECRET ?? '';
    const authHeader = request.headers.get('authorization') ?? '';
    const provided = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : '';
    if (!expected || provided !== expected) {
      throw new AppError(401, 'Unauthorized');
    }

    const result = await processReminders();
    return NextResponse.json(result);
  } catch (err) {
    return toErrorResponse(err);
  }
}
