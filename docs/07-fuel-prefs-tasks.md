# DriveVault — Fuel & Preferences Tweaks (Phase 1.5)

> Task breakdown for branch `feat/fuel-prefs-and-ui`. These are the "between Phase 1 and 2"
> tweaks plus the UI/UX polish, bundled together so the fuel-record and vehicle-form screens
> are touched once. Follows the same rules as `04-phase1-tasks.md`: match Doc 2
> (`02-database-schema.md`) and Doc 3 (`03-api-contract.md`) exactly, finish with the stated
> "Done when" including tests.

Legend: 🟦 backend · 🟩 mobile · 🟨 infra/setup
Scope source: `feature-notes.md` (🟢 Now + 🟡 1.5 items). 🔴 Odometer OCR is **out of scope** (Phase 3).

---

## Ordering

```
BACKEND (sequential — migration first)
  F1 (migration) → F2 (/me prefs) → F3 (vehicle fields) → F4 (fuel variant + currency default)
        │ deploy to Cloud Run
        ▼
MOBILE (after backend live; F6–F8 parallel)
  F5 (distance-unit util) ─┬─ F6 (settings)
                           ├─ F7 (vehicle form + detail)
                           ├─ F8 (fuel record rework)
                           └─ F9 (home quick actions)
        ▼
  F10 (smoke pass)
```

---

## Backend

### 🟦 F1 — Migration: new columns
Alembic migration adding, exactly per Doc 2:
- `users`: `currency char(3) NOT NULL DEFAULT 'USD'`, `distance_unit text NOT NULL DEFAULT 'km'`
- `vehicles`: `fuel_type text NULL`, `default_fuel_variant text NULL`, `distance_unit text NULL`
- `fuel_logs`: `fuel_variant text NULL`

**Done when:** `alembic upgrade head` adds all six columns with the right defaults/nullability,
`alembic downgrade -1` cleanly removes them, and existing rows backfill the `NOT NULL` user
columns via server defaults.

### 🟦 F2 — `/me` preferences
Extend the user Pydantic schema + `me` router/service to expose and update `currency` and
`distanceUnit` (Doc 3). Validate `distanceUnit ∈ {km, mi}` and `currency` is a 3-letter code.
**Done when:** `GET /me` returns the new fields; `PATCH /me` updates them; tests cover a valid
update and a 422 on an invalid `distanceUnit`.

### 🟦 F3 — Vehicle fuel + unit fields
Add `fuelType`, `defaultFuelVariant`, `distanceUnit` to the vehicle create/patch/response
schemas + service (Doc 3). All optional; `fuelType` validated against the enum, `distanceUnit ∈
{km, mi, null}`.
**Done when:** create/patch round-trips the three fields; existing vehicle CRUD + ownership
tests still pass; a test asserts `distanceUnit: null` is accepted (inherit).

### 🟦 F4 — Fuel variant + currency-from-preference
- Add optional `fuelVariant` to fuel-log create/patch/response.
- Make `currency` optional on **fuel-log** and **maintenance** create; when omitted, fill from
  the requesting user's `currency` preference (Doc 3 conventions).
**Done when:** a fuel log persists `fuelVariant`; a fuel log AND a maintenance record created
without `currency` are stored with the user's preferred currency; explicit `currency` still wins.

### 🟨 F4d — Deploy
Apply the migration to Neon and deploy the updated backend to Cloud Run (push to `main` /
`gcloud run deploy`).
**Done when:** the live API returns the new fields on `/me` and vehicle/fuel responses.

---

## Mobile

### 🟩 F5 — Distance-unit display utility
A shared helper that converts/display-formats odometer values using the effective unit
(vehicle `distanceUnit` ?? user `distanceUnit`). Storage/wire stays km — convert at the edge.
**Done when:** unit tests cover km↔mi conversion and the vehicle-override-falls-back-to-user rule.

### 🟩 F6 — Settings: currency + distance preference
Settings screen controls for `currency` and `distanceUnit`, persisting via `PATCH /me`; reflect
the values from `GET /me`.
**Done when:** changing either preference persists across app restart and updates displayed units.

### 🟩 F7 — Vehicle form + detail: fuel & unit fields
Add `fuelType` (picker), `defaultFuelVariant` (free text), and per-vehicle `distanceUnit`
override (km/mi/inherit) to the vehicle form; surface the override on the detail page.
**Done when:** creating/editing a vehicle persists the three fields; detail shows the effective
unit; leaving the override blank inherits the user default.

### 🟩 F8 — Fuel record rework
Rework the add/edit fuel-log screen so it:
- has a **vehicle dropdown** (pre-selected when opened with a vehicle),
- shows the **latest odometer** reading as the odometer placeholder,
- **auto-fills the unit price** from the vehicle's latest fuel log (editable),
- has a **fuel-variant selector** (free text + presets) defaulting to the vehicle's
  `defaultFuelVariant`,
- displays odometer in the effective distance unit (via F5).
**Done when:** the screen can be opened standalone (vehicle chosen via dropdown) or with a
vehicle pre-selected; placeholders/prefill populate from the latest log; a saved log carries the
selected vehicle, variant, and km-normalized odometer.

### 🟩 F9 — Home quick actions
Quick-action shortcut(s) on the home/dashboard (e.g. "Add Fuel Log") that open F8 with vehicle
context pre-filled.
**Done when:** tapping the shortcut opens the fuel-record screen ready to save with minimal taps.

---

## Wrap-up

### 🟩🟦 F10 — Smoke pass
Against the deployed backend: set currency + distance prefs → add a vehicle with fuel type +
variant + unit override → from home quick action, add a fuel log (dropdown vehicle, prefilled
price, placeholder odometer, variant) → confirm it persists and displays in the right unit.
**Done when:** the full flow works on a device; note any bugs as follow-ups.

---

## Deferred (not this branch)
- 🔴 **Odometer OCR** — Phase 3 (ML Kit on-device). The manual odometer field added in F8 is the
  foundation OCR will later auto-fill.
