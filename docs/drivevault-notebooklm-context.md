# DriveVault — Full App Context for NotebookLM

> Generated 2026-06-13. Covers Phase 1 MVP. Source of truth: codebase + docs.

---

## 1. What DriveVault Is

DriveVault is a **personal vehicle ownership management app** for iOS (and eventually Android). It lets users:

- Track multiple vehicles (car, motorcycle, pickup, other).
- Log every fuel fill-up and see fuel economy trends.
- Record maintenance and repair history.
- Store important documents (insurance, registration, warranty, etc.) with expiry reminders.
- View a cross-vehicle expense and cost summary.

The app is a **Flutter mobile frontend** backed by a **FastAPI (Python) REST API** with a **PostgreSQL database** (hosted on Neon, serverless). Files and photos are stored on **Cloudinary**. Authentication is Firebase Auth (email/password + Google sign-in). Phase 1 is online-only; offline sync is deferred.

---

## 2. Tech Stack

| Layer | Technology |
|---|---|
| Mobile | Flutter 3.44 + Dart 3.12 |
| State management | Riverpod 3.x |
| Navigation | go_router (StatefulShellRoute) |
| Backend API | FastAPI 0.115 + Python 3.12 |
| ORM / migrations | SQLAlchemy 2 + Alembic |
| Database | PostgreSQL 16 (Neon serverless) |
| Auth | Firebase Auth (email/password, Google) |
| File storage | Cloudinary (free tier) |
| Push notifications | Firebase Cloud Messaging (Phase 2) |
| Backend hosting | Google Cloud Run (always-free, min-instances=0) |
| AI (deferred) | Gemini free tier via AIProvider interface (Phases 3–6 only) |

---

## 3. Architecture Overview

```
Flutter App (mobile)
    │
    ├── Firebase Auth → ID token
    │
    └── FastAPI backend (Cloud Run)
            │
            ├── Verifies Firebase ID token
            ├── Business logic (services layer)
            ├── SQLAlchemy → Neon PostgreSQL
            └── Signs Cloudinary upload requests
                    │
                    └── Client uploads files directly to Cloudinary
                            └── Backend stores only the secure_url
```

**Auth flow:** Firebase issues a JWT (ID token) → Flutter sends it as `Authorization: Bearer <token>` on every request → backend verifies with Firebase Admin SDK → resolves/creates the `users` row by `firebase_uid`.

**File upload flow:** Backend generates a Cloudinary signed upload params → Flutter uploads the file directly to Cloudinary (bytes never pass through FastAPI) → Flutter sends back the resulting `secure_url` + `public_id` → backend stores it on the DB record.

---

## 4. Navigation Architecture (Mobile)

The shell has **4 tabs** (floating dark pill tab bar at the bottom):

| Index | Label | Route | Purpose |
|---|---|---|---|
| 0 | Home | `/home` | Dashboard — default landing after login |
| 1 | Garage | `/garage` | Vehicle list + detail |
| 2 | Expenses | `/expenses` | Cross-vehicle expense history |
| 3 | Settings | `/profile` | Profile, preferences, sign out |

**Auth screens** (no tab bar): `/splash` → `/login`, `/signup`, `/forgot-password`, `/verify-email`.

Email/password users are routed to `/verify-email` after sign-up and gated there until Firebase email is verified. Google sign-in bypasses the gate.

**Forms** are full-screen modal dialogs (`fullscreenDialog: true`) with Cancel / Save in the top app bar.

---

## 5. Database Schema (Phase 1 Tables)

All primary keys are UUID v4. Every table has `created_at` and `updated_at` (timestamptz, UTC). Money is stored as **integer cents** (`*_cents`) + 3-letter ISO currency code. Distances/odometers are stored as **integer kilometres** (display conversion happens at the UI edge only).

### `users`
Mirrors a Firebase Auth account. Created lazily on the user's first authenticated API call.

| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| firebase_uid | text | UNIQUE NOT NULL |
| email | text | NOT NULL |
| display_name | text | nullable |
| photo_url | text | nullable |
| currency | char(3) | NOT NULL DEFAULT 'LKR' — account-wide money preference |
| distance_unit | text | NOT NULL DEFAULT 'km' — 'km' or 'mi', display-only |

### `vehicles`

| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| user_id | uuid | FK → users.id CASCADE |
| make | text | NOT NULL |
| model | text | NOT NULL |
| year | int | NULL, CHECK 1900–2100 |
| registration_number | text | nullable |
| vin | text | nullable |
| purchase_date | date | nullable |
| purchase_price_cents | bigint | nullable |
| currency | char(3) | DEFAULT 'LKR' |
| current_mileage | int | nullable, km — synced automatically on fuel log create/delete |
| photo_url | text | Cloudinary secure_url |
| photo_public_id | text | Cloudinary public_id (for deletion) |
| vehicle_type | text | 'car' / 'motorcycle' / 'pickup' / 'other' |
| fuel_type | text | 'petrol' / 'diesel' / 'electric' / 'hybrid' / 'other' |
| distance_unit | text | nullable — per-vehicle override; null = inherit user default |

### `fuel_logs`

| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| vehicle_id | uuid | FK → vehicles.id CASCADE |
| date | date | NOT NULL |
| liters | numeric(8,3) | NOT NULL, CHECK > 0 |
| price_cents | bigint | NOT NULL — **total amount paid** (not unit price) |
| currency | char(3) | DEFAULT 'LKR' |
| odometer | int | NOT NULL, km — must be strictly greater than all previous readings |
| is_full_tank | boolean | DEFAULT true |
| notes | text | nullable |

On every fuel log create, the backend updates `vehicles.current_mileage` to `MAX(odometer)` for that vehicle's logs. On delete, it recomputes the max (or sets null if no logs remain).

### `maintenance_records`

| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| vehicle_id | uuid | FK → vehicles.id CASCADE |
| date | date | NOT NULL |
| odometer | int | nullable, km |
| service_type | text | NOT NULL (free text, e.g. 'Oil Change') |
| category | text | 'maintenance' / 'repair' / 'upgrade' / 'inspection' |
| cost_cents | bigint | DEFAULT 0 |
| currency | char(3) | DEFAULT 'LKR' |
| workshop | text | nullable |
| notes | text | nullable |
| source | text | DEFAULT 'manual' (Phase 3 will add 'ai_extraction') |

### `documents`
Stores only metadata. File bytes live in Cloudinary.

| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| vehicle_id | uuid | FK → vehicles.id CASCADE |
| doc_type | text | 'registration' / 'insurance' / 'warranty' / 'service' / 'manual' / 'other' |
| title | text | NOT NULL |
| storage_url | text | NOT NULL — Cloudinary secure_url |
| storage_public_id | text | Cloudinary public_id (for deletion) |
| mime_type | text | nullable |
| file_size_bytes | bigint | nullable |
| issue_date | date | nullable |
| expiry_date | date | nullable — drives renewal reminders |

---

## 6. API Contract (Phase 1 Endpoints)

Base URL:
- Local: `http://localhost:8000`
- Production: `https://drivevault-backend-250609806849.us-central1.run.app`
- All endpoints under `/api/v1`
- Auth: `Authorization: Bearer <Firebase ID token>` on every protected endpoint
- Money: integer cents. Distances: km. JSON keys: lowerCamelCase.
- Ownership: users see only their own data; another user's resource returns 404 (not 403).

### Auth / User

**`GET /api/v1/me`** — Returns current user, creates the row on first call.
```json
{
  "id": "uuid",
  "firebaseUid": "string",
  "email": "user@example.com",
  "displayName": "Kasun",
  "photoUrl": null,
  "currency": "LKR",
  "distanceUnit": "km",
  "createdAt": "2026-06-08T10:00:00Z"
}
```

**`PATCH /api/v1/me`** — Update profile/preferences. Body (all optional):
`{ "displayName": "...", "photoUrl": "...", "currency": "LKR", "distanceUnit": "mi" }`
(A `currency` value is accepted but coerced to `LKR` server-side.)

### Vehicles

- `GET /api/v1/vehicles` — List all vehicles for current user.
- `POST /api/v1/vehicles` — Create a vehicle. Required: `make`, `model`. Optional: `year`, `registrationNumber`, `vin`, `purchaseDate`, `purchasePriceCents`, `currency`, `currentMileage`, `vehicleType`, `fuelType`, `distanceUnit`, `photoUrl`, `photoPublicId`.
- `GET /api/v1/vehicles/{vehicleId}` — Single vehicle.
- `PATCH /api/v1/vehicles/{vehicleId}` — Partial update.
- `DELETE /api/v1/vehicles/{vehicleId}` — Deletes vehicle and ALL nested data (cascade).

