import { NextRequest, NextResponse } from 'next/server';

import { requireUser } from '@/server/auth/require-user';
import { toErrorResponse } from '@/server/lib/errors';
import { createCredentialSchema } from '@/server/schemas/driving-credentials';
import {
  createCredential,
  listCredentials,
} from '@/server/services/driving-credentials';

export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
  try {
    const user = await requireUser(req);
    const data = await listCredentials(user.id);
    return NextResponse.json(data);
  } catch (err) {
    return toErrorResponse(err);
  }
}

export async function POST(req: NextRequest) {
  try {
    const user = await requireUser(req);
    const body: unknown = await req.json();
    // Zod validation failures → 400 via toErrorResponse (established convention).
    // Python/FastAPI returns 422 for Pydantic body validation — intentional drift.
    const payload = createCredentialSchema.parse(body);
    const created = await createCredential(user.id, payload);
    return NextResponse.json(created, { status: 201 });
  } catch (err) {
    return toErrorResponse(err);
  }
}
