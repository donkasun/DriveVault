import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, outline }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final Widget? icon;
  final bool expand;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final bg = switch (variant) {
      AppButtonVariant.primary   => AppColors.primary,
      AppButtonVariant.secondary => AppColors.surfaceDark,
      AppButtonVariant.outline   => Colors.transparent,
    };
    final fg = switch (variant) {
      AppButtonVariant.primary   => AppColors.onPrimary,
      AppButtonVariant.secondary => AppColors.textOnDark,
      AppButtonVariant.outline   => AppColors.textPrimary,
    };
    final side = variant == AppButtonVariant.outline
        ? const BorderSide(color: AppColors.divider, width: 1.5)
        : BorderSide.none;

    final style = ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      disabledBackgroundColor: bg.withValues(alpha: 0.5),
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: side,
      ),
      minimumSize: expand ? const Size(double.infinity, 48) : const Size(0, 48),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    );

    final child = isLoading
        ? SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconTheme(data: IconThemeData(color: fg, size: 18), child: icon!),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              )
            : Text(label);

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child: child,
    );
  }
}