### Fuel Logs

- `GET /api/v1/vehicles/{vehicleId}/fuel-logs` — List logs, newest first. Optional: `from`, `to` (YYYY-MM-DD).
- `POST /api/v1/vehicles/{vehicleId}/fuel-logs` — Create. Required: `date`, `liters`, `priceCents` (total paid), `odometer`. Optional: `isFullTank`, `notes`. Any `currency` sent is ignored — the backend forces it to `LKR`. Odometer must exceed all existing readings.
- `PATCH /api/v1/fuel-logs/{id}` — Update.
- `DELETE /api/v1/fuel-logs/{id}` — Delete. Recomputes `current_mileage` on the vehicle.

### Fuel Stats

**`GET /api/v1/vehicles/{vehicleId}/fuel-stats`**
```json
{
  "avgConsumptionLPer100Km": 8.6,
  "avgCostPerKmCents": 14,
  "totalLiters": 410.0,
  "totalSpentCents": 70200,
  "monthlySpend": [
    { "month": "2026-05", "spentCents": 23400 }
  ]
}
```

### Maintenance Records

- `GET /api/v1/vehicles/{vehicleId}/maintenance` — List records, newest first. Optional: `category`, `from`, `to`.
- `POST /api/v1/vehicles/{vehicleId}/maintenance` — Create. Required: `date`, `serviceType`. Optional: `odometer`, `category`, `costCents`, `currency`, `workshop`, `notes`.
- `GET /api/v1/maintenance/{id}` · `PATCH /api/v1/maintenance/{id}` · `DELETE /api/v1/maintenance/{id}`

### Documents

- `GET /api/v1/vehicles/{vehicleId}/documents` — List. Optional: `docType`.
- `POST /api/v1/vehicles/{vehicleId}/documents` — Save metadata after client has uploaded file to Cloudinary. Required: `docType`, `title`, `storageUrl`.
- `GET /api/v1/documents/{id}` · `PATCH /api/v1/documents/{id}` · `DELETE /api/v1/documents/{id}` (delete also removes the Cloudinary asset).

### Cloudinary Signing

**`POST /api/v1/uploads/cloudinary-signature`** — Returns signed params for direct client-to-Cloudinary upload. Request: `{ "folder": "vehicles/{vehicleId}/documents" }`. Response: `{ "signature", "timestamp", "apiKey", "cloudName", "folder" }`.

### Dashboard

**`GET /api/v1/dashboard`**
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

---

## 7. Fuel Efficiency — How It's Calculated

The calculation lives entirely in **`backend/app/services/fuel_logs.py` → `compute_fuel_stats()`**.

### Algorithm

1. Fetch all fuel logs for the vehicle, sorted **date ascending**.
2. Compute aggregate totals across **all** logs (not just segments):
   - `totalLiters` = sum of every `liters` value.
   - `totalSpentCents` = sum of every `price_cents`.
3. Iterate over **consecutive pairs** (previous log, current log):
   - `distance = current.odometer − previous.odometer`
   - Skip the pair if `distance ≤ 0` (out-of-order or duplicate entry).
   - Accumulate: `segment_distance_km`, `segment_liters` (from current log), `segment_spent_cents` (from current log).
4. Compute economy metrics from the accumulated segment totals:
   - `avgConsumptionLPer100Km = (segment_liters / segment_distance_km) × 100` — rounded to 1 decimal place, or `null` if no valid segments.
   - `avgCostPerKmCents = segment_spent_cents / segment_distance_km` — rounded to nearest integer, or `null`.
5. Build `monthlySpend` by grouping all logs by `YYYY-MM`, sorted newest first.

### Key design choices

- **`is_full_tank` is NOT used** in the economy calculation. All consecutive pairs are used regardless of whether it was a partial fill. This is intentional (documented in the API contract as "partial fills are included") but means the average is a blended figure across full and partial fills.
- The classic "interval method" (only using full-tank → full-tank segments) is **not** implemented. If you want a more accurate economy figure, you would need to filter on `is_full_tank = true` at both endpoints of each segment.
- Economy is always computed server-side and returned as `L/100km`. The mobile app converts to display units.

### Mobile Display Conversion (`distance_unit.dart`)

