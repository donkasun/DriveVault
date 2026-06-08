# DriveVault — Phase 1 Task Breakdown

> Phase 1 (Foundation MVP) decomposed into **small, ordered, independently-testable tasks**,
> sized for a focused coding session (or a smaller LLM taking one at a time). Build in order:
> backend foundation → backend resources → mobile foundation → mobile screens.
>
> **Rules for every task:** follow Doc 1 (`01-tech-spec.md`), match Doc 2 (`02-database-schema.md`)
> and Doc 3 (`03-api-contract.md`) exactly, and finish with the stated "Done when" including tests.

Legend: 🟦 backend · 🟩 mobile · 🟨 infra/setup

---

## A. Backend Foundation

### 🟨 Task A1 — Backend project scaffold
Create `backend/` with FastAPI, the folder layout from Doc 1 §3, `pyproject.toml`
(FastAPI, Uvicorn, SQLAlchemy 2, Alembic, psycopg, pydantic-settings, firebase-admin, pytest),
and a `GET /health` endpoint returning `{"status":"ok"}`.
**Done when:** `uvicorn app.main:app` runs and `/health` returns 200; one passing test hits `/health`.

### 🟨 Task A2 — Config & DB session
Add `app/core/config.py` (pydantic-settings reading `.env`), `app/core/db.py`
(SQLAlchemy engine + `SessionLocal` + `get_db` dependency). Add `docker-compose.yml` with
`postgres:16`. Document env vars from Doc 1 §5.
**Done when:** app connects to local Docker Postgres on startup; a test using a test DB session passes.

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

## B. Backend Resources (one task per resource)

### 🟦 Task B1 — Vehicles CRUD
Pydantic schemas + router + service for all `/vehicles` endpoints (Doc 3). Enforce ownership
(caller sees only their vehicles; others → 404).
**Done when:** tests cover create, list, get, patch, delete, and a cross-user 404.

### 🟦 Task B2 — Fuel logs CRUD
`/vehicles/{id}/fuel-logs` + `/fuel-logs/{id}` endpoints per Doc 3. Validate `liters > 0`.
**Done when:** CRUD tests pass, including date-range filtering and ownership checks.

### 🟦 Task B3 — Fuel stats
`GET /vehicles/{id}/fuel-stats` — compute avg L/100km and cost-per-km from consecutive
**full-tank** entries, plus monthly spend. Put math in a service function.
**Done when:** a unit test with fixed fuel logs asserts the exact computed numbers.

### 🟦 Task B4 — Maintenance CRUD
`/vehicles/{id}/maintenance` + `/maintenance/{id}` per Doc 3 (set `source='manual'`).
**Done when:** CRUD + category-filter tests pass.

### 🟦 Task B4b — Cloudinary upload signature endpoint
`POST /api/v1/uploads/cloudinary-signature` per Doc 3 — sign upload params with the Cloudinary
API secret (server-side only) and return `{signature, timestamp, apiKey, cloudName, folder}`.
Put the signing in a small service. **Done when:** a test asserts the signature matches a
known SHA-1 of the sorted params + secret, and the secret is never returned.

### 🟦 Task B5 — Documents CRUD (metadata)
`/vehicles/{id}/documents` + `/documents/{id}` per Doc 3 — metadata only, store `storageUrl`
+ `storagePublicId`. On delete, also delete the Cloudinary asset by `public_id`.
**Done when:** CRUD + docType-filter tests pass (mock the Cloudinary delete call).

### 🟦 Task B6 — Dashboard aggregate
`GET /api/v1/dashboard` — aggregate vehicle count, monthly fuel spend, total ownership cost,
cost breakdown, and upcoming document-expiry renewals (Doc 3).
**Done when:** a test seeds 1 vehicle with fuel+maintenance and asserts the aggregated response.

### 🟨 Task B7 — Deploy backend to Render + Neon
Add `Dockerfile` (Gunicorn+Uvicorn), create a Neon project, run migrations against Neon,
deploy to Render, set env vars, confirm `/health` is reachable publicly.
**Done when:** the public Render URL serves `/health` and a manual authed `/me` call works.

---

## C. Mobile Foundation

### 🟩 Task C1 — Flutter project scaffold
Create `mobile/` with the Doc 1 §3 layout, add deps (Riverpod, go_router, dio/http,
firebase_core, firebase_auth, firebase_storage, firebase_messaging). Set up theme + router shell.
**Done when:** app builds and runs on a simulator showing an empty home shell.

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

