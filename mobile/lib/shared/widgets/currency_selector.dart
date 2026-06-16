import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../constants/currencies.dart';
import 'bottom_sheet_picker_field.dart';

/// Fixed symbol column width — keeps currency names vertically aligned.
const _symbolColumnWidth = 44.0;

/// Profile currency picker: bottom-sheet field with symbol + name rows.
class CurrencySelector extends StatelessWidget {
  final String? value;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  const CurrencySelector({
    super.key,
    required this.value,
    this.onChanged,
    this.enabled = true,
  });

  static String _fieldLabel(String code) {
    final info = currencyInfoFor(code);
    return info?.name ?? code;
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetPickerField<String>(
      label: 'Currency',
      sheetTitle: 'Select currency',
      value: value != null && profileCurrencyCodes.contains(value)
          ? value
          : null,
      options: profileCurrencyCodes,
      labelBuilder: _fieldLabel,
      sheetItemBuilder: (context, code, isSelected) =>
          _CurrencySelectorRow(code: code, isSelected: isSelected),
      enabled: enabled,
      onChanged: onChanged,
    );
  }
}

class _CurrencySelectorRow extends StatelessWidget {
  final String code;
  final bool isSelected;

  const _CurrencySelectorRow({
    required this.code,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final info = currencyInfoFor(code)!;

    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      color: isSelected ? AppColors.primary.withValues(alpha: 0.28) : null,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          SizedBox(
            width: _symbolColumnWidth,
            child: Text(
              info.symbol,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              info.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isSelected)
            const Icon(Icons.check, color: AppColors.textPrimary, size: 20),
        ],
      ),
    );
  }
}
