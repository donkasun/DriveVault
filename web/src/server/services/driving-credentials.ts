import 'server-only';

import { and, eq } from 'drizzle-orm';

import { db } from '@/server/db/client';
import { userDocuments } from '@/server/db/schema';
import { AppError } from '@/server/lib/errors';
import type {
  CreateCredential,
  CredentialResponse,
  UpdateCredential,
} from '@/server/schemas/driving-credentials';
import { daysUntil, renewalStatus } from '@/server/services/renewals';

/** Display labels for credential doc types — used by Phase 5b dashboard renewals merge. */
export const DOC_TYPE_LABELS: Record<string, string> = {
  license: "Driver's License",
  permit: 'Driving Permit',
  international_license: 'International Driving License',
};

export type UserDocument = typeof userDocuments.$inferSelect;

/** Serialize a user_documents row with computed status / daysUntilExpiry. */
export function toCredentialResponse(
  row: UserDocument,
  today: Date = new Date(),
): CredentialResponse {
  const hasExpiry = row.expiryDate != null;
  return {
    id: row.id,
    docType: row.docType,
    docNumber: row.docNumber,
    issueDate: row.issueDate,
    expiryDate: row.expiryDate,
    notes: row.notes,
    status: hasExpiry ? renewalStatus(row.expiryDate!, today) : null,
    daysUntilExpiry: hasExpiry ? daysUntil(row.expiryDate!, today) : null,
    createdAt: row.createdAt.toISOString(),
    updatedAt: row.updatedAt.toISOString(),
  };
}

/** List all driving credentials for a user (no vehicle join). */
export async function listCredentials(
  userId: string,
): Promise<CredentialResponse[]> {
  const rows = await db
    .select()
    .from(userDocuments)
    .where(eq(userDocuments.userId, userId));

  return rows.map((row) => toCredentialResponse(row));
}

/** Create a driving credential owned by the user. */
export async function createCredential(
  userId: string,
  payload: CreateCredential,
): Promise<CredentialResponse> {
  const [row] = await db
    .insert(userDocuments)
    .values({
      userId,
      docType: payload.docType,
      docNumber: payload.docNumber ?? null,
      issueDate: payload.issueDate ?? null,
      expiryDate: payload.expiryDate ?? null,
      notes: payload.notes ?? null,
    })
    .returning();

  return toCredentialResponse(row);
}

/** Ownership-checked fetch. 404 if missing or not owned. */
export async function getCredentialForUser(
  userId: string,
  credentialId: string,
): Promise<UserDocument> {
  const [row] = await db
    .select()
    .from(userDocuments)
    .where(
      and(eq(userDocuments.id, credentialId), eq(userDocuments.userId, userId)),
    )
    .limit(1);

  if (!row) {
    throw new AppError(404, 'Credential not found');
  }
  return row;
}

/** Partial update of an owned credential. */
export async function updateCredential(
  userId: string,
  credentialId: string,
  payload: UpdateCredential,
): Promise<CredentialResponse> {
  const existing = await getCredentialForUser(userId, credentialId);

  const updates: Partial<typeof userDocuments.$inferInsert> = {
    updatedAt: new Date(),
  };

  if (payload.docType !== undefined) updates.docType = payload.docType;
  if (payload.docNumber !== undefined) updates.docNumber = payload.docNumber;
  if (payload.issueDate !== undefined) updates.issueDate = payload.issueDate;
  if (payload.expiryDate !== undefined) updates.expiryDate = payload.expiryDate;
  if (payload.notes !== undefined) updates.notes = payload.notes;

  const [updated] = await db
    .update(userDocuments)
    .set(updates)
    .where(eq(userDocuments.id, existing.id))
    .returning();

  return toCredentialResponse(updated);
}

/** Delete an owned credential. */
export async function deleteCredential(
  userId: string,
  credentialId: string,
): Promise<void> {
  const credential = await getCredentialForUser(userId, credentialId);
  await db.delete(userDocuments).where(eq(userDocuments.id, credential.id));
}
