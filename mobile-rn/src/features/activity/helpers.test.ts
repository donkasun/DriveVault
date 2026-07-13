import {
  activityDateLabel,
  activitySubLabel,
  activityTitle,
  docTypeLabel,
  filterActivityByKind,
  filterActivityByVehicle,
  groupActivityByMonth,
} from './helpers';
import type { ActivityEntry } from './types';

function entry(overrides: Partial<ActivityEntry>): ActivityEntry {
  return {
    type: 'fuel',
    id: 'e1',
    vehicleId: 'v1',
    vehicleLabel: 'Toyota Hilux',
    date: '2026-07-01',
    amountCents: 1000,
    label: 'Fuel',
    currency: 'LKR',
    createdAt: '2026-07-01T00:00:00Z',
    liters: 10,
    isFullTank: true,
    odometer: 1000,
    notes: null,
    source: null,
    category: null,
    workshop: null,
    title: null,
    docType: null,
    storageUrl: null,
    storagePublicId: null,
    mimeType: null,
    fileSizeBytes: null,
    issueDate: null,
    expiryDate: null,
    ...overrides,
  };
}

describe('filterActivityByKind', () => {
  it('returns everything when kind is null', () => {
    const entries = [entry({ type: 'fuel' }), entry({ type: 'maintenance' })];
    expect(filterActivityByKind(entries, null)).toEqual(entries);
  });

  it('filters to the given kind', () => {
    const fuel = entry({ type: 'fuel' });
    const maint = entry({ type: 'maintenance' });
    expect(filterActivityByKind([fuel, maint], 'maintenance')).toEqual([maint]);
  });
});

describe('filterActivityByVehicle', () => {
  it('returns everything when vehicleId is null', () => {
    const entries = [entry({ vehicleId: 'v1' }), entry({ vehicleId: 'v2' })];
    expect(filterActivityByVehicle(entries, null)).toEqual(entries);
  });

  it('filters to the given vehicle', () => {
    const v1 = entry({ vehicleId: 'v1' });
    const v2 = entry({ vehicleId: 'v2' });
    expect(filterActivityByVehicle([v1, v2], 'v2')).toEqual([v2]);
  });
});

describe('groupActivityByMonth', () => {
  it('groups by calendar month, newest first, and sums amountCents', () => {
    const july1 = entry({ date: '2026-07-01', amountCents: 500 });
    const july15 = entry({ date: '2026-07-15', amountCents: 700 });
    const june = entry({ date: '2026-06-20', amountCents: 300 });

    const groups = groupActivityByMonth([july1, july15, june]);

    expect(groups).toHaveLength(2);
    expect(groups[0]!.month).toEqual(new Date(2026, 6, 1));
    expect(groups[0]!.entries).toEqual([july1, july15]);
    expect(groups[0]!.subtotalCents).toBe(1200);
    expect(groups[1]!.month).toEqual(new Date(2026, 5, 1));
    expect(groups[1]!.subtotalCents).toBe(300);
  });

  it('treats null amountCents as 0 in the subtotal (document entries)', () => {
    const doc = entry({ date: '2026-07-01', amountCents: null, type: 'document' });
    const groups = groupActivityByMonth([doc]);
    expect(groups[0]!.subtotalCents).toBe(0);
  });

  it('returns an empty array for no entries', () => {
    expect(groupActivityByMonth([])).toEqual([]);
  });
});

describe('activityDateLabel', () => {
  const now = new Date(2026, 6, 13);

  it('labels today and yesterday', () => {
    expect(activityDateLabel('2026-07-13', now)).toBe('Today');
    expect(activityDateLabel('2026-07-12', now)).toBe('Yesterday');
  });

  it('formats older dates as "d MMM"', () => {
    expect(activityDateLabel('2026-06-20', now)).toBe('20 Jun');
  });
});

describe('docTypeLabel', () => {
  it('maps known doc types', () => {
    expect(docTypeLabel('insurance')).toBe('Insurance');
    expect(docTypeLabel('registration')).toBe('Registration');
    expect(docTypeLabel('service_record')).toBe('Service record');
    expect(docTypeLabel('warranty')).toBe('Warranty');
    expect(docTypeLabel('receipt')).toBe('Receipt');
  });

  it('title-cases unknown types by replacing underscores', () => {
    expect(docTypeLabel('custom_type')).toBe('custom type');
  });
});

describe('activityTitle / activitySubLabel', () => {
  const now = new Date(2026, 6, 13);

  it('fuel: title "Fuel", sub label includes liters + tank state', () => {
    const e = entry({ type: 'fuel', date: '2026-07-13', liters: 12.345, isFullTank: false });
    expect(activityTitle(e)).toBe('Fuel');
    expect(activitySubLabel(e, now)).toBe('Today · 12.3 L · Partial');
  });

  it('maintenance: title falls back to "Service" when label is blank', () => {
    const withLabel = entry({ type: 'maintenance', label: 'Oil change', date: '2026-07-13' });
    const blank = entry({ type: 'maintenance', label: '', date: '2026-07-13' });
    expect(activityTitle(withLabel)).toBe('Oil change');
    expect(activityTitle(blank)).toBe('Service');
    expect(activitySubLabel(blank, now)).toBe('Today');
  });

  it('document: title uses `title`, sub label includes the doc type label', () => {
    const e = entry({
      type: 'document',
      title: 'Insurance policy',
      docType: 'insurance',
      date: '2026-07-13',
    });
    expect(activityTitle(e)).toBe('Insurance policy');
    expect(activitySubLabel(e, now)).toBe('Today · Insurance');
  });
});
