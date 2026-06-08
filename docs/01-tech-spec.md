# DriveVault — Tech Spec & Architecture

> Companion to `DriveVault_PRD.md`. This document locks every technical decision so
> implementation can proceed without guesswork. When the PRD and this doc disagree on a
> technical detail, **this doc wins**.

---

## 1. Final Stack (decisions are locked)

| Layer | Choice | Version (pin) |
|---|---|---|
| Mobile | Flutter | 3.44.x (Dart 3.12.x) |
| State management | Riverpod | 3.x (`flutter_riverpod`) |
| Local DB (offline — **later phase**) | Drift (SQLite) | 2.x |
| Backend API | FastAPI | 0.115.x |
| Language (backend) | Python | 3.12 |
| ASGI server | Uvicorn (+ Gunicorn in prod) | latest |
| Database | PostgreSQL (Neon, serverless) | 16 |
| Vector search (Phase 6) | pgvector extension | 0.7+ |
| ORM / migrations | SQLAlchemy 2.x + Alembic | latest |
| Auth | Firebase Auth | latest SDK |
| File/blob storage | **Cloudinary** (free tier) | latest SDK |
| Push notifications | Firebase Cloud Messaging (FCM) | latest SDK |
| Backend hosting | Render (free web service) | — |
| DB hosting | Neon (free serverless Postgres) | — |

### What Firebase is used for (and only this)
- **Auth** — email/password, Google, Apple sign-in.
- **FCM** — push notifications (Phase 2 reminders onward).

Firebase is **NOT** the database, and **NOT** file storage. **Neon Postgres is the single
source of truth** for all structured/relational data (required for Phase 4 SQL tool-calling
and Phase 6 pgvector RAG). **Cloudinary** holds all files/photos — Firebase Storage is
deliberately avoided because it now requires the paid Blaze plan.

### Cloudinary (file/photo storage)
Holds Document Vault files, vehicle photos, and invoice images. The free tier needs **no
billing card**. Most DriveVault files are images, which Cloudinary is optimized for (and which
helps the Phase 3 OCR pipeline). Credentials: `cloud name`, `API key`, `API secret` (secret
stays server-side only).

---

## 2. System Architecture

```
        ┌─────────────────────────────┐
        │      Flutter App (mobile)    │
        │      Riverpod state          │
        └───────┬─────────────┬────────┘
                │             │
   (1) sign in  │             │ (3) API calls w/ Firebase ID token
                ▼             ▼
        ┌──────────────┐   ┌──────────────────────────┐
        │ Firebase Auth│   │   FastAPI backend (Render)│
        │ + FCM        │   │   - verifies ID token     │
        └──────┬───────┘   │   - business logic        │
               │           │   - signs Cloudinary uploads│
   (2) ID token│           │   - SQLAlchemy            │
               │           └────────────┬─────────────┘
               │                        │ (4) SQL
               │                        ▼
               │              ┌────────────────────────┐
               │              │  Neon PostgreSQL 16     │
               │              │  + pgvector (Phase 6)   │
               │              └────────────────────────┘
               │
               ▼            ┌────────────────────────┐
        (files/photos) ────▶│  Cloudinary (media)     │
        client uploads      │  returns secure_url     │
        direct w/ signature └────────────────────────┘
```

### Auth flow (every authenticated request)
1. Flutter signs the user in via **Firebase Auth** (email / Google / Apple).
2. Firebase returns a **Firebase ID token (JWT)**.
3. Flutter sends each API request with header `Authorization: Bearer <ID_TOKEN>`.
4. FastAPI verifies the token with the **Firebase Admin SDK**, extracts the Firebase `uid`.
5. FastAPI looks up (or lazily creates) the matching row in the `users` table keyed by `firebase_uid`.

**The backend never stores passwords.** Identity is owned entirely by Firebase; Postgres
stores a `users` row that mirrors the Firebase account.

### File upload flow (Cloudinary signed upload)
1. Flutter asks FastAPI for an upload signature: `POST /api/v1/uploads/cloudinary-signature`.
   The backend signs the upload params with the Cloudinary **API secret** (which never leaves
   the server) and returns `{ signature, timestamp, apiKey, cloudName, folder }`.
2. Flutter uploads the file **directly to Cloudinary** with those signed params and receives a
   `secure_url` (+ `public_id`).
3. Flutter sends the `secure_url` (and `public_id`) to FastAPI, which stores them on the
   `documents` / `vehicles` row. The **file bytes never pass through FastAPI or Postgres.**

---

## 3. Repository Layout

Monorepo with two top-level apps.

```
DriveVault/
├── docs/                      # PRD + these spec docs
├── mobile/                    # Flutter app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/              # config, theme, router, api client, firebase init
│   │   ├── features/          # one folder per feature (vertical slices)
│   │   │   ├── auth/
│   │   │   ├── vehicles/
│   │   │   ├── fuel/
│   │   │   ├── maintenance/
│   │   │   ├── documents/
│   │   │   └── dashboard/
│   │   └── shared/            # reusable widgets, models, utils
│   └── pubspec.yaml
└── backend/                   # FastAPI app
    ├── app/
    │   ├── main.py            # FastAPI app factory, router registration
    │   ├── core/              # config, security (token verify), db session
    │   ├── models/            # SQLAlchemy models (one file per table group)
    │   ├── schemas/           # Pydantic request/response models
    │   ├── routers/           # one file per resource (vehicles.py, fuel.py, ...)
    │   ├── services/          # business logic (kept out of routers)
    │   └── deps.py            # FastAPI dependencies (get_db, get_current_user)
    ├── alembic/               # migrations
    ├── tests/                 # pytest
    ├── pyproject.toml
    └── Dockerfile
```

