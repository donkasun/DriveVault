import { formatCents } from './formatting';

describe('formatCents', () => {
  it('omits the decimal part for whole amounts', () => {
    // Flutter: LKR 2679300 cents → "Rs 26,793" not "Rs 26,793.00"
    expect(formatCents(2679300, 'LKR')).toBe('Rs 26,793');
  });

  it('keeps the decimal part when there are fractional cents', () => {
    expect(formatCents(2679350, 'LKR')).toBe('Rs 26,793.50');
  });

  it('spaces multi-letter symbols away from the digits', () => {
    expect(formatCents(50, 'LKR')).toBe('Rs 0.50');
  });

  it('keeps single-glyph symbols tight against the digits', () => {
    expect(formatCents(412050, 'USD')).toBe('$4,120.50');
    expect(formatCents(412050, 'EUR')).toBe('€4,120.50');
    expect(formatCents(412050, 'INR')).toBe('₹4,120.50');
  });

  it('does not space mixed letter+glyph symbols (A$, C$)', () => {
    expect(formatCents(412050, 'AUD')).toBe('A$4,120.50');
    expect(formatCents(412050, 'CAD')).toBe('C$4,120.50');
  });

  it('defaults to the fallback currency (LKR)', () => {
    expect(formatCents(412000)).toBe('Rs 4,120');
  });

  it('falls back to the ISO code as the symbol for unknown currencies', () => {
    expect(formatCents(123456, 'XYZ')).toBe('XYZ 1,234.56');
  });

  it('handles zero', () => {
    expect(formatCents(0, 'LKR')).toBe('Rs 0');
  });

  it('handles negative amounts', () => {
    expect(formatCents(-2679300, 'LKR')).toBe('-Rs 26,793');
    expect(formatCents(-412050, 'USD')).toBe('-$4,120.50');
  });
});
