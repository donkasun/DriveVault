/**
 * Quick-add bottom sheet. Parity with Flutter `shared/widgets/quick_add_sheet.dart`.
 *
 * Presentational: it takes the vehicle list and callbacks as props (best-practices
 * §3) — the container wires the data. Actions other than "Add vehicle" are
 * disabled until at least one vehicle exists.
 */

import Ionicons from '@expo/vector-icons/Ionicons';
import { Modal, Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { Colors, Radii, Spacing, Typography } from '@/constants/theme';

export type QuickAddAction = 'fuel' | 'service' | 'document' | 'vehicle';

type Props = {
  visible: boolean;
  onClose: () => void;
  onSelect: (action: QuickAddAction) => void;
  /** Drives the enabled/disabled state of the first three actions. */
  hasVehicles: boolean;
  loading?: boolean;
  error?: string | null;
};

const ACTIONS: {
  action: QuickAddAction;
  icon: React.ComponentProps<typeof Ionicons>['name'];
  label: string;
  description: string;
  /** "Add vehicle" is always available — it is how you get your first vehicle. */
  alwaysEnabled?: boolean;
}[] = [
  {
    action: 'fuel',
    icon: 'car-sport',
    label: 'Log fuel',
    description: 'Record a fill-up',
  },
  {
    action: 'service',
    icon: 'build',
    label: 'Add service',
    description: 'Log a maintenance record',
  },
  {
    action: 'document',
    icon: 'cloud-upload',
    label: 'Upload document',
    description: 'Insurance, registration, etc.',
  },
  {
    action: 'vehicle',
    icon: 'car',
    label: 'Add vehicle',
    description: 'Register a new vehicle',
    alwaysEnabled: true,
  },
];

export function QuickAddSheet({
  visible,
  onClose,
  onSelect,
  hasVehicles,
  loading = false,
  error = null,
}: Props) {
  return (
    <Modal visible={visible} transparent animationType="slide" onRequestClose={onClose}>
      <Pressable style={styles.backdrop} onPress={onClose} accessibilityLabel="Dismiss" />

      <View style={styles.sheet}>
        <SafeAreaView edges={['bottom']}>
          <View style={styles.body}>
            <View style={styles.header}>
              <Text style={styles.title}>Quick add</Text>
              <Pressable
                accessibilityRole="button"
                accessibilityLabel="Close"
                testID="quick_add_close"
                onPress={onClose}
                style={styles.close}
              >
                <Ionicons name="close" size={20} color={Colors.textPrimary} />
              </Pressable>
            </View>

            {error ? <Text style={styles.error}>Could not load vehicles: {error}</Text> : null}

            {!loading && !error && !hasVehicles ? (
              <View style={styles.hint}>
                <Ionicons name="information-circle-outline" size={16} color={Colors.textMuted} />
                <Text style={styles.hintText}>
                  Add a vehicle first to log fuel, services, or documents.
                </Text>
              </View>
            ) : null}

            <ScrollView scrollEnabled={false}>
              {ACTIONS.map((item) => {
                const enabled = item.alwaysEnabled || (hasVehicles && !loading && !error);
                return (
                  <ActionRow
                    key={item.action}
                    icon={item.icon}
                    label={item.label}
                    description={item.description}
                    enabled={enabled}
                    onPress={() => onSelect(item.action)}
                  />
                );
              })}
            </ScrollView>
          </View>
        </SafeAreaView>
      </View>
    </Modal>
  );
}

type ActionRowProps = {
  icon: React.ComponentProps<typeof Ionicons>['name'];
  label: string;
  description: string;
  enabled: boolean;
  onPress: () => void;
};

function ActionRow({ icon, label, description, enabled, onPress }: ActionRowProps) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityState={{ disabled: !enabled }}
      testID={`quick_add_${label.toLowerCase().replace(/\s+/g, '_')}`}
      disabled={!enabled}
      onPress={onPress}
      style={({ pressed }) => [
        styles.row,
        !enabled && styles.rowDisabled,
        pressed && enabled && styles.rowPressed,
      ]}
    >
      <View style={styles.badge}>
        <Ionicons name={icon} size={20} color={Colors.onPrimary} />
      </View>

      <View style={styles.rowText}>
        <Text style={[styles.rowLabel, !enabled && styles.rowLabelDisabled]}>{label}</Text>
        <Text style={styles.rowDescription}>{description}</Text>
      </View>

      <Ionicons name="chevron-forward" size={20} color={Colors.textMuted} />
    </Pressable>
  );
}

const styles = StyleSheet.create({
  backdrop: {
    position: 'absolute',
    top: 0,
    right: 0,
    bottom: 0,
    left: 0,
    backgroundColor: 'rgba(0,0,0,0.4)',
  },
  sheet: {
    marginTop: 'auto',
    backgroundColor: Colors.surface,
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
  },
  body: {
    paddingHorizontal: Spacing.three,
    paddingTop: 20,
    paddingBottom: 12,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: Spacing.three,
  },
  title: {
    ...Typography.titleMedium,
    flex: 1,
    color: Colors.textPrimary,
  },
  close: {
    width: 32,
    height: 32,
    borderRadius: Radii.pill,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: Colors.background,
  },
  error: {
    color: Colors.danger,
    marginBottom: Spacing.three,
  },
  hint: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderRadius: Radii.field,
    backgroundColor: Colors.background,
    marginBottom: 12,
  },
  hintText: {
    ...Typography.bodySmall,
    color: Colors.textMuted,
    marginLeft: Spacing.two,
    flex: 1,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    minHeight: 56,
    paddingHorizontal: 14,
    paddingVertical: 12,
    borderRadius: 14,
    backgroundColor: Colors.background,
    marginBottom: Spacing.two,
  },
  rowDisabled: {
    opacity: 0.45,
  },
  rowPressed: {
    opacity: 0.8,
  },
  badge: {
    width: 40,
    height: 40,
    borderRadius: 10,
    backgroundColor: Colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  rowText: {
    flex: 1,
    marginLeft: 14,
  },
  rowLabel: {
    fontSize: 15,
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  rowLabelDisabled: {
    color: Colors.textMuted,
  },
  rowDescription: {
    fontSize: 12,
    color: Colors.textMuted,
  },
});
