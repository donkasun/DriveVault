import { describe, expect, it } from 'vitest';

import { daysUntil, renewalStatus } from './renewals';

describe('daysUntil', () => {
  it('returns positive days for future dates', () => {
    expect(daysUntil('2026-07-20', '2026-07-10')).toBe(10);
  });

  it('returns 0 for same day', () => {
    expect(daysUntil('2026-07-10', '2026-07-10')).toBe(0);
  });

  it('returns negative days when overdue', () => {
    expect(daysUntil('2026-07-05', '2026-07-10')).toBe(-5);
  });
});

describe('renewalStatus', () => {
  const today = '2026-07-10';

  it('returns overdue when remaining < 0', () => {
    expect(renewalStatus('2026-07-09', today)).toBe('overdue');
  });

  it('returns soon when remaining is 0–30', () => {
    expect(renewalStatus('2026-07-10', today)).toBe('soon');
    expect(renewalStatus('2026-08-09', today)).toBe('soon');
  });

  it('returns ok when remaining > 30', () => {
    expect(renewalStatus('2026-08-10', today)).toBe('ok');
  });
});

describe('Date inputs are read as UTC, not the host timezone', () => {
  // 19:46Z on Jul 14 is already Jul 15 in a +05:30 host. Reading local calendar
  // components off such an instant shifts every result by a day, so these must
  // hold no matter what TZ the suite runs under.
  const instant = new Date('2026-07-14T19:46:00Z');

  it('counts from the UTC date of a Date input', () => {
    expect(daysUntil('2026-07-29', instant)).toBe(15);
  });

  it('does not shift status across the local-vs-UTC date boundary', () => {
    expect(renewalStatus('2026-08-13', instant)).toBe('soon'); // exactly 30 days
    expect(renewalStatus('2026-08-14', instant)).toBe('ok'); // 31 days
  });
});
