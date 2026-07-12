import { NextRequest, NextResponse } from 'next/server';

import { AppError, toErrorResponse } from '@/server/lib/errors';
import { processReminders } from '@/server/services/reminder-processing';

export const dynamic = 'force-dynamic';

/**
 * Internal endpoint — not for public use. Triggered on a schedule by a GitHub
 * Actions workflow (.github/workflows/process-reminders.yml), which sends a
 * POST with the `X-Internal-Secret` header. Guarded exactly like the FastAPI
 * original (backend/app/routers/internal.py).
 */
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
