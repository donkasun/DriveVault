# FastAPI → Next.js Migration Audit

> **Scope:** Phases 1–5 of `web/docs/migration-plan.md` (the API port). Phases 6–8
> (internal reminders/cron, marketing pages, cutover) are not yet implemented.
> **Date:** 2026-07-12 · **Branch:** `feat/fastapi-to-nextjs-migration`

This document records (a) the toolchain/verification state after fixing the install,
(b) contract-parity findings vs the FastAPI source, (c) issues & risks, and
(d) a code-quality / best-practices review (state management, modularization,
logic/UI separation, duplication, re-rendering).

---

## 1. Toolchain & verification status

| Check | Result | Notes |
|---|---|---|
| `pnpm install` | ✅ Fixed | See below — global supply-chain policy was blocking it. |
| `tsc --noEmit` | ✅ Clean | No type errors. |
| `eslint src` | ✅ Clean | No lint errors. |
| Pure-logic unit tests | ✅ 20 passing | fuel-stats math, cloudinary signature, renewals, docs-status, vehicle-label. |
| DB-integration tests | ✅ Green (2026-07-12) | Full suite against local Docker Postgres (`localhost:5433`): **120 passed, 2 skipped**. Unblocked by restoring `server/db/client.ts` (Phase 6a had left illegal `export`s inside `try/catch`) and restoring the real vehicles `[id]` route integration test (Phase 6a `vi.doSpyModule` mock was invalid). |

### 1.1 Install fix (what was wrong)

`pnpm install` failed with `ERR_PNPM ... minimumReleaseAge`. This is **not** a bad
lockfile — it is a **global** pnpm supply-chain guard in `~/.config/pnpm/rc`:

```
minimumReleaseAge: 10080   # 7 days, in minutes
```

It rejects any package published within the last 7 days (several transitive deps —
`@rolldown/*`, `@typescript-eslint/*`, etc. — were newer than the cutoff). The lockfile
resolves cleanly; the policy just refuses to materialize it.

**Resolution used:** a one-off override that does **not** weaken the global setting:

```bash
pnpm install --config.minimumReleaseAge=0
```

Deps are now installed under `web/node_modules`. `tsc`, `eslint`, and the unit tests all
run. (Alternative permanent fixes if desired: add `minimumReleaseAge=0` to a project
`web/.npmrc`, or lower the global value. Left untouched deliberately — the guard is a
reasonable security posture.)

### 1.2 Running the full test suite (requires Postgres)

The route/service tests are **DB-integration tests** — they seed and query a real
Postgres (the local Docker DB on host port `5433`, per `docs/ops-notes.md`). To run them:

```bash
# 1. bring up local Docker Postgres (backend/docker-compose.yml)
# 2. create web/.env.local with:
#    DATABASE_URL=postgresql://drivevault:drivevault@localhost:5433/drivevault
# 3. from web/:
pnpm test
```

`vitest.setup.ts` loads `.env.local` if `DATABASE_URL` is unset. Without a database the
20 pure-logic tests still pass in isolation; the other 99 cannot run.

### 1.3 Running tests on a fresh machine (prerequisites NOT in git)

Committing the code is **necessary but not sufficient** — two things the tests depend on
are intentionally not committed. A clean `git clone` + `pnpm install` will **not** run the
full suite until both are provided.

**What the suite actually needs:** only a `DATABASE_URL` to a **schema-provisioned**
Postgres. It does **not** need Firebase or Cloudinary secrets — 15/16 route-test files
`vi.mock` `requireUser` (so `firebase-admin` never initializes), and the Cloudinary test
uses a fixed timestamp with env defaulting to `''`. Those secrets matter for *running the
app*, not for tests.

**Gotcha 1 — `web/.env.local` is git-ignored.** Recreate it on the new machine (copy
`.env.example`). At minimum set `DATABASE_URL`.

**Gotcha 2 — no Drizzle migration files exist.** `drizzle.config.ts` points `out` at
`src/server/db/migrations`, but that directory is empty/untracked, and nothing runs
`push`/`migrate` at test time. The integration tests `db.insert(...)` against tables they
assume **already exist**. On an empty database they fail with "relation does not exist".
The schema is owned by the backend's **Alembic** migrations (Drizzle is baselined against
it, per §5 of the migration plan).

