import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../features/dashboard/domain/dashboard_data.dart';
import '../../features/vehicles/domain/vehicle.dart';

/// The semantic tone of a [StatusPill].
///
/// Maps to the cross-cutting status scale documented in `docs/redesign-plan.md`:
/// - [ok]      → success green (`AppColors.success` / `AppColors.successBg`)
/// - [soon]    → warning amber (`AppColors.warning` / `AppColors.warningBg`)
/// - [overdue] → danger  red   (`AppColors.danger`  / `AppColors.dangerBg`)
/// - [neutral] → muted grey   (`AppColors.textMuted` / `AppColors.divider`)
enum PillTone { ok, soon, overdue, neutral }

/// A small rounded pill: tinted background + same-hue ink text + optional leading glyph.
///
/// Pure presentational — no providers, no API calls.
///
/// ### Minimal usage
/// ```dart
/// StatusPill(label: 'Valid', tone: PillTone.ok)
/// ```
///
/// ### From a [RenewalStatus] enum
/// ```dart
/// StatusPill.fromRenewalStatus(RenewalStatus.soon, daysRemaining: 14)
/// ```
///
/// ### From a [DocsStatus] model
/// ```dart
/// StatusPill.fromDocsStatus(vehicle.docsStatus)
/// ```
class StatusPill extends StatelessWidget {
  final String label;
  final PillTone tone;

  /// Optional leading glyph text (e.g. "✓", "⚠"). Kept as a plain string so
  /// it renders with the same style as the label rather than an Icon widget.
  final String? glyph;

  /// When non-null the pill becomes tappable with a minimum height of 44 px
  /// (a11y touch target). Without [onTap] the minimum height is 24 px.
  final VoidCallback? onTap;

  const StatusPill({
    super.key,
    required this.label,
    required this.tone,
    this.glyph,
    this.onTap,
  });

  // ── Domain helpers ──────────────────────────────────────────────────────────

  /// Creates a [StatusPill] from a [RenewalStatus] enum value.
  ///
  /// - [ok]      → "✓ Valid"
  /// - [soon]    → "◷ Nd left"  (supply [daysRemaining] for the count)
  /// - [overdue] → "⚠ Overdue"
  factory StatusPill.fromRenewalStatus(
    RenewalStatus status, {
    int? daysRemaining,
    Key? key,
    VoidCallback? onTap,
  }) {
    final (glyph, label, tone) = switch (status) {
      RenewalStatus.ok => ('✓', 'Valid', PillTone.ok),
      RenewalStatus.soon => (
        '◷',
        daysRemaining != null ? '${daysRemaining}d left' : 'Soon',
        PillTone.soon,
      ),
      RenewalStatus.overdue => ('⚠', 'Overdue', PillTone.overdue),
    };
    return StatusPill(
      key: key,
      label: label,
      tone: tone,
      glyph: glyph,
      onTap: onTap,
    );
  }

  /// Creates a [StatusPill] from a [DocsStatus] model.
  ///
  /// - `"valid"`        → "Docs valid"   (ok)
  /// - `"needs_action"` → "N need action" (warning when count>0, danger when ≥3)
  /// - `"none"` / other → "No docs"      (neutral)
  factory StatusPill.fromDocsStatus(
    DocsStatus status, {
    Key? key,
    VoidCallback? onTap,
  }) {
    final (glyph, label, tone) = switch (status.state) {
      'valid' => ('✓', 'Docs valid', PillTone.ok),
      'needs_action' => (
        '⚠',
        '${status.needsActionCount} need action',
        status.needsActionCount >= 3 ? PillTone.overdue : PillTone.soon,
      ),
      _ => (null as String?, 'No docs', PillTone.neutral),
    };
    return StatusPill(
      key: key,
      label: label,
      tone: tone,
      glyph: glyph,
      onTap: onTap,
    );
  }

  // ── Color resolution ────────────────────────────────────────────────────────

  static Color _bg(PillTone tone) => switch (tone) {
    PillTone.ok => AppColors.successBg,
    PillTone.soon => AppColors.warningBg,
    PillTone.overdue => AppColors.dangerBg,
    PillTone.neutral => AppColors.divider,
  };

  static Color _ink(PillTone tone) => switch (tone) {
    PillTone.ok => AppColors.success,
    PillTone.soon => AppColors.warning,
    PillTone.overdue => AppColors.danger,
    PillTone.neutral => AppColors.textMuted,
  };

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bg = _bg(tone);
    final ink = _ink(tone);
    final isTappable = onTap != null;

    final pill = Container(
      constraints: BoxConstraints(minHeight: isTappable ? 44 : 24),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (glyph != null) ...[
            Text(
              glyph!,
              style: TextStyle(
                color: ink,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: ink,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              height: 1,
            ),
          ),
        ],
      ),
    );

    if (!isTappable) return pill;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: pill,
    );
  }
}
