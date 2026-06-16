import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// A labelled metric tile for dashboard-style stat displays.
///
/// Renders a white surface card (`appCardDecoration`) containing:
/// - A small uppercase muted [label] (overline style)
/// - A bold [value] string (pre-formatted by the caller)
/// - An optional [caption] / trend slot rendered below the value
/// - An optional [trailing] widget (e.g. a sparkline or icon)
///
/// Pure presentational — no providers, no API calls. The caller is
/// responsible for formatting [value] (e.g. via `formatCents` from
/// `lib/shared/utils/formatting.dart`).
///
/// ### Example
/// ```dart
/// StatCard(
///   label: 'Monthly fuel',
///   value: r'$120.00',
///   caption: '↑ 8% vs last month',
/// )
/// ```
class StatCard extends StatelessWidget {
  /// Short uppercase muted label shown above the value (e.g. "Monthly fuel").
  final String label;

  /// Pre-formatted value string shown in large bold type (e.g. "\$120.00").
  final String value;

  /// Optional secondary line below [value] — used for captions, trends, etc.
  final String? caption;

  /// Optional widget placed at the trailing edge of the card (right side).
  /// Useful for sparklines, status icons, or trend arrows.
  final Widget? trailing;

  /// Internal padding. Defaults to 16 px on all sides.
  final EdgeInsetsGeometry padding;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.trailing,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: 2),
          Text(
            caption!,
            style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ],
    );

    return DecoratedBox(
      decoration: appCardDecoration,
      child: Padding(
        padding: padding,
        child: trailing != null
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: content),
                  const SizedBox(width: 12),
                  trailing!,
                ],
              )
            : content,
      ),
    );
  }
}
