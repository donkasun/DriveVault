/**
 * A labelled metric tile for dashboard-style stat displays. Parity with
 * Flutter `shared/widgets/stat_card.dart`.
 *
 * Renders a white surface card (`cardShadow`) containing:
 * - A small uppercase muted `label` (overline style)
 * - A bold `value` string (pre-formatted by the caller)
 * - An optional `caption` line below the value
 * - An optional `trailing` node (e.g. a sparkline or icon)
 *
 * Pure presentational — no providers, no API calls. The caller formats
 * `value` (e.g. via `formatCents` from `lib/formatting.ts`).
 */

import { StyleSheet, Text, View } from 'react-native';

import { Colors, Radii, cardShadow } from '@/constants/theme';

type Props = {
  label: string;
  value: string;
  caption?: string;
  trailing?: React.ReactNode;
};

export function StatCard({ label, value, caption, trailing }: Props) {
  const content = (
    <View style={styles.content}>
      <Text style={styles.label}>{label.toUpperCase()}</Text>
      <Text style={styles.value}>{value}</Text>
      {caption != null ? <Text style={styles.caption}>{caption}</Text> : null}
    </View>
  );

  return (
    <View style={[styles.card, cardShadow]}>
      {trailing != null ? (
        <View style={styles.row}>
          <View style={styles.flex}>{content}</View>
          <View style={styles.trailing}>{trailing}</View>
        </View>
      ) : (
        content
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: Colors.surface,
    borderRadius: Radii.card,
    padding: 16,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  flex: {
    flex: 1,
  },
  trailing: {
    marginLeft: 12,
  },
  content: {
    alignItems: 'flex-start',
  },
  label: {
    fontSize: 10,
    fontWeight: '600',
    letterSpacing: 0.8,
    color: Colors.textMuted,
  },
  value: {
    marginTop: 4,
    fontSize: 18,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  caption: {
    marginTop: 2,
    fontSize: 12,
    color: Colors.textMuted,
  },
});
