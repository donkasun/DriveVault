import { NextRequest, NextResponse } from 'next/server';

import { requireUser } from '@/server/auth/require-user';
import { toErrorResponse } from '@/server/lib/errors';
import { updateDocumentSchema } from '@/server/schemas/documents';
import {
  deleteDocument,
  getDocumentResponseForUser,
  updateDocument,
} from '@/server/services/documents';

export const dynamic = 'force-dynamic';

type RouteContext = { params: Promise<{ id: string }> };

export async function GET(req: NextRequest, context: RouteContext) {
  try {
    const user = await requireUser(req);
    const { id } = await context.params;
    const data = await getDocumentResponseForUser(user.id, id);
    return NextResponse.json(data);
  } catch (err) {
    return toErrorResponse(err);
  }
}

export async function PATCH(req: NextRequest, context: RouteContext) {
  try {
    const user = await requireUser(req);
    const { id } = await context.params;
    const body: unknown = await req.json();
    // Zod validation failures → 400 via toErrorResponse (established convention).
    // Python/FastAPI returns 422 for Pydantic body validation — intentional drift.
    const payload = updateDocumentSchema.parse(body);
    const updated = await updateDocument(user.id, id, payload);
    return NextResponse.json(updated);
  } catch (err) {
    return toErrorResponse(err);
  }
}

export async function DELETE(req: NextRequest, context: RouteContext) {
  try {
    const user = await requireUser(req);
    const { id } = await context.params;
    await deleteDocument(user.id, id);
    return new NextResponse(null, { status: 204 });
  } catch (err) {
    return toErrorResponse(err);
  }
}
