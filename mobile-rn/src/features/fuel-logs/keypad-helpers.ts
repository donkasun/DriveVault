/**
 * Pure text-editing logic for the fuel-entry custom numeric keypad.
 * Parity with Flutter `fuel_numeric_keypad.dart` `_KeyButton`/`_press`, minus
 * cursor/selection tracking: the RN keypad fields are display-only (no native
 * `TextInput` caret), so presses always apply at the end of the string —
 * matching actual user-observable behaviour since there is no cursor to move.
 *
 * Keys: '0'-'9', '.', and the backspace sentinel '⌫'.
 */

export const BACKSPACE = '⌫';

/** Applies one keypad press to `current` and returns the new text. */
export function applyKeypadPress(current: string, key: string): string {
  if (key === BACKSPACE) {
    return current.slice(0, -1);
  }
  // Guard: only one decimal point, same as Flutter.
  if (key === '.' && current.includes('.')) return current;
  return current + key;
}