The Flutter app converts the backend's `L/100km` figure to the user's preferred unit for display:

| User unit | Display format | Formula |
|---|---|---|
| `km` | `X.X km/L` | `100 / avgConsumptionLPer100Km` |
| `mi` | `X.X mpg` | `235.215 / avgConsumptionLPer100Km` (US gallon) |

Distance (odometer / mileage) conversion:
- Storage / wire: always integer **km**.
- `km → display`: `km × 0.621371` (for miles).
- `display → storage`: `mi × 1.609344`, rounded to nearest integer.

---

## 8. Dashboard Metrics — How They're Calculated

Computed in **`backend/app/services/dashboard.py` → `get_dashboard_data()`**.

| Metric | Calculation |
|---|---|
| `vehicleCount` | COUNT of `vehicles` rows for the user |
| `monthlyFuelSpendCents` | SUM of `fuel_logs.price_cents` where `date` is in the current calendar month |
| `fuelCents` (breakdown) | SUM of all `fuel_logs.price_cents` across all user vehicles, all time |
| `maintenanceCents` | SUM of all `maintenance_records.cost_cents` across all user vehicles |
| `purchaseCents` | SUM of `vehicles.purchase_price_cents` (NULL treated as 0) |
| `totalOwnershipCostCents` | `fuelCents + maintenanceCents + purchaseCents` |
| `upcomingRenewals` | Documents with `expiry_date` between today and 90 days from now |

---

## 9. Expenses Tab — How It Works

There is **no backend `/expenses` endpoint**. The Expenses tab is entirely **client-side**.

`allExpensesProvider` (Riverpod `FutureProvider`):
1. Reads all vehicles from `vehiclesProvider`.
2. For each vehicle, watches `fuelLogsProvider(vehicleId)` and `maintenanceRecordsProvider(vehicleId)`.
3. Maps fuel logs → `Expense(kind: fuel, costCents: priceCents, currency: log.currency)`.
4. Maps maintenance records → `Expense(kind: maintenance, costCents: costCents ?? 0, currency: record.currency ?? kFallbackCurrency)`.
5. Merges all into one list, sorted newest-first by date.

The Expenses screen has two filter chips: **All / Fuel / Maintenance** and an **All Vehicles / specific vehicle** picker. The total shown is the sum of `costCents` across the filtered list.

---

## 10. User Settings

Two **account-level preferences** stored on the `users` table and managed via `GET/PATCH /api/v1/me`.

### Currency (`currency`)
- Stored as a 3-letter ISO 4217 code; in Phase 1 it is **always `LKR`**.
- **Hard-locked:** every money-bearing write (`vehicles`, `fuel_logs`, `maintenance_records`) and `PATCH /me` is coerced to `LKR` server-side via `LOCKED_CURRENCY` (`backend/app/core/constants.py`). Any `currency` a client sends is overwritten.
- **No user-facing picker** — the `CurrencySelector` widget exists but is currently unused. Multi-currency is deferred; the `currency` columns and currency list are retained so it can be re-enabled without a migration.
- No FX/conversion exists.

### Distance Unit (`distanceUnit`)
- `'km'` or `'mi'`. Default: `'km'`.
- **Display-only** — odometer and mileage values are **always stored as integer kilometres** in the database and sent over the API in km.
- Conversion happens only at the UI edge (in `distance_unit.dart`).
- Per-vehicle override also exists: `vehicles.distance_unit` (`null` = inherit user default). Resolution: `vehicleUnit ?? userUnit`.
- Editable on the Profile screen via a segmented button (Kilometres / Miles).

---

## 11. Vehicle Cards — Stats Shown

The `VehicleCard` widget (shown in the Garage tab for each vehicle) computes and displays four stats in real time:

| Stat | Source | How Computed |
|---|---|---|
| **Mileage** | `vehicle.currentMileage` | `formatDistance(km, unit)` — converts to user's display unit |
| **Economy** | `fuelStatsProvider` → `avgConsumptionLPer100Km` | `formatEconomy()` → km/L or mpg |
| **Spent** | `fuelStatsProvider.totalSpentCents` + `maintenanceRecordsProvider` | fuel total + sum of `costCents` from all maintenance records |
| **Docs** | `documentsProvider` | Count of documents for the vehicle |

The card also has four quick-action buttons: Add Fuel, Service, Docs, Details.

