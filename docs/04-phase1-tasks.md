# DriveVault — Phase 1 Task Breakdown

> Phase 1 (Foundation MVP) decomposed into **small, ordered, independently-testable tasks**.
> Tasks are grouped into **parallel execution batches** — each batch can be split across
> multiple git worktrees running simultaneously.
>
> **Rules for every task:** follow Doc 1 (`01-tech-spec.md`), match Doc 2 (`02-database-schema.md`)
> and Doc 3 (`03-api-contract.md`) exactly, and finish with the stated "Done when" including tests.

Legend: 🟦 backend · 🟩 mobile · 🟨 infra/setup

---

## Parallel Execution Plan

```
BATCH 1 — ✅ COMPLETE (merged to main)
┌─────────────────────────────────────┐  ┌─────────────────────────────────────┐
│ task/backend-models ✅              │  │ task/mobile-auth ✅                 │
│ A3a → A3b → A3c → A4 → A5          │  │ C2a → C2b → C2c → C3 → C2d         │
└──────────────┬──────────────────────┘  └──────────────────────┬──────────────┘
               │ merged                                          │ merged
               ▼                                                 │
BATCH 2 — ✅ COMPLETE (merged to main)
┌─────────────────────┐ ┌────────────────────┐ ┌────────────────────────┐
│ task/backend-fuel ✅│ │task/backend-maint ✅│ │task/backend-documents ✅│
│ B1 → B2 → B3        │ │ B4 → B4b           │ │ B5                     │
└──────────┬──────────┘ └────────┬───────────┘ └───────────┬────────────┘
           │                     │                          │
           └──────────┬──────────┘                          │
                      │ merged                              │
                      └──────────────┬──────────────────────┘
                                     ▼
BATCH 3 — ✅ COMPLETE (squash-merged to main d677aad)
┌───────────────────────────────────────┐
│ task/backend-deploy                   │
│ B6 ✅ → B7 ✅                          │
└───────────────────────┬───────────────┘
                        │ merged
                        ▼
BATCH 4 — ✅ COMPLETE (squash-merged to main b44060d)
┌─────────────────────────┐ ┌────────────────────────────────────────┐ ┌────────────────────────┐
│ task/mobile-garage ✅   │ │ task/mobile-vehicle-detail ✅          │ │ task/mobile-dashboard ✅│
│ D1a → D1b → D1c        │ │ D2 → D3 → D4 → D5a → D5b → D5c       │ │ D6                     │
└─────────────────────────┘ └────────────────────────────────────────┘ └────────────────────────┘
           All 3 merge → E1 ✅ (end-to-end smoke pass — passed 2026-06-10)
```

---

## A. Backend Foundation  (`task/backend-models`)

### 🟦 Task A3a — Alembic setup + `users` & `vehicles` models
Configure **Alembic** (env wired to `DATABASE_URL` + the `Base` metadata). Implement `users`
and `vehicles` models exactly per Doc 2 (types, FKs, cascade, indexes, `created_at`/`updated_at`).
Create the initial migration.
**Done when:** `alembic upgrade head` creates both tables; a test inserts a user + vehicle and reads it back.

### 🟦 Task A3b — `fuel_logs`, `maintenance_records`, `documents` models
Add these three models per Doc 2 (FKs → vehicles, cascade, indexes, money as cents). New migration.
**Done when:** `alembic upgrade head` adds the tables; a test inserts a fuel log + maintenance
record + document under a vehicle and reads them back.

### 🟦 Task A3c — `maintenance_schedules` & `reminders` models
Add the two Phase-2 tables per Doc 2 (FKs, nullable schedule/document links). New migration.
**Done when:** `alembic upgrade head` adds them; a test inserts a schedule + reminder.

### 🟦 Task A4 — Firebase token auth dependency
Add `firebase-admin` init and a `get_current_user` dependency: verify the `Authorization:
Bearer` Firebase ID token, extract `uid`/`email`, and **lazily upsert** the `users` row.
**Done when:** a protected dummy route returns 401 without a token and 200 with a mocked-valid
token; a test mocks `firebase_admin.auth.verify_id_token`.

### 🟦 Task A5 — `/me` endpoints
Implement `GET /api/v1/me` and `PATCH /api/v1/me` per Doc 3.
**Done when:** tests cover create-on-first-call and profile update.

---

## C. Mobile Foundation  (`task/mobile-auth`)
*Runs in parallel with `task/backend-models`.*

### 🟩 Task C2a — Firebase init + email/password auth
Initialize Firebase in `main` using the generated `firebase_options.dart`. Implement
email/password **sign-up, sign-in, sign-out** and an `authProvider` exposing auth state +
login/sign-up screens.
**Done when:** a user can sign up, sign in, and sign out with email/password.

### 🟩 Task C2b — Google sign-in
Add **Google** sign-in to the auth repository + login screen (provider already enabled in the
Firebase console). *(Apple deferred — needs Apple Developer setup.)*
**Done when:** a user can sign in with Google and reach the home shell.

