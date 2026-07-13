# FastAPI → Next.js Migration — Status

> **One-file dashboard.** For detail: phase specs live in `migration-plan.md`;
> verification/risks live in `migration-audit.md`. This file is the quick "where are we".
> **Last updated:** 2026-07-13 · **Branch:** `feat/fastapi-to-nextjs-migration`
> **HEAD:** `5f92e1b` (Phase 7)

## TL;DR

**Code-complete through Phase 7.** The entire HTTP API and the public compliance/marketing
site are built, typechecked, linted, and (for the API) covered by tests. The only remaining
phase is **Phase 8 — Cutover**, which is entirely deploy-gated: nothing left to *build*, only
to *deploy, verify live, and switch over*.

## Phase completion

| Phase | Scope | Status |
|---|---|---|
| 1 | Foundation (env, Drizzle schema, auth, errors, health) | ✅ Done |
| 2 | `/me` + users service | ✅ Done |
| 3 | Vehicles + fuel logs + fuel-stats | ✅ Done |
| 4 | Maintenance + documents + Cloudinary signature | ✅ Done |
| 5 | Dashboard + activity + driving credentials | ✅ Done |
| 6 | Internal reminders + scheduled trigger (GitHub Actions) + FCM | ✅ Done (code) |
| 7 | Compliance/marketing pages (`/`, `/privacy`, `/terms`, `/support`) | ✅ Done |
| 8 | Cutover (deploy, parity, URL switch, decommission) | ⬜ Not started — deploy-gated |

## What's verified

- **16** API route handlers ported (all Phase 1–6 endpoints; 1:1 with the FastAPI map).
- **23** test files. Pure-logic unit tests (fuel-stats math, cloudinary signature, renewals,
  docs-status, vehicle-label) pass anywhere. DB-integration tests: **120 passed / 2 skipped**
  against local Docker Postgres (verified 2026-07-12 by a collaborator).
- `tsc --noEmit` clean · `eslint` clean · `next build` prerenders the 4 marketing routes static.
- Contract parity confirmed by line-by-line reading vs `backend/` (schema, auth, fuel-stats,
  cloudinary, ownership-404s, error shape). See `migration-audit.md` §2.

## What's NOT yet verified

- Full test suite has never run in *this* environment (no Docker here) — only the collaborator's
  machine. Re-run `pnpm test` against Docker Postgres for local assurance.
- No real side-by-side JSON diff of Next vs a live FastAPI instance for a seeded user (audit R5).
- FCM push has not been exercised end-to-end on a deployed host.

## Remaining work (Phase 8 + carried-over items)

### Deploy-gated (do these when deploying to Vercel)
1. Deploy `web/` to Vercel; set env: `DATABASE_URL` (Neon), `FIREBASE_PROJECT_ID`,
   `FIREBASE_CREDENTIALS_JSON`, `CLOUDINARY_*`, `INTERNAL_SECRET`.
2. Establish **single migration owner = Drizzle**: baseline against the existing (Alembic-created)
   schema; stop running Alembic and Drizzle migrate against prod in parallel.
3. Wire the reminders cron: set GitHub repo **variable** `API_BASE_URL` + **secret**
   `INTERNAL_SECRET`; run `.github/workflows/process-reminders.yml` manually once; confirm FCM
   delivers. Then retire Cloud Scheduler → Cloud Run.
4. Point a preview mobile build at `https://<vercel>/api/v1`; full smoke (auth, garage, fuel,
   maintenance, docs upload, dashboard, profile, credentials, sign out).
5. Switch production mobile `API_BASE_URL` to the new host.
6. Keep Cloud Run on standby ~1 week; then disable its deploy workflow / archive `backend/`.
7. Update root docs: `01-tech-spec.md`, `03-api-contract.md` base URL, `CLAUDE.md`/`AGENTS.md`
   stack lines, `ops-notes.md`.

### Decisions / sign-off (no deploy needed)
- **R2** — 400-vs-422: confirm the mobile client doesn't branch on `422` (Zod returns 400 where
  FastAPI returned 422). If it does, map Zod errors to 422 in `toErrorResponse`.
- **Compliance facts** — confirm the four values in `web/src/lib/site.ts` (contact email, legal
  entity, jurisdiction) and get the Privacy/Terms copy reviewed before public launch. Optional
  custom domain (`drivevault.app`).
- **R4** — fuel-stats banker's-rounding drift (edge-case only): accept or implement round-half-to-even.

## Notable design decisions (already made, documented)

- **Scheduling via GitHub Actions**, not Vercel Cron (per preference) — daily `0 2 * * *`,
  POST + `X-Internal-Secret`. Endpoint stays POST-only (FastAPI parity).
- `reminders` Drizzle table added; `scheduleId`/`documentId` are nullable UUIDs without Drizzle
  FKs (`maintenance_schedules` not modeled yet) — matches the `aiExtractionId` precedent.
- Compliance facts centralized in `web/src/lib/site.ts`; brand yellow `#FFD600` used only as fill
  behind dark ink.
- `DELETE /documents/{id}` deletes the DB row only (no Cloudinary asset cleanup) — matches Python.

## Pointers

- Specs & per-phase reviewer notes → `web/docs/migration-plan.md`
- Verification, issues/risks (R1–R6), fresh-machine test setup → `web/docs/migration-audit.md`
- Conventions → `web/docs/best-practices.md`
