import { NextRequest, NextResponse } from 'next/server';

import { requireUser } from '@/server/auth/require-user';
import { toErrorResponse } from '@/server/lib/errors';
import { computeFuelStats } from '@/server/services/fuel-stats';

export const dynamic = 'force-dynamic';

type RouteContext = { params: Promise<{ id: string }> };

export async function GET(req: NextRequest, context: RouteContext) {
  try {
    const user = await requireUser(req);
    const { id } = await context.params;
    const data = await computeFuelStats(user.id, id);
    return NextResponse.json(data);
  } catch (err) {
    return toErrorResponse(err);
  }
}
