import { StyleSheet, Text, View } from 'react-native';

import { Colors } from '@/constants/theme';
import { formatCents } from '@/lib/formatting';

const MONTHS = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

type Props = {
  month: Date;
  subtotalCents: number;
  currency: string;
};

/** Parity with Flutter `expense_history_screen.dart`'s `_MonthHeader`. */
export function ExpenseMonthHeader({ month, subtotalCents, currency }: Props) {
  return (
    <View style={styles.row}>
      <Text style={styles.month}>{`${MONTHS[month.getMonth()]} ${month.getFullYear()}`}</Text>
      <Text style={styles.subtotal}>{formatCents(subtotalCents, currency)}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 4,
    paddingTop: 12,
    paddingBottom: 6,
  },
  month: {
    flex: 1,
    fontSize: 14,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  subtotal: {
    fontSize: 12,
    fontWeight: '600',
    color: Colors.textMuted,
  },
});
