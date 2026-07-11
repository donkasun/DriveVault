import { NextRequest, NextResponse } from 'next/server';

import { requireUser } from '@/server/auth/require-user';
import { toErrorResponse } from '@/server/lib/errors';
import { createFuelLogSchema } from '@/server/schemas/fuel-logs';
import { createFuelLog, listFuelLogs } from '@/server/services/fuel-logs';

export const dynamic = 'force-dynamic';

type RouteContext = { params: Promise<{ id: string }> };

export async function GET(req: NextRequest, context: RouteContext) {
  try {
    const user = await requireUser(req);
    const { id } = await context.params;
    const from = req.nextUrl.searchParams.get('from');
    const to = req.nextUrl.searchParams.get('to');
    const data = await listFuelLogs(user.id, id, from, to);
    return NextResponse.json(data);
  } catch (err) {
    return toErrorResponse(err);
  }
}

export async function POST(req: NextRequest, context: RouteContext) {
  try {
    const user = await requireUser(req);
    const { id } = await context.params;
    const body: unknown = await req.json();
    // Zod validation failures → 400 via toErrorResponse (established convention).
    // Python/FastAPI returns 422 for Pydantic body validation — intentional drift.
    const payload = createFuelLogSchema.parse(body);
    const created = await createFuelLog(user.id, id, payload);
    return NextResponse.json(created, { status: 201 });
  } catch (err) {
    return toErrorResponse(err);
  }
}
