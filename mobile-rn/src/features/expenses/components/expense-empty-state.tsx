/**
 * Empty state — parity with Flutter `expense_history_screen.dart`'s
 * `_EmptyState`. Copy and CTA switch based on whether the Month range filter
 * is what's producing the empty result.
 */

import { StyleSheet, Text, View } from 'react-native';

import { AppButton } from '@/components/app-button';
import { Colors } from '@/constants/theme';

type Props = {
  isMonthFilter: boolean;
  onLogFillUp?: () => void;
};

export function ExpenseEmptyState({ isMonthFilter, onLogFillUp }: Props) {
  return (
    <View style={styles.container}>
      <View style={styles.iconTile}>
        <Text style={styles.iconGlyph}>🧾</Text>
      </View>
      <Text style={styles.title}>{isMonthFilter ? 'No expenses this month' : 'No expenses yet'}</Text>
      <Text style={styles.subtitle}>
        {isMonthFilter
          ? 'Fuel and maintenance costs will appear here once logged.'
          : 'Your fuel and service costs will show up here as you log them.'}
      </Text>
      {!isMonthFilter && onLogFillUp ? (
        <AppButton label="Log a fill-up" onPress={onLogFillUp} style={styles.cta} />
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 32,
    paddingBottom: 80,
  },
  iconTile: {
    width: 72,
    height: 72,
    borderRadius: 20,
    backgroundColor: '#FFFFFF',
    alignItems: 'center',
    justifyContent: 'center',
  },
  iconGlyph: {
    fontSize: 32,
  },
  title: {
    marginTop: 20,
    fontSize: 18,
    fontWeight: '800',
    letterSpacing: -0.3,
    color: Colors.textPrimary,
    textAlign: 'center',
  },
  subtitle: {
    marginTop: 8,
    fontSize: 14,
    fontWeight: '400',
    lineHeight: 20,
    color: Colors.textMuted,
    textAlign: 'center',
  },
  cta: {
    marginTop: 24,
    minWidth: 200,
  },
});
