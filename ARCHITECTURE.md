# Architecture & Design Decisions

This document narrates the *why* behind DriveVault's design — the decisions made, the trade-offs considered, and what was deliberately left out. Read the linked specs for full detail.

**Related docs:** [Tech spec](docs/01-tech-spec.md) · [Database schema](docs/02-database-schema.md) · [API contract](docs/03-api-contract.md) · [Product vision](docs/DriveVault_PRD.md)

---

## Problem Framing

Most people own one or more vehicles but have no single place to track what's been done to them. Service history lives in a glove-box folder, fuel receipts get thrown away, insurance renewals are remembered (or forgotten) from calendar reminders. Manufacturer apps only work for one brand. Generic expense trackers have no vehicle context.

DriveVault is a dedicated vehicle ownership ledger — structured around the vehicle, not the transaction. The goal is that when you sell a vehicle, you can hand over a complete, verified history without digging through old receipts.

---

## Design Process

The project followed a deliberate sequence: **PRD → database schema → API contract → implementation**.

Starting with the PRD forces clarity on the user problem before touching code. Locking the schema next means the data model reflects the domain, not the first implementation idea. Writing the API contract before any mobile or backend code lets both sides develop in parallel against a shared, immutable interface — no mid-build renegotiation. By the time code was written, every column name, JSON key, and HTTP status code was already decided.

This sequence is visible in the `docs/` folder: each document was a gate before the next layer could start.

---

## Key Decisions & Trade-offs

### 1. Money stored as integer cents — never floats

**Decision:** All monetary values are stored and transmitted as integers (e.g. `price_cents: 2500` = $25.00), with a separate `currency` ISO-4217 string.

**Why:** Floating-point arithmetic is lossy. `0.1 + 0.2 != 0.3` in IEEE 754. For financial data, silent rounding errors compound. Integer cents are exact.

**Ruled out:** `DECIMAL`/`NUMERIC` in Postgres (correct, but verbose to work with in SQLAlchemy); storing as float (never acceptable for money).

---

### 2. UUID v4 primary keys everywhere

**Decision:** All tables use `gen_random_uuid()` UUIDs as primary keys, not serial integers.

**Why:** Sequential integer IDs leak information — a competitor or bad actor can enumerate resources by incrementing an ID. UUIDs also make multi-region and offline-generated IDs trivial (no sequence coordination needed).

**Ruled out:** Serial integers (enumerable); ULID (correct but added a dependency with no Phase 1 benefit).

---

### 3. Cross-user access returns 404, not 403

**Decision:** If user A requests a resource owned by user B, the API returns 404 (not found), not 403 (forbidden).

**Why:** Returning 403 confirms that the resource exists, just that the requester can't access it. That's an information leak. 404 reveals nothing about whether the resource exists at all.

**Ruled out:** 403 (conventional but leaks resource existence); 401 (wrong — the user is authenticated, just not authorised).

---

### 4. Firebase Auth + FastAPI backend, not Firestore as database

**Decision:** Firebase is used for authentication and push notifications only. PostgreSQL (Neon) is the system of record for all structured data. The FastAPI backend verifies Firebase ID tokens on every request.

**Why:** Firestore's document model isn't a good fit for relational vehicle data (joins, aggregates, referential integrity). PostgreSQL gives us relational queries, transactions, Alembic migrations, and a path to pgvector for AI in Phase 6. Firebase Auth gives us email/password + Google SSO out of the box without building token management.

**Ruled out:** Firestore as DB (wrong data model, no SQL, no pgvector); rolling our own auth (unnecessary risk).

---

### 5. Cloudinary direct upload — bytes never touch FastAPI

**Decision:** The mobile client requests a signed upload URL from the backend, uploads the file directly to Cloudinary, then sends only the resulting `secure_url` back to the API.

**Why:** If file bytes routed through FastAPI on Cloud Run, every upload would consume memory and CPU on the API server, and Cloud Run's request timeout would limit file size. Direct upload offloads transfer entirely to Cloudinary's CDN infrastructure.

**Ruled out:** Uploading via FastAPI (memory/timeout constraints); Firebase Storage (requires paid Blaze plan).

---

