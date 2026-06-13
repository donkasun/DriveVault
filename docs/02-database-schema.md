# DriveVault — Database Schema

> Full relational schema for **all 6 phases**, on **Neon PostgreSQL 16**. Designed up front
> so later phases need few/no migrations. Tables are grouped by the phase that first *uses*
> them, but you may create all Phase 1–2 tables in the initial migration.

## Conventions (apply to every table)
- Primary keys are `uuid` (default `gen_random_uuid()`), column name `id`.
- Every table has `created_at timestamptz NOT NULL DEFAULT now()` and
  `updated_at timestamptz NOT NULL DEFAULT now()` (app updates `updated_at` on write).
- Money is stored as **integer cents** (`*_cents`) plus a 3-letter `currency` (default `'LKR'`).
- Foreign keys use `ON DELETE CASCADE` from a parent the child cannot exist without
  (e.g. delete a vehicle → delete its fuel logs).
- Mileage/odometer stored as integer kilometres (`int`). A `distance_unit` (`'km'`/`'mi'`) is
  **display-only** — the app converts mi↔km at the edge; stored values are always kilometres.
- `created_at`/`updated_at` omitted from column lists below for brevity — **add them to every table**.

> **Currency (Phase 1):** locked to a single currency, `'LKR'`. The multi-value picker is
> deferred to a later phase; columns and defaults stay so re-enabling needs no migration.

---

## ER Overview

```
users (1) ──< vehicles (1) ──< fuel_logs
                       │   ├──< maintenance_records
                       │   ├──< documents
                       │   ├──< maintenance_schedules ──< reminders
                       │   ├──< vehicle_health_scores
                       │   └──< (documents) ──< document_embeddings
                       └──< ai_extractions
```

---

# PHASE 1 TABLES (MVP)

## `users`
Mirrors a Firebase Auth account. Created lazily on first authenticated request.

| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK |
| firebase_uid | text | **UNIQUE NOT NULL** (from Firebase token) |
| email | text | NOT NULL |
| display_name | text | NULL |
| photo_url | text | NULL |
| currency | char(3) | NOT NULL DEFAULT 'LKR' (user-level money preference) |
| distance_unit | text | NOT NULL DEFAULT 'km' ('km'\|'mi', display-only) |
| created_at | timestamptz | NOT NULL |
| updated_at | timestamptz | NOT NULL |

Indexes: unique on `firebase_uid`, index on `email`.

## `vehicles`
| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK |
| user_id | uuid | FK → users.id, ON DELETE CASCADE, NOT NULL |
| make | text | NOT NULL |
| model | text | NOT NULL |
| year | int | NULL (CHECK 1900–2100) |
| registration_number | text | NULL |
| vin | text | NULL |
| purchase_date | date | NULL |
| purchase_price_cents | bigint | NULL |
| currency | char(3) | NOT NULL DEFAULT 'LKR' |
| current_mileage | int | NULL (km) |
| photo_url | text | NULL (Cloudinary secure_url) |
| photo_public_id | text | NULL (Cloudinary public_id, for replace/delete) |
| vehicle_type | text | NULL ('car'\|'motorcycle'\|'pickup'\|'other') |
| fuel_type | text | NULL ('petrol'\|'diesel'\|'electric'\|'hybrid'\|'other', fixed per vehicle) |
| distance_unit | text | NULL ('km'\|'mi', display-only; NULL = inherit user default) |

Indexes: `user_id`.

## `fuel_logs`
| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK |
| vehicle_id | uuid | FK → vehicles.id, CASCADE, NOT NULL |
| date | date | NOT NULL |
| liters | numeric(8,3) | NOT NULL (CHECK > 0) |
| price_cents | bigint | NOT NULL (total paid) |
| currency | char(3) | NOT NULL DEFAULT 'LKR' |
| odometer | int | NOT NULL (km) |
| is_full_tank | boolean | NOT NULL DEFAULT true |
| notes | text | NULL |

Indexes: `vehicle_id`, `(vehicle_id, date)`.
> Fuel economy / cost-per-km are **computed in the API**, not stored (derive from consecutive
> full-tank entries).

## `maintenance_records`
| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK |
| vehicle_id | uuid | FK → vehicles.id, CASCADE, NOT NULL |
| date | date | NOT NULL |
| odometer | int | NULL (km) |
| service_type | text | NOT NULL (e.g. 'Oil Change') |
| category | text | NULL ('maintenance'\|'repair'\|'upgrade'\|'inspection') |
| cost_cents | bigint | NOT NULL DEFAULT 0 |
| currency | char(3) | NOT NULL DEFAULT 'LKR' |
| workshop | text | NULL |
| notes | text | NULL |
| source | text | NOT NULL DEFAULT 'manual' ('manual'\|'ai_extraction') |
| ai_extraction_id | uuid | FK → ai_extractions.id, NULL (Phase 3 link) |

