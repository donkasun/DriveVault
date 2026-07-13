import { attentionRenewals, friendlyDate, greetingFor, initialsFor } from './helpers';
import type { UpcomingRenewal } from './types';

function renewal(overrides: Partial<UpcomingRenewal>): UpcomingRenewal {
  return {
    vehicleId: 'v1',
    title: 'Insurance',
    expiryDate: '2026-08-01',
    docType: 'insurance',
    vehicleLabel: 'Toyota Hilux',
    daysRemaining: 10,
    status: 'soon',
    ...overrides,
  };
}

describe('attentionRenewals', () => {
  it('keeps only soon/overdue renewals', () => {
    const ok = renewal({ status: 'ok' });
    const soon = renewal({ status: 'soon' });
    const overdue = renewal({ status: 'overdue' });
    const nullStatus = renewal({ status: null });

    expect(attentionRenewals([ok, soon, overdue, nullStatus])).toEqual([soon, overdue]);
  });

  it('returns an empty array when nothing needs attention', () => {
    expect(attentionRenewals([renewal({ status: 'ok' })])).toEqual([]);
  });
});

describe('greetingFor', () => {
  it('returns morning before noon', () => {
    expect(greetingFor(9)).toBe('Good morning,');
  });

  it('returns afternoon before 5pm', () => {
    expect(greetingFor(14)).toBe('Good afternoon,');
  });

  it('returns welcome back in the evening', () => {
    expect(greetingFor(20)).toBe('Welcome back,');
  });
});

describe('initialsFor', () => {
  it('returns ? for an empty name', () => {
    expect(initialsFor('  ')).toBe('?');
  });

  it('returns a single letter for a one-word name', () => {
    expect(initialsFor('Madonna')).toBe('M');
  });

  it('returns two letters for a full name', () => {
    expect(initialsFor('Jane Doe')).toBe('JD');
  });

  it('uppercases lowercase input', () => {
    expect(initialsFor('jane doe')).toBe('JD');
  });
});

describe('friendlyDate', () => {
  const now = new Date(2026, 6, 13); // 13 Jul 2026, local

  it('labels today', () => {
    expect(friendlyDate('2026-07-13', now)).toBe('Today');
  });

  it('labels yesterday', () => {
    expect(friendlyDate('2026-07-12', now)).toBe('Yesterday');
  });

  it('formats older dates as "d MMM"', () => {
    expect(friendlyDate('2026-07-01', now)).toBe('1 Jul');
  });

  it('returns the raw string when unparsable', () => {
    expect(friendlyDate('not-a-date', now)).toBe('not-a-date');
  });
});
