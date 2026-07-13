/**
 * Auth form field: uppercase label + filled white rounded input.
 * Parity with Flutter login_screen `_FieldLabel` + `_fieldDecoration`.
 */

import { forwardRef } from 'react';
import { StyleSheet, Text, TextInput, View, type TextInputProps } from 'react-native';

import { Colors, Spacing } from '@/constants/theme';

type Props = TextInputProps & {
  label: string;
  /** Rendered inside the field, left of the text (Flutter's prefixIcon). */
  prefix?: React.ReactNode;
  /** Rendered inside the field, right of the text (e.g. the "Forgot?" button). */
  suffix?: React.ReactNode;
  error?: string | null;
};

export const AuthField = forwardRef<TextInput, Props>(function AuthField(
  { label, prefix, suffix, error, style, ...inputProps },
  ref,
) {
  return (
    <View>
      <Text style={styles.label}>{label}</Text>
      <View style={[styles.field, !!error && styles.fieldError]}>
        {prefix ? <View style={styles.prefix}>{prefix}</View> : null}
        <TextInput
          ref={ref}
          style={[styles.input, style]}
          placeholderTextColor={Colors.textMuted}
          autoCapitalize="none"
          autoCorrect={false}
          {...inputProps}
        />
        {suffix ? <View style={styles.suffix}>{suffix}</View> : null}
      </View>
      {error ? <Text style={styles.errorText}>{error}</Text> : null}
    </View>
  );
});

const styles = StyleSheet.create({
  label: {
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 1.4,
    color: Colors.textMuted,
    marginBottom: 6,
  },
  field: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.surface,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: 'transparent',
    minHeight: 52,
  },
  fieldError: {
    borderColor: Colors.danger,
  },
  prefix: {
    paddingLeft: Spacing.three,
  },
  suffix: {
    paddingRight: Spacing.half,
  },
  input: {
    flex: 1,
    fontSize: 15,
    color: Colors.textPrimary,
    paddingHorizontal: Spacing.three,
    paddingVertical: 15,
  },
  errorText: {
    marginTop: Spacing.one,
    fontSize: 12,
    color: Colors.danger,
  },
});
