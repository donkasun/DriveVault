# DriveVault — Design References

Visual direction for the mobile app, agreed during UI brainstorming. Pair this with
[`../06-ui-screens.md`](../06-ui-screens.md) (navigation + per-screen content).

## Files here
- **`mockup-screens.html`** — the agreed v2 mockup (Home · Garage · Vehicle detail). Open in
  a browser to see the target look. This is our "good enough to start" baseline.
- **`DESIGN-LANGUAGE.md`** — the palette, components, and patterns below in detail.
- **(add your screenshots here)** — see "Source references" below; drop the original images
  into this folder to keep them for reference.

## Source references (please add the image files)
The originals were shared in chat but cleared from the image cache. To preserve them, save
each into this folder with these names:

| Save as | What it showed | What we took from it |
|---|---|---|
| `ref-01-paper-sketch.png` | Your hand sketch | Screen structure: Garage list, Home cards, Vehicle detail, tab bar |
| `ref-02-tab-bar.png` | Dark floating pill tab bar | **Tab bar style** — floating dark pill, active tab in a white circle highlight |
| `ref-03-design-language.png` | "Drive Safe" app screens | **Overall language** — light bg, soft rounded cards, green accent, rings, sparklines |
| `ref-04-vehicle-card.png` | Dark car card ("Ferrari Sergio") | **Vehicle card** — photo overlapping top, name/meta, "DETAILS →", stat row |

## Design language (summary)

**Mood:** clean, modern, friendly — light backgrounds with bold dark feature cards.

**Color**
- Background: light grey `#f3f4f7`
- Surfaces/cards: white `#ffffff`, soft shadow `0 4px 14px rgba(20,20,40,.06)`
- **Primary accent: green** `#16a34a` / `#22c55e`
- Secondary: blue `#2f6bff`
- Highlight/link: amber `#f5b301` (e.g. "DETAILS →")
- Dark cards (vehicles, hero): `#15151c → #23232e` gradient
- Status pills: warn `#fde7e7/#d23b3b`, ok `#e3f6ea/#16a34a`, info `#e6efff/#2f6bff`

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
