# DriveVault — Task Dashboard

> **Living document.** Single source of truth for *what's been done, what's next, and who's doing it.*
> Update the **Status** and **Executor** cells as work progresses. Tasks come from
> [`04-phase1-tasks.md`](./04-phase1-tasks.md); the `S` tasks are one-time project setup.

## Legend
**Status:** ✅ Done · 🟡 In progress · ⏳ Blocked / waiting · ⬜ Not started
**Executor:** `Opus` (setup & scaffolds) · `SmallLLM` (feature tasks, one at a time per worktree) · `User` (manual)

---

## 0. Setup (one-time)

| Order | ID | Task | Status | Executor | Notes |
|---|---|---|---|---|---|
| 1 | S1 | Project docs (PRD, tech spec, schema, API, tasks, README) | ✅ | Opus | `docs/` |
| 2 | S2 | `CLAUDE.md` working agreement | ✅ | Opus | repo root |
| 3 | S3 | `git init` + `.gitignore` (committed) | ✅ | Opus | branch `main` |
| 4 | S4 | This task dashboard | ✅ | Opus | `docs/05-task-dashboard.md` |
| 5 | S5 | Install Flutter SDK | ✅ | Opus | Flutter 3.44.1 / Dart 3.12.1 |
| 6 | S6 | Toolchains for device builds | 🟡 | User | Xcode 26.5 ✅; Android needs `cmdline-tools` + licenses |
| 7 | S7 | Firebase project + wiring + Auth providers | ✅ | Opus + User | `drivevault-app`, `flutterfire configure` done; Admin key generated; Email/Password + Google enabled |
| 8 | S8 | Cloudinary account (free, no card) | ✅ | User | creds in backend `.env` (cloud `dqx43joma`) |

---

## Batch 1 — ✅ COMPLETE (squash-merged to main `35a23f8`)

### Worktree: `task/backend-models`

| Order | ID | Task | Status | Executor | Notes |
|---|---|---|---|---|---|
| 1 | A3a | Alembic setup + users/vehicles models | ✅ | SmallLLM | migration passing |
| 2 | A3b | fuel/maintenance/documents models | ✅ | SmallLLM | migration passing |
| 3 | A3c | schedules/reminders models | ✅ | SmallLLM | migration passing |
| 4 | A4 | Firebase token auth dependency (`get_current_user`) | ✅ | SmallLLM | check_revoked=True, email_verified guard, race condition handled |
| 5 | A5 | `/me` endpoints (GET, PATCH) | ✅ | SmallLLM | lazy upsert; tests passing |

### Worktree: `task/mobile-auth`

| Order | ID | Task | Status | Executor | Notes |
|---|---|---|---|---|---|
| 1 | C2a | Firebase init + email/password auth | ✅ | SmallLLM | tests passing, main initialized |
| 2 | C2b | Google sign-in | ✅ | SmallLLM | google_sign_in integrated |
| 3 | C2c | Auth gate + persistence | ✅ | SmallLLM | GoRouter redirect listener |
| 4 | C3 | API client + token injection | ✅ | SmallLLM | Dio + token interceptor; null guard; typed exceptions |
| 5 | C2d | Email-verification gate | ✅ | SmallLLM | committed `a60b0b2`; 25/25 tests, analyze clean; **gates Batch 4 mobile** |

---

## Batch 2 — ✅ COMPLETE (squash-merged to main)

### Worktree: `task/backend-fuel`

| Order | ID | Task | Status | Executor | Notes |
|---|---|---|---|---|---|
| 1 | B1 | Vehicles CRUD | ✅ | SmallLLM | ownership → 404; tests passing |
| 2 | B2 | Fuel logs CRUD | ✅ | SmallLLM | date-range filter + ownership; tests passing |
| 3 | B3 | Fuel stats (computed) | ✅ | SmallLLM | full-tank math in service; exact-values test passing |

### Worktree: `task/backend-maint`

| Order | ID | Task | Status | Executor | Notes |
|---|---|---|---|---|---|
| 1 | B4 | Maintenance CRUD | ✅ | SmallLLM | `source='manual'`; category filter + ownership; tests passing |
| 2 | B4b | Cloudinary upload signature endpoint | ✅ | SmallLLM | SHA-1 signing; secret never returned; test passing |

### Worktree: `task/backend-documents`

