# DriveVault — Design References

Visual direction for the mobile app, agreed during UI brainstorming. Pair this with
[`../06-ui-screens.md`](../06-ui-screens.md) (navigation + per-screen content).

## Files here
- **`mockup-screens.html`** — the agreed v2 mockup (Home · Garage · Vehicle detail). Open in
  a browser to see the target look. This is our "good enough to start" baseline.
- **`ref-02-tab-bar.png`** — floating dark pill tab bar (active tab in white circle).
- **`ref-03-design-language.png`** — "Drive Safe" app screens (overall visual language).
- **`ref-04-vehicle-card.png`** — dark vehicle card reference ("Ferrari Sergio").
- **`ref-color-theme.jpg`** — ⭐ **Active color reference.** Furniture app UI showing the yellow/black/white design language: cool grey background, white cards with soft shadows, dark navy nav pill, bright yellow accent. This is the source of truth for the current palette.

## Source references

| File | What it showed | What we took from it |
|---|---|---|
| `ref-01-paper-sketch.png` *(not yet added)* | Your hand sketch | Screen structure: Garage list, Home cards, Vehicle detail, tab bar |
| `ref-02-tab-bar.png` | Dark floating pill tab bar | **Tab bar style** — floating dark pill, active tab pill |
| `ref-03-design-language.png` | "Drive Safe" app screens | Screen structure reference (green accent retired) |
| `ref-04-vehicle-card.png` | Dark car card ("Ferrari Sergio") | **Vehicle card** — photo overlapping top, name/meta, stat row |
| `ref-color-theme.jpg` | Furniture app — yellow/black/white UI | ⭐ **Active palette source** — background, surface, dark nav, yellow accent, shadows |

## Design language (summary)

**Mood:** clean, light, high-contrast — cool grey background, white cards, yellow accent with dark navy surfaces.
Reference: furniture app UI (yellow product highlights, dark nav pill, soft card shadows).

**Color** (`AppColors` in `mobile/lib/core/theme/app_theme.dart`)

| Token | Hex | Use |
|---|---|---|
| `background` | `#EBEBF0` | App scaffold background |
| `surface` | `#FFFFFF` | Cards, sheets, inputs |
| `surfaceDark` | `#1E1D2B` | Vehicle cards, tab bar, dark hero sections |
| `primary` | `#FFD600` | Buttons, active tab pill, highlights |
| `onPrimary` | `#1E1D2B` | Text / icons on yellow |
| `textPrimary` | `#1A1A2E` | Body text, headings |
| `textMuted` | `#9898A6` | Secondary labels, captions |
| `textOnDark` | `#FFFFFF` | Text on dark surfaces |
| `textOnDarkMuted` | `#9898A6` | Muted text on dark surfaces |
| `divider` | `#E2E2EA` | List dividers, input borders |
| `success` | `#22C55E` | OK status pills |
| `warning` | `#F59E0B` | Warning pills |
| `danger` | `#EF4444` | Error / overdue |

**Shape & type**
- Card radius ~16–18px; tab bar radius ~26px; generous padding
- Bold 800-weight titles, small uppercase muted labels (letter-spacing)

**Signature components**
- **Floating dark pill tab bar** (Garage · Home · Profile) — active tab = white circle + colored icon
- **Dark vehicle card** — vehicle photo overlapping the top edge, name + year/registration,
  amber "DETAILS →", bottom **stat row** (mileage · economy · spent · docs)
- **Stat cards** with optional **green progress ring** and **mini sparklines**
- **Dashed "＋ Add Vehicle" card** at the end of the Garage list
- **Full-screen modal dialogs** for all create/edit forms (Cancel / Save)

> The green ring on Home is a placeholder for Phase 1 (cost progress); it becomes the
> **Vehicle Health Score** in Phase 5.
