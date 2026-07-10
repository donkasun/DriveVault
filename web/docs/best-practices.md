# Next.js Best Practices — DriveVault `web/`

Working conventions for the DriveVault web app (marketing/compliance site + API host).
Read before adding features. The FastAPI backend in `backend/` is the behavior reference
until cutover; API shapes stay locked to `docs/03-api-contract.md` and
`docs/02-database-schema.md` at the repo root.

---

## 1. What this app is

`web/` is a **Next.js App Router** project that will eventually:

1. **Host the public website** — marketing, privacy policy, terms, app-store / Play compliance
   pages, support contact.
2. **Host the DriveVault REST API** — same `/api/v1/*` contract the mobile clients use today
   (replacing Cloud Run FastAPI).

Until migration is complete, treat the Python backend as source of truth for runtime
behavior. Do not invent endpoints or rename JSON keys.

---

## 2. Project & folder structure

Organize by **responsibility**, not by dumping everything into `app/`:

```
web/
  src/
    app/                          # routes only — pages + Route Handlers
      (marketing)/                # public site (privacy, terms, landing)
        page.tsx
        privacy/page.tsx
        terms/page.tsx
      api/
        health/route.ts           # GET /health (public)
        v1/
          me/route.ts             # /api/v1/me
          vehicles/
            route.ts
            [id]/route.ts
          ...
      layout.tsx
    server/                       # Node-only code (never import from client components)
      db/                         # Drizzle client + schema
      auth/                       # Firebase Admin verify + getCurrentUser
      services/                   # business logic (mirrors backend/app/services)
      lib/                        # env, errors, cloudinary sign
    components/                   # shared UI (marketing + any authenticated web UI)
    lib/                          # isomorphic helpers (formatting, constants)
  docs/
    best-practices.md             # this file
    migration-plan.md
```

Rules:

- **`app/` is thin.** Pages compose components. Route Handlers parse the request, call a
  service, return a `Response`. No SQL and no Firebase Admin calls inlined in route files
  beyond a one-line service call.
- **`server/` is server-only.** Use the `server-only` package at the top of modules that
  touch secrets, DB, or Admin SDK so a mistaken client import fails the build.
- **Services own business logic + DB access** — same boundary as FastAPI
  `routers/ → services/`. Independently testable.
- A file over ~250–300 lines is doing too much — split it.
- Co-locate tests next to the module: `vehicles.test.ts` beside the service, or under
  `__tests__/` mirroring the path.

---

## 3. TypeScript

- `strict: true` — do not loosen it.
- No `any`. Prefer `unknown` + narrowing, or Zod-parsed types at the HTTP boundary.
- Prefer `type` for data shapes; `interface` only when you need declaration merging.
- Wire JSON stays **lowerCamelCase** (matches Doc 3 / mobile clients). DB columns stay
  **snake_case** (matches Doc 2). Convert at the service/schema boundary — never leak
  snake_case into API responses.

---

## 4. App Router conventions

### Rendering

- Default to **Server Components**. Add `"use client"` only for interactivity
  (forms with client validation, accordions, analytics widgets).
- Marketing/compliance pages should be static or ISR where possible — fast, cacheable,
  no auth required.
- Never put secrets in Client Components or `NEXT_PUBLIC_*` except values that are
  truly public (e.g. Firebase web config for a future web login, Cloudinary cloud name).

### Routing

- Use **route groups** `(marketing)`, `(app)` for layout splits without affecting the URL.
- API lives under `src/app/api/...` so URLs are `/api/...` — keep the FastAPI prefix
  `/api/v1` by nesting `api/v1/...`.
- `GET /health` stays at `/api/health` **or** `/health` via `src/app/health/route.ts` —
  match the migration plan’s chosen path and update Doc 3 only if the public URL changes
  (prefer keeping `/health` at the site root for uptime checks).

### Caching

- Authenticated API routes: **`dynamic = 'force-dynamic'`** (or no caching). Never cache
  user-specific JSON at the CDN.
- Marketing pages: static by default; revalidate when legal copy changes.

---

## 5. API Route Handlers

### Shape

```ts
// src/app/api/v1/vehicles/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { requireUser } from '@/server/auth/require-user';
import { listVehicles, createVehicle } from '@/server/services/vehicles';
import { toErrorResponse } from '@/server/lib/errors';

export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
  try {
    const user = await requireUser(req);
    const data = await listVehicles(user.id);
    return NextResponse.json(data);
  } catch (err) {
    return toErrorResponse(err);
  }
}
```

### Rules

- **One resource family per folder**, mirroring FastAPI routers.
- Validate bodies with **Zod** (or equivalent). Map validation failures to **400/422** with
  `{ "detail": "..." }` — same error envelope as FastAPI.
