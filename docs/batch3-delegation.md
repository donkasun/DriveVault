# Batch 3 Delegation Brief

> Hand this file to the agent working in the `task/backend-deploy` worktree.
> Tasks are **sequential** — finish B6 completely (tests passing) before starting B7.

---

## Context

- **Repo:** DriveVault monorepo — FastAPI backend + Flutter mobile
- **Branch to work on:** `task/backend-deploy` (worktree at `worktrees/backend-deploy`)
- **Merge target:** `batch3` branch → squash-merge PR to `main` when both tasks done
- **Batch 2 is merged.** All B1–B5 backend resources (vehicles, fuel logs, maintenance, documents, uploads) are live on `main`. You can read and call those services freely.

**Before writing any code, read:**
1. `docs/01-tech-spec.md` — stack, conventions, architecture rules
2. `docs/02-database-schema.md` — exact table/column definitions
3. `docs/03-api-contract.md` — exact endpoint shapes (especially the Dashboard and Health sections)

---

## Task B6 — Dashboard aggregate endpoint

**Branch:** `task/backend-deploy`
**File locations:** follow the existing pattern — router in `backend/app/routers/`, service in `backend/app/services/`, schema in `backend/app/schemas/`.

### What to build

`GET /api/v1/dashboard` — aggregated summary across **all** of the caller's vehicles.

**Exact response shape (from `docs/03-api-contract.md`):**
```json
{
  "vehicleCount": 2,
  "monthlyFuelSpendCents": 23400,
  "totalOwnershipCostCents": 412000,
  "costBreakdown": {
    "fuelCents": 70200,
    "maintenanceCents": 320000,
    "purchaseCents": 0
  },
  "upcomingRenewals": [
    { "vehicleId": "uuid", "title": "Insurance", "expiryDate": "2026-12-31" }
  ]
}
```

**Field definitions:**
| Field | How to compute |
|---|---|
| `vehicleCount` | COUNT of vehicles owned by caller |
| `monthlyFuelSpendCents` | SUM of `fuel_logs.price_cents` for the current calendar month, across all caller's vehicles |
| `totalOwnershipCostCents` | `fuelCents` + `maintenanceCents` + `purchaseCents` |
| `costBreakdown.fuelCents` | SUM of all `fuel_logs.price_cents` for caller |
| `costBreakdown.maintenanceCents` | SUM of all `maintenance_records.cost_cents` for caller |
| `costBreakdown.purchaseCents` | SUM of all `vehicles.purchase_price_cents` for caller (treat NULL as 0) |
| `upcomingRenewals` | Documents where `expiry_date` is between today and today+90 days, across all caller's vehicles. Each entry: `vehicleId`, `title` (document title), `expiryDate`. Order by `expiry_date ASC`. |

**Architecture rules:**
- Router (`routers/dashboard.py`) calls service only — no SQL in the router.
- Service (`services/dashboard.py`) does all DB queries via SQLAlchemy.
- Schema (`schemas/dashboard.py`) defines `DashboardRead`, `CostBreakdown`, `UpcomingRenewal`.
- Register `dashboard.router` in `backend/app/main.py`.

**Done when:**
- [ ] `GET /api/v1/dashboard` returns the exact shape above.
- [ ] A test seeds 1 vehicle with fuel logs + maintenance records + a document expiring in 30 days, and asserts every field in the response matches expected values.
- [ ] A cross-user test confirms one user cannot see another's data in the aggregate.
- [ ] Tests pass: `pytest backend/tests/test_dashboard.py`

---

## Task B7 — Deploy backend to Render + Neon

> ⚠️ **User action required** for account setup steps. The agent handles code/config; the user creates accounts and sets env vars in the Render dashboard.

### Step 1 — Dockerfile (agent)

A `Dockerfile` already exists at `backend/Dockerfile`. Verify it:
- Uses `python:3.12-slim`
- Installs deps via `pyproject.toml`
- Runs `alembic upgrade head` then starts Gunicorn+Uvicorn workers
- Exposes port `8000`
- `CMD ["gunicorn", "app.main:app", "-w", "4", "-k", "uvicorn.workers.UvicornWorker", "--bind", "0.0.0.0:8000"]`

If the Dockerfile is missing any of the above, fix it.

### Step 2 — Neon database (user)

1. Create a free [Neon](https://neon.tech) project named `drivevault`.
2. Copy the connection string (format: `postgresql://user:pass@host/dbname?sslmode=require`).
3. Share the `DATABASE_URL` with the agent to wire into Render env vars.

### Step 3 — Run migrations against Neon (agent, once DATABASE_URL is available)

```bash
DATABASE_URL=<neon-url> alembic upgrade head
```

Confirm all tables created with no errors.

### Step 4 — Render deployment (user + agent)

1. User: create a free [Render](https://render.com) Web Service, connect the GitHub repo, set root directory to `backend/`, build command `pip install -e .`, start command from Dockerfile CMD above.
2. Agent: verify `render.yaml` (if it exists) or provide the correct Render config.
3. User: set these env vars in the Render dashboard:

| Var | Value |
|---|---|
| `DATABASE_URL` | Neon connection string |
| `FIREBASE_PROJECT_ID` | `drivevault-app` |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Contents of the Firebase Admin SDK JSON (stored as a secret) |
| `CLOUDINARY_CLOUD_NAME` | from `backend/.env` |
| `CLOUDINARY_API_KEY` | from `backend/.env` |
| `CLOUDINARY_API_SECRET` | from `backend/.env` |
| `CORS_ORIGINS` | `http://localhost:*` for now (extend when mobile is live) |

### Step 5 — Smoke test (user + agent)

```bash
# Health check
curl https://<render-url>/health
# Expected: {"status":"ok"}

# Authed /me (get a Firebase ID token from the Flutter app or Firebase console)
curl -H "Authorization: Bearer <token>" https://<render-url>/api/v1/me
```

**Done when:**
- [ ] `GET https://<render-url>/health` returns `{"status": "ok"}` publicly.
- [ ] `GET https://<render-url>/api/v1/me` returns the user object with a valid Firebase token.
- [ ] All Batch 2 endpoints reachable (spot-check `GET /api/v1/vehicles`).

---

## Merge instructions (after both tasks done)

1. Commit all changes on `task/backend-deploy`.
2. Open a PR: `task/backend-deploy` → `batch3`.
3. Squash-merge into `batch3`.
4. Open a PR: `batch3` → `main`.
5. Squash-merge into `main`.
6. Update `docs/05-task-dashboard.md`: mark B6 ✅, B7 ✅, Batch 3 complete, open Batch 4 gate.
7. Tag the commit: `git tag v0.1.0-backend` (first deployable backend).

---

## Key files to read before starting

```
backend/app/main.py                  ← register dashboard router here
backend/app/routers/vehicles.py      ← CRUD pattern to follow
backend/app/services/fuel_logs.py    ← fuel stats query pattern
backend/app/services/vehicles.py     ← ownership check pattern
backend/app/models/                  ← all SQLAlchemy models
backend/tests/test_fuel_resources.py ← test structure to follow
docs/02-database-schema.md           ← exact column names
docs/03-api-contract.md              ← exact response shapes
```