**Within each Flutter feature folder:** `data/` (repos, api), `domain/` (models), and
`presentation/` (screens, widgets, providers).

---

## 4. Each feature/unit has one clear job

- **Routers** only parse requests and call services. No SQL or business logic in routers.
- **Services** hold business logic and talk to the DB via SQLAlchemy. Independently testable.
- **Schemas (Pydantic)** define the API contract — the only shapes that cross the wire.
- On mobile, **repositories** are the only thing that calls the API; **providers** expose
  state to widgets; **widgets** never call the API directly.

If a file grows past a few hundred lines, split it — it's doing too much.

---

## 5. Environment & Secrets

### Backend (`backend/.env`)
```
DATABASE_URL=postgresql+psycopg://<user>:<pass>@<neon-host>/<db>?sslmode=require
FIREBASE_PROJECT_ID=drivevault-app
FIREBASE_CREDENTIALS_JSON=<path-or-inline service account JSON>
CLOUDINARY_CLOUD_NAME=<your-cloud-name>
CLOUDINARY_API_KEY=<your-api-key>
CLOUDINARY_API_SECRET=<your-api-secret>   # server-side only — never ship to the client
ENVIRONMENT=local|production
CORS_ORIGINS=http://localhost:*,https://<your-app-domain>
```

### Mobile
- `firebase_options.dart` generated by FlutterFire CLI.
- API base URL via `--dart-define=API_BASE_URL=...` (local vs Render prod).

**Never commit** `.env`, the Firebase service-account JSON, or `google-services.json`.

---

## 6. Local Dev vs Production

| | Local | Production |
|---|---|---|
| Postgres | Docker `postgres:16` container | Neon free tier |
| Backend | `uvicorn app.main:app --reload` | Render web service (Gunicorn+Uvicorn) |
| Firebase | Real Firebase project (dev) | Same or separate prod project |
| API base URL | `http://localhost:8000` | `https://drivevault-api.onrender.com` |

`docker-compose.yml` runs Postgres locally so devs don't need Neon to start.

> **Render free-tier note:** the service spins down after ~15 min idle; the first request
> after sleep is slow (~30s cold start). Acceptable for demos — wake it before a showcase.

---

## 7. Out of Scope for the MVP (explicitly deferred)

To keep the first build small and reliable, these are **intentionally not** in Phase 1:

- ❌ **Offline-first / Drift sync** — MVP is **online-first** (talk to FastAPI directly).
  Drift local cache + sync is a dedicated later task.
- ❌ All **AI features** (OCR, chat, RAG) — Phases 3–6.
- ❌ Reminders / scheduling — Phase 2.

The database schema (Doc 2) *designs* tables for all phases up front to avoid migrations,
but only Phase 1 tables are *used* in the MVP.

---

## 8. AI Strategy (Phases 3 / 4 / 6 — deferred, documented now)

No AI ships in Phase 1. This section locks how AI features will work later so the
architecture doesn't need rework. **Hard constraint: keep the app small — no on-device LLM.**

### Decision: cloud LLM behind a swappable interface, on-device OCR only
- **Default LLM provider:** **Google Gemini free tier** (rate-limited, network-required, $0
  for demo usage).
- All AI calls go through a single backend **`AIProvider` interface** so Gemini can later be
  swapped for OpenAI / Claude / a self-hosted model without touching the app or routers.
- **No on-device Gemma / no bundled LLM.** On-device LLMs add 1 GB+ to the app download —
  explicitly rejected. The only on-device ML is ML Kit OCR (a few MB).

### Per-phase plan
| Phase | Capability | Approach | App-size impact |
|---|---|---|---|
| 3 | Invoice OCR (image → text) | **ML Kit Text Recognition**, on-device | ~few MB |
| 3 | Structure OCR text → maintenance record | Gemini free tier (`AIProvider`) | 0 |
| 4 | NL chat → tool/SQL calling | Gemini free tier (`AIProvider`) | 0 |
| 6 | Embeddings for semantic search | Gemini embeddings → `document_embeddings` (pgvector) | 0 |

### Notes
- **The LLM "thinking" never runs in the app or on Render's free CPU** — it's an API call to
  Gemini. Render free tier cannot host an LLM (no GPU, low RAM), so self-hosting is out unless
  hosting is upgraded.
- Phase 4 tool-calling is the highest-risk AI feature; a stronger provider can be swapped in
  via `AIProvider` if Gemini-free quality is insufficient.
- Trade-off accepted: **AI features require a network connection** (no offline AI). Fine for a
  portfolio/demo; revisit if offline AI becomes a requirement.

---

## 9. Conventions

- **API style:** REST, JSON, plural resource nouns (`/vehicles`, `/fuel-logs`).
- **IDs:** UUID v4 primary keys everywhere.
- **Timestamps:** all tables have `created_at` / `updated_at` (UTC, `timestamptz`).
- **Money:** store as integer **cents** (`amount_cents`) + a `currency` code — never floats.
- **Naming:** `snake_case` in Python/SQL, `camelCase` in Dart, `lowerCamelCase` JSON keys.
- **Tests:** backend uses `pytest`; every endpoint gets at least one happy-path + one auth
  failure test. Flutter uses `flutter_test` for widget/unit tests.
- **Errors:** FastAPI returns consistent JSON `{ "detail": "<message>" }` with proper HTTP codes.
