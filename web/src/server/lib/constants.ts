/**
 * App-wide constants.
 *
 * LOCKED_CURRENCY: while multi-currency is deferred (see
 * docs/superpowers/specs/2026-06-13-lock-currency-lkr-design.md), every money-bearing
 * record and the user preference are forced to this single currency. Re-enable seam:
 * remove the coercions that reference this constant.
 */
export const LOCKED_CURRENCY = 'LKR';
