import 'server-only';

import { and, desc, eq } from 'drizzle-orm';

import { db } from '@/server/db/client';
import { documents, vehicles } from '@/server/db/schema';
import { AppError } from '@/server/lib/errors';
import type {
  CreateDocument,
  DocumentResponse,
  UpdateDocument,
} from '@/server/schemas/documents';
import { getVehicleForUser } from '@/server/services/vehicles';

export type Document = typeof documents.$inferSelect;

function toDocumentResponse(row: Document): DocumentResponse {
  return {
    id: row.id,
    vehicleId: row.vehicleId,
    docType: row.docType,
    title: row.title,
    storageUrl: row.storageUrl,
    storagePublicId: row.storagePublicId,
    mimeType: row.mimeType,
    fileSizeBytes: row.fileSizeBytes,
    issueDate: row.issueDate,
    expiryDate: row.expiryDate,
    createdAt: row.createdAt.toISOString(),
    updatedAt: row.updatedAt.toISOString(),
  };
}

/**
 * List documents for an owned vehicle.
 * Optional docType filter; order expiryDate desc, then createdAt desc
 * (matches Python list_documents).
 */
export async function listDocuments(
  userId: string,
  vehicleId: string,
  docType?: string | null,
): Promise<DocumentResponse[]> {
  await getVehicleForUser(userId, vehicleId);

  const conditions = [eq(documents.vehicleId, vehicleId)];
  if (docType != null) {
    conditions.push(eq(documents.docType, docType));
  }

  const rows = await db
    .select()
    .from(documents)
    .where(and(...conditions))
    .orderBy(desc(documents.expiryDate), desc(documents.createdAt));

  return rows.map(toDocumentResponse);
}

/**
 * Create a document metadata row (file already uploaded to Cloudinary by client).
 *
 * Judgment: do NOT wrap DB errors as 400 "Failed to create document" like the
 * Python fat router — unexpected errors fall through to standard 500 via
 * toErrorResponse. Same for update/delete.
 */
export async function createDocument(
  userId: string,
  vehicleId: string,
  payload: CreateDocument,
): Promise<DocumentResponse> {
  await getVehicleForUser(userId, vehicleId);

  const [row] = await db
    .insert(documents)
    .values({
      vehicleId,
      docType: payload.docType,
      title: payload.title,
      storageUrl: payload.storageUrl,
      storagePublicId: payload.storagePublicId ?? null,
      mimeType: payload.mimeType ?? null,
      fileSizeBytes: payload.fileSizeBytes ?? null,
      issueDate: payload.issueDate ?? null,
      expiryDate: payload.expiryDate ?? null,
    })
    .returning();

  return toDocumentResponse(row);
}

/** Ownership-checked fetch via join on vehicles.user_id. 404 if missing/not owned. */
export async function getDocumentForUser(
  userId: string,
  documentId: string,
): Promise<Document> {
  const [row] = await db
    .select({ document: documents })
    .from(documents)
    .innerJoin(vehicles, eq(documents.vehicleId, vehicles.id))
    .where(and(eq(documents.id, documentId), eq(vehicles.userId, userId)))
    .limit(1);

  if (!row) {
    throw new AppError(404, 'Document not found');
  }
  return row.document;
}

/** API read: owned document serialized for the wire. */
export async function getDocumentResponseForUser(
  userId: string,
  documentId: string,
): Promise<DocumentResponse> {
  const document = await getDocumentForUser(userId, documentId);
  return toDocumentResponse(document);
}

/** Partial update of an owned document. */
export async function updateDocument(
  userId: string,
  documentId: string,
  payload: UpdateDocument,
): Promise<DocumentResponse> {
  const existing = await getDocumentForUser(userId, documentId);

  const updates: Partial<typeof documents.$inferInsert> = {
    updatedAt: new Date(),
  };

  if (payload.docType !== undefined && payload.docType !== null) {
    updates.docType = payload.docType;
  }
  if (payload.title !== undefined && payload.title !== null) {
    updates.title = payload.title;
  }
  if (payload.storageUrl !== undefined && payload.storageUrl !== null) {
    updates.storageUrl = payload.storageUrl;
  }
  if (payload.storagePublicId !== undefined) {
    updates.storagePublicId = payload.storagePublicId;
  }
  if (payload.mimeType !== undefined) updates.mimeType = payload.mimeType;
  if (payload.fileSizeBytes !== undefined) {
    updates.fileSizeBytes = payload.fileSizeBytes;
  }
  if (payload.issueDate !== undefined) updates.issueDate = payload.issueDate;
  if (payload.expiryDate !== undefined) updates.expiryDate = payload.expiryDate;

  const [updated] = await db
    .update(documents)
    .set(updates)
    .where(eq(documents.id, existing.id))
    .returning();

  return toDocumentResponse(updated);
}

/**
 * Delete owned document DB row only.
 * Drift vs Doc 3: contract says DELETE also removes the Cloudinary asset via
 * public_id; real Python only deletes the DB row — we match Python.
 */
export async function deleteDocument(
  userId: string,
  documentId: string,
): Promise<void> {
  const document = await getDocumentForUser(userId, documentId);
  await db.delete(documents).where(eq(documents.id, document.id));
}
