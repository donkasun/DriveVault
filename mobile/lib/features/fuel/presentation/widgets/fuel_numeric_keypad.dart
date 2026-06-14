import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Custom one-handed numeric keypad for the quick fuel-entry sheet.
/// Injects characters into the currently-focused [TextEditingController].
///
/// Keys:
///   Row 1: 7 8 9
///   Row 2: 4 5 6
///   Row 3: 1 2 3
///   Row 4: . 0 ⌫
///
/// Each key is at least 48 dp tall (≥44 dp a11y minimum).
class FuelNumericKeypad extends StatelessWidget {
  /// The controller that keypad presses are sent to. Pass the controller of
  /// the currently-focused field; swap it when focus changes.
  final TextEditingController controller;

  /// Called after every key press (useful to notify parent to re-derive).
  final VoidCallback? onChanged;

  const FuelNumericKeypad({
    super.key,
    required this.controller,
    this.onChanged,
  });

  void _press(String key) {
    final ctrl = controller;
    final text = ctrl.text;
    final sel = ctrl.selection;

    // Determine the effective cursor position and selected range.
    final int start = sel.isValid
        ? sel.start.clamp(0, text.length)
        : text.length;
    final int end = sel.isValid ? sel.end.clamp(0, text.length) : text.length;

    String newText;
    int newCursor;

    if (key == '⌫') {
      if (start == end && start > 0) {
        // Delete char before cursor.
        newText = text.substring(0, start - 1) + text.substring(end);
        newCursor = start - 1;
      } else if (start != end) {
        // Delete selection.
        newText = text.substring(0, start) + text.substring(end);
        newCursor = start;
      } else {
        return;
      }
    } else {
      // Guard: only one decimal point.
      if (key == '.' && text.contains('.')) return;
      newText = text.substring(0, start) + key + text.substring(end);
      newCursor = start + key.length;
    }

    ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
    onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['7', '8', '9'],
      ['4', '5', '6'],
      ['1', '2', '3'],
      ['.', '0', '⌫'],
    ];
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in keys)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  for (final key in row) ...[
                    Expanded(
                      child: _KeyButton(label: key, onTap: () => _press(key)),
                    ),
                    if (key != row.last) const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _KeyButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDelete = label == '⌫';
    return Material(
      key: isDelete ? const ValueKey('keypad_backspace') : null,
      color: isDelete ? AppColors.background : AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDelete ? Colors.transparent : AppColors.divider,
            ),
          ),
          child: isDelete
              ? const Icon(
                  Icons.backspace_outlined,
                  size: 20,
                  color: AppColors.textPrimary,
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
        ),
      ),
    );
  }
}
