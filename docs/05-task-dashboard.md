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

## Batch 1 — Run NOW (2 worktrees in parallel)

### Worktree: `task/backend-models`

| Order | ID | Task | Status | Executor | Notes |
|---|---|---|---|---|---|
| 1 | A3a | Alembic setup + users/vehicles models | ✅ | SmallLLM | migration passing |
| 2 | A3b | fuel/maintenance/documents models | ✅ | SmallLLM | migration passing |
| 3 | A3c | schedules/reminders models | ✅ | SmallLLM | migration passing |
| 4 | A4 | Firebase token auth dependency (`get_current_user`) | ⬜ | SmallLLM | mock `verify_id_token` in tests |
| 5 | A5 | `/me` endpoints (GET, PATCH) | ⬜ | SmallLLM | lazy user upsert |

### Worktree: `task/mobile-auth`

| Order | ID | Task | Status | Executor | Notes |
|---|---|---|---|---|---|
| 1 | C2a | Firebase init + email/password auth | ✅ | SmallLLM | tests passing, main initialized |
| 2 | C2b | Google sign-in | ✅ | SmallLLM | google_sign_in integrated |
| 3 | C2c | Auth gate + persistence | ✅ | SmallLLM | GoRouter redirect listener |
| 4 | C3 | API client + token injection | ⬜ | SmallLLM | base URL via `--dart-define` |

---

## Batch 2 — Start after `task/backend-models` merges (3 worktrees in parallel)

### Worktree: `task/backend-fuel`

| Order | ID | Task | Status | Executor | Notes |
|---|---|---|---|---|---|
| 1 | B1 | Vehicles CRUD | ⬜ | SmallLLM | ownership → 404 |
| 2 | B2 | Fuel logs CRUD | ⬜ | SmallLLM | validate liters > 0 |
| 3 | B3 | Fuel stats (computed) | ⬜ | SmallLLM | full-tank math in a service |

### Worktree: `task/backend-maint`

| Order | ID | Task | Status | Executor | Notes |
|---|---|---|---|---|---|
| 1 | B4 | Maintenance CRUD | ⬜ | SmallLLM | `source='manual'` |
| 2 | B4b | Cloudinary upload signature endpoint | ⬜ | SmallLLM | secret stays server-side |

### Worktree: `task/backend-documents`

| Order | ID | Task | Status | Executor | Notes |
|---|---|---|---|---|---|
| 1 | B5 | Documents CRUD (metadata) | ⬜ | SmallLLM | store `storageUrl` + `publicId`; delete Cloudinary asset |

---

## Batch 3 — Start after all of Batch 2 merges (sequential)

### Worktree: `task/backend-deploy`

| Order | ID | Task | Status | Executor | Notes |
|---|---|---|---|---|---|
| 1 | B6 | Dashboard aggregate | ⬜ | SmallLLM | `/api/v1/dashboard` |
| 2 | B7 | Deploy to Render + Neon | ⬜ | User + SmallLLM | needs Neon & Render accounts |

---

## Batch 4 — Start after `task/mobile-auth` merged AND B7 live (3 worktrees in parallel)

### Worktree: `task/mobile-garage`

| Order | ID | Task | Status | Executor | Notes |
|---|---|---|---|---|---|
| 1 | D1a | Vehicles list (Garage) | ⬜ | SmallLLM | VehicleCard + 4 states |
| 2 | D1b | Add/Edit Vehicle form (modal) | ⬜ | SmallLLM | POST/PATCH + delete |
| 3 | D1c | Vehicle photo upload (Cloudinary) | ⬜ | SmallLLM | signed upload |

### Worktree: `task/mobile-vehicle-detail`

| Order | ID | Task | Status | Executor | Notes |
|---|---|---|---|---|---|
| 1 | D2 | Vehicle detail shell (one scroll) | ⬜ | SmallLLM | sections for D3–D5 |
| 2 | D3 | Fuel tracking UI (+ stats card) | ⬜ | SmallLLM | |
| 3 | D4 | Maintenance UI | ⬜ | SmallLLM | |
| 4 | D5a | Documents list (grouped) | ⬜ | SmallLLM | by type + expiry |
| 5 | D5b | Document upload (Cloudinary) | ⬜ | SmallLLM | signed upload |
| 6 | D5c | Document viewer + delete | ⬜ | SmallLLM | open + delete |

### Worktree: `task/mobile-dashboard`

| Order | ID | Task | Status | Executor | Notes |
|---|---|---|---|---|---|
| 1 | D6 | Dashboard screen | ⬜ | SmallLLM | calls `/dashboard` |

---

## Wrap-up

| Order | ID | Task | Status | Executor | Notes |
|---|---|---|---|---|---|
| 1 | E1 | End-to-end Phase 1 smoke pass | ⬜ | User | add vehicle → fuel → service → doc → dashboard |

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
| Backend | 5 | 15 |
| Mobile | 4 | 15 |
| Wrap-up | 0 | 1 |
| **Total** | **16** | **39** |

---

## Parallel worktree quick reference

| Batch | Worktree | Tasks | Gate |
|---|---|---|---|
| 1 | `task/backend-models` | A3a→A3b→A3c→A4→A5 | ✅ Start now |
| 1 | `task/mobile-auth` | C2a→C2b→C2c→C3 | ✅ Start now |
| 2 | `task/backend-fuel` | B1→B2→B3 | `task/backend-models` merged |
| 2 | `task/backend-maint` | B4→B4b | `task/backend-models` merged |
| 2 | `task/backend-documents` | B5 | `task/backend-models` merged |
| 3 | `task/backend-deploy` | B6→B7 | All Batch 2 merged |
| 4 | `task/mobile-garage` | D1a→D1b→D1c | `task/mobile-auth` merged + B7 live |
| 4 | `task/mobile-vehicle-detail` | D2→D3→D4→D5a→D5b→D5c | `task/mobile-auth` merged + B7 live |
| 4 | `task/mobile-dashboard` | D6 | `task/mobile-auth` merged + B7 live |

> **How to update:** when a task finishes, flip its Status to ✅ and add a one-line note.
> When a worktree merges, check that batch's gate conditions and spin up the next batch.
