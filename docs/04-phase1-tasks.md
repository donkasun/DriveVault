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

### 🟦 Task A3 — SQLAlchemy models (Phase 1 + 2 tables)
Implement models for: `users`, `vehicles`, `fuel_logs`, `maintenance_records`, `documents`,
`maintenance_schedules`, `reminders` — exactly matching Doc 2 (types, FKs, cascade, indexes,
`created_at`/`updated_at`). Create the initial **Alembic** migration.
**Done when:** `alembic upgrade head` creates all tables; a test inserts a user+vehicle and reads it back.

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

### 🟦 Task B5 — Documents CRUD (metadata)
`/vehicles/{id}/documents` + `/documents/{id}` per Doc 3 — metadata only, store `storageUrl`.
**Done when:** CRUD + docType-filter tests pass.

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

### 🟩 Task C2 — Firebase init + Auth (email/Google/Apple)
Wire FlutterFire, implement sign-in/up with **email/password, Google, Apple**; an
`authProvider` exposing auth state; an auth gate routing signed-out users to a login screen.
**Done when:** a user can sign up, sign in, and sign out; signed-in state persists across restart.

### 🟩 Task C3 — API client with token injection
An `ApiClient` (base URL via `--dart-define`) that attaches the current Firebase ID token as
`Authorization: Bearer` on every request and maps error JSON to typed failures.
**Done when:** calling `GET /me` returns the user; a 401 is surfaced as a typed auth error.

---

## D. Mobile Screens (each: model → repository → provider → screen)

### 🟩 Task D1 — Vehicles list + create/edit
List the user's vehicles (calls `/vehicles`); form to create/edit; photo upload to Firebase
Storage then save returned URL. Delete with confirm.
**Done when:** user can add, view, edit, photograph, and delete a vehicle end-to-end against the live API.

### 🟩 Task D2 — Vehicle detail shell
A vehicle detail screen with tabs/sections for Fuel, Maintenance, Documents (containers for D3–D5).
**Done when:** tapping a vehicle opens detail with empty sub-sections.

### 🟩 Task D3 — Fuel tracking UI
List fuel logs, add/edit/delete entry form, and a fuel-stats card (calls `/fuel-stats`).
**Done when:** adding logs updates the list and the computed economy/cost card.

### 🟩 Task D4 — Maintenance UI
List maintenance records, add/edit/delete form with service type + category + cost.
**Done when:** records appear newest-first and persist via the API.

### 🟩 Task D5 — Document vault UI
Pick a file/photo, upload to Firebase Storage, save metadata via API, list documents by type,
show expiry, open/delete.
**Done when:** a document can be uploaded, listed, opened, and deleted.

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
`A1→A2→A3→A4→A5 → B1→B2→B3→B4→B5→B6→B7 → C1→C2→C3 → D1→D2→D3→D4→D5→D6 → E1`

Backend can be built and tested fully before mobile starts, since Doc 3 is the fixed contract.
