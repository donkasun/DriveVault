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

    // Clamp the corner radius to half the height so the rounded rect never
    // becomes degenerate (radius ≫ height) — Impeller can otherwise clip the
    // whole bar to nothing on iOS.
    final cornerRadius = radius.clamp(0.0, height / 2);

    // All-zero / empty → show a neutral placeholder track.
    if (total == 0 || segments.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(cornerRadius),
        ),
      );
    }

    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cornerRadius),
      ),
      child: Row(
        // Stretch so each childless segment fills the bar height — without
        // this the segments collapse to zero height and paint nothing.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < segments.length; i++)
            _buildSegment(segments[i], total),
        ],
      ),
    );
  }

  Widget _buildSegment(BreakdownSegment segment, int total) {
    final fraction = segment.valueCents / total;

    // Skip zero-value segments to avoid hairline artefacts.
    if (fraction == 0) return const SizedBox.shrink();

    return Expanded(
      flex: (fraction * 1000).round(),
      child: DecoratedBox(
        decoration: BoxDecoration(color: segment.color),
      ),
    );
  }
}

/// A single legend entry: coloured dot + label + optional amount.
///
/// Matches the design's pill/legend spec — used in both the dashboard spend
/// card and the expense history summary card.
class LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  /// Pre-formatted amount string (e.g. "Rs 25,493"). Pass null to omit.
  final String? amountText;

  const LegendDot({
    super.key,
    required this.color,
    required this.label,
    this.amountText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        if (amountText != null) ...[
          const SizedBox(width: 5),
          Text(
            amountText!,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ],
    );
  }
}

/// Composes [BreakdownBar] + a legend row ([LegendDot]s) into one reusable
/// widget.  Pass [formatAmount] to show formatted amounts next to each label.
class BreakdownBarWithLegend extends StatelessWidget {
  final List<BreakdownSegment> segments;
  final String Function(int cents)? formatAmount;
  final double barHeight;

  const BreakdownBarWithLegend({
    super.key,
    required this.segments,
    this.formatAmount,
    this.barHeight = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BreakdownBar(segments: segments, height: barHeight),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (int i = 0; i < segments.length; i++) ...[
                if (i > 0) const SizedBox(width: 16),
                LegendDot(
                  color: segments[i].color,
                  label: segments[i].label,
                  amountText: formatAmount != null
                      ? formatAmount!(segments[i].valueCents)
                      : null,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
