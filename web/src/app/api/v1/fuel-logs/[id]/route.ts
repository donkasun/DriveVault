import { NextRequest, NextResponse } from 'next/server';

import { requireUser } from '@/server/auth/require-user';
import { toErrorResponse } from '@/server/lib/errors';
import { updateFuelLogSchema } from '@/server/schemas/fuel-logs';
import { deleteFuelLog, updateFuelLog } from '@/server/services/fuel-logs';

export const dynamic = 'force-dynamic';

type RouteContext = { params: Promise<{ id: string }> };

export async function PATCH(req: NextRequest, context: RouteContext) {
  try {
    const user = await requireUser(req);
    const { id } = await context.params;
    const body: unknown = await req.json();
    // Zod validation failures → 400 via toErrorResponse (established convention).
    // Python/FastAPI returns 422 for Pydantic body validation — intentional drift.
    const payload = updateFuelLogSchema.parse(body);
    const updated = await updateFuelLog(user.id, id, payload);
    return NextResponse.json(updated);
  } catch (err) {
    return toErrorResponse(err);
  }
}

export async function DELETE(req: NextRequest, context: RouteContext) {
  try {
    const user = await requireUser(req);
    const { id } = await context.params;
    await deleteFuelLog(user.id, id);
    return new NextResponse(null, { status: 204 });
  } catch (err) {
    return toErrorResponse(err);
  }
}
