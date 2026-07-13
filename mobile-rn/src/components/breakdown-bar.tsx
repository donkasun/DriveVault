/**
 * A horizontal proportional bar for cost-breakdown visualisations, plus a
 * legend row. Parity with Flutter `shared/widgets/breakdown_bar.dart`
 * (`BreakdownBar` / `LegendDot` / `BreakdownBarWithLegend`).
 *
 * Pure presentational — no providers, no API calls. Accepts pre-formatted
 * amount strings via `formatAmount` and cents values for proportion math.
 */

import { ScrollView, StyleSheet, Text, View } from 'react-native';

import { Colors } from '@/constants/theme';

export type BreakdownSegment = {
  label: string;
  valueCents: number;
  color: string;
};

type BarProps = {
  segments: BreakdownSegment[];
  /** Height of the rendered bar track. Defaults to 8. */
  height?: number;
};

/**
 * Renders each segment as a proportional slice. All-zero / empty shows a
 * neutral muted-grey track instead.
 */
export function BreakdownBar({ segments, height = 8 }: BarProps) {
  const total = segments.reduce((sum, s) => sum + s.valueCents, 0);
  const radius = height / 2;

  if (total === 0 || segments.length === 0) {
    return (
      <View
        style={[styles.track, { height, borderRadius: radius, backgroundColor: Colors.divider }]}
      />
    );
  }

  return (
    <View style={[styles.track, { height, borderRadius: radius, flexDirection: 'row' }]}>
      {segments.map((segment) => {
        const fraction = segment.valueCents / total;
        if (fraction === 0) return null;
        return (
          <View
            key={segment.label}
            style={{ flex: fraction, backgroundColor: segment.color }}
          />
        );
      })}
    </View>
  );
}

type LegendDotProps = {
  color: string;
  label: string;
  /** Pre-formatted amount string (e.g. "Rs 25,493"). Omit to hide it. */
  amountText?: string;
};

export function LegendDot({ color, label, amountText }: LegendDotProps) {
  return (
    <View style={styles.legendDot}>
      <View style={[styles.dot, { backgroundColor: color }]} />
      <Text style={styles.legendLabel}>{label}</Text>
      {amountText != null ? <Text style={styles.legendAmount}>{amountText}</Text> : null}
    </View>
  );
}

type WithLegendProps = {
  segments: BreakdownSegment[];
  formatAmount?: (cents: number) => string;
  barHeight?: number;
};

export function BreakdownBarWithLegend({ segments, formatAmount, barHeight = 8 }: WithLegendProps) {
  return (
    <View>
      <BreakdownBar segments={segments} height={barHeight} />
      <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.legendScroll}>
        <View style={styles.legendRow}>
          {segments.map((segment, i) => (
            <View key={segment.label} style={i > 0 ? styles.legendSpacer : undefined}>
              <LegendDot
                color={segment.color}
                label={segment.label}
                amountText={formatAmount?.(segment.valueCents)}
              />
            </View>
          ))}
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  track: {
    overflow: 'hidden',
  },
  legendScroll: {
    marginTop: 10,
  },
  legendRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  legendSpacer: {
    marginLeft: 16,
  },
  legendDot: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  dot: {
    width: 9,
    height: 9,
    borderRadius: 3,
  },
  legendLabel: {
    marginLeft: 6,
    fontSize: 12.5,
    fontWeight: '600',
    color: Colors.textMuted,
  },
  legendAmount: {
    marginLeft: 5,
    fontSize: 12.5,
    fontWeight: '800',
    color: Colors.textPrimary,
  },
});