**Fresh-machine recipe:**

```bash
# 1. Provision the schema. Either:
#    (a) bring up the backend's Docker Postgres — Alembic migrates on boot:
cd backend && docker compose up -d            # exposes Postgres on host port 5433
#    (b) OR baseline a fresh DB with Drizzle:
cd web && pnpm drizzle-kit push               # note: this artifact is not committed today

# 2. Create web/.env.local (git-ignored) with a matching DATABASE_URL:
#    DATABASE_URL=postgresql://drivevault:drivevault@localhost:5433/drivevault

# 3. Run the suite:
cd web && pnpm install && pnpm test           # expect all 119 tests green
```

> If `pnpm install` is blocked by the global `minimumReleaseAge` supply-chain policy
> (see §1.1), use `pnpm install --config.minimumReleaseAge=0` or add `minimumReleaseAge=0`
> to a project `web/.npmrc`.

---

## 2. Contract-parity findings (vs FastAPI source)

The port is **faithful**. Verified line-by-line against `backend/`:

- **DB schema** (`server/db/schema.ts`) — column-for-column match with the SQLAlchemy
  models: types, nullability, server defaults, CHECK constraints, indexes.
  `user_documents` correctly ported from the Alembic-only table (not in Doc 2).
- **Auth** (`require-user.ts` / `upsert-user.ts`) — faithful to `deps.py`:
  `check_revoked=True`, distinct revoked-vs-invalid 401 messages, email trusted only when
  `email_verified`, Google display/photo sync, and the concurrent-insert unique-violation
  race re-select.
- **Fuel-stats interval math** (`fuel-stats.ts`) — line-for-line port of
  `compute_fuel_stats`, incl. the "interval never re-closes once opened" semantics and
  reverse-sorted monthly spend. Covered by the ported fixtures (green).
- **Cloudinary signature** (`cloudinary.ts`) — identical SHA1-over-sorted-params
  algorithm; file bytes never touch the server.
- **Ownership 404s** — services filter by `userId` in the WHERE clause and throw
  `AppError(404)`, matching "another user's resource → 404 (not 403)".
- **Error shape** — `{ detail }` with correct HTTP status via `toErrorResponse`.
- **Route coverage** — all 15 Phase 1–5 endpoints present and mapped 1:1.

---

## 3. Issues & risks

| # | Severity | Issue | Status / recommendation |
|---|---|---|---|
| R1 | ~~**High (process)**~~ | ~~Full test suite never executed against a real DB.~~ **Resolved 2026-07-12** — `pnpm test` against Docker Postgres: 120 passed / 2 skipped. | Done. |
| R2 | Medium | **Validation status drift: 400 vs 422.** Zod failures return **400**; FastAPI/Pydantic returned **422** for bad bodies and invalid-UUID path params. Documented as intentional in the route handlers. | Confirm the mobile client does not branch on `422` specifically. If it does, map Zod errors to 422 in `toErrorResponse`. |
| R3 | Low | ~~**Temp route `_auth-check`**~~ **Resolved 2026-07-12** — route + test deleted. | Done. |
| R4 | Low | **Banker's-rounding drift** in fuel-stats (`Math.round` half-up vs Python round-half-to-even). Only bites on exact `.5`-cent values; current fixtures don't hit it. | Documented in `fuel-stats.ts`. Accept, or implement round-half-to-even if strict parity matters. |
| R5 | Low | **No real side-by-side parity check.** Phase 2 & 5 "golden JSON vs live FastAPI" steps are blocked (no live FastAPI / Firebase creds). Parity rests on unit tests + code reading only. | Run one seeded-user diff against live FastAPI at cutover. |
| R6 | Info | `DELETE /documents/{id}` does not remove the Cloudinary asset — **matches Python** (DB-only delete). Not a regression. | Optional follow-up (see migration-plan Phase 4b note). |

---

## 4. Best-practices review

### 4.1 Important context: this is an **API-only** codebase today

`web/` currently ships the `/api/v1/*` route handlers plus two static server components
(`app/layout.tsx`, `app/page.tsx`). There are:

- **no client components** (`grep -r "use client"` → none),
- **no React state** (no `useState`/`useEffect`/`useReducer`/context/store),
- **no data-fetching hooks** (no react-query/swr/zustand/redux).

