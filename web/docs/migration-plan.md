# FastAPI → Next.js Migration Plan

> **For agentic workers:** Implement phase-by-phase. Prefer subagent-driven development
> with review between phases. Checkboxes track progress. Do **not** change API JSON keys
> or DB columns — `docs/03-api-contract.md` and `docs/02-database-schema.md` (repo root)
> win. Conventions: `web/docs/best-practices.md`.

**Goal:** Move DriveVault’s HTTP API from FastAPI (Cloud Run) into this Next.js app so one
Vercel project serves (1) compliance/marketing pages and (2) `/api/v1/*` for mobile clients.

**Architecture:** Next.js App Router Route Handlers replace FastAPI routers; a `server/services`
layer ports Python services; Drizzle + Neon replace SQLAlchemy + Alembic-on-boot; Firebase
Admin verification stays. Mobile clients keep the same contract — only the base URL changes
at cutover.

**Tech stack (target):** Next.js 16 (App Router) · TypeScript · Zod · Drizzle ORM ·
Neon Postgres · firebase-admin · Cloudinary signed uploads · Vercel · pnpm

**Non-goals during migration:** Redesigning the API, adding AI features, rewriting mobile,
dropping Firebase Auth.

---

## 0. Principles

1. **Contract freeze.** Same paths, status codes, camelCase JSON, `{ detail }` errors.
2. **One vertical slice at a time.** e.g. health → me → vehicles → … each shippable.
3. **FastAPI stays live** until cutover checklist passes. Run both against the **same Neon
   DB** only after schema ownership is clear (prefer Next.js read-only first, then dual
   write carefully — see Phase 2).
4. **Port tests, don’t delete them.** Every FastAPI test module gets a Jest/Vitest
   equivalent before retiring the Python route.
5. **No secrets in git.** `.env.example` only.

---

## 1. Current FastAPI inventory (source)

| Area | Location | Notes |
|---|---|---|
| App factory | `backend/app/main.py` | CORS + router mount under `/api/v1` |
| Auth dep | `backend/app/deps.py` | Firebase Bearer → lazy user upsert |
| Config | `backend/app/core/config.py` | env via pydantic-settings |
| Models | `backend/app/models/*` | 9 tables |
| Schemas | `backend/app/schemas/*` | Pydantic wire shapes |
| Services | `backend/app/services/*` | Business logic |
| Routers | `backend/app/routers/*` | Thin HTTP layer |
| Migrations | `backend/alembic/versions/*` | 9 revisions |
| Deploy | `backend/Dockerfile` + GHA → Cloud Run | Alembic on container start |
| Live URL | `https://drivevault-backend-250609806849.us-central1.run.app` | |

### Endpoint map (must preserve)

| Method | Path | Auth |
|---|---|---|
| GET | `/health` | public |
| GET/PATCH | `/api/v1/me` | Firebase |
| GET/POST | `/api/v1/vehicles` | Firebase |
| GET/PATCH/DELETE | `/api/v1/vehicles/{id}` | Firebase |
| GET/POST | `/api/v1/vehicles/{id}/fuel-logs` | Firebase |
| PATCH/DELETE | `/api/v1/fuel-logs/{id}` | Firebase |
| GET | `/api/v1/vehicles/{id}/fuel-stats` | Firebase |
| GET/POST | `/api/v1/vehicles/{id}/maintenance` | Firebase |
| GET/PATCH/DELETE | `/api/v1/maintenance/{id}` | Firebase |
| GET/POST | `/api/v1/vehicles/{id}/documents` | Firebase |
| GET/PATCH/DELETE | `/api/v1/documents/{id}` | Firebase |
| POST | `/api/v1/uploads/cloudinary-signature` | Firebase |
| GET | `/api/v1/dashboard` | Firebase |
| GET/POST | `/api/v1/me/driving-credentials` | Firebase |
| PATCH/DELETE | `/api/v1/me/driving-credentials/{id}` | Firebase |
| GET | `/api/v1/activity` | Firebase |
| POST | `/api/v1/internal/process-reminders` | `X-Internal-Secret` |

---

## 2. Target layout inside `web/`

