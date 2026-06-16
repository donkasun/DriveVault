import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Shared AppBar for add/edit form screens: Cancel left, centered title, Save pill right.
class FormScreenAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FormScreenAppBar({
    super.key,
    required this.title,
    this.onSave,
    this.onCancel,
    this.saving = false,
    this.cancelEnabled = true,
    this.saveLabel = 'Save',
  });

  final String title;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;
  final bool saving;
  final bool cancelEnabled;
  final String saveLabel;

  static const _titleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  static const _saveButtonPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 6,
  );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      leadingWidth: 80,
      title: Text(title, style: _titleStyle),
      leading: TextButton(
        onPressed: cancelEnabled
            ? (onCancel ?? () => Navigator.of(context).pop())
            : null,
        style: TextButton.styleFrom(foregroundColor: AppColors.textPrimary),
        child: const Text('Cancel', maxLines: 1),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: saving
              ? const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
                  onPressed: onSave,
                  style: TextButton.styleFrom(
                    backgroundColor: onSave != null
                        ? AppColors.primary
                        : AppColors.divider,
                    foregroundColor: onSave != null
                        ? AppColors.onPrimary
                        : AppColors.textMuted,
                    disabledBackgroundColor: AppColors.divider,
                    disabledForegroundColor: AppColors.textMuted,
                    padding: _saveButtonPadding,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  child: Text(saveLabel),
                ),
        ),
      ],
    );
  }
}
