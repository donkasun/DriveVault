import {
  documentExpirySubLabel,
  documentIconKey,
  documentRenewalStatus,
  maintenanceIconKey,
  maintenanceSubtitle,
  relativeDateLabel,
  sortByDateDesc,
  sortDocumentsByExpiry,
  splitStatPrefix,
  splitStatSuffix,
} from './vehicle-detail-helpers';
import type { Document } from '@/features/documents/types';

describe('splitStatSuffix', () => {
  it('splits a number and unit suffix', () => {
    expect(splitStatSuffix('78,855 km')).toEqual(['78,855', 'km']);
  });

  it('handles the empty-state dash with no suffix', () => {
    expect(splitStatSuffix('—')).toEqual(['—', null]);
  });

  it('returns the whole string with a null suffix when there is no space', () => {
    expect(splitStatSuffix('12.3')).toEqual(['12.3', null]);
  });
});

describe('splitStatPrefix', () => {
  it('splits a currency prefix from the amount', () => {
    expect(splitStatPrefix('Rs 19,393')).toEqual(['Rs', '19,393']);
  });

  it('returns a null prefix when there is no space', () => {
    expect(splitStatPrefix('19393')).toEqual([null, '19393']);
  });
});

describe('sortByDateDesc', () => {
  it('orders newest first', () => {
    const items = [{ date: '2026-01-01' }, { date: '2026-06-15' }, { date: '2026-03-10' }];
    expect(sortByDateDesc(items, (i) => i.date).map((i) => i.date)).toEqual([
      '2026-06-15',
      '2026-03-10',
      '2026-01-01',
    ]);
  });

  it('does not mutate the input array', () => {
    const items = [{ date: '2026-01-01' }, { date: '2026-06-15' }];
    const copy = [...items];
    sortByDateDesc(items, (i) => i.date);
    expect(items).toEqual(copy);
  });
});

describe('maintenanceIconKey', () => {
  it('maps known categories case-insensitively', () => {
    expect(maintenanceIconKey('Repair')).toBe('repair');
    expect(maintenanceIconKey('upgrade')).toBe('upgrade');
    expect(maintenanceIconKey('INSPECTION')).toBe('inspection');
  });

  it('falls back to default for unknown/null categories', () => {
    expect(maintenanceIconKey(null)).toBe('default');
    expect(maintenanceIconKey('oil-change')).toBe('default');
  });
});

describe('maintenanceSubtitle', () => {
  it('joins date, workshop, and odometer with a bullet', () => {
    expect(
      maintenanceSubtitle({ date: '2026-05-20', workshop: 'City Auto', odometer: 47800 }),
    ).toBe('2026-05-20 • City Auto • 47800 km');
  });

  it('omits a blank workshop and a missing odometer', () => {
    expect(maintenanceSubtitle({ date: '2026-05-20', workshop: '   ', odometer: null })).toBe(
      '2026-05-20',
    );
  });
});

describe('documentIconKey', () => {
  it('maps known doc types case-insensitively', () => {
    expect(documentIconKey('Insurance')).toBe('insurance');
    expect(documentIconKey('revenue_license')).toBe('revenue_license');
    expect(documentIconKey('EMISSION_TEST')).toBe('emission_test');
  });

  it('falls back to default for unknown types', () => {
    expect(documentIconKey('warranty')).toBe('default');
  });
});

describe('documentExpirySubLabel', () => {
  const fmt = (d: Date) => `${d.getDate()} MMM`;

  it('returns "No expiry date" when there is none', () => {
    expect(documentExpirySubLabel(null, fmt)).toBe('No expiry date');
  });

  it('returns "No expiry date" for an unparseable date', () => {
    expect(documentExpirySubLabel('not-a-date', fmt)).toBe('No expiry date');
  });

  it('formats a valid expiry date', () => {
    expect(documentExpirySubLabel('2026-12-31', fmt)).toBe('Expires 31 MMM');
  });
});

describe('documentRenewalStatus', () => {
  const now = new Date('2026-07-13T00:00:00');

  it('returns null when there is no expiry date', () => {
    expect(documentRenewalStatus(null, now)).toBeNull();
  });

  it('returns null when expiry is more than 30 days away', () => {
    expect(documentRenewalStatus('2026-09-01', now)).toBeNull();
  });

  it('returns "soon" within 30 days', () => {
    expect(documentRenewalStatus('2026-07-20', now)).toEqual({
      status: 'soon',
      daysRemaining: 7,
    });
  });

  it('returns "overdue" for a past date', () => {
    expect(documentRenewalStatus('2026-07-01', now)).toEqual({
      status: 'overdue',
      daysRemaining: 12,
    });
  });
});

describe('relativeDateLabel', () => {
  const now = new Date('2026-07-13T12:00:00');
  const fmt = (d: Date) => `${d.getDate()} MMM`;

  it('returns "Today" for the current date', () => {
    expect(relativeDateLabel('2026-07-13', fmt, now)).toBe('Today');
  });

  it('returns "Yesterday" for one day back', () => {
    expect(relativeDateLabel('2026-07-12', fmt, now)).toBe('Yesterday');
  });

  it('formats older dates with the caller-supplied formatter', () => {
    expect(relativeDateLabel('2026-06-01', fmt, now)).toBe('1 MMM');
  });

  it('returns the raw string when it does not parse as a date', () => {
    expect(relativeDateLabel('not-a-date', fmt, now)).toBe('not-a-date');
  });
});

describe('sortDocumentsByExpiry', () => {
  const now = new Date('2026-07-13T00:00:00');
  const base: Omit<Document, 'expiryDate'> = {
    id: 'x',
    vehicleId: 'v',
    docType: 'insurance',
    title: 't',
    storageUrl: 'u',
    storagePublicId: null,
    mimeType: null,
    fileSizeBytes: null,
    issueDate: null,
    createdAt: '2026-01-01',
    updatedAt: null,
  };

  it('orders overdue, then soon-first, then ok, then no-expiry last', () => {
    const docs: Document[] = [
      { ...base, id: 'no-expiry', expiryDate: null },
      { ...base, id: 'ok', expiryDate: '2026-12-01' },
      { ...base, id: 'overdue', expiryDate: '2026-06-01' },
      { ...base, id: 'soon-far', expiryDate: '2026-08-01' },
      { ...base, id: 'soon-near', expiryDate: '2026-07-15' },
    ];

    expect(sortDocumentsByExpiry(docs, now).map((d) => d.id)).toEqual([
      'overdue',
      'soon-near',
      'soon-far',
      'ok',
      'no-expiry',
    ]);
  });
});
