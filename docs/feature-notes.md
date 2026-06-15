# DriveVault — Feature Notes / Enhancement Ideas

> Captured improvement ideas. Each is tagged with the phase bucket it belongs to.
> Implementation breakdown for the current branch lives in `07-fuel-prefs-tasks.md`.

**Bucket legend**
- 🟢 **Now** — current branch (`feat/fuel-prefs-and-ui`); client-side only, no schema/API change.
- 🟡 **1.5** — between Phase 1 and 2; small additive schema + API change, bundled into this branch
  so screens aren't reworked twice.
- 🔴 **P3** — deferred to a later phase (AI / OCR), per Doc 1 §7–8.

---

## 1. Fuel Record

- 🔴 **P3 — Odometer OCR** — take a picture of the odometer to OCR the current mileage and
  auto-populate the odometer field. (OCR = ML Kit, Phase 3; the manual field works without it.)
- 🟢 **Now — Auto-fill unit price** — pre-fill the unit price from the latest fuel record for
  that vehicle (if one exists). Just a starting value the user can edit (prices vary each time).
- ~~**1.5 — Fuel variant per vehicle**~~ (DROPPED 2026-06-13 — removed in migration f2001 / commit 57d26e7) — record which fuel variant the user is using per
  vehicle. At fuel-record time the user can change the variant (e.g. between specific grades),
  *not* whether it's petrol or diesel — that's fixed per vehicle.
- 🟢 **Now — Vehicle dropdown in Add Fuel Log** — the add-fuel-log page has a vehicle dropdown
  with the relevant vehicle already selected, so the screen can open directly from home instead
  of navigating into vehicle detail.
- 🟢 **Now — Home quick actions** — quick-action shortcuts on the home page (e.g. Add Fuel Log)
  that open the relevant screen with context pre-filled.
- 🟢 **Now — Odometer placeholder** — show the latest odometer reading as the placeholder in the
  odometer field.

---

## 2. Settings

- ~~**1.5 — Currency preference**~~ (SUPERSEDED 2026-06-13 — currency hard-locked to `LKR`, no user selection; migration f3001 / `LOCKED_CURRENCY`) — let the user select their currency preference.
  Single currency per user → no currency dropdown in fuel/service records (backend defaults
  currency from the user preference).
- 🟡 **1.5 — Distance preference** — user-level distance unit (km/mile); default for all vehicles.
- 🟡 **1.5 — Per-vehicle distance unit override** — vehicle form and vehicle detail pages can
  change the distance unit (km/mile) per vehicle, overriding the user-level default.
