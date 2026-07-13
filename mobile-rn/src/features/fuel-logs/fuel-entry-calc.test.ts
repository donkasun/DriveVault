import { FuelEntryCalc } from './fuel-entry-calc';
import { estimateNextOdometer } from './odometer-estimate';

describe('FuelEntryCalc', () => {
  it('has no derived field until two values are set', () => {
    const calc = new FuelEntryCalc();
    expect(calc.derivedField).toBeNull();

    calc.setField('liters', 40);
    expect(calc.derivedField).toBeNull();
  });

  it('seeds a sticky price-per-liter from the last log', () => {
    const calc = new FuelEntryCalc(310);
    expect(calc.pricePerLiter).toBe(310);
    // One locked field is not enough to derive anything yet.
    expect(calc.derivedField).toBeNull();
  });

  it('derives total from liters × sticky per-liter', () => {
    const calc = new FuelEntryCalc(310);
    calc.setField('liters', 40);

    expect(calc.derivedField).toBe('total');
    expect(calc.total).toBeCloseTo(12400, 6);
  });

  it('derives liters from total ÷ per-liter', () => {
    const calc = new FuelEntryCalc(310);
    calc.setField('total', 12400);

    expect(calc.derivedField).toBe('liters');
    expect(calc.liters).toBeCloseTo(40, 6);
  });

  it('derives per-liter from total ÷ liters', () => {
    const calc = new FuelEntryCalc();
    calc.setField('liters', 40);
    calc.setField('total', 12400);

    expect(calc.derivedField).toBe('perLiter');
    expect(calc.pricePerLiter).toBeCloseTo(310, 6);
  });

  it('keeps liters and recomputes total when per-liter is edited with all three set', () => {
    // The documented rule: "When per-liter is edited while both others are set,
    // liters is kept and total is recomputed."
    const calc = new FuelEntryCalc();
    calc.setField('liters', 40);
    calc.setField('total', 12400);
    expect(calc.pricePerLiter).toBeCloseTo(310, 6);

    calc.setField('perLiter', 350);

    expect(calc.liters).toBeCloseTo(40, 6);
    expect(calc.total).toBeCloseTo(14000, 6);
    expect(calc.derivedField).toBe('total');
  });

  it('evicts the oldest field when a third is edited (non per-liter case)', () => {
    const calc = new FuelEntryCalc();
    calc.setField('liters', 40); // locked: [liters]
    calc.setField('perLiter', 310); // locked: [liters, perLiter] → total derived
    expect(calc.total).toBeCloseTo(12400, 6);

    calc.setField('total', 20000); // evicts liters (oldest) → liters derived
    expect(calc.derivedField).toBe('liters');
    expect(calc.liters).toBeCloseTo(20000 / 310, 6);
    expect(calc.pricePerLiter).toBeCloseTo(310, 6);
  });

  it('clearing a field unlocks it without making it authoritative', () => {
    const calc = new FuelEntryCalc();
    calc.setField('liters', 40);
    calc.setField('total', 12400);
    expect(calc.derivedField).toBe('perLiter');

    calc.setField('total', null);

    expect(calc.total).toBeNull();
    expect(calc.derivedField).toBeNull();
  });

  it('does not divide by zero', () => {
    const calc = new FuelEntryCalc();
    calc.setField('total', 12400);
    calc.setField('perLiter', 0);
    expect(calc.liters).toBeNull();

    const calc2 = new FuelEntryCalc();
    calc2.setField('liters', 0);
    calc2.setField('total', 12400);
    expect(calc2.pricePerLiter).toBeNull();
  });

  it('isComplete requires positive liters and a non-negative total', () => {
    const calc = new FuelEntryCalc();
    expect(calc.isComplete).toBe(false);

    calc.setField('liters', 40);
    calc.setField('total', 12400);
    expect(calc.isComplete).toBe(true);
  });
});

describe('estimateNextOdometer', () => {
  it('returns null with fewer than two readings', () => {
    expect(estimateNextOdometer([])).toBeNull();
    expect(estimateNextOdometer([48200])).toBeNull();
  });

  it('averages the deltas and rounds to the nearest 10', () => {
    // Descending: deltas 500, 500 → avg 500 → 48200 + 500 = 48700
    expect(estimateNextOdometer([48200, 47700, 47200])).toBe(48700);
  });

  it('rounds the estimate to the nearest 10', () => {
    // deltas: 503, 500 → avg 501.5 → 48200 + 501.5 = 48701.5 → 48700
    expect(estimateNextOdometer([48200, 47697, 47197])).toBe(48700);
  });

  it('ignores non-positive deltas', () => {
    // Only the 48200→47700 delta counts; the flat pair is skipped.
    expect(estimateNextOdometer([48200, 47700, 47700])).toBe(48700);
  });

  it('returns null when no positive delta exists', () => {
    expect(estimateNextOdometer([48200, 48200, 48200])).toBeNull();
  });

  it('honours maxSamples', () => {
    // With maxSamples=2 only the first pair is considered: delta 500.
    expect(estimateNextOdometer([48200, 47700, 40000], 2)).toBe(48700);
  });
});
