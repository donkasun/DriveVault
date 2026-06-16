import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Circular close button used in bottom sheet headers.
/// Light lavender background with a muted X icon.
class SheetCloseButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const SheetCloseButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed ?? () => Navigator.of(context).pop(),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFEEEEF5),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.close_rounded,
          size: 16,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
