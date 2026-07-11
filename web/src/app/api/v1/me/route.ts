import { NextRequest, NextResponse } from 'next/server';

import { requireUser } from '@/server/auth/require-user';
import { toErrorResponse } from '@/server/lib/errors';
import { updateMeSchema } from '@/server/schemas/users';
import { toUserResponse, updateUserProfile } from '@/server/services/users';

export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
  try {
    const user = await requireUser(req);
    return NextResponse.json(toUserResponse(user));
  } catch (err) {
    return toErrorResponse(err);
  }
}

export async function PATCH(req: NextRequest) {
  try {
    const user = await requireUser(req);
    const body: unknown = await req.json();
    // Zod validation failures → 400 via toErrorResponse (established convention).
    // Python/FastAPI returns 422 for Pydantic body validation — intentional drift.
    const patch = updateMeSchema.parse(body);
    const updated = await updateUserProfile(user, patch);
    return NextResponse.json(toUserResponse(updated));
  } catch (err) {
    return toErrorResponse(err);
  }
}
