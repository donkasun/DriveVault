/**
 * Add/edit driving-credential form. Parity with Flutter
 * `driving_credentials/presentation/driving_credential_form_screen.dart`.
 *
 * One component handles both modes: pass `credential` to edit an existing
 * one, omit it to create a new one. Only `hooks.ts` talks to the API.
 */

import { useState } from 'react';
import { Alert, ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';

import { BottomSheetPickerField } from '@/components/bottom-sheet-picker-field';
import { FormScreenAppBar } from '@/components/form-screen-app-bar';
import { Colors, Radii, Spacing } from '@/constants/theme';
import { buildCreatePayload, buildUpdatePayload, type CredentialFormState } from '../credential-form';
import { useCreateCredential, useDeleteCredential, useUpdateCredential } from '../hooks';
import { CREDENTIAL_DOC_TYPES, credentialLabelFor, type DrivingCredential } from '../types';
import { CredentialDateField } from './credential-date-field';

type Props = {
  existing?: DrivingCredential;
  onDone: (didChange: boolean) => void;
};

export function DrivingCredentialFormScreen({ existing, onDone }: Props) {
  const isEdit = existing != null;

  const [state, setState] = useState<CredentialFormState>({
    docType: (existing?.docType as CredentialFormState['docType']) ?? 'license',
    docNumber: existing?.docNumber ?? '',
    issueDate: existing?.issueDate ?? '',
    expiryDate: existing?.expiryDate ?? '',
    notes: existing?.notes ?? '',
  });
  const [docTypeError, setDocTypeError] = useState<string | null>(null);

  const createCredential = useCreateCredential();
  const updateCredential = useUpdateCredential(existing?.id ?? '');
  const deleteCredential = useDeleteCredential();

  const saving = createCredential.isPending || updateCredential.isPending || deleteCredential.isPending;

  async function handleSave() {
    if (!state.docType) {
      setDocTypeError('Please select a type');
      return;
    }
    setDocTypeError(null);

    try {
      if (isEdit) {
        await updateCredential.mutateAsync(buildUpdatePayload(state));
      } else {
        await createCredential.mutateAsync(buildCreatePayload(state));
      }
      onDone(true);
    } catch (e) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Could not save');
    }
  }

  function handleDelete() {
    if (!existing) return;
    const label = credentialLabelFor(existing.docType);
    Alert.alert(`Delete "${label}"?`, 'This cannot be undone.', [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Delete',
        style: 'destructive',
        onPress: async () => {
          try {
            await deleteCredential.mutateAsync(existing.id);
            onDone(true);
          } catch (e) {
            Alert.alert('Error', e instanceof Error ? e.message : 'Could not delete');
          }
        },
      },
    ]);
  }

  return (
    <View style={styles.screen}>
      <FormScreenAppBar
        title={isEdit ? 'Edit Credential' : 'Add Credential'}
        saving={saving}
        onSave={handleSave}
        onCancel={() => onDone(false)}
      />
      <ScrollView contentContainerStyle={styles.content} keyboardShouldPersistTaps="handled">
        <BottomSheetPickerField
          label="Document Type *"
          sheetTitle="Select credential type"
          value={state.docType}
          options={[...CREDENTIAL_DOC_TYPES]}
          getOptionLabel={credentialLabelFor}
          onSelect={(v) => setState((s) => ({ ...s, docType: v }))}
          enabled={!isEdit}
          error={docTypeError}
        />

        <View style={styles.fieldGap}>
          <Text style={styles.fieldLabel}>Document Number</Text>
          <TextInput
            style={styles.input}
            value={state.docNumber}
            onChangeText={(v) => setState((s) => ({ ...s, docNumber: v }))}
          />
        </View>

        <CredentialDateField
          label="Issue Date"
          value={state.issueDate}
          onChange={(v) => setState((s) => ({ ...s, issueDate: v }))}
        />

        <CredentialDateField
          label="Expiry Date"
          value={state.expiryDate}
          onChange={(v) => setState((s) => ({ ...s, expiryDate: v }))}
        />
        {!state.expiryDate ? (
          <Text style={styles.hint}>Add an expiry date to receive renewal reminders.</Text>
        ) : null}

        <View style={styles.fieldGap}>
          <Text style={styles.fieldLabel}>Notes</Text>
          <TextInput
            style={[styles.input, styles.notesInput]}
            value={state.notes}
            onChangeText={(v) => setState((s) => ({ ...s, notes: v }))}
            multiline
            numberOfLines={3}
          />
        </View>

        {isEdit ? (
          <Text style={styles.deleteLink} onPress={saving ? undefined : handleDelete}>
            Delete Credential
          </Text>
        ) : null}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  content: {
    padding: Spacing.three,
  },
  fieldGap: {
    marginBottom: Spacing.two + 8,
  },
  fieldLabel: {
    fontSize: 12,
    color: Colors.textMuted,
    marginBottom: 4,
  },
  input: {
    minHeight: 52,
    borderWidth: 1,
    borderColor: Colors.divider,
    borderRadius: Radii.field,
    paddingHorizontal: Spacing.three,
    fontSize: 16,
    color: Colors.textPrimary,
    backgroundColor: Colors.surface,
  },
  notesInput: {
    minHeight: 88,
    textAlignVertical: 'top',
    paddingVertical: 12,
  },
  hint: {
    marginTop: -8,
    marginBottom: Spacing.two + 8,
    fontSize: 12,
    color: Colors.textMuted,
  },
  deleteLink: {
    marginTop: Spacing.four,
    textAlign: 'center',
    fontSize: 15,
    fontWeight: '600',
    color: Colors.danger,
  },
});
