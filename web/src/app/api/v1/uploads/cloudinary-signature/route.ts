import { NextRequest, NextResponse } from 'next/server';

import { requireUser } from '@/server/auth/require-user';
import { toErrorResponse } from '@/server/lib/errors';
import { cloudinarySignatureRequestSchema } from '@/server/schemas/uploads';
import { signCloudinaryUpload } from '@/server/services/cloudinary';

export const dynamic = 'force-dynamic';

/**
 * POST /api/v1/uploads/cloudinary-signature
 * Returns a short-lived signature so the client uploads directly to Cloudinary
 * (file bytes never hit this Next.js server).
 */
export async function POST(req: NextRequest) {
  try {
    await requireUser(req);
    const body: unknown = await req.json();
    // Zod validation failures → 400 via toErrorResponse (established convention).
    // Python/FastAPI returns 422 for Pydantic body validation — intentional drift.
    const payload = cloudinarySignatureRequestSchema.parse(body);
    const signed = signCloudinaryUpload(payload.folder);
    return NextResponse.json(signed);
  } catch (err) {
    return toErrorResponse(err);
  }
}
