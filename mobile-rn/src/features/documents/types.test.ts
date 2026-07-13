import { daysUntilExpiry, groupDocumentsByType, isImageDocument } from './types';
import type { Document } from './types';

function makeDoc(overrides: Partial<Document>): Document {
  return {
    id: overrides.id ?? 'doc-1',
    vehicleId: 'vehicle-1',
    docType: 'insurance',
    title: 'Doc',
    storageUrl: 'https://example.com/doc.pdf',
    storagePublicId: null,
    mimeType: null,
    fileSizeBytes: null,
    issueDate: null,
    expiryDate: null,
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: null,
    ...overrides,
  };
}

describe('isImageDocument', () => {
  it('is true for image mime types', () => {
    expect(isImageDocument(makeDoc({ mimeType: 'image/jpeg' }))).toBe(true);
  });

  it('is false for non-image mime types', () => {
    expect(isImageDocument(makeDoc({ mimeType: 'application/pdf' }))).toBe(false);
  });

  it('is false when mimeType is null', () => {
    expect(isImageDocument(makeDoc({ mimeType: null }))).toBe(false);
  });
});

describe('daysUntilExpiry', () => {
  const now = new Date('2026-07-13T12:00:00.000Z');

  it('returns null when there is no expiry date', () => {
    expect(daysUntilExpiry(null, now)).toBeNull();
  });

  it('returns null for an unparseable expiry date', () => {
    expect(daysUntilExpiry('not-a-date', now)).toBeNull();
  });

  it('returns a positive count for a future date', () => {
    expect(daysUntilExpiry('2026-07-20', now)).toBe(7);
  });

  it('returns a negative count for a past date (expired)', () => {
    expect(daysUntilExpiry('2026-07-01', now)).toBe(-12);
  });

  it('returns 0 for today', () => {
    expect(daysUntilExpiry('2026-07-13', now)).toBe(0);
  });
});

describe('groupDocumentsByType', () => {
  it('groups documents by docType, preserving relative order within a group', () => {
    const docs = [
      makeDoc({ id: '1', docType: 'insurance' }),
      makeDoc({ id: '2', docType: 'registration' }),
      makeDoc({ id: '3', docType: 'insurance' }),
    ];

    const grouped = groupDocumentsByType(docs);

    expect(Object.keys(grouped).sort()).toEqual(['insurance', 'registration']);
    expect(grouped.insurance.map((d) => d.id)).toEqual(['1', '3']);
    expect(grouped.registration.map((d) => d.id)).toEqual(['2']);
  });

  it('returns an empty object for an empty list', () => {
    expect(groupDocumentsByType([])).toEqual({});
  });
});
