/**
 * DriveVault design tokens — parity with Flutter `mobile/lib/core/theme/app_theme.dart`.
 * Light-only, matching Flutter Phase 1. Do not add hex literals elsewhere in the app.
 */

import { Platform } from 'react-native';

export const Colors = {
  // Background
  background: '#EBEBF0',
  surface: '#FFFFFF',
  surfaceDark: '#1E1D2B',

  // Accent
  primary: '#FFD600',
  onPrimary: '#1E1D2B',

  // Text
  textPrimary: '#1A1A2E',
  textMuted: '#9898A6',
  textOnDark: '#FFFFFF',
  textOnDarkMuted: 'rgba(244,243,248,0.62)',

  // Utility
  divider: '#E2E2EA',

  // Status — pill palette (pills, icons, banners, dots)
  success: '#34D399',
  warning: '#FBBF24',
  danger: '#FF7A7A',
  successBg: 'rgba(34,197,94,0.16)',
  warningBg: 'rgba(245,158,11,0.18)',
  dangerBg: 'rgba(239,68,68,0.18)',

  // Design-language tokens
  dashedBorder: '#C2C4CF',
  cardGradientStart: '#23232E',
  cardGradientEnd: '#15151C',
  photoUploadTint: '#FFF9E6',
} as const;

export const Spacing = {
  half: 2,
  one: 4,
  two: 8,
  three: 16,
  four: 24,
  five: 32,
  six: 64,
} as const;

export const Radii = {
  field: 12,
  card: 16,
  pill: 999,
} as const;

/** Flutter `appCardDecoration` — box-shadow: 0 4px 14px rgba(20,20,40,0.06). */
export const cardShadow = {
  shadowColor: '#14141F',
  shadowOpacity: 0.06,
  shadowRadius: 14,
  shadowOffset: { width: 0, height: 4 },
  elevation: 3,
} as const;

/** Flutter `textTheme` scale. */
export const Typography = {
  displayLarge: { fontSize: 32, fontWeight: '800' },
  displayMedium: { fontSize: 28, fontWeight: '800' },
  headlineLarge: { fontSize: 24, fontWeight: '700' },
  headlineMedium: { fontSize: 20, fontWeight: '700' },
  titleLarge: { fontSize: 18, fontWeight: '600' },
  titleMedium: { fontSize: 16, fontWeight: '600' },
  titleSmall: { fontSize: 14, fontWeight: '600' },
  bodyLarge: { fontSize: 16, fontWeight: '400' },
  bodyMedium: { fontSize: 14, fontWeight: '400' },
  bodySmall: { fontSize: 12, fontWeight: '400' },
  labelLarge: { fontSize: 12, fontWeight: '600', letterSpacing: 0.8 },
  labelSmall: { fontSize: 10, fontWeight: '600', letterSpacing: 0.8 },
} as const;

export const Fonts = Platform.select({
  ios: {
    sans: 'system-ui',
    serif: 'ui-serif',
    rounded: 'ui-rounded',
    mono: 'ui-monospace',
  },
  default: {
    sans: 'normal',
    serif: 'serif',
    rounded: 'normal',
    mono: 'monospace',
  },
});

export const BottomTabInset = Platform.select({ ios: 50, android: 80 }) ?? 0;
export const MaxContentWidth = 800;
