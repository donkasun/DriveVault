# DriveVault — v2 Redesign Implementation Plan

> Source of the design: `docs/design-references/DriveVault Redesign (offline).html` (Claude
> design export — critique + 6 principles + screen-by-screen + IA + design system + a11y).
> This plan turns that into ordered, scoped, buildable tasks. Brand & 4-tab IA are preserved.

## Decisions (locked 2026-06-14)
- **API scope: FULL.** Extend `/dashboard` with upcoming renewals **and** recent activity, and
  add a **docs-status** field to the vehicle list. (vs. renewals-only / UI-only.)
- **Center FAB: YES.** Add a central `+` to the floating tab bar that opens a global quick-add
  sheet (Fuel / Service / Document / Vehicle), Fuel as default.
- **Delivery:** this phased plan doc; execute one task at a time, offloading implementation to
  Sonnet subagents per `CLAUDE.md`.

## The six redesign principles (the lens for every task)
1. One number, one meaning — no decorative ring, no triple-counted total, money never truncates.
2. Lead with peace of mind — renewals / "you're all set" own the top of Home.
3. Capture in three taps — fuel = smart sheet, live-derive, numeric keypad, vehicle pre-selected.
4. Respect the chrome — content always clears the floating tab bar.
5. Contrast is non-negotiable — yellow is **fill behind dark ink only**, never text; WCAG AA.
6. Human data — one economy unit, plausible math, friendly dates, real `0` not `—`.

---

## Phase 1 — Auth flows  ← IN PROGRESS (current focus)

**Problem:** every auth screen still uses the **retired green `#16A34A` / amber `#F5B301`**
palette and the off-white `#F3F4F7` background — none use the new `AppColors` (yellow `#FFD600`
on dark `#1E1D2B`, `#EBEBF0` scaffold) already defined in `mobile/lib/core/theme/app_theme.dart`.
Redesign brief for auth: *"a dark panel, the wordmark, and a single clear path in."*

**Scope (UI-only — no contract/schema change):**
- `splash_screen.dart` — yellow/dark brand mark + `AppColors`; spinner uses `primary`.
- `login_screen.dart` — **dark branded header panel** (yellow rounded logo + "DriveVault"
  wordmark on `surfaceDark`), light card below; primary button = **yellow fill + dark ink**
  (not green); "Forgot password" + "Create account" links use dark/ink, not amber; Google
  button unchanged in function.
- `signup_screen.dart` — same treatment; keep optional display-name field.
- `forgot_password_screen.dart` — same; success state uses `successBg`, not the old green wash.
- `verify_email_screen.dart` — legacy screen (no longer gated) restyled for consistency.
- `widgets/verify_email_banner.dart` — already clean; just confirm it reads `AppColors`.

**Design rules to apply:**
- Replace all hardcoded hex with `AppColors` tokens. Background → `AppColors.background`.
- Primary CTA → `AppColors.primary` fill, `AppColors.onPrimary` text (yellow-on-dark, AA).
- Use the **darkened muted** `#73738A` for secondary text where contrast matters (the redesign's
  AA-safe muted), not `Colors.grey`.
- Replace `Icons.directions_car_filled` brand glyph with the wordmark + yellow logo tile
  (matches the topbar logo in the redesign: a rounded yellow square with a dark speedometer icon).
- Keep all auth **logic, routes, and Firebase calls unchanged** — purely visual.

**Done when:** auth screens render in the yellow/dark identity; no `0xFF16A34A`/`0xFFF5B301`/
`0xFFF3F4F7` left in `features/auth`; `flutter analyze` clean for auth; existing auth widget
tests pass (`flutter test test/features/auth` if present) and any color-asserting tests updated.

---

## Phase 2 — Home / Dashboard
- "Needs attention" card first (overdue + ≤30d renewals, each deep-links to the vehicle).
- One honest spend card (total + fuel/maintenance breakdown bar; this-month secondary). Remove
  decorative ring + dead "Rs 0" tile. Recent-activity list. Graceful greeting fallback.
- **Backend:** `/dashboard` gains `upcomingRenewals[]` + `recentActivity[]` (see Phase 6).

## Phase 3 — Fuel quick-entry sheet (#1 daily action)
- Full-page form → **bottom sheet**; live-derive (any 2 of liters/total/price → 3rd, tagged
  AUTO); custom numeric keypad bottom third; Full/Partial toggle; vehicle pre-selected. Client-only.

## Phase 4 — Garage + Vehicle detail
- Garage: contained photo banner, single economy unit (km/L), card collapses 8 micro-targets →
  tappable card + "Log fuel"; **docs status pill**. Vehicle detail: stat row off the photo onto a
  card, bottom padding clears tab bar, docs ring, delete → confirm sheet, colour-coded expiry.
- **Backend:** vehicle list gains derived `docsStatus`.

## Phase 5 — Expenses + Settings + center-FAB nav
- Expenses: title + All-time/Month toggle, breakdown bar, category-led rows, month grouping.
- Settings: phantom currency picker → locked LKR row; **renewal-reminders toggle** (prefs already
  scaffolded in backend); sign-out → quiet neutral row (not red).
- Nav: central `+` FAB → global quick-add sheet; prototype offers a plain-4-tab fallback toggle.

## Phase 6 — Backend / DB (supports Phases 2,4,5)
- `users`: renewal-reminder preference fields + migration `f4001_user_renewal_reminders` (started).
- `/dashboard`: add `upcomingRenewals[]` (computed from document `expiry_date`) + `recentActivity[]`.
- Vehicle list: derived `docsStatus` (valid / N needs-action) to avoid N+1 calls.
- Shared **status scale** (ok / soon ≤30d / overdue) reused by renewal pills, doc rows, alerts.
- Update `02-database-schema.md` + `03-api-contract.md` to match before mobile consumes them.

---

## Cross-cutting (apply everywhere)
- **Status scale:** ok = `success`, soon (≤30d) = `warning`, overdue = `danger`; same thresholds app-wide.
- **Contrast:** yellow = fill-only; muted text darkened to AA; white-on-dark ≥ 12:1.
- **Tap targets ≥ 44px**; primary actions in the bottom third; content clears the floating bar.
- **Every async screen** designs all four states: loading · empty · error · loaded.
