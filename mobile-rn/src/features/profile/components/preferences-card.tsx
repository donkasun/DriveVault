/**
 * Preferences card: distance-unit segmented toggle, locked currency display,
 * renewal-reminders switch. Parity with Flutter `_PreferencesCard` in
 * `profile_screen.dart`.
 */

import Ionicons from '@expo/vector-icons/Ionicons';
import { Pressable, StyleSheet, Switch, Text, View } from 'react-native';

import { Colors } from '@/constants/theme';
import { currencyInfoFor } from '@/lib/currencies';
import type { AppUser } from '../types';

// One-off colors lifted from `profile_screen.dart` `_PreferenceRowShell` /
// `_DistanceUnitSelector` / `_LockedCurrencyLabel` — not in the shared theme.
const TITLE_COLOR = '#24243A'; // line 701
const SUBTITLE_COLOR = '#9A9AAF'; // line 712
const DISTANCE_ICON_BG = '#EFF2FF'; // line 615
const DISTANCE_ICON_TINT = '#3F5DE8'; // line 616
const CURRENCY_ICON_BG = '#F1F2F8'; // line 627
const CURRENCY_ICON_TINT = '#8D92A8'; // line 628
const REMINDERS_ICON_BG = '#FFF3D9'; // line 639
const REMINDERS_ICON_TINT = '#F08A00'; // line 640
const TOGGLE_TRACK = '#F4F5FA'; // line 747
const TOGGLE_THUMB = '#1F1F2E'; // line 763
const TOGGLE_INACTIVE_TEXT = '#8A8AA3'; // line 786/807
const LOCKED_TEXT = '#8C8CA1'; // line 843
const LOCKED_ICON = '#C1C1D0'; // line 852

type Props = {
  user: AppUser;
  saving: boolean;
  onDistanceUnitChange: (unit: 'km' | 'mi') => void;
  onRenewalRemindersChange: (enabled: boolean) => void;
};

export function PreferencesCard({
  user,
  saving,
  onDistanceUnitChange,
  onRenewalRemindersChange,
}: Props) {
  const currencyInfo = currencyInfoFor(user.currency);

  return (
    <View style={styles.card}>
      <PreferenceRow
        icon="resize-outline"
        iconBg={DISTANCE_ICON_BG}
        iconTint={DISTANCE_ICON_TINT}
        title="Distance unit"
      >
        <DistanceUnitSelector
          value={user.distanceUnit}
          enabled={!saving}
          onChange={onDistanceUnitChange}
        />
      </PreferenceRow>
      <View style={styles.divider} />
      <PreferenceRow
        icon="cash-outline"
        iconBg={CURRENCY_ICON_BG}
        iconTint={CURRENCY_ICON_TINT}
        title="Currency"
        subtitle="Locked for this account"
      >
        <View style={styles.lockedRow}>
          <Text style={styles.lockedText} numberOfLines={1}>
            {user.currency} · {currencyInfo?.name ?? user.currency}
          </Text>
          <Ionicons name="lock-closed-outline" size={16} color={LOCKED_ICON} />
        </View>
      </PreferenceRow>
      <View style={styles.divider} />
      <PreferenceRow
        icon="notifications-outline"
        iconBg={REMINDERS_ICON_BG}
        iconTint={REMINDERS_ICON_TINT}
        title="Renewal reminders"
        subtitle="Alert before documents expire"
      >
        <Switch
          value={user.renewalRemindersEnabled}
          onValueChange={saving ? undefined : onRenewalRemindersChange}
          disabled={saving}
          trackColor={{ false: '#E3E3EC', true: '#FFD100' }}
          thumbColor={user.renewalRemindersEnabled ? TOGGLE_THUMB : '#FFFFFF'}
        />
      </PreferenceRow>
    </View>
  );
}

type RowProps = {
  icon: keyof typeof Ionicons.glyphMap;
  iconBg: string;
  iconTint: string;
  title: string;
  subtitle?: string;
  children: React.ReactNode;
};

function PreferenceRow({ icon, iconBg, iconTint, title, subtitle, children }: RowProps) {
  return (
    <View style={styles.row}>
      <View style={[styles.iconWrap, { backgroundColor: iconBg }]}>
        <Ionicons name={icon} size={20} color={iconTint} />
      </View>
      <View style={styles.rowText}>
        <Text style={styles.rowTitle}>{title}</Text>
        {subtitle ? <Text style={styles.rowSubtitle}>{subtitle}</Text> : null}
      </View>
      {children}
    </View>
  );
}

function DistanceUnitSelector({
  value,
  enabled,
  onChange,
}: {
  value: 'km' | 'mi';
  enabled: boolean;
  onChange: (unit: 'km' | 'mi') => void;
}) {
  return (
    <View style={styles.selector} pointerEvents={enabled ? 'auto' : 'none'}>
      <Pressable
        onPress={() => onChange('km')}
        style={[styles.selectorOption, value === 'km' && styles.selectorOptionActive]}
      >
        <Text style={[styles.selectorText, value === 'km' && styles.selectorTextActive]}>Km</Text>
      </Pressable>
      <Pressable
        onPress={() => onChange('mi')}
        style={[styles.selectorOption, value === 'mi' && styles.selectorOptionActive]}
      >
        <Text style={[styles.selectorText, value === 'mi' && styles.selectorTextActive]}>Miles</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: Colors.surface,
    borderRadius: 24,
    shadowColor: '#000000',
    shadowOpacity: 0.08,
    shadowRadius: 22,
    shadowOffset: { width: 0, height: 8 },
    elevation: 3,
  },
  divider: {
    height: 1,
    backgroundColor: Colors.divider,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 14,
    paddingVertical: 10,
  },
  iconWrap: {
    width: 40,
    height: 40,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  rowText: {
    flex: 1,
    marginLeft: 14,
  },
  rowTitle: {
    fontSize: 15,
    fontWeight: '700',
    color: TITLE_COLOR,
  },
  rowSubtitle: {
    marginTop: 2,
    fontSize: 13,
    fontWeight: '500',
    color: SUBTITLE_COLOR,
  },
  lockedRow: {
    flexDirection: 'row',
    alignItems: 'center',
    columnGap: 6,
    maxWidth: 160,
  },
  lockedText: {
    flexShrink: 1,
    fontSize: 13,
    fontWeight: '600',
    color: LOCKED_TEXT,
    textAlign: 'right',
  },
  selector: {
    width: 164,
    height: 44,
    padding: 4,
    borderRadius: 999,
    backgroundColor: TOGGLE_TRACK,
    flexDirection: 'row',
  },
  selectorOption: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 999,
  },
  selectorOptionActive: {
    backgroundColor: TOGGLE_THUMB,
  },
  selectorText: {
    fontSize: 13,
    fontWeight: '700',
    color: TOGGLE_INACTIVE_TEXT,
  },
  selectorTextActive: {
    color: '#FFFFFF',
  },
});
