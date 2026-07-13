/**
 * Fuel-pump glyph used on fuel activity tiles. Parity with Flutter
 * `shared/widgets/fuel_pump_icon.dart` — full tank renders solid dark green;
 * partial renders the plain glyph in the surrounding tile's ink color (the
 * Dart gradient-split fill has no direct RN equivalent without a shader, so
 * this uses a flat color instead — a deliberate, documented deviation).
 */

import MaterialIcons from '@expo/vector-icons/MaterialIcons';

import { Colors } from '@/constants/theme';

type Props = {
  isFullTank: boolean;
  size?: number;
  /** When true (yellow-tinted background), use a darker ink for contrast. */
  darkInk?: boolean;
};

const FULL_TANK_COLOR = '#15803D';

export function FuelPumpIcon({ isFullTank, size = 22, darkInk = false }: Props) {
  const color = isFullTank ? FULL_TANK_COLOR : darkInk ? '#A06800' : Colors.primary;
  return <MaterialIcons name="local-gas-station" size={size} color={color} />;
}
