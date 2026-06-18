# DriveVault — Fuel & Preferences Tweaks (Phase 1.5)

> Task breakdown for branch `feat/fuel-prefs-and-ui`. These are the "between Phase 1 and 2"
> tweaks plus the UI/UX polish, bundled together so the fuel-record and vehicle-form screens
> are touched once. Follows the same rules as `04-phase1-tasks.md`: match Doc 2
> (`02-database-schema.md`) and Doc 3 (`03-api-contract.md`) exactly, finish with the stated
> "Done when" including tests.

Legend: 🟦 backend · 🟩 mobile · 🟨 infra/setup
Scope source: `feature-notes.md` (🟢 Now + 🟡 1.5 items). 🔴 Odometer OCR is **out of scope** (Phase 3).

---

## Parallel Execution Plan

F1 (migration) is done ✅ and unblocks everything below. F2/F3/F4 touch different
routers+schemas (`me`/users, `vehicles`, `fuel`+`maintenance`) so they run in parallel; F5 has
no backend dependency so it runs alongside them.

```
BATCH 1 — parallel (F1 ✅ unblocks all)
┌─────────────────────┐ ┌──────────────────────┐ ┌────────────────────────────┐ ┌────────────────────────┐
│ 🟦 F2 /me prefs     │ │ 🟦 F3 vehicle fields │ │ 🟦 F4 fuel variant+currency│ │ 🟩 F5 distance-unit util│
│ task/be-me-prefs    │ │ task/be-vehicle-flds │ │ task/be-fuel-variant       │ │ task/mobile-distance-util│
└──────────┬──────────┘ └──────────┬───────────┘ └─────────────┬──────────────┘ └────────────┬───────────┘
           └───────── merge F2+F3+F4 ─────────────┬─────────────┘                             │ merge
                                                  ▼                                            │
                                   GATE 🟨 F4d — migrate Neon + deploy Cloud Run               │
                                                  └──────────────────┬─────────────────────────┘
                                                                     ▼
BATCH 2 — parallel (after F4d live AND F5 merged)
┌─────────────────────┐ ┌──────────────────────────┐ ┌────────────────────────────────────┐
│ 🟩 F6 settings      │ │ 🟩 F7 vehicle form+detail │ │ 🟩 F8 fuel record → 🟩 F9 home quick │
│ task/mobile-settings│ │ task/mobile-vehicle-form  │ │ task/mobile-fuel-record (F8 then F9) │
└──────────┬──────────┘ └────────────┬─────────────┘ └──────────────────┬───────────────────┘
           └───────────────── merge all ─────────────────────────────────┘
                                      ▼
BATCH 3
  🟩🟦 F10 — end-to-end smoke pass
```

> **Delegation (per CLAUDE.md):** dispatch each Batch-1/Batch-2 worktree to a **Sonnet subagent**
> with its task spec + the relevant Doc 2/Doc 3 section. Keep F4d (deploy) and F10 (smoke) in the
> main session. Worktrees live under `.worktrees/`, branched off `feat/fuel-prefs-and-ui`.

---

## Backend

### 🟦 F1 — Migration: new columns ✅
Alembic migration adding, exactly per Doc 2:
- `users`: `currency char(3) NOT NULL DEFAULT 'LKR'`, `distance_unit text NOT NULL DEFAULT 'km'`
- `vehicles`: `fuel_type text NULL`, `default_fuel_variant text NULL`, `distance_unit text NULL`
- `fuel_logs`: `fuel_variant text NULL`

**Done when:** `alembic upgrade head` adds all six columns with the right defaults/nullability,
`alembic downgrade -1` cleanly removes them, and existing rows backfill the `NOT NULL` user
columns via server defaults.

### 🟦 F2 — `/me` preferences ✅
Extend the user Pydantic schema + `me` router/service to expose and update `currency` and
`distanceUnit` (Doc 3). Validate `distanceUnit ∈ {km, mi}` and `currency` is a 3-letter code.
**Done when:** `GET /me` returns the new fields; `PATCH /me` updates them; tests cover a valid
update and a 422 on an invalid `distanceUnit`.

### 🟦 F3 — Vehicle fuel + unit fields ✅
Add `fuelType`, `defaultFuelVariant`, `distanceUnit` to the vehicle create/patch/response
schemas + service (Doc 3). All optional; `fuelType` validated against the enum, `distanceUnit ∈
{km, mi, null}`.
**Done when:** create/patch round-trips the three fields; existing vehicle CRUD + ownership
tests still pass; a test asserts `distanceUnit: null` is accepted (inherit).

### 🟦 F4 — Fuel variant + currency-from-preference ✅ (currency-from-preference later SUPERSEDED — currency is now hard-locked to `LKR` via migration f3001 + `LOCKED_CURRENCY`.)
- Add optional `fuelVariant` to fuel-log create/patch/response.
- Make `currency` optional on **fuel-log** and **maintenance** create; when omitted, fill from
  the requesting user's `currency` preference (Doc 3 conventions).
**Done when:** a fuel log persists `fuelVariant`; a fuel log AND a maintenance record created
without `currency` are stored with the user's preferred currency; explicit `currency` still wins.

### 🟨 F4d — Deploy ✅
Apply the migration to Neon and deploy the updated backend to Cloud Run (push to `main` /
`gcloud run deploy`).
**Done when:** the live API returns the new fields on `/me` and vehicle/fuel responses.
**Done:** Neon (`silent-haze-14400595`) migrated to `f1001`; backend image `:e1164cf` built
(amd64) + deployed manually via `gcloud run deploy` from the feature branch (not merged to
`main`) → revision `drivevault-backend-00003-69g`. Verified: `/health` ok, `/me` 401, and the
live `/openapi.json` exposes `distanceUnit`/`fuelType`/`defaultFuelVariant`/`fuelVariant`.

