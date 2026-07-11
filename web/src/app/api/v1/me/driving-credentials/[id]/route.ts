import { NextRequest, NextResponse } from 'next/server';

import { requireUser } from '@/server/auth/require-user';
import { toErrorResponse } from '@/server/lib/errors';
import { updateCredentialSchema } from '@/server/schemas/driving-credentials';
import {
  deleteCredential,
  updateCredential,
} from '@/server/services/driving-credentials';

export const dynamic = 'force-dynamic';

type RouteContext = { params: Promise<{ id: string }> };

/** No GET-by-id — matches Python (PATCH + DELETE only). */
export async function PATCH(req: NextRequest, context: RouteContext) {
  try {
    const user = await requireUser(req);
    const { id } = await context.params;
    const body: unknown = await req.json();
    // Zod validation failures → 400 via toErrorResponse (established convention).
    // Python/FastAPI returns 422 for Pydantic body validation — intentional drift.
    const payload = updateCredentialSchema.parse(body);
    const updated = await updateCredential(user.id, id, payload);
    return NextResponse.json(updated);
  } catch (err) {
    return toErrorResponse(err);
  }
}

export async function DELETE(req: NextRequest, context: RouteContext) {
  try {
    const user = await requireUser(req);
    const { id } = await context.params;
    await deleteCredential(user.id, id);
    return new NextResponse(null, { status: 204 });
  } catch (err) {
    return toErrorResponse(err);
  }
}
