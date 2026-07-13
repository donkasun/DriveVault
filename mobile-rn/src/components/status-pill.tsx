/**
 * Small rounded status pill: tinted background + same-hue ink text + optional
 * leading glyph. Parity with Flutter `shared/widgets/status_pill.dart`.
 *
 * Pure presentational — no data fetching, no global state.
 */

import { Pressable, StyleSheet, Text, View } from 'react-native';

import { Colors } from '@/constants/theme';

export type PillTone = 'ok' | 'soon' | 'overdue' | 'neutral';

type Props = {
  label: string;
  tone: PillTone;
  /** Leading glyph text (e.g. "✓", "⚠"). Rendered with the same style as the label. */
  glyph?: string | null;
  /** Override the glyph font size. Defaults to 12 (same as label). */
  glyphSize?: number;
  /** When provided the pill becomes tappable with a 44px minimum touch target. */
  onPress?: () => void;
  /** Use on dark-surface cards — switches to solid light backgrounds + dark ink. */
  onDark?: boolean;
};

// ── Color resolution ────────────────────────────────────────────────────────
// Light-surface default: translucent tinted bg + pastel ink (theme tokens).
// Dark-surface (onDark): solid light bg + dark ink — one-off literals lifted
// from Flutter `status_pill.dart` lines 200-228, not present in AppColors.

const ON_DARK_BG: Record<PillTone, string> = {
  ok: '#DCFCE7', // solid light green — status_pill.dart line 200
  soon: '#FCF1DC', // solid light amber, design rgb(252,241,220) — line 201
  overdue: '#FCEBEB', // solid light red, design rgb(252,235,235) — line 202
  neutral: '#E8E8F0', // solid light grey — line 203
};

const ON_DARK_INK: Record<PillTone, string> = {
  ok: '#15803D', // dark green — status_pill.dart line 217
  soon: '#B45309', // dark amber, design rgb(180,83,9) — line 218
  overdue: '#DC2626', // dark red, design rgb(220,38,38) — line 219
  neutral: Colors.textMuted,
};

const LIGHT_BG: Record<PillTone, string> = {
  ok: Colors.successBg,
  soon: Colors.warningBg,
  overdue: Colors.dangerBg,
  neutral: 'rgba(255,255,255,0.08)', // status_pill.dart line 210 (0x14FFFFFF)
};

const LIGHT_INK: Record<PillTone, string> = {
  ok: Colors.success,
  soon: Colors.warning,
  overdue: Colors.danger,
  neutral: Colors.textOnDarkMuted,
};

function resolveBg(tone: PillTone, onDark: boolean): string {
  return onDark ? ON_DARK_BG[tone] : LIGHT_BG[tone];
}

function resolveInk(tone: PillTone, onDark: boolean): string {
  return onDark ? ON_DARK_INK[tone] : LIGHT_INK[tone];
}

export function StatusPill({ label, tone, glyph = null, glyphSize = 12, onPress, onDark = false }: Props) {
  const bg = resolveBg(tone, onDark);
  const ink = resolveInk(tone, onDark);
  const isTappable = onPress != null;

  const content = (
    <View
      style={[
        styles.pill,
        { backgroundColor: bg, minHeight: isTappable ? 44 : 24 },
      ]}
    >
      {glyph != null ? (
        <Text style={[styles.glyph, { color: ink, fontSize: glyphSize }]}>{glyph}</Text>
      ) : null}
      <Text style={[styles.label, { color: ink }]}>{label}</Text>
    </View>
  );

  if (!isTappable) return content;

  return (
    <Pressable accessibilityRole="button" accessibilityLabel={label} onPress={onPress}>
      {content}
    </Pressable>
  );
}

// ── Domain helper types ──────────────────────────────────────────────────────
// Mirror the Flutter domain enums these factories switch on. Kept as plain
// string unions here since the RN app doesn't share Dart enum types.

export type RenewalStatus = 'ok' | 'soon' | 'overdue';
export type CredentialStatus = 'ok' | 'soon' | 'overdue';
export type DocsStatusState = 'valid' | 'needs_action' | 'none' | string;

type StatusPillFactoryProps = {
  label: string;
  tone: PillTone;
  glyph: string | null;
  glyphSize?: number;
};

/**
 * Builds `StatusPill` props from a `RenewalStatus`.
 * - ok      → "✓ Valid"
 * - soon    → "⊙ Nd left" (supply `daysRemaining` for the count)
 * - overdue → "⚠ Overdue Nd" (supply `daysRemaining` for the count)
 */
export function renewalStatusPill(
  status: RenewalStatus,
  daysRemaining?: number,
): StatusPillFactoryProps {
  switch (status) {
    case 'ok':
      return { glyph: '✓', label: 'Valid', tone: 'ok' };
    case 'soon':
      return {
        glyph: '⊙',
        label: daysRemaining != null ? `${daysRemaining}d left` : 'Soon',
        tone: 'soon',
      };
    case 'overdue':
      return {
        glyph: '⚠',
        label:
          daysRemaining != null ? `Overdue ${Math.abs(daysRemaining)}d` : 'Overdue',
        tone: 'overdue',
      };
  }
}

export type DocsStatusLike = {
  state: DocsStatusState;
  needsActionCount: number;
};

/**
 * Builds `StatusPill` props from a docs status object `{ state, needsActionCount }`.
 * - "valid"        → "Docs valid" (ok)
 * - "needs_action" → "N need action" (overdue)
 * - other          → "No docs" (neutral)
 */
export function docsStatusPill(status: DocsStatusLike): StatusPillFactoryProps {
  switch (status.state) {
    case 'valid':
      return { glyph: '✓', label: 'Docs valid', tone: 'ok' };
    case 'needs_action':
      return {
        glyph: '⚠',
        label: `${status.needsActionCount} need action`,
        tone: 'overdue',
      };
    default:
      return { glyph: null, label: 'No docs', tone: 'neutral' };
  }
}

/**
 * Builds `StatusPill` props from a `CredentialStatus`.
 * - ok      → "✓ Valid"
 * - soon    → "⊙ Nd left" (supply `daysLeft` for the count)
 * - overdue → "⚠ Overdue Nd" (supply `daysLeft` for the count)
 */
export function credentialStatusPill(
  status: CredentialStatus | null | undefined,
  daysLeft?: number,
): StatusPillFactoryProps {
  switch (status) {
    case 'ok':
      return { glyph: '✓', label: 'Valid', tone: 'ok' };
    case 'soon':
      return { glyph: '⊙', label: `${daysLeft ?? 0}d left`, tone: 'soon' };
    case 'overdue':
      return {
        glyph: '⚠',
        label: `Overdue ${Math.abs(daysLeft ?? 0)}d`,
        tone: 'overdue',
      };
    default:
      return { glyph: '–', label: 'Unknown', tone: 'ok' };
  }
}

const styles = StyleSheet.create({
  pill: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    alignSelf: 'flex-start',
    paddingHorizontal: 11,
    paddingVertical: 5,
    borderRadius: 100,
  },
  glyph: {
    fontWeight: '700',
    marginRight: 4,
  },
  label: {
    fontSize: 12,
    fontWeight: '700',
    letterSpacing: 0.2,
  },
});