---

## Mobile

### 🟩 F5 — Distance-unit display utility ✅
A shared helper that converts/display-formats odometer values using the effective unit
(vehicle `distanceUnit` ?? user `distanceUnit`). Storage/wire stays km — convert at the edge.
**Done when:** unit tests cover km↔mi conversion and the vehicle-override-falls-back-to-user rule.

### 🟩 F6 — Settings: currency + distance preference ✅ (the currency control was later removed — currency is locked to `LKR`; only the distance-unit control remains.)
Settings screen controls for `currency` and `distanceUnit`, persisting via `PATCH /me`; reflect
the values from `GET /me`.
**Done when:** changing either preference persists across app restart and updates displayed units.

### 🟩 F7 — Vehicle form + detail: fuel & unit fields ✅
Add `fuelType` (picker), `defaultFuelVariant` (free text), and per-vehicle `distanceUnit`
override (km/mi/inherit) to the vehicle form; surface the override on the detail page.
**Done when:** creating/editing a vehicle persists the three fields; detail shows the effective
unit; leaving the override blank inherits the user default.

### 🟩 F8 — Fuel record rework ✅
Rework the add/edit fuel-log screen so it:
- has a **vehicle dropdown** (pre-selected when opened with a vehicle),
- shows the **latest odometer** reading as the odometer placeholder,
- **auto-fills the unit price** from the vehicle's latest fuel log (editable),
- ~~has a **fuel-variant selector** (free text + presets) defaulting to the vehicle's
  `defaultFuelVariant`~~ — **per-fuel-log `fuelVariant` was dropped** (migration
  `f2001_drop_fuel_variant`); vehicle-level `default_fuel_variant`/`fuel_type` still exist
  but are not recorded on individual log entries,
- displays odometer in the effective distance unit (via F5).
**Done when:** the screen can be opened standalone (vehicle chosen via dropdown) or with a
vehicle pre-selected; placeholders/prefill populate from the latest log; a saved log carries the
selected vehicle and km-normalized odometer.

### 🟩 F9 — Home quick actions ✅
Quick-action shortcut(s) on the home/dashboard (e.g. "Add Fuel Log") that open F8 with vehicle
context pre-filled.
**Done when:** tapping the shortcut opens the fuel-record screen ready to save with minimal taps.

---

## Wrap-up

### 🟩🟦 F10 — Smoke pass ✅ (API-level)
Against the deployed backend: set currency + distance prefs → add a vehicle with fuel type +
variant + unit override → from home quick action, add a fuel log (dropdown vehicle, prefilled
price, placeholder odometer, variant) → confirm it persists and displays in the right unit.
**Done when:** the full flow works on a device; note any bugs as follow-ups.
**Done (2026-06-11):** the app has no `web/` scaffold and the only device is an offline Android
emulator, so the flow was smoke-tested at the **API level** against live Cloud Run with the
`smoketest@drivevault.dev` account (the exact calls the F6/F7/F8 screens make). All passed:
PATCH/GET `/me` prefs (F6), `POST /vehicles` with fuelType/defaultFuelVariant/distanceUnit (F7),
`POST /fuel-logs` with `currency` defaulting to the user pref (F8/F4). (`fuelVariant` was later dropped — migration f2001.)
The UI itself is covered by 110 passing widget/unit tests.

**Follow-up bug found + FIXED (pre-existing, Phase 1):** `DELETE /vehicles/{id}` returned **500**
when the vehicle had any child rows (fuel logs / maintenance / documents). Cause: the FK has
DB-level `ON DELETE CASCADE`, but the SQLAlchemy relationships on `Vehicle` lacked
`passive_deletes=True` (+ `cascade="all, delete-orphan"`), so the ORM tried to NULL the children's
non-nullable `vehicle_id` first → `IntegrityError`. **Fixed** in `backend/app/models/vehicles.py`
(commit `241fb70`) with a regression test; redeployed (Cloud Run revision
`drivevault-backend-00004-wlv`) and verified live — deleting a vehicle that has a fuel log now
returns 204 and cascades.

---

## Worktree summary

| Batch | Worktree branch | Tasks | Track | Start condition |
|---|---|---|---|---|
| 1 | `task/be-me-prefs` | F2 | 🟦 | F1 ✅ |
| 1 | `task/be-vehicle-flds` | F3 | 🟦 | F1 ✅ |
| 1 | `task/be-fuel-variant` | F4 | 🟦 | F1 ✅ |
| 1 | `task/mobile-distance-util` | F5 | 🟩 | none (no backend dep) |
| gate | — (main session) | F4d deploy | 🟨 | F2 + F3 + F4 merged |
| 2 | `task/mobile-settings` | F6 | 🟩 | F4d live **and** F5 merged |
| 2 | `task/mobile-vehicle-form` | F7 | 🟩 | F4d live **and** F5 merged |
| 2 | `task/mobile-fuel-record` | F8 → F9 | 🟩 | F4d live **and** F5 merged |
| 3 | — (main session) | F10 smoke | 🟩🟦 | all Batch-2 merged |

> **Conflict check:** Batch-1 backend tasks edit disjoint files (F2: `users` schema + `me`
> router/service · F3: `vehicles` schema + service · F4: `fuel`/`maintenance` schemas + services).
> F4 only *reads* `current_user.currency` — no users-schema change — so it won't collide with F2.
> Batch-2 tasks live in separate feature folders (settings, vehicles, fuel/dashboard) and all
> import the already-merged F5 util.

---

## Deferred (not this branch)
- 🔴 **Odometer OCR** — Phase 3 (ML Kit on-device). The manual odometer field added in F8 is the
  foundation OCR will later auto-fill.