### 6. Cloud Run with min-instances=0

**Decision:** The backend is deployed to Google Cloud Run with `--min-instances=0`, meaning instances scale to zero when idle.

**Why:** For a portfolio/MVP project, always-free tier matters. Zero idle instances = zero idle cost. The trade-off is a ~1–3 second cold start on the first request after idle — acceptable for this use case.

**Ruled out:** min-instances=1 (eliminates cold starts but exits the free tier); traditional VM (over-engineered for MVP scale).

---

### 7. Interval-method fuel economy calculation

**Decision:** Fuel economy (L/100km or km/L) is calculated using the interval method: economy for a fill-up = litres added ÷ km driven since the previous fill-up.

**Why:** The naive approach (fill-to-fill) assumes every fill-up starts from empty, which breaks with partial fills. The interval method uses actual odometer readings and is accurate regardless of fill level.

**Ruled out:** Fill-to-fill (inaccurate with partial fills); running average only (loses per-fill granularity).

---

### 8. Currency locked to LKR in Phase 1

**Decision:** Phase 1 uses a single locked currency (LKR — Sri Lankan Rupee). The schema has `currency` columns on all monetary tables; the lock is enforced at the service layer, not the schema layer.

**Why:** Multi-currency adds significant complexity (exchange rates, conversion UI, display logic) that isn't needed to validate the core product. The seam is already designed in — removing the lock in Phase 2 is a service-layer change, not a schema migration.

**Ruled out:** Hard-coding LKR in the schema (would require a migration to unlock); full multi-currency in Phase 1 (unnecessary scope for MVP validation).

---

## Data Model Highlights

The schema is designed around five core entities: `users`, `vehicles`, `fuel_logs`, `maintenance_records`, and `documents`. All are owned by a user; vehicles are the parent entity for the other four.

Key design choices:
- Odometer readings are stored on `fuel_logs` and `maintenance_records` directly (not a separate odometer table), which keeps queries simple while supporting sync.
- `documents` stores only metadata + `storage_url` (a Cloudinary URL) — the file never lives in Postgres.
- The schema already includes Phase 6 tables (`embeddings`, `ai_predictions`) — they're empty in Phase 1 but the foreign keys are in place.

See [full schema →](docs/02-database-schema.md)

---

## API Design Principles

- **REST with plural nouns:** `/api/v1/vehicles`, `/api/v1/fuel-logs`, etc.
- **All money on the wire as cents:** `amount_cents: integer` + `currency: string`
- **Ownership enforced in the service layer:** every query filters by the authenticated user's ID. Cross-user access → 404.
- **Consistent error shape:** `{ "detail": "<message>" }` with correct HTTP status codes.
- **No business logic in routers:** routers parse requests and call services. Services hold all logic and DB access.

See [full API contract →](docs/03-api-contract.md)

---

## Mobile Architecture

The Flutter app uses a strict feature-folder structure:

```
features/<name>/
  data/         # Repository class + API client calls (Dio)
  domain/       # Dart domain models (not Pydantic — just plain classes)
  presentation/ # Screen widgets + Riverpod providers
```

Rules enforced throughout:
- **Only repositories call the API.** Providers call repositories; widgets call providers.
- **Riverpod providers expose `AsyncValue<T>`.** Widgets handle loading/error/data states declaratively.
- **go_router handles auth gating.** A `redirect` listener on the auth state stream redirects unauthenticated users to `/login` without any widget-level guard logic.

---

## What's Deferred and Why

| Feature | Deferred to | Reason |
|---|---|---|
| Offline sync (Drift) | Phase 5 | Online-first is simpler; Drift adds significant complexity for little MVP benefit |
| AI maintenance predictions | Phase 3 | Requires meaningful data history first; `AIProvider` interface is already designed |
| OCR receipt scanning | Phase 4 | ML Kit is ready; deferred until maintenance log UX is proven |
| pgvector / embeddings | Phase 6 | Extension is enabled in Neon; tables are in the schema; deferred until AI features are built |
| Multi-currency | Phase 2 | Schema seam exists; service-layer lock removed when scope allows |
| Push notifications | Phase 2 | FCM is wired up; reminder scheduling logic is Phase 2 scope |