---

## 12. Money Handling

- All monetary values are stored as **integer cents** (`bigint`) in PostgreSQL.
- Every money-bearing record (`fuel_logs`, `maintenance_records`, `vehicles`) carries its own `currency` field (3-letter ISO code).
- Currency is **forced to `LKR`** on every write via `LOCKED_CURRENCY`; in Phase 1 every record's `currency` is `LKR`.
- **There is no multi-currency conversion.** The app displays amounts in the currency stored on the record.
- The `formatCents()` utility (`formatting.dart`) converts cents → display string using `intl`'s `NumberFormat.simpleCurrency`, falling back to `"CODE X.XX"` for unknown codes.
- Example: `412000` cents with `currency='USD'` → `"$4,120.00"`. With `currency='LKR'` → `"Rs 4,120.00"`.

---

## 13. Code Architecture (Mobile)

Feature folders under `mobile/lib/features/`:
```
auth/        data/ presentation/
dashboard/   data/ domain/ presentation/
documents/   data/ domain/ presentation/
expenses/    data/ domain/ presentation/
fuel/        data/ domain/ presentation/
maintenance/ data/ domain/ presentation/
profile/     data/ domain/ presentation/
vehicles/    data/ domain/ presentation/
```

**Layer responsibilities:**
- `data/` — repositories that call the API (the only layer that touches the network). Riverpod providers live here.
- `domain/` — plain Dart model classes with `fromJson` / `toJson`.
- `presentation/` — screens, widgets. Only reads state from providers; never calls the API directly.

**Core:**
- `core/router/` — go_router config + auth redirect logic + tab-switch provider.
- `core/theme/` — `AppColors`, `AppTheme`.
- `core/network/` — `ApiClient` (wraps `http`, attaches Firebase ID token), `ApiException`.
- `core/config/` — `AppConfig` (API base URL from `--dart-define=API_BASE_URL`).
- `shared/widgets/` — `FormScreenAppBar`, `BottomSheetPickerField`, `CurrencySelector`, etc.
- `shared/utils/` — `formatCents()`, `formatDistance()`, `formatEconomy()`, `DistanceUnit` enum, distance conversion.

---

## 14. Code Architecture (Backend)

```
backend/app/
├── main.py           — FastAPI app factory, router registration
├── deps.py           — get_db, get_current_user dependencies
├── core/
│   ├── config.py     — settings (env vars)
│   ├── db.py         — SQLAlchemy engine + session
│   └── firebase.py   — Firebase Admin SDK init + token verification
├── models/           — SQLAlchemy ORM models (one file per table group)
├── schemas/          — Pydantic request/response schemas
├── routers/          — one file per resource; parse request, call service
└── services/         — business logic + DB access; independently testable
```

**Conventions:**
- Routers never contain SQL or business logic — they delegate to services.
- Services use SQLAlchemy and raise `HTTPException` for domain errors.
- Pydantic schemas use `serialization_alias` for camelCase JSON keys.
- `model_config = ConfigDict(populate_by_name=True)` allows both snake_case and camelCase input.

---

## 15. Known Discrepancies (Docs vs Code)

These are doc inaccuracies as of 2026-06-14 — the code is the source of truth.

| # | Location | Issue |
|---|---|---|
| 1 | `mobile/lib/features/fuel/domain/fuel_log.dart` | `FuelLog.fromJson` does not parse `updatedAt` (the API returns it; the Dart model silently drops it) |
| 2 | `backend/app/routers/dashboard.py` | `DashboardRead` schema is imported from `schemas/documents.py` — logically misplaced but functionally correct |

---

## 16. Deferred / Out of Scope (Phase 1)

- **Offline-first / Drift sync** — app is online-only in Phase 1.
- **Push notifications / reminders** — Phase 2 (`maintenance_schedules`, `reminders` tables exist in schema but are unused).
- **AI features** — Phase 3 (OCR on invoice images via ML Kit + Gemini), Phase 4 (NL chat / SQL tool-calling), Phase 6 (pgvector RAG).
- **Apple sign-in** — needs Apple Developer setup, deferred.
- **Vehicle health score** — Phase 5.
- **Multi-currency conversion** — not planned; each record stores its own currency.
- **User-selectable currency** — locked to `LKR` for now; the picker/coercions are a seam to re-enable later.
