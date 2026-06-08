# DriveVault — Task Dashboard

> **Living document.** Single source of truth for *what's been done, what's next, and who's doing it.*
> Update the **Status** and **Executor** cells as work progresses. Tasks A–E come from
> [`04-phase1-tasks.md`](./04-phase1-tasks.md); the `S` tasks are one-time project setup.

## Legend
**Status:** ✅ Done · 🟡 In progress · ⏳ Blocked / waiting · ⬜ Not started
**Executor:** `Opus` (strong model — setup & scaffolds) · `SmallLLM` (feature tasks, one at a time) · `User` (manual: installs, cloud accounts)

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
| 7 | S7 | Firebase project + wiring | 🟡 | Opus + User | `drivevault-app` created, `flutterfire configure` done; **User must enable Auth providers in console** (Email/Google) |
| 8 | S8 | Cloudinary account (free, no card) | ⬜ | User | sign up → put cloud name / API key / secret in backend `.env` |

---

## 1. Backend (FastAPI) — build first; Docs 2 & 3 are the fixed contract

| Order | ID | Task | Status | Executor | Notes |
|---|---|---|---|---|---|
| 1 | A1 | Project scaffold + `/health` | ✅ | Opus | pytest passing |
| 2 | A2 | Config + DB session + `docker-compose` | ✅ | Opus | Postgres 16 local |
| 3 | A3 | SQLAlchemy models (P1+P2) + initial Alembic migration | ⬜ | SmallLLM | match `02-database-schema.md` exactly |
| 4 | A4 | Firebase token auth dependency (`get_current_user`) | ⬜ | SmallLLM | mock `verify_id_token` in tests |
| 5 | A5 | `/me` endpoints (GET, PATCH) | ⬜ | SmallLLM | lazy user upsert |
| 6 | B1 | Vehicles CRUD | ⬜ | SmallLLM | ownership → 404 |
| 7 | B2 | Fuel logs CRUD | ⬜ | SmallLLM | validate liters > 0 |
| 8 | B3 | Fuel stats (computed) | ⬜ | SmallLLM | full-tank math in a service |
| 9 | B4 | Maintenance CRUD | ⬜ | SmallLLM | `source='manual'` |
| 10 | B4b | Cloudinary upload signature endpoint | ⬜ | SmallLLM | signs uploads; secret stays server-side |
| 11 | B5 | Documents CRUD (metadata) | ⬜ | SmallLLM | store `storageUrl` + `publicId`; delete Cloudinary asset |
| 12 | B6 | Dashboard aggregate | ⬜ | SmallLLM | `/api/v1/dashboard` |
| 13 | B7 | Deploy to Render + Neon | ⏳ | User + SmallLLM | needs Neon & Render accounts |

---

## 2. Mobile (Flutter) — after backend contract is stable

| Order | ID | Task | Status | Executor | Notes |
|---|---|---|---|---|---|
| 1 | C1 | Flutter scaffold (feature folders, deps, shell, router) | ✅ | Opus | analyze clean, widget test passing |
| 2 | C2 | Firebase init + Auth (email/Google/Apple) | ⬜ | SmallLLM | persists across restart |
| 3 | C3 | API client + token injection | ⬜ | SmallLLM | base URL via `--dart-define` |
| 4 | D1 | Vehicles list + create/edit (+ photo upload) | ⬜ | SmallLLM | end-to-end vs live API |
| 5 | D2 | Vehicle detail shell (tabs) | ⬜ | SmallLLM | containers for D3–D5 |
| 6 | D3 | Fuel tracking UI (+ stats card) | ⬜ | SmallLLM | |
| 7 | D4 | Maintenance UI | ⬜ | SmallLLM | |
| 8 | D5 | Document vault UI (upload/list/open) | ⬜ | SmallLLM | Firebase Storage |
| 9 | D6 | Dashboard screen | ⬜ | SmallLLM | calls `/dashboard` |

---

## 3. Wrap-up

| Order | ID | Task | Status | Executor | Notes |
|---|---|---|---|---|---|
| 1 | E1 | End-to-end Phase 1 smoke pass | ⬜ | User | add vehicle → fuel → service → doc → dashboard |

---

## Progress summary

| Group | Done | Total |
|---|---|---|
| Setup | 5 | 8 |
| Backend | 2 | 13 |
| Mobile | 1 | 9 |
| Wrap-up | 0 | 1 |
| **Total** | **8** | **31** |

**Critical path right now:** both scaffolds (backend A1/A2, mobile C1) are done. Hand the
feature tasks to the small LLM — start with **A3** (backend models) and **C2** (Firebase auth).
The only remaining `Opus`/`User` setup item is S6 (Android `cmdline-tools`, optional if building iOS).

> **How to update:** when an executor finishes a task, flip its Status to ✅, add a one-line
> note (e.g. "tests passing"), and bump the Progress summary counts. Keep one task 🟡 per
> executor at a time (per `CLAUDE.md` golden rule #1).