### 🟩 Task C3 — API client with token injection
An `ApiClient` (base URL via `--dart-define`) that attaches the current Firebase ID token as
`Authorization: Bearer` on every request and maps error JSON to typed failures.
**Done when:** calling `GET /me` returns the user; a 401 is surfaced as a typed auth error.

---

## D. Mobile Screens (each: model → repository → provider → screen)

### 🟩 Task D1a — Vehicles list (Garage)
Repository + provider + `VehicleCard`; the Garage list screen calling `GET /vehicles` with the
4 states (loading/empty/error/loaded) and the dashed "＋ Add Vehicle" card. Matches Doc 6 layout.
**Done when:** the list renders vehicles from the live API with all four states handled.

### 🟩 Task D1b — Add/Edit Vehicle form (modal)
Full-screen modal form (Cancel/Save) for `POST`/`PATCH /vehicles`; delete with confirm.
**Done when:** user can create, edit, and delete a vehicle; the list updates.

### 🟩 Task D1c — Vehicle photo upload (Cloudinary)
From the form, pick a photo → request the signature (`/uploads/cloudinary-signature`) → upload
to Cloudinary → save the returned `secure_url` + `public_id`.
**Done when:** a vehicle photo can be attached/replaced end-to-end and shows on the card.

### 🟩 Task D2 — Vehicle detail shell
A vehicle detail screen with tabs/sections for Fuel, Maintenance, Documents (containers for D3–D5).
**Done when:** tapping a vehicle opens detail with empty sub-sections.

### 🟩 Task D3 — Fuel tracking UI
List fuel logs, add/edit/delete entry form, and a fuel-stats card (calls `/fuel-stats`).
**Done when:** adding logs updates the list and the computed economy/cost card.

### 🟩 Task D4 — Maintenance UI
List maintenance records, add/edit/delete form with service type + category + cost.
**Done when:** records appear newest-first and persist via the API.

### 🟩 Task D5a — Documents list (grouped)
Repository + provider; the Documents section lists docs from `GET /documents` **grouped by
type** with **expiry badges**, plus the 4 states.
**Done when:** documents render grouped by type with expiry indicators and all states handled.

### 🟩 Task D5b — Document upload (Cloudinary)
Pick a file/photo → signature → upload to Cloudinary → save metadata via `POST /documents`
(modal form: docType, title, issue/expiry dates).
**Done when:** a document uploads and appears in the grouped list.

### 🟩 Task D5c — Document viewer + delete
Open the image/PDF from `storage_url`; delete (also deletes the Cloudinary asset server-side).
**Done when:** a document can be opened and deleted.

### 🟩 Task D6 — Dashboard screen
Home dashboard calling `GET /dashboard`: monthly fuel spend, total ownership cost, cost
breakdown, upcoming renewals.
**Done when:** dashboard reflects real seeded data across vehicles.

---

## E. Wrap-up

### 🟩🟦 Task E1 — End-to-end smoke pass
Manually run the full PRD Phase 1 success path: add vehicle → track fuel → add service →
upload document → view dashboard, against the deployed backend.
**Done when:** all five flows work on a device against Render+Neon; note any bugs as follow-ups.

---

## Suggested order
```
A1→A2→A3a→A3b→A3c→A4→A5 → B1→B2→B3→B4→B4b→B5→B6→B7
→ C1→C2a→C2b→C2c→C3 → D1a→D1b→D1c→D2→D3→D4→D5a→D5b→D5c→D6 → E1
```
Backend can be built and tested fully before mobile starts, since Doc 3 is the fixed contract.

> **Task sizing:** tasks are split small enough for one focused session / a smaller LLM. Tip:
> build the *first* of a repeated pattern carefully (B1 = the CRUD template; D1a = the
> screen template), then later ones follow it almost mechanically.

---

## Later phases (2–6)
Detailed task docs for Phases 2–6 are written **just-in-time**, when each phase begins — not
up front (they'd be speculative and rewritten once Phase 1 code exists). What already covers
them: the **PRD** (per-phase features) and **`02-database-schema.md`** (all 6 phases of tables).
When a phase starts, create `0N-phaseN-tasks.md` in this same format.
