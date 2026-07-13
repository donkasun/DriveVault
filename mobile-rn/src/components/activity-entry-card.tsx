/**
 * Shared visual card used in both the home screen "Recent activity" list and
 * the standalone Activity screen. Parity with Flutter
 * `shared/widgets/activity_entry_card.dart`.
 *
 * Callers are responsible for wrapping with swipe-to-delete (if needed) and
 * adding vertical spacing between cards.
 */

import { Pressable, StyleSheet, Text, View } from 'react-native';

import { Colors, Radii, cardShadow } from '@/constants/theme';
import { FALLBACK_CURRENCY } from '@/lib/currencies';
import { formatCents } from '@/lib/formatting';

type Props = {
  /** Leading 40×40 icon node. */
  icon: React.ReactNode;
  /** Primary bold text (e.g. "Fuel" or "Oil Change"). */
  title: string;
  /** Optional lighter text shown after the title (e.g. vehicle name when multiple vehicles exist). */
  titleSub?: string | null;
  /** Secondary muted text (e.g. "Today · 12.3 L · Full"). */
  subLabel: string;
  amountCents?: number | null;
  currency?: string;
  onPress?: () => void;
};

export function ActivityEntryCard({
  icon,
  title,
  titleSub,
  subLabel,
  amountCents,
  currency = FALLBACK_CURRENCY,
  onPress,
}: Props) {
  const content = (
    <View style={styles.row}>
      {icon}
      <View style={styles.textCol}>
        <Text numberOfLines={1} style={styles.titleLine}>
          <Text style={styles.title}>{title}</Text>
          {titleSub != null ? <Text style={styles.titleSub}>{`  ${titleSub}`}</Text> : null}
        </Text>
        <Text numberOfLines={1} style={styles.subLabel}>
          {subLabel}
        </Text>
      </View>
      {amountCents != null ? (
        <Text style={styles.amount}>{formatCents(amountCents, currency)}</Text>
      ) : null}
    </View>
  );

  return (
    <View style={[styles.card, cardShadow]}>
      {onPress ? (
        <Pressable
          accessibilityRole="button"
          onPress={onPress}
          style={({ pressed }) => [styles.pressable, pressed && styles.pressed]}
        >
          {content}
        </Pressable>
      ) : (
        <View style={styles.pressable}>{content}</View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: Colors.surface,
    borderRadius: Radii.card,
    overflow: 'hidden',
  },
  pressable: {
    paddingHorizontal: 14,
    paddingVertical: 10,
  },
  pressed: {
    opacity: 0.85,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  textCol: {
    flex: 1,
    marginLeft: 13,
  },
  titleLine: {
    fontSize: 15,
  },
  title: {
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  titleSub: {
    fontSize: 12,
    fontWeight: '400',
    color: Colors.textMuted,
  },
  subLabel: {
    marginTop: 1,
    fontSize: 12.5,
    fontWeight: '500',
    color: Colors.textMuted,
  },
  amount: {
    marginLeft: 12,
    fontSize: 15,
    fontWeight: '800',
    letterSpacing: -0.3,
    color: Colors.textPrimary,
  },
});