Indexes: `vehicle_id`, `(vehicle_id, date)`, `category`.

## `documents`
Metadata only — bytes live in Cloudinary.

| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK |
| vehicle_id | uuid | FK → vehicles.id, CASCADE, NOT NULL |
| doc_type | text | NOT NULL ('registration'\|'insurance'\|'warranty'\|'service'\|'manual'\|'other') |
| title | text | NOT NULL |
| storage_url | text | NOT NULL (Cloudinary secure_url) |
| storage_public_id | text | NULL (Cloudinary public_id, for delete) |
| mime_type | text | NULL |
| file_size_bytes | bigint | NULL |
| issue_date | date | NULL |
| expiry_date | date | NULL (drives renewal reminders) |

Indexes: `vehicle_id`, `doc_type`, `expiry_date`.

---

# PHASE 2 TABLES (Smart Ownership)

## `maintenance_schedules`
Recurring service intervals (time- and/or distance-based).

| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK |
| vehicle_id | uuid | FK → vehicles.id, CASCADE, NOT NULL |
| service_type | text | NOT NULL (e.g. 'Oil Change') |
| interval_months | int | NULL (e.g. 6) |
| interval_km | int | NULL (e.g. 5000) |
| last_service_date | date | NULL |
| last_service_odometer | int | NULL |
| is_active | boolean | NOT NULL DEFAULT true |

At least one of `interval_months` / `interval_km` must be set (enforce in API).
Indexes: `vehicle_id`.

## `reminders`
Generated alerts (service due, document expiring).

| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK |
| vehicle_id | uuid | FK → vehicles.id, CASCADE, NOT NULL |
| schedule_id | uuid | FK → maintenance_schedules.id, NULL |
| document_id | uuid | FK → documents.id, NULL |
| reminder_type | text | NOT NULL ('service_due'\|'document_expiry') |
| title | text | NOT NULL |
| due_date | date | NULL |
| due_odometer | int | NULL |
| status | text | NOT NULL DEFAULT 'pending' ('pending'\|'sent'\|'dismissed'\|'done') |

Indexes: `vehicle_id`, `status`, `due_date`.

---

# PHASE 3 TABLE (AI Document Intelligence)

## `ai_extractions`
Raw + structured output of an uploaded invoice, before user confirms import.

| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK |
| vehicle_id | uuid | FK → vehicles.id, CASCADE, NOT NULL |
| document_id | uuid | FK → documents.id, NULL (source file) |
| status | text | NOT NULL DEFAULT 'pending' ('pending'\|'completed'\|'failed'\|'imported') |
| provider | text | NULL ('gemini'\|'openai'\|...) |
| raw_text | text | NULL (OCR output) |
| extracted_json | jsonb | NULL (structured fields) |
| confidence | numeric(4,3) | NULL (0–1) |

Indexes: `vehicle_id`, `status`.
> A confirmed extraction creates a `maintenance_records` row with
> `source='ai_extraction'` and `ai_extraction_id` set.

---

# PHASE 5 TABLE (Predictive)

## `vehicle_health_scores`
Snapshot of computed scores over time (history enables trend charts).

| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK |
| vehicle_id | uuid | FK → vehicles.id, CASCADE, NOT NULL |
| computed_at | timestamptz | NOT NULL DEFAULT now() |
| health_score | int | NULL (0–100) |
| resale_readiness_score | int | NULL (0–100) |
| factors_json | jsonb | NULL (breakdown of inputs) |

Indexes: `vehicle_id`, `(vehicle_id, computed_at)`.

---

# PHASE 6 TABLE (RAG)

Requires `CREATE EXTENSION IF NOT EXISTS vector;` on Neon.

## `document_embeddings`
Chunked text from documents/invoices/manuals for semantic search.

| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK |
| document_id | uuid | FK → documents.id, CASCADE, NOT NULL |
| vehicle_id | uuid | FK → vehicles.id, CASCADE, NOT NULL |
| chunk_index | int | NOT NULL |
| content | text | NOT NULL (the chunk text) |
| embedding | vector(1536) | NOT NULL (dim depends on model — adjust) |

Indexes: `document_id`; plus an HNSW/IVFFlat index on `embedding` for vector search.
> Hybrid retrieval (Phase 6) combines SQL queries with vector similarity over this table.

---

## Migration Strategy
- Use **Alembic**. Initial migration creates Phase 1 (+ optionally Phase 2) tables.
- Add later-phase tables in their own migrations when that phase starts.
- Enable `pgvector` only when Phase 6 begins (Neon: enable the extension, then migrate).