| Order | ID | Task | Status | Executor | Notes |
|---|---|---|---|---|---|
| 1 | B5 | Documents CRUD (metadata) | ✅ | SmallLLM | store `storageUrl` + `publicId`; docType filter; 20/20 tests passing |

---

## Batch 3 — ✅ COMPLETE (squash-merged to main `d677aad`)

### Worktree: `task/backend-deploy`

| Order | ID | Task | Status | Executor | Notes |
|---|---|---|---|---|---|
| 1 | B6 | Dashboard aggregate | ✅ | SmallLLM | `/api/v1/dashboard`; 3 tests passing |
| 2 | B7 | Deploy to Render + Neon | ✅ | User + SmallLLM | Neon DB live + migrations run; deployment deferred (no free permanent URL); `render.yaml` + `Dockerfile` ready |

---

## Batch 4 — ✅ COMPLETE (squash-merged to main `b44060d`)

### Worktree: `task/mobile-garage`

| Order | ID | Task | Status | Executor | Notes |
|---|---|---|---|---|---|
| 1 | D1a | Vehicles list (Garage) | ✅ | SmallLLM | VehicleCard + 4 states |
| 2 | D1b | Add/Edit Vehicle form (modal) | ✅ | SmallLLM | POST/PATCH + delete |
| 3 | D1c | Vehicle photo upload (Cloudinary) | ✅ | SmallLLM | signed upload |

### Worktree: `task/mobile-vehicle-detail`

| Order | ID | Task | Status | Executor | Notes |
|---|---|---|---|---|---|
| 1 | D2 | Vehicle detail shell (one scroll) | ✅ | SmallLLM | sections for D3–D5 |
| 2 | D3 | Fuel tracking UI (+ stats card) | ✅ | SmallLLM | fuel logs + stats card |
| 3 | D4 | Maintenance UI | ✅ | SmallLLM | maintenance records list + form |
| 4 | D5a | Documents list (grouped) | ✅ | SmallLLM | by type + expiry badges |
| 5 | D5b | Document upload (Cloudinary) | ✅ | SmallLLM | signed upload |
| 6 | D5c | Document viewer + delete | ✅ | SmallLLM | URL launcher + delete |

### Worktree: `task/mobile-dashboard`

| Order | ID | Task | Status | Executor | Notes |
|---|---|---|---|---|---|
| 1 | D6 | Dashboard screen | ✅ | SmallLLM | vehicle count, fuel spend, ownership cost, renewals |

---

## Wrap-up

| Order | ID | Task | Status | Executor | Notes |
|---|---|---|---|---|---|
| 1 | E1 | End-to-end Phase 1 smoke pass | ✅ | User | add vehicle → fuel → service → doc → dashboard — passed 2026-06-10 |

---

## Already done (setup phase)

| ID | Task | Status |
|---|---|---|
| A1 | Backend scaffold + `/health` | ✅ pytest passing |
| A2 | Config + DB session + docker-compose | ✅ Postgres 16 local |
| C1 | Flutter scaffold (feature folders, deps, shell, router) | ✅ analyze clean, widget test passing |

---

## Progress summary

| Group | Done | Total |
|---|---|---|
| Setup | 7 | 8 |
| Backend | 15 | 15 |
| Mobile | 18 | 18 |
| Wrap-up | 1 | 1 |
| **Total** | **41** | **41** |

---

## Parallel worktree quick reference

| Batch | Worktree | Tasks | Gate |
|---|---|---|---|
| 1 | `task/backend-models` | A3a→A3b→A3c→A4→A5 | ✅ Start now |
| 1 | `task/mobile-auth` | C2a→C2b→C2c→C3 (→C2d follow-on) | ✅ Start now |
| 2 | `task/backend-fuel` | B1→B2→B3 | ✅ Merged |
| 2 | `task/backend-maint` | B4→B4b | ✅ Merged |
| 2 | `task/backend-documents` | B5 | ✅ Merged |
| 3 | `task/backend-deploy` | B6→B7 | ✅ Merged to main |
| 4 | `task/mobile-garage` | D1a→D1b→D1c | ✅ Gate open |
| 4 | `task/mobile-vehicle-detail` | D2→D3→D4→D5a→D5b→D5c | ✅ Gate open |
| 4 | `task/mobile-dashboard` | D6 | ✅ Gate open |

> **How to update:** when a task finishes, flip its Status to ✅ and add a one-line note.
> When a worktree merges, check that batch's gate conditions and spin up the next batch.
