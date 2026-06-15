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

  /// Override the glyph font size. Defaults to 12 (same as label). Use to
  /// compensate for glyphs that render optically small at the same point size
  /// (e.g. ◷ needs ~14 to match ⚠ at 12).
  final double glyphSize;

  /// When non-null the pill becomes tappable with a minimum height of 44 px
  /// (a11y touch target). Without [onTap] the minimum height is 24 px.
  final VoidCallback? onTap;

  /// Use on dark-surface cards (e.g. Needs Attention). Switches to solid
  /// light backgrounds + dark ink so the pill reads against the dark card.
  final bool onDark;

  const StatusPill({
    super.key,
    required this.label,
    required this.tone,
    this.glyph,
    this.glyphSize = 12,
    this.onTap,
    this.onDark = false,
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
    bool onDark = false,
  }) {
    final (glyph, label, tone, glyphSize) = switch (status) {
      RenewalStatus.ok => ('✓', 'Valid', PillTone.ok, 12.0),
      RenewalStatus.soon => (
        '⊙',
        daysRemaining != null ? '${daysRemaining}d left' : 'Soon',
        PillTone.soon,
        12.0,
      ),
      RenewalStatus.overdue => (
        '⚠',
        daysRemaining != null
            ? 'Overdue ${daysRemaining.abs()}d'
            : 'Overdue',
        PillTone.overdue,
        12.0,
      ),
    };
    return StatusPill(
      key: key,
      label: label,
      tone: tone,
      glyph: glyph,
      glyphSize: glyphSize,
      onTap: onTap,
      onDark: onDark,
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
  // Light-surface default: translucent tinted bg + pastel ink.
  // Dark-surface (onDark): solid light bg + dark ink — matches design's pill
  // style inside the dark Needs Attention card.

  static Color _bg(PillTone tone, {bool onDark = false}) {
    if (onDark) {
      return switch (tone) {
        PillTone.ok      => const Color(0xFFDCFCE7), // solid light green
        PillTone.soon    => const Color(0xFFFCF1DC), // solid light amber — design rgb(252,241,220)
        PillTone.overdue => const Color(0xFFFCEBEB), // solid light red  — design rgb(252,235,235)
        PillTone.neutral => const Color(0xFFE8E8F0), // solid light grey
      };
    }
    return switch (tone) {
      PillTone.ok      => AppColors.successBg,
      PillTone.soon    => AppColors.warningBg,
      PillTone.overdue => AppColors.dangerBg,
      PillTone.neutral => const Color(0x14FFFFFF),
    };
  }

  static Color _ink(PillTone tone, {bool onDark = false}) {
    if (onDark) {
      return switch (tone) {
        PillTone.ok      => const Color(0xFF15803D), // dark green
        PillTone.soon    => const Color(0xFFB45309), // dark amber — design rgb(180,83,9)
        PillTone.overdue => const Color(0xFFDC2626), // dark red   — design rgb(220,38,38)
        PillTone.neutral => AppColors.textMuted,
      };
    }
    return switch (tone) {
      PillTone.ok      => AppColors.success,
      PillTone.soon    => AppColors.warning,
      PillTone.overdue => AppColors.danger,
      PillTone.neutral => AppColors.textOnDarkMuted,
    };
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bg = _bg(tone, onDark: onDark);
    final ink = _ink(tone, onDark: onDark);
    final isTappable = onTap != null;

    final pill = Container(
      constraints: BoxConstraints(minHeight: isTappable ? 44 : 24),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
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
                fontSize: glyphSize,
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
              fontSize: 12,
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