```
web/src/
  app/
    (marketing)/
      page.tsx                 # landing (minimal OK)
      privacy/page.tsx
      terms/page.tsx
      support/page.tsx
    health/route.ts            # GET /health
    api/v1/
      me/route.ts
      vehicles/route.ts
      vehicles/[id]/route.ts
      vehicles/[id]/fuel-logs/route.ts
      fuel-logs/[id]/route.ts
      vehicles/[id]/fuel-stats/route.ts
      vehicles/[id]/maintenance/route.ts
      maintenance/[id]/route.ts
      vehicles/[id]/documents/route.ts
      documents/[id]/route.ts
      uploads/cloudinary-signature/route.ts
      dashboard/route.ts
      me/driving-credentials/route.ts
      me/driving-credentials/[id]/route.ts
      activity/route.ts
      internal/process-reminders/route.ts
  server/
    db/
      schema.ts                # Drizzle tables = Doc 2
      client.ts
      migrations/              # drizzle-kit
    auth/
      firebase-admin.ts
      require-user.ts
      require-internal-secret.ts
    services/                  # port of backend/app/services
    lib/
      env.ts
      errors.ts
      cloudinary.ts
  content/                     # privacy.md, terms.md (optional MDX)
```

---

## 3. Stack decisions (locked for this migration)

| Concern | Choice | Rationale |
|---|---|---|
| HTTP API | App Router Route Handlers | Native on Vercel; maps 1:1 to routers |
| Validation | Zod | TS-native; replace Pydantic at the edge |
| ORM | Drizzle + drizzle-kit | Typed SQL; Neon-friendly; mirrors schema docs |
| DB prod | Existing Neon database | No data migration of rows if schema identical |
| Auth | `firebase-admin` | Same tokens mobile already sends |
| Uploads | Cloudinary signature only | Unchanged |
| Cron | Vercel Cron → `/api/v1/internal/process-reminders` | Replaces Cloud Scheduler → Cloud Run |
| Package manager | pnpm | Repo standard |
| Tests | Vitest (or Jest) + Node | Port pytest intent |

**Pre-approved deps to add when Phase 1 starts** (flag versions if they conflict):
`drizzle-orm`, `drizzle-kit`, `@neondatabase/serverless`, `firebase-admin`, `zod`,
`server-only`, `vitest` (dev).

---

## Phase 0 — Scaffold hygiene (this PR)

**Status:** In progress on branch `feat/fastapi-to-nextjs-migration`.

- [x] Create Next.js app in `web/`
- [x] Root + `web/` gitignore updates for Next.js / Vercel / env
- [x] `web/docs/best-practices.md`
- [x] `web/docs/migration-plan.md` (this file)
- [ ] Commit + push branch

**Done when:** branch pushed; `pnpm --dir web lint` works; docs present.

---

## Phase 1 — Foundation (env, DB, auth, errors, health)

**Goal:** Next.js can verify Firebase, talk to Postgres, and serve `/health` + a secured
stub.

### Tasks

- [x] **1.1** Add `.env.example` mirroring `backend/.env.example` (Next-friendly names OK;
      document mapping). Include `INTERNAL_SECRET`.
- [x] **1.2** Install foundation deps (list in §3); configure `drizzle.config.ts`.
- [x] **1.3** Port Doc 2 tables to `server/db/schema.ts` (snake_case columns, UUID PKs,
      timestamptz). Generate initial Drizzle migration **from the live schema** or by
      translating Alembic — do not invent columns.
- [x] **1.4** `server/db/client.ts` — Neon serverless in prod, local connection for Docker
      Postgres (`localhost:5433` when applicable).
- [x] **1.5** `server/auth/firebase-admin.ts` + `requireUser(req)` porting
      `backend/app/deps.py` (verify token, lazy upsert, email_verified rules).
- [x] **1.6** `server/lib/errors.ts` — `toErrorResponse` → `{ detail }` + correct status.
- [x] **1.7** `GET /health` → `{ "status": "ok" }`.
- [x] **1.8** Smoke route `GET /api/v1/me` (can be Phase 2) or a temporary
      `GET /api/v1/_auth-check` that returns `{ uid }` — remove before cutover.
- [x] **1.9** Vitest: mock Firebase; assert 401 without token; 200 with mocked token.

**Done when:** health public; auth dependency unit-tested; Drizzle can `select` from
`users` against local Docker Postgres.

---

## Phase 2 — `/me` + users service

**Port:** `backend/app/routers/me.py`, `services/users.py`, `schemas/users.py`