### 🟩 Task C2c — Auth gate + persistence
Add a go_router **redirect** (auth gate): signed-out → `/login`, signed-in → `/home`. Ensure
auth state **persists across app restarts**.
**Done when:** restarting the app keeps the user signed in; signing out returns to `/login`.

### 🟩 Task C3 — API client with token injection (in progress)
An `ApiClient` (base URL via `--dart-define`) that attaches the current Firebase ID token as
`Authorization: Bearer` on every request and maps error JSON to typed failures.
**Done when:** calling `GET /me` returns the user; a 401 is surfaced as a typed auth error.

### 🟩 Task C2d — Email-verification gate *(follow-on; runs anytime, no backend dep)*
Send `sendEmailVerification()` after email/password sign-up; route unverified password users to
a `/verify-email` screen (Resend / I've-verified / Sign out); Google/Apple bypass. Extend
`resolveAuthRedirect` with `isEmailVerified` + `isPasswordProvider`. Plan:
`docs/superpowers/plans/2026-06-09-email-verification-gate.md`.
**Done when:** gate unit tests pass for verified / unverified / provider-bypass; an unverified
email/password user lands on `/verify-email` and reaches `/home` only after verifying.
**Gates:** must merge before the Batch 4 mobile worktrees start (so unverified accounts can't
seed real vehicle data).

---

## B. Backend Resources

### `task/backend-fuel` — Vehicles · Fuel · Stats
*Starts after `task/backend-models` merges.*

#### 🟦 Task B1 — Vehicles CRUD
Pydantic schemas + router + service for all `/vehicles` endpoints (Doc 3). Enforce ownership
(caller sees only their vehicles; others → 404).
**Done when:** tests cover create, list, get, patch, delete, and a cross-user 404.

#### 🟦 Task B2 — Fuel logs CRUD
`/vehicles/{id}/fuel-logs` + `/fuel-logs/{id}` endpoints per Doc 3. Validate `liters > 0`.
**Done when:** CRUD tests pass, including date-range filtering and ownership checks.

#### 🟦 Task B3 — Fuel stats
`GET /vehicles/{id}/fuel-stats` — compute avg L/100km and cost-per-km from consecutive
**full-tank** entries, plus monthly spend. Put math in a service function.
**Done when:** a unit test with fixed fuel logs asserts the exact computed numbers.

---

### `task/backend-maint` — Maintenance · Cloudinary Signature
*Starts after `task/backend-models` merges, parallel with `task/backend-fuel`.*

#### 🟦 Task B4 — Maintenance CRUD
`/vehicles/{id}/maintenance` + `/maintenance/{id}` per Doc 3 (set `source='manual'`).
**Done when:** CRUD + category-filter tests pass.

#### 🟦 Task B4b — Cloudinary upload signature endpoint
`POST /api/v1/uploads/cloudinary-signature` per Doc 3 — sign upload params with the Cloudinary
API secret (server-side only) and return `{signature, timestamp, apiKey, cloudName, folder}`.
Put the signing in a small service. **Done when:** a test asserts the signature matches a
known SHA-1 of the sorted params + secret, and the secret is never returned.

---

### `task/backend-documents` — Documents CRUD
*Starts after `task/backend-models` merges, parallel with the above two.*

#### 🟦 Task B5 — Documents CRUD (metadata)
`/vehicles/{id}/documents` + `/documents/{id}` per Doc 3 — metadata only, store `storageUrl`
+ `storagePublicId`. On delete, also delete the Cloudinary asset by `public_id`.
**Done when:** CRUD + docType-filter tests pass (mock the Cloudinary delete call).

---

## Backend Wrap-up  (`task/backend-deploy`)
*Starts after all three Batch 2 worktrees merge.*

### 🟦 Task B6 — Dashboard aggregate
`GET /api/v1/dashboard` — aggregate vehicle count, monthly fuel spend, total ownership cost,
cost breakdown, and upcoming document-expiry renewals (Doc 3).
**Done when:** a test seeds 1 vehicle with fuel+maintenance and asserts the aggregated response.

### 🟨 Task B7 — Deploy backend to Cloud Run + Neon ✅
`Dockerfile` (Gunicorn+Uvicorn) + `.dockerignore` added. Neon DB (`silent-haze-14400595`) already
had migrations applied. Firebase credentials stored in GCP Secret Manager (`firebase-credentials`).
Deployed to Google Cloud Run (`--min-instances=0`, `--allow-unauthenticated`).
GitHub Actions auto-deploy wired up (`.github/workflows/deploy-backend.yml`).
**Live URL:** `https://drivevault-backend-250609806849.us-central1.run.app`
**Done when:** ✅ `/health` → `{"status":"ok"}` · ✅ `/api/v1/me` without token → `401`

---

## D. Mobile Screens ✅ COMPLETE (squash-merged to main `b44060d`)

### `task/mobile-garage` — Garage tab
*Starts after `task/mobile-auth` merged AND B7 live.*

#### 🟩 Task D1a — Vehicles list (Garage)
Repository + provider + `VehicleCard`; the Garage list screen calling `GET /vehicles` with the
4 states (loading/empty/error/loaded) and the dashed "＋ Add Vehicle" card. Matches Doc 6 layout.
**Done when:** the list renders vehicles from the live API with all four states handled.

#### 🟩 Task D1b — Add/Edit Vehicle form (modal)
Full-screen modal form (Cancel/Save) for `POST`/`PATCH /vehicles`; delete with confirm.
**Done when:** user can create, edit, and delete a vehicle; the list updates.

#### 🟩 Task D1c — Vehicle photo upload (Cloudinary)
From the form, pick a photo → request the signature (`/uploads/cloudinary-signature`) → upload
to Cloudinary → save the returned `secure_url` + `public_id`.
**Done when:** a vehicle photo can be attached/replaced end-to-end and shows on the card.

---

### `task/mobile-vehicle-detail` — Vehicle detail tab content
*Starts after `task/mobile-auth` merged AND B7 live. Parallel with `task/mobile-garage`.*

#### 🟩 Task D2 — Vehicle detail shell
A vehicle detail screen with tabs/sections for Fuel, Maintenance, Documents (containers for D3–D5).
**Done when:** tapping a vehicle opens detail with empty sub-sections.

#### 🟩 Task D3 — Fuel tracking UI
List fuel logs, add/edit/delete entry form, and a fuel-stats card (calls `/fuel-stats`).
**Done when:** adding logs updates the list and the computed economy/cost card.

#### 🟩 Task D4 — Maintenance UI
List maintenance records, add/edit/delete form with service type + category + cost.
**Done when:** records appear newest-first and persist via the API.

#### 🟩 Task D5a — Documents list (grouped)
Repository + provider; the Documents section lists docs from `GET /documents` **grouped by
type** with **expiry badges**, plus the 4 states.
**Done when:** documents render grouped by type with expiry indicators and all states handled.

#### 🟩 Task D5b — Document upload (Cloudinary)
Pick a file/photo → signature → upload to Cloudinary → save metadata via `POST /documents`
(modal form: docType, title, issue/expiry dates).
**Done when:** a document uploads and appears in the grouped list.

#### 🟩 Task D5c — Document viewer + delete
Open the image/PDF from `storage_url`; delete (also deletes the Cloudinary asset server-side).
**Done when:** a document can be opened and deleted.

---

### `task/mobile-dashboard` — Home/Dashboard screen
*Starts after `task/mobile-auth` merged AND B7 live. Parallel with the other two mobile screen worktrees.*

#### 🟩 Task D6 — Dashboard screen
Home dashboard calling `GET /dashboard`: monthly fuel spend, total ownership cost, cost
breakdown, upcoming renewals.
**Done when:** dashboard reflects real seeded data across vehicles.

---

## E. Wrap-up

### 🟩🟦 Task E1 — End-to-end smoke pass
Manually run the full PRD Phase 1 success path: add vehicle → track fuel → add service →
upload document → view dashboard, against the deployed backend.
**Done when:** all five flows work on a device against Cloud Run+Neon; note any bugs as follow-ups.

---

## Worktree summary

| Batch | Worktree branch | Tasks | Start condition |
|---|---|---|---|
| 1 | `task/backend-models` | A3a→A3b→A3c→A4→A5 | ✅ Merged to main |
| 1 | `task/mobile-auth` | C2a→C2b→C2c→C3→C2d | ✅ Merged to main |
| 2 | `task/backend-fuel` | B1→B2→B3 | ✅ Gate open |
| 2 | `task/backend-maint` | B4→B4b | ✅ Gate open |
| 2 | `task/backend-documents` | B5 | ✅ Gate open |
| 3 | `task/backend-deploy` | B6→B7 | After all Batch 2 merged |
| 4 | `task/mobile-garage` | D1a→D1b→D1c | After `task/mobile-auth` + C2d merged + B7 live |
| 4 | `task/mobile-vehicle-detail` | D2→D3→D4→D5a→D5b→D5c | After `task/mobile-auth` + C2d merged + B7 live |
| 4 | `task/mobile-dashboard` | D6 | After `task/mobile-auth` + C2d merged + B7 live |

> **Task sizing tip:** B1 is the CRUD template — later B tasks follow the same pattern.
> D1a is the screen template — later D tasks follow almost mechanically.

---

## Later phases (2–6)
Detailed task docs for Phases 2–6 are written **just-in-time**, when each phase begins — not
up front (they'd be speculative and rewritten once Phase 1 code exists). What already covers
them: the **PRD** (per-phase features) and `02-database-schema.md` (all 6 phases of tables).
When a phase starts, create `0N-phaseN-tasks.md` in this same format.
