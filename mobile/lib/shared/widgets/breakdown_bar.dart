import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// One segment of a [BreakdownBar].
class BreakdownSegment {
  final String label;
  final int valueCents;
  final Color color;

  const BreakdownSegment({
    required this.label,
    required this.valueCents,
    required this.color,
  });
}

/// A horizontal proportional bar for cost-breakdown visualisations.
///
/// Renders each [segments] entry as a proportional slice of the bar.
/// The first segment gets a fully rounded left cap; the last gets a
/// fully rounded right cap. Segments in the middle are square-edged so
/// they abut cleanly. When all values are zero (or [segments] is empty),
/// a neutral muted-grey track is shown instead.
///
/// Pure presentational — no providers, no API calls. Accepts pre-formatted
/// strings via [BreakdownSegment.label] and cents values for proportion math.
///
/// ### Example
/// ```dart
/// BreakdownBar(
///   segments: const [
///     BreakdownSegment(label: 'Fuel',        valueCents: 8400,  color: AppColors.primary),
///     BreakdownSegment(label: 'Maintenance',  valueCents: 3200,  color: AppColors.surfaceDark),
///     BreakdownSegment(label: 'Purchase',     valueCents: 15000, color: AppColors.textMuted),
///   ],
/// )
/// ```
class BreakdownBar extends StatelessWidget {
  final List<BreakdownSegment> segments;

  /// Height of the rendered bar track. Defaults to 8 px.
  final double height;

  /// Corner radius of the outer bar (applies to the first and last caps).
  /// Defaults to 100 (fully pill-shaped ends).
  final double radius;

  const BreakdownBar({
    super.key,
    required this.segments,
    this.height = 8,
    this.radius = 100,
  });

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<int>(0, (sum, s) => sum + s.valueCents);

    // All-zero / empty → show a neutral placeholder track.
    if (total == 0 || segments.isEmpty) {
      return SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Row(
          children: [
            for (int i = 0; i < segments.length; i++)
              _buildSegment(segments[i], total, i, segments.length),
          ],
        ),
      ),
    );
  }

  Widget _buildSegment(
    BreakdownSegment segment,
    int total,
    int index,
    int count,
  ) {
    final fraction = segment.valueCents / total;

    // Skip zero-value segments to avoid hairline artefacts.
    if (fraction == 0) return const SizedBox.shrink();

    return Expanded(
      flex: (fraction * 1000).round(),
      child: ColoredBox(color: segment.color),
    );
  }
}
