import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Form field that looks like a dropdown but opens a modal bottom sheet to pick
/// a value. Uses the root navigator so the sheet appears above shell UI (e.g.
/// floating tab bar).
///
/// Integrates with [Form] validation when a [validator] is provided: calling
/// `_formKey.currentState!.validate()` will trigger the validator and display
/// any error message below the field, just like a [TextFormField].
class BottomSheetPickerField<T> extends StatefulWidget {
  final String label;
  final String? sheetTitle;
  final T? value;
  final List<T> options;
  final String Function(T option) labelBuilder;
  final Widget Function(BuildContext context, T option, bool isSelected)?
  sheetItemBuilder;
  final ValueChanged<T>? onChanged;
  final bool enabled;

  /// Optional validator — same contract as [FormField.validator].
  /// Return a non-null string to show an error; return null for valid.
  final String? Function(T? value)? validator;

  const BottomSheetPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.labelBuilder,
    this.sheetItemBuilder,
    this.sheetTitle,
    this.onChanged,
    this.enabled = true,
    this.validator,
  });

  @override
  State<BottomSheetPickerField<T>> createState() =>
      _BottomSheetPickerFieldState<T>();
}

class _BottomSheetPickerFieldState<T> extends State<BottomSheetPickerField<T>> {
  final _fieldKey = GlobalKey<FormFieldState<T>>();

  @override
  void didUpdateWidget(BottomSheetPickerField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep FormField internal state in sync when the parent rebuilds with a
    // new value (e.g. after onChanged triggers setState in the parent).
    if (oldWidget.value != widget.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fieldKey.currentState?.didChange(widget.value);
      });
    }
  }

  Future<void> _openSheet(BuildContext context) async {
    if (!widget.enabled || widget.onChanged == null) return;

    final selected = await showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final maxListHeight = MediaQuery.sizeOf(ctx).height * 0.45;

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  widget.sheetTitle ?? widget.label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxListHeight),
                child: ListView(
                  shrinkWrap: true,
                  children: widget.options.map((option) {
                    final isSelected = option == widget.value;
                    if (widget.sheetItemBuilder != null) {
                      return InkWell(
                        onTap: () =>
                            Navigator.of(ctx, rootNavigator: true).pop(option),
                        child: widget.sheetItemBuilder!(
                          ctx,
                          option,
                          isSelected,
                        ),
                      );
                    }
                    return ListTile(
                      title: Text(widget.labelBuilder(option)),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check,
                              color: AppColors.textPrimary,
                            )
                          : null,
                      selected: isSelected,
                      onTap: () =>
                          Navigator.of(ctx, rootNavigator: true).pop(option),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      _fieldKey.currentState?.didChange(selected);
      widget.onChanged!(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayText = widget.value != null
        ? widget.labelBuilder(widget.value as T)
        : '';

    final decorator = GestureDetector(
      onTap: widget.enabled ? () => _openSheet(context) : null,
      child: FormField<T>(
        key: _fieldKey,
        initialValue: widget.value,
        validator: widget.validator,
        builder: (fieldState) {
          return InputDecorator(
            decoration: InputDecoration(
              labelText: widget.label,
              border: const OutlineInputBorder(),
              enabled: widget.enabled,
              errorText: fieldState.errorText,
              suffixIcon: Icon(
                Icons.keyboard_arrow_down,
                color: widget.enabled
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
              ),
            ),
            child: Text(
              displayText,
              style: TextStyle(
                fontSize: 16,
                color: widget.enabled
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
              ),
            ),
          );
        },
      ),
    );

    return decorator;
  }
}
