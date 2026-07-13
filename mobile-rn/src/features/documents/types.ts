/**
 * Document domain types — Doc 3 `## Documents`.
 * Parity with Flutter `mobile/lib/features/documents/domain/document.dart`.
 */

export type Document = {
  id: string;
  vehicleId: string;
  docType: string;
  title: string;
  storageUrl: string;
  storagePublicId: string | null;
  mimeType: string | null;
  fileSizeBytes: number | null;
  issueDate: string | null;
  expiryDate: string | null;
  createdAt: string;
  updatedAt: string | null;
};

export type CreateDocumentPayload = {
  docType: string;
  title: string;
  storageUrl: string;
  storagePublicId?: string | null;
  mimeType?: string | null;
  fileSizeBytes?: number | null;
  issueDate?: string | null;
  expiryDate?: string | null;
};

export type UpdateDocumentPayload = Partial<CreateDocumentPayload>;

/** True when the document's mime type is an image (Flutter `Document.isImage`). */
export function isImageDocument(doc: Document): boolean {
  return doc.mimeType != null && doc.mimeType.startsWith('image/');
}

/**
 * Days until `expiryDate` (negative = already expired). Null when there is no
 * expiry date or it fails to parse. Parity with Flutter `Document.daysUntilExpiry()`.
 */
export function daysUntilExpiry(expiryDate: string | null, now: Date = new Date()): number | null {
  if (expiryDate == null) return null;
  const expiry = new Date(expiryDate);
  if (Number.isNaN(expiry.getTime())) return null;

  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const expiryDay = new Date(expiry.getFullYear(), expiry.getMonth(), expiry.getDate());
  const msPerDay = 24 * 60 * 60 * 1000;
  return Math.round((expiryDay.getTime() - today.getTime()) / msPerDay);
}

/**
 * Groups documents by `docType`, preserving each group's original relative
 * order. Parity with Flutter `groupDocumentsByType()` in `document.dart`.
 */
export function groupDocumentsByType(documents: readonly Document[]): Record<string, Document[]> {
  const grouped: Record<string, Document[]> = {};
  for (const doc of documents) {
    (grouped[doc.docType] ??= []).push(doc);
  }
  return grouped;
}
