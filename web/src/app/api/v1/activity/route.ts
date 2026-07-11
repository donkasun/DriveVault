import { NextRequest, NextResponse } from 'next/server';

import { requireUser } from '@/server/auth/require-user';
import { toErrorResponse } from '@/server/lib/errors';
import { activityLimitSchema } from '@/server/schemas/activity';
import { getActivity } from '@/server/services/activity';

export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
  try {
    const user = await requireUser(req);
    const raw = req.nextUrl.searchParams.get('limit');
    // Default 50; invalid (non-int / out of 1–200) → ZodError → 400.
    const limit =
      raw === null ? 50 : activityLimitSchema.parse(raw);
    const data = await getActivity(user.id, limit);
    return NextResponse.json(data);
  } catch (err) {
    return toErrorResponse(err);
  }
}
