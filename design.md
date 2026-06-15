# DriveVault — UI/UX Redesign Brief

> Hand this file (plus screenshots of every current screen) to a design session.
> Goal: redesign the UI to be **more user-friendly, easier to navigate, and more usable**,
> while staying within the existing tech stack, navigation architecture, and brand palette.

---

## Your role
You are a senior product designer + Flutter UI engineer. I'm sharing **screenshots of every
current screen** of my mobile app, **DriveVault**. Critique what exists, then propose a
concrete, buildable redesign.

## What DriveVault is
A **personal vehicle-ownership management app** (Flutter, iOS-first). Users:
- Track multiple vehicles (car, motorcycle, pickup, other)
- Log every fuel fill-up and see fuel-economy trends
- Record maintenance/repair history
- Store documents (insurance, registration, warranty) with expiry reminders
- View a cross-vehicle expense & cost summary

**Target user:** an everyday vehicle owner (not a fleet manager) who wants their car's costs,
paperwork, and upkeep in one place. Primary value = peace of mind ("nothing is overdue, I know
what this vehicle costs me"). Currency is locked to **LKR** app-wide; there is no currency picker.

## Tech & layout constraints (must respect)
- **Flutter 3.44 + Riverpod + go_router.** Designs must be implementable with standard Flutter
  widgets — no web/CSS-only patterns. Mobile portrait; single-hand reach matters.
- **Money = integer cents**, displayed as LKR. **Mileage = integer km.** Never show floats for money.
- Architecture: only repositories call the API; widgets render state. Every async screen must
  handle **4 states: loading · empty · error · loaded** — design empty and error states, not
  just the happy path.
- **Don't propose backend/schema/API changes.** This is a pure UI/UX redesign of existing data.

## Current navigation (4-tab shell — keep unless you make a strong case)
Bottom **floating dark pill tab bar**, left→right: **Home · Garage · Expenses · Settings**.
Home is the default landing tab.
- **Home** — dashboard: total ownership cost (accent progress ring), this-month fuel spend,
  cost breakdown (fuel/maintenance/purchase), upcoming renewals (document expiry pills).
  Tapping a renewal deep-links into that vehicle.
- **Garage** — vertical list of **vehicle cards**; tap → **Vehicle detail** (one scrolling page:
  hero photo + stat row, then Fuel / Maintenance / Documents sections, each with an add action).
  A dashed "＋ Add Vehicle" card ends the list.
- **Expenses** — combined expense history across all vehicles.
- **Settings** — profile (name, email, avatar), edit profile, sign out.
- **Auth** (above the shell): Splash, Login, Sign-up, Forgot-password. Email/password sign-up
  shows a **soft, dismissible "verify your email" banner** on the dashboard — not a hard gate.
- **All create/edit forms are full-screen modal dialogs** with a shared app bar: centered title,
  **Cancel** (text, left) / **Save** (yellow pill, right). Fuel has a lightweight **quick-entry
  bottom sheet** (odometer + any two of {liters, total paid, price/L}, third derived) as the
  default add path.

## Current design language (the brand — evolve it, don't discard it)
- **Mood:** clean, light, high-contrast.
- **Palette**

  | Token | Hex | Use |
  |---|---|---|
  | `background` | `#EBEBF0` | App scaffold background (cool grey) |
  | `surface` | `#FFFFFF` | Cards, sheets, inputs |
  | `surfaceDark` | `#1E1D2B` | Vehicle cards, tab bar, dark hero sections |
  | `primary` | `#FFD600` | Buttons, active tab pill, highlights (yellow) |
  | `onPrimary` | `#1E1D2B` | Text/icons on yellow |
  | `textPrimary` | `#1A1A2E` | Body text, headings |
  | `textMuted` | `#9898A6` | Secondary labels, captions |
  | `success` | `#22C55E` | OK status pills |
  | `warning` | `#F59E0B` | Warning pills |
  | `danger` | `#EF4444` | Error / overdue |
  | `divider` | `#E2E2EA` | List dividers, input borders |

- **Shape/type:** card radius ~16–18px, tab-bar radius ~26px, generous padding; bold 800-weight
  titles; small uppercase muted labels with letter-spacing.
- **Signature components:** floating dark pill tab bar (active = white circle + colored icon);
  dark vehicle card (photo overlapping the top edge, name + reg, stat row of mileage · economy ·
  spent · docs); stat cards with progress rings + mini sparklines; full-screen modal forms.

## Deliverables (in order)
1. **Heuristic critique** of the current screens (from the screenshots): specific usability,
   hierarchy, navigation, and accessibility problems — reference the actual screens.
2. **Redesign principles** (3–6) tied to the problems found.
3. **Screen-by-screen redesign** for at least: Home/Dashboard, Garage list, Vehicle detail,
   the fuel quick-entry sheet, Expenses, and one auth screen. For each: what changes, why it
   improves usability/navigation, and how it handles loading/empty/error.
4. **Navigation & IA recommendations** — is the 4-tab split right? Are actions discoverable?
   Is the add-fuel / add-anything flow as fast as it should be?
5. **Component / design-system pass** — typography scale, spacing, stat card, list rows,
   pills/badges, buttons — consistent and reusable in Flutter.
6. **Accessibility** — tap target sizes, contrast (especially yellow-on-white and text-on-dark),
   one-handed reachability.

## How to work
- **Preserve the brand** (yellow/dark/light palette, card+pill language) — refine and modernize,
  don't replace it with a generic look.
- Prefer **concrete, annotated proposals** (ASCII wireframes or clear layout descriptions) over
  vague advice. Show before → after thinking.
- Flag any tradeoff where "prettier" fights "faster to use" — value **usability and speed over
  decoration**.
- If something in the screenshots is ambiguous, **ask before assuming.**

---

## Reference docs (source of truth in this repo)
- `docs/06-ui-screens.md` — navigation architecture + per-screen data/actions/states
- `docs/design-references/README.md` — palette, components, design language
- `docs/design-references/mockup-screens.html` — agreed v2 mockup baseline
- `docs/drivevault-notebooklm-context.md` — full app context
- `mobile/lib/core/theme/app_theme.dart` — `AppColors` (live palette tokens)