- [x] Zod schemas for GET response + PATCH body (currency forced `LKR`).
- [x] `GET/PATCH /api/v1/me` Route Handlers.
- [x] Tests: create-on-first-call; patch displayName / distanceUnit / renewalRemindersEnabled.
- [ ] Manual smoke with a real Firebase ID token against local Next + Docker DB.
      **Blocked:** no real Firebase credentials in this session; 401-without-token smoke
      (Vitest) is enough for now.

**Done when:** mobile (or curl) can hit Next.js `/api/v1/me` with parity to FastAPI.

---

## Phase 3 — Vehicles + fuel logs + fuel stats

**Port:** `routers/vehicles.py`, `services/vehicles.py`, `services/fuel_logs.py`, schemas

- [x] CRUD `/api/v1/vehicles` + `/api/v1/vehicles/{id}`
- [x] Fuel logs nested + top-level patch/delete
- [x] `GET .../fuel-stats` — port pure math from Python service **with the same fixtures**
      as `backend/tests` so numbers match exactly
- [x] Ownership 404 tests (cross-user)

**Done when:** vehicle + fuel test suite parity; Flutter/RN can point at Next for these
routes in a side-by-side check.

---

## Phase 4 — Maintenance + documents + Cloudinary signature

**Port:** maintenance, documents, uploads services/routers

- [x] Maintenance CRUD + category filters
- [x] Documents CRUD + `docType` query alias
- [x] `POST /uploads/cloudinary-signature` — same signature algorithm as
      `backend/app/services/uploads.py` (no Cloudinary SDK required)
- [x] Confirm file bytes never hit the Next server

**Done when:** upload signature works from mobile; document + maintenance CRUD parity.

> **Reviewer note (Phase 4b):** Doc 3 says `DELETE /documents/{id}` also removes the
> Cloudinary asset via `public_id`. Real Python (`routers/documents.py`) only deletes
> the DB row. Next.js matches Python (DB-only delete). Fixing Cloudinary cleanup is a
> separate follow-up if desired — do not treat it as a Next.js regression.

---

## Phase 5 — Dashboard, activity, driving credentials

**Port:** dashboard, activity, driving_credentials (+ renewals helpers)

- [ ] `GET /dashboard` — same aggregation rules as Doc 3 (renewals window, activity merge)
- [ ] `GET /activity?limit=`
- [ ] Driving credentials under `/me/driving-credentials`
- [ ] Snapshot tests or golden JSON from FastAPI responses vs Next for a seeded user

**Done when:** home-screen payload matches FastAPI for the seeded Hilux user.

---

## Phase 6 — Internal reminders + Vercel Cron

**Port:** `internal.py`, `reminder_processing.py`, FCM send path

- [ ] `POST /api/v1/internal/process-reminders` guarded by `X-Internal-Secret`
- [ ] `vercel.json` cron schedule (match existing Cloud Scheduler cadence)
- [ ] Verify FCM send still works with Firebase Admin on Vercel
- [ ] Retire Cloud Scheduler → Cloud Run job only after Next cron is proven

**Done when:** one successful scheduled run in preview/prod; secret rejection tested.

---

## Phase 7 — Compliance / marketing site

**Goal:** Stable public pages for store / legal compliance (can start in parallel after
Phase 0).

- [ ] `/privacy` — privacy policy
- [ ] `/terms` — terms of service
- [ ] `/support` — contact / support instructions
- [ ] Optional landing at `/`
- [ ] Footer links; `last updated` dates; accessible markup
- [ ] Custom domain (e.g. `drivevault.app`) on Vercel

**Done when:** URLs suitable for App Store / Play Console listing; no auth required.

---

## Phase 8 — Cutover

1. [ ] Deploy `web` to Vercel production; run Drizzle migrations if any pending (coordinate
       with Alembic — **single migration owner** going forward = Drizzle).
2. [ ] Point a preview mobile build at `https://<vercel>/api/v1` (or custom API domain).
3. [ ] Full smoke: auth, garage, fuel, maintenance, docs upload, dashboard, profile,
       credentials, sign out.
4. [ ] Switch production mobile `API_BASE_URL` / Expo public env to the new host.
5. [ ] Keep Cloud Run up in read-only / standby for ~1 week; monitor errors.
6. [ ] Disable Cloud Run deploy workflow; archive `backend/` or mark deprecated in README.
7. [ ] Update root `docs/01-tech-spec.md`, `docs/03-api-contract.md` base URL,
       `CLAUDE.md` / `AGENTS.md` stack lines.
