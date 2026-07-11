import { describe, expect, it } from 'vitest';

import { computeDocsStatus } from './docs-status';

describe('computeDocsStatus', () => {
  const today = '2026-07-10';

  it('returns none when there are no expiry docs', () => {
    expect(computeDocsStatus([], today)).toEqual({
      state: 'none',
      needsActionCount: 0,
    });
    expect(computeDocsStatus([{ expiryDate: null }], today)).toEqual({
      state: 'none',
      needsActionCount: 0,
    });
  });

  it('returns valid when all docs are >30 days away', () => {
    expect(
      computeDocsStatus(
        [{ expiryDate: '2026-08-20' }, { expiryDate: '2026-09-01' }],
        today,
      ),
    ).toEqual({ state: 'valid', needsActionCount: 0 });
  });

  it('returns needs_action counting soon and overdue', () => {
    expect(
      computeDocsStatus(
        [
          { expiryDate: '2026-07-05' }, // overdue
          { expiryDate: '2026-07-20' }, // soon
          { expiryDate: '2026-09-01' }, // ok
        ],
        today,
      ),
    ).toEqual({ state: 'needs_action', needsActionCount: 2 });
  });
});
