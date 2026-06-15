import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../utils/formatting.dart';

/// Shared visual card used in both the home screen "Recent activity" list
/// and the Expenses screen expense list.
///
/// Callers are responsible for wrapping with Dismissible (if needed) and
/// adding vertical spacing between cards.
class ActivityEntryCard extends StatelessWidget {
  /// Leading 40×40 icon widget.
  final Widget icon;

  /// Primary bold text (e.g. "Fuel" or "Oil Change").
  final String title;

  /// Optional lighter text shown below the title (e.g. vehicle name when
  /// multiple vehicles exist).
  final String? titleSub;

  /// Secondary muted text (e.g. "Today · 12.3 L · Full").
  final String subLabel;

  final int? amountCents;
  final String currency;
  final VoidCallback? onTap;

  const ActivityEntryCard({
    super.key,
    required this.icon,
    required this.title,
    this.titleSub,
    required this.subLabel,
    this.amountCents,
    this.currency = 'USD',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: appCardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          text: title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          children: titleSub != null
                              ? [
                                  TextSpan(
                                    text: '  $titleSub',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subLabel,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (amountCents != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    formatCents(amountCents!, currency: currency),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
