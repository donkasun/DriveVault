import { NextRequest, NextResponse } from 'next/server';

import { requireUser } from '@/server/auth/require-user';
import { toErrorResponse } from '@/server/lib/errors';
import { getDashboardData } from '@/server/services/dashboard';

export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
  try {
    const user = await requireUser(req);
    const data = await getDashboardData(user.id);
    return NextResponse.json(data);
  } catch (err) {
    return toErrorResponse(err);
  }
}
