import { NextRequest, NextResponse } from 'next/server';

import { requireUser } from '@/server/auth/require-user';
import { toErrorResponse } from '@/server/lib/errors';

// Temporary smoke-test route for Phase 1 (task 1.8). Confirms Firebase auth +
// lazy user upsert work end-to-end. DELETE BEFORE CUTOVER — replaced by the
// real `/api/v1/me` route in Phase 2.
export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
  try {
    const user = await requireUser(req);
    return NextResponse.json({ uid: user.firebaseUid });
  } catch (err) {
    return toErrorResponse(err);
  }
}