So two of the requested dimensions — **state management** and **re-rendering** — have
**no surface area yet**. There is nothing to fix; there is a standard to *set* when UI
work (Phase 7 marketing pages, and any future dashboard UI) begins. Guidance below.

### 4.2 Modularization — ✅ good

Clean, consistent layering that mirrors the backend and the CLAUDE.md architecture rules:

```
app/api/v1/**/route.ts   → parse request, requireUser, call service, shape response
server/services/*.ts     → business logic + Drizzle DB access (the only DB callers)
server/schemas/*.ts      → Zod wire shapes (the only things that cross the wire)
server/auth, server/lib  → cross-cutting (auth, errors, constants, cloudinary)
```

- All service files are small (largest = `fuel-logs.ts` at 185 lines) — well within the
  "split past a few hundred lines" rule.
- Routers contain **no SQL / no business logic** — they delegate to services. ✔
- `server-only` import guards service/db modules from ever being bundled client-side. ✔

### 4.3 Logic / UI separation — ✅ good (for the API)

No presentation logic leaks into services; response shaping is done via explicit mappers
(`toVehicleDto`-style) and Zod schemas rather than returning raw ORM rows. This is exactly
the "explicit mappers so the contract can't silently drift" guidance from the plan.

### 4.4 Duplicate functionality — ✅ mostly centralized; one optional cleanup

**Already well-factored (no action):**
- Expiry/status math is centralized in `server/services/renewals.ts` (`daysUntil`,
  `renewalStatus`) and reused by `docs-status.ts`, `dashboard-renewals.ts`, and
  `driving-credentials.ts`. No copy-paste.
- Vehicle labelling centralized in `vehicle-label.ts`, reused by activity + dashboard.

**Intentional duplication (leave as-is):**
- `activity.ts` and `dashboard-activity.ts` both merge fuel+maintenance+documents, but
  emit **different contract shapes** (rich feed vs lean 10-item recent list) mirroring two
  distinct Python endpoints. Merging them would risk contract drift. Keep separate.

**Optional cleanup (low priority) — route boilerplate:**
- All 16 route files repeat the same skeleton (~46 handlers):
  ```ts
  try { const user = await requireUser(req); /* ... */ }
  catch (err) { return toErrorResponse(err); }
  ```
  A tiny `withUser(handler)` higher-order wrapper in `server/lib/` would remove the
  repeated `try/catch` + `requireUser` and guarantee uniform error handling. This is
  idiomatic-Next either way; deferring is fine, but it's the one real DRY opportunity.

### 4.5 State management & re-rendering — ⚠️ N/A now; standard to set for Phase 7+

When client UI is added, adopt these defaults (documented here so the first UI PR doesn't
improvise):

- **Prefer Server Components + server data fetching.** Keep `"use client"` at the leaves.
  Most marketing/compliance pages (Phase 7) should be fully static server components with
  zero client JS.
- **No global store until proven necessary.** For any interactive dashboard, start with
  server components + URL/searchParams state; reach for a store (Zustand) only when shared
  client state genuinely spans components.
- **Data fetching:** if client-side fetching is needed, standardize on one library (TanStack
  Query) rather than ad-hoc `useEffect` fetches — avoids waterfalls and manual cache bugs.
- **Re-render hygiene:** colocate state as low as possible; memoize only measured hotspots;
  pass stable keys/props. Don't pre-optimize before there's a component tree to measure.

---

## 5. Action items (prioritized)

1. ~~**[High]** Run `pnpm test` against local Docker Postgres and confirm all 119 tests
   green (R1).~~ ✅ Done 2026-07-12 — 120 passed / 2 skipped.
2. **[Medium]** Decide 400-vs-422 policy with the mobile client (R2).
3. ~~**[Low]** Delete `app/api/v1/_auth-check/` before cutover (R3).~~ ✅ Done 2026-07-12.
4. **[Low]** One live-FastAPI golden-JSON parity diff for a seeded user at cutover (R5).
5. **[Optional]** `withUser` route wrapper to remove per-handler boilerplate (§4.4).
6. **[Future]** Apply §4.5 state/rendering standards when Phase 7 UI starts.
7. Proceed with Phase 6 (internal reminders + Vercel Cron) and Phase 7 (compliance pages).