8. [ ] Update GHA / ops notes (`docs/ops-notes.md`).

**Done when:** production mobile traffic hits Next.js only; FastAPI scaled to zero;
docs updated.

---

## 4. Python → TypeScript porting cheat sheet

| FastAPI | Next.js |
|---|---|
| `APIRouter` + `@router.get` | `export async function GET` in `route.ts` |
| `Depends(get_current_user)` | `await requireUser(req)` |
| `Depends(get_db)` | `db` from `server/db/client` inside service |
| Pydantic model | Zod schema + inferred `type` |
| `HTTPException(status, detail=)` | throw `AppError(status, detail)` → `toErrorResponse` |
| SQLAlchemy `select` | Drizzle `db.select().from(...)` |
| Alembic revision | `drizzle-kit generate` / `migrate` |
| `CORSMiddleware` | `next.config.ts` headers **or** explicit CORS on Route Handlers if browser clients need it (mobile doesn’t need CORS) |
| Gunicorn + Uvicorn | Vercel serverless / Node runtime for Route Handlers |
| Cloud Scheduler | Vercel Cron |

### camelCase responses

FastAPI uses Pydantic aliases. In TS, either:

- Keep Drizzle rows snake_case and map with explicit mappers (`toVehicleDto(row)`), or
- Use a small `camelCaseKeys` helper at the boundary.

Prefer **explicit mappers** for domain objects so the contract can’t silently drift.

---

## 5. Database migration strategy (critical)

**Preferred path:**

1. Treat the **existing Neon schema** (created by Alembic) as canonical.
2. Introspect into Drizzle (`drizzle-kit pull`) **or** hand-write `schema.ts` to match Doc 2
   exactly, then baseline so Drizzle does not try to recreate tables.
3. New schema changes after cutover happen **only** via Drizzle.
4. Do **not** run Alembic and Drizzle migrate against prod in parallel.

**Local:** continue using Docker Postgres; run the same baseline.

---

## 6. Testing strategy

| Layer | How |
|---|---|
| Zod schemas | Unit tests for accept/reject fixtures from Doc 3 |
| Services | DB integration tests (test database) ported from pytest |
| Route Handlers | Call handlers with mocked `requireUser` |
| Parity | Optional script: hit FastAPI + Next with same token, diff JSON |

Run scoped tests per phase. Full suite before cutover.

---

## 7. Risk register

| Risk | Mitigation |
|---|---|
| Subtle fuel-stats math drift | Port tests with fixed fixtures first |
| Firebase Admin cold start on Vercel | Lazy init singleton; measure p95 |
| Dual writers corrupt data | Never dual-write; cut over by URL switch |
| Drizzle vs Alembic fight | Baseline + single owner (Phase 8) |
| Cron secret leak | Env-only `INTERNAL_SECRET`; rotate on cutover |
| CORS surprises for web clients | Mobile unaffected; add origins only when browser app needs API |

---

## 8. Suggested branches / worktrees

| Branch | Phase |
|---|---|
| `feat/fastapi-to-nextjs-migration` | Phase 0 (docs + scaffold) |
| `feat/web-api-foundation` | Phase 1 |
| `feat/web-api-me` | Phase 2 |
| `feat/web-api-vehicles-fuel` | Phase 3 |
| `feat/web-api-maint-docs` | Phase 4 |
| `feat/web-api-dashboard` | Phase 5 |
| `feat/web-api-cron` | Phase 6 |
| `feat/web-compliance-pages` | Phase 7 (parallel OK) |
| `feat/web-api-cutover` | Phase 8 |

---

## 9. Open questions (ask before guessing)

1. Custom domains: `drivevault.app` for marketing and `api.drivevault.app` vs single host
   with path `/api/v1`?
2. Keep Cloud Run as internal failover for 7 days or longer?
3. Vitest vs Jest for this package — default **Vitest** unless the monorepo standardizes
   otherwise.
4. Should compliance copy be lawyer-reviewed before Phase 7 merge to main?

---

## 10. Execution handoff

Phase 0 completes with this commit. Next implementation step: **Phase 1 — Foundation**.

Two options when ready to code:

1. **Subagent-Driven** — one subagent per task, review between tasks  
2. **Inline Execution** — implement in-session with checkpoints
