/**
 * Floating pill tab bar. Parity with Flutter `mobile/lib/core/router/main_shell.dart`.
 *
 * Layout: Home · Garage · [raised center +] · Expenses · Settings.
 * The four tabs flex evenly; the add button sits in the middle, raised 10px.
 *
 * NOTE: the fourth tab is LABELLED "Settings" but routes to /profile — that is
 * Flutter's behaviour, not a bug. Keep both.
 */

import { memo, useCallback } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import Ionicons from '@expo/vector-icons/Ionicons';

import ExpensesIcon from '@/../assets/icons/expenses.svg';
import GarageIcon from '@/../assets/icons/garage.svg';
import HomeIcon from '@/../assets/icons/home.svg';
import SettingsIcon from '@/../assets/icons/settings.svg';
import { Colors } from '@/constants/theme';

export type TabKey = 'home' | 'garage' | 'expenses' | 'profile';

const TABS: { key: TabKey; label: string; Icon: React.FC<{ width: number; height: number; color: string }> }[] = [
  { key: 'home', label: 'Home', Icon: HomeIcon },
  { key: 'garage', label: 'Garage', Icon: GarageIcon },
  { key: 'expenses', label: 'Expenses', Icon: ExpensesIcon },
  { key: 'profile', label: 'Settings', Icon: SettingsIcon },
];

type Props = {
  active: TabKey;
  onSelect: (key: TabKey) => void;
  onQuickAdd: () => void;
};

export function FloatingTabBar({ active, onSelect, onQuickAdd }: Props) {
  return (
    <View style={styles.bar}>
      <Tab tab={TABS[0]} active={active === TABS[0].key} onSelect={onSelect} />
      <Tab tab={TABS[1]} active={active === TABS[1].key} onSelect={onSelect} />

      <View style={styles.addSlot}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel="Quick add"
          testID="fab_quick_add"
          onPress={onQuickAdd}
          style={({ pressed }) => [styles.addButton, pressed && styles.addPressed]}
        >
          <Ionicons name="add" size={34} color={Colors.textPrimary} />
        </Pressable>
      </View>

      <Tab tab={TABS[2]} active={active === TABS[2].key} onSelect={onSelect} />
      <Tab tab={TABS[3]} active={active === TABS[3].key} onSelect={onSelect} />
    </View>
  );
}

type TabProps = {
  tab: (typeof TABS)[number];
  active: boolean;
  onSelect: (key: TabKey) => void;
};

const Tab = memo(function Tab({ tab, active, onSelect }: TabProps) {
  const { key, label, Icon } = tab;
  const onPress = useCallback(() => onSelect(key), [onSelect, key]);

  return (
    <Pressable
      accessibilityRole="tab"
      accessibilityState={{ selected: active }}
      accessibilityLabel={label}
      onPress={onPress}
      style={styles.tab}
    >
      {active ? (
        <>
          <View style={styles.activeChip}>
            <Icon width={24} height={24} color={Colors.textPrimary} />
          </View>
          <Text style={styles.activeLabel} numberOfLines={1}>
            {label}
          </Text>
        </>
      ) : (
        <>
          <Icon width={20} height={20} color={Colors.textOnDarkMuted} />
          <Text style={styles.inactiveLabel} numberOfLines={1}>
            {label}
          </Text>
        </>
      )}
    </Pressable>
  );
});

const styles = StyleSheet.create({
  bar: {
    flexDirection: 'row',
    alignItems: 'stretch',
    height: 82,
    paddingHorizontal: 10,
    paddingVertical: 10,
    borderRadius: 40,
    backgroundColor: Colors.surfaceDark,
    shadowColor: '#000',
    shadowOpacity: 0.25,
    shadowRadius: 28,
    shadowOffset: { width: 0, height: 10 },
    elevation: 12,
  },
  tab: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  activeChip: {
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 40,
    backgroundColor: Colors.primary,
  },
  activeLabel: {
    marginTop: 3,
    fontSize: 10,
    fontWeight: '700',
    color: Colors.primary,
  },
  inactiveLabel: {
    marginTop: 4,
    fontSize: 10,
    fontWeight: '600',
    color: Colors.textOnDarkMuted,
  },
  addSlot: {
    paddingHorizontal: 6,
    justifyContent: 'center',
  },
  addButton: {
    width: 72,
    height: 72,
    borderRadius: 36,
    backgroundColor: Colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
    // Raised above the bar, matching Flutter's Transform.translate(0, -10).
    marginTop: -20,
    shadowColor: Colors.primary,
    shadowOpacity: 0.55,
    shadowRadius: 12,
    shadowOffset: { width: 0, height: 6 },
    elevation: 10,
  },
  addPressed: {
    opacity: 0.9,
  },
});
