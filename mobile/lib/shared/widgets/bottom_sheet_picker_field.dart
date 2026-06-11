import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Form field that looks like a dropdown but opens a modal bottom sheet to pick
/// a value. Uses the root navigator so the sheet appears above shell UI (e.g.
/// floating tab bar).
class BottomSheetPickerField<T> extends StatelessWidget {
  final String label;
  final String? sheetTitle;
  final T? value;
  final List<T> options;
  final String Function(T option) labelBuilder;
  final Widget Function(BuildContext context, T option, bool isSelected)?
      sheetItemBuilder;
  final ValueChanged<T>? onChanged;
  final bool enabled;

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
  });

  Future<void> _openSheet(BuildContext context) async {
    if (!enabled || onChanged == null) return;

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
                  sheetTitle ?? label,
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
                  children: options.map((option) {
                    final isSelected = option == value;
                    if (sheetItemBuilder != null) {
                      return InkWell(
                        onTap: () =>
                            Navigator.of(ctx, rootNavigator: true).pop(option),
                        child: sheetItemBuilder!(ctx, option, isSelected),
                      );
                    }
                    return ListTile(
                      title: Text(labelBuilder(option)),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: AppColors.textPrimary)
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

    if (selected != null) onChanged!(selected);
  }

  @override
  Widget build(BuildContext context) {
    final displayText = value != null ? labelBuilder(value as T) : '';

    return GestureDetector(
      onTap: enabled ? () => _openSheet(context) : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          enabled: enabled,
          suffixIcon: Icon(
            Icons.keyboard_arrow_down,
            color: enabled ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
        child: Text(
          displayText,
          style: TextStyle(
            fontSize: 16,
            color: enabled ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
