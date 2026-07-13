/**
 * Shared header for add/edit form screens: Cancel left, centered title, Save pill right.
 * Parity with Flutter `shared/widgets/form_screen_app_bar.dart`.
 */

import { ActivityIndicator, Pressable, StyleSheet, Text, View } from 'react-native';

import { Colors } from '@/constants/theme';

type Props = {
  title: string;
  onSave?: () => void;
  onCancel?: () => void;
  saving?: boolean;
  cancelEnabled?: boolean;
  saveLabel?: string;
};

export function FormScreenAppBar({
  title,
  onSave,
  onCancel,
  saving = false,
  cancelEnabled = true,
  saveLabel = 'Save',
}: Props) {
  const saveDisabled = onSave == null;

  return (
    <View style={styles.bar}>
      <View style={styles.side}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel="Cancel"
          disabled={!cancelEnabled}
          onPress={onCancel}
          hitSlop={8}
        >
          <Text style={[styles.cancel, !cancelEnabled && styles.cancelDisabled]}>Cancel</Text>
        </Pressable>
      </View>

      <View style={styles.titleWrap}>
        <Text style={styles.title} numberOfLines={1}>
          {title}
        </Text>
      </View>

      <View style={[styles.side, styles.sideRight]}>
        {saving ? (
          <ActivityIndicator size="small" color={Colors.textPrimary} />
        ) : (
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={saveLabel}
            accessibilityState={{ disabled: saveDisabled }}
            disabled={saveDisabled}
            onPress={onSave}
            style={[styles.saveButton, saveDisabled && styles.saveButtonDisabled]}
          >
            <Text style={[styles.saveLabel, saveDisabled && styles.saveLabelDisabled]}>
              {saveLabel}
            </Text>
          </Pressable>
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  bar: {
    flexDirection: 'row',
    alignItems: 'center',
    height: 56,
    paddingHorizontal: 8,
    backgroundColor: Colors.surface,
  },
  side: {
    width: 80,
    justifyContent: 'center',
  },
  sideRight: {
    alignItems: 'flex-end',
  },
  titleWrap: {
    flex: 1,
    alignItems: 'center',
  },
  title: {
    fontSize: 16,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  cancel: {
    fontSize: 15,
    fontWeight: '400',
    color: Colors.textPrimary,
  },
  cancelDisabled: {
    color: Colors.textMuted,
  },
  saveButton: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 999,
    backgroundColor: Colors.primary,
  },
  saveButtonDisabled: {
    backgroundColor: Colors.divider,
  },
  saveLabel: {
    fontSize: 14,
    fontWeight: '700',
    color: Colors.onPrimary,
  },
  saveLabelDisabled: {
    color: Colors.textMuted,
  },
});
