import { applyKeypadPress, BACKSPACE } from './keypad-helpers';

describe('applyKeypadPress', () => {
  it('appends digits', () => {
    expect(applyKeypadPress('', '5')).toBe('5');
    expect(applyKeypadPress('5', '2')).toBe('52');
  });

  it('appends a decimal point once', () => {
    expect(applyKeypadPress('12', '.')).toBe('12.');
    expect(applyKeypadPress('12.', '.')).toBe('12.'); // guarded — no second point
    expect(applyKeypadPress('12.5', '.')).toBe('12.5');
  });

  it('backspaces the last character', () => {
    expect(applyKeypadPress('12.5', BACKSPACE)).toBe('12.');
    expect(applyKeypadPress('1', BACKSPACE)).toBe('');
  });

  it('backspace on empty string stays empty', () => {
    expect(applyKeypadPress('', BACKSPACE)).toBe('');
  });
});