- Auth via `Authorization: Bearer <Firebase ID token>` on every protected route.
- Ownership: missing or other-user’s resource → **404**, never 403.
- Money: integer **cents** only. Currency locked to `LKR` server-side (same as FastAPI).
- Creates → **201**; deletes → **204** with empty body.
- Do not stream file bytes through Next.js — clients upload to Cloudinary with a
  backend-signed request; we store only `secure_url`.

### Error helper

Centralize mapping:

| Condition | Status | Body |
|---|---|---|
| Validation | 400 or 422 | `{ detail }` |
| Missing/invalid token | 401 | `{ detail }` |
| Not found / not owned | 404 | `{ detail }` |
| Conflict | 409 | `{ detail }` |
| Unexpected | 500 | `{ detail: "Internal server error" }` (log the real error) |

---

## 6. Auth (Firebase Admin)

- Verify ID tokens with **Firebase Admin** (`firebase-admin`), same as FastAPI
  `get_current_user`.
- Lazy-upsert the `users` row on first authenticated request (by `firebase_uid`).
- Prefer `email` only when `email_verified` is true (match FastAPI behavior).
- Put credentials in env: `FIREBASE_CREDENTIALS_JSON` (full SA JSON string) or
  workload identity on Vercel — **never** commit the JSON file.
- Internal cron routes (reminders) use `X-Internal-Secret`, not Firebase — same as
  FastAPI `/internal/process-reminders`.

---

## 7. Database

- **Postgres 16** (Neon in prod, Docker locally on host port **5433** if 5432 is taken).
- Prefer **Drizzle ORM** + `drizzle-kit` migrations (typed, close to SQL, good on Neon
  serverless). Prisma is acceptable only if the team already standardizes on it — do not
  run two ORMs.
- Schema must match Doc 2 column names/types. Port Alembic history carefully — see
  `migration-plan.md`.
- Connection: use Neon’s serverless driver on Vercel (`@neondatabase/serverless` +
  Drizzle) for Route Handlers; local Docker can use a standard `pg` pool.
- All DB access goes through `server/db` + services — no ad-hoc queries in route files.

---

## 8. Environment & secrets

| Var | Where | Notes |
|---|---|---|
| `DATABASE_URL` | server | Neon / local Postgres |
| `FIREBASE_PROJECT_ID` | server | e.g. `drivevault-app` |
| `FIREBASE_CREDENTIALS_JSON` | server | SA JSON string |
| `CLOUDINARY_CLOUD_NAME` | server (+ public name OK) | |
| `CLOUDINARY_API_KEY` | server | |
| `CLOUDINARY_API_SECRET` | server | never `NEXT_PUBLIC_` |
| `INTERNAL_SECRET` | server | cron / scheduler |
| `CORS_ORIGINS` | server | if browser clients call the API |

- Commit `.env.example` only. Real `.env` / `.env.local` stay gitignored.
- Use Vercel project env for production; pull locally with `vercel env pull` when linked.

---

## 9. Marketing / compliance pages

Compliance and store listing often require a **stable public URL** for:

- Privacy policy
- Terms of service
- Support / contact
- Account deletion instructions (if required by Apple/Google)
- Optional: landing / product overview

Conventions:

- Plain, readable pages — accessible HTML, clear headings, last-updated date.
- No auth walls on legal pages.
- Prefer markdown or MDX in `content/` rendered by a server component so legal can edit
  copy without touching route logic.
- Keep URLs stable (`/privacy`, `/terms`, `/support`) — store listings hard-code them.

---

## 10. Testing

- **Unit-test services** with a test DB or mocked Drizzle — port the intent of
  `backend/tests/`.
- **Route Handler tests** via `GET`/`POST` against the handler (or lightweight
  integration with a test server).
- Do not test Next.js internals or Firebase Admin itself — mock token verification.
- Run scoped tests for the feature you changed.

---

## 11. Tooling

- **Package manager: pnpm only** — never commit `package-lock.json` or `yarn.lock`.
- Lint: `pnpm lint` (ESLint / `eslint-config-next`) must be clean before a task is done.
- Format: stick to the repo’s Prettier/ESLint defaults once configured; don’t bikeshed.
- **No new dependencies** without flagging first (same rule as the rest of DriveVault).

---

## 12. Deploy

- Target: **Vercel** (App Router + Route Handlers + Neon).
- Keep FastAPI on Cloud Run until the migration plan’s cutover checklist passes.
- After cutover, point mobile `API_BASE_URL` / `EXPO_PUBLIC_API_BASE_URL` at the Vercel
  deployment (or a custom domain like `api.drivevault.app` that rewrites to `/api/v1`).

---

## 13. Parity with existing DriveVault rules

These still apply inside `web/`:

- UUID v4 primary keys, `timestamptz` UTC, money in cents, odometer in km.
- Ownership → 404.
- File bytes never transit our servers.
- Phase scope: no AI / offline sync features unless a task says so.
