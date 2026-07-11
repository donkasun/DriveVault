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
