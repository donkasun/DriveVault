# DriveVault — API Contract (Phase 1)

> REST/JSON contract for the **Phase 1 MVP** backend (FastAPI). This is the agreement between
> the Flutter app and the backend — either side can be built independently against it.
> Later-phase endpoints are added in their own contract docs.

## Conventions
- Base URL (prod): `https://drivevault-backend-250609806849.us-central1.run.app`  ·  (local): `http://localhost:8000`
- All endpoints are under `/api/v1`.
- **Auth:** every endpoint except none-listed-as-public requires header
  `Authorization: Bearer <Firebase ID token>`. The backend resolves the current user from it.
- All request/response bodies are JSON. Timestamps are ISO-8601 UTC. Money is integer cents.
- **Currency:** locked to `LKR` for now (multi-currency deferred). `currency` on money
  records and on `PATCH /me` is **forced server-side to `LKR`** regardless of request value. **Distance unit** (`km`/`mi`) is a
  display-only preference — odometer/mileage values on the wire and in storage are always km.
- A user can only access **their own** vehicles and nested resources. Accessing another
  user's resource returns `404` (not `403`, to avoid leaking existence).

### Standard error shape
```json
{ "detail": "Human-readable message" }
```
| Code | Meaning |
|---|---|
| 400 | Validation error (bad/missing fields) |
| 401 | Missing/invalid/expired Firebase token |
| 404 | Resource not found or not owned by caller |
| 409 | Conflict (e.g. duplicate) |
| 422 | FastAPI body validation error |
| 500 | Server error |

---

## Auth / Current User

### `GET /api/v1/me`
Returns the current user, lazily creating the `users` row on first call.
**Response 200**
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
`distanceUnit` (`"km"`\|`"mi"`) is the user's account-wide display-only preference (storage stays in km). `currency` is **locked to `LKR`** and forced server-side (see the Currency note above).

### `PATCH /api/v1/me`
Update profile fields. Body (all optional):
`{ "displayName": "...", "photoUrl": "...", "currency": "LKR", "distanceUnit": "mi" }`
(A `currency` value is accepted but coerced to `LKR`.)
**Response 200** — updated user object.

---

## Vehicles

### `GET /api/v1/vehicles`
List the caller's vehicles. **200** → `[ Vehicle, ... ]`

### `POST /api/v1/vehicles`
Create a vehicle.
**Request**
```json
{
  "make": "Toyota",
  "model": "Hilux",
  "year": 2020,
  "registrationNumber": "ABC-1234",
  "vin": "JTEBU5JR...",
  "purchaseDate": "2020-03-15",
  "purchasePriceCents": 3500000,
  "currency": "LKR",
  "currentMileage": 48000,
  "vehicleType": "pickup",
  "fuelType": "petrol",
  "distanceUnit": null,
  "photoUrl": null,
  "photoPublicId": null
}
```
Only `make` and `model` are required. `fuelType` (`petrol`\|`diesel`\|`electric`\|`hybrid`\|`other`)
is optional and fixed per vehicle. `distanceUnit`
(`"km"`\|`"mi"`\|`null`) overrides the user default per vehicle; `null` = inherit. **201** → `Vehicle`.

### `GET /api/v1/vehicles/{vehicleId}`
**200** → `Vehicle`  ·  **404** if not owned.

### `PATCH /api/v1/vehicles/{vehicleId}`
Partial update (any subset of create fields). **200** → `Vehicle`.

### `DELETE /api/v1/vehicles/{vehicleId}`
Deletes the vehicle **and all nested data** (cascade). **204** no content.

**Vehicle object**
```json
{
  "id": "uuid",
  "make": "Toyota", "model": "Hilux", "year": 2020,
  "registrationNumber": "ABC-1234", "vin": "JTEBU5JR...",
  "purchaseDate": "2020-03-15", "purchasePriceCents": 3500000, "currency": "LKR",
  "currentMileage": 48000, "vehicleType": "pickup",
  "fuelType": "petrol", "distanceUnit": null,
  "photoUrl": null, "photoPublicId": null,
  "createdAt": "2026-06-08T10:00:00Z", "updatedAt": "2026-06-08T10:00:00Z"
}
```

---

## Fuel Logs
All nested under a vehicle.

### `GET /api/v1/vehicles/{vehicleId}/fuel-logs`
Query params (optional): `from=YYYY-MM-DD`, `to=YYYY-MM-DD`. **200** → `[ FuelLog, ... ]` (newest first).

### `POST /api/v1/vehicles/{vehicleId}/fuel-logs`
**Request**
```json
{
  "date": "2026-06-01",
  "liters": 45.5,
  "priceCents": 7800,
  "currency": "LKR",
  "odometer": 48200,
  "isFullTank": true,
  "notes": null
}
```
Required: `date`, `liters`, `priceCents`, `odometer`. `currency` is ignored if sent — the backend forces it to `LKR` (see Currency note). **201** → `FuelLog`.

**Odometer validation:** `odometer` must be strictly greater than the highest existing
odometer for that vehicle's fuel logs. If not, returns **400**
`{"detail": "Odometer must be greater than the latest reading (<n> km)"}`.
A successful create also updates the vehicle's `currentMileage` to the new odometer value.

### `PATCH /api/v1/fuel-logs/{id}` · `DELETE /api/v1/fuel-logs/{id}`
Update / delete a single log. **200** / **204**.
On delete, the vehicle's `currentMileage` is recomputed to the highest odometer among
remaining fuel logs for that vehicle (`null` if no logs remain).

### `GET /api/v1/vehicles/{vehicleId}/fuel-stats`
Computed economy metrics. `avgConsumptionLPer100Km` / `avgCostPerKmCents` use the **interval method**: a measurement interval runs between two full-tank fills (`isFullTank: true`). Partial fills accumulate into the interval that closes at the next full tank; partial fills before the first full tank or after the last full tank are excluded from the averages (they remain in `totalLiters` / `totalSpentCents`). Both averages are `null` until at least one full-tank interval exists.
**200**
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

**FuelLog object:** create fields + `id`, `vehicleId`, `createdAt`, `updatedAt`.

> Note (2026-06-14): `fuelVariant` was fully removed — the column was dropped from the DB (migration f2001) and is no longer referenced by the backend model/schemas or the mobile app.

---

## Maintenance Records

### `GET /api/v1/vehicles/{vehicleId}/maintenance`
Optional `category`, `from`, `to` query params. **200** → `[ MaintenanceRecord, ... ]` (newest first).

### `POST /api/v1/vehicles/{vehicleId}/maintenance`
**Request**
```json
{
  "date": "2026-05-20",
  "odometer": 47800,
  "serviceType": "Oil Change",
  "category": "maintenance",
  "costCents": 6500,
  "currency": "LKR",
  "workshop": "City Auto",
  "notes": "5W-30 synthetic"
}
```
Required: `date`, `serviceType`. `currency` is ignored if sent — the backend forces it to `LKR`; there is no currency dropdown in the app. **201** → `MaintenanceRecord`.

### `GET /api/v1/maintenance/{id}` · `PATCH /api/v1/maintenance/{id}` · `DELETE /api/v1/maintenance/{id}`
**200** / **200** / **204**.

**MaintenanceRecord object:** create fields + `id`, `vehicleId`, `source` ("manual"),
`aiExtractionId` (null in Phase 1), `createdAt`, `updatedAt`.

---

## Uploads (Cloudinary signing)

### `POST /api/v1/uploads/cloudinary-signature`
Returns a short-lived signature so the client can upload a file **directly to Cloudinary**
(file bytes never touch the backend). The Cloudinary API secret stays server-side.
**Request**
```json
{ "folder": "vehicles/{vehicleId}/documents" }
```
**Response 200**
```json
{
  "signature": "a1b2c3...",
  "timestamp": 1733692800,
  "apiKey": "1234567890",
  "cloudName": "drivevault",
  "folder": "vehicles/{vehicleId}/documents"
}
```
The client then POSTs the file + these params to
`https://api.cloudinary.com/v1_1/{cloudName}/auto/upload` and gets back `secure_url` and
`public_id`, which it passes to the documents/vehicles endpoints below.

---

## Documents
File bytes are uploaded by the client **directly to Cloudinary** (using the signature above);
the API only stores metadata + the resulting `secure_url` / `public_id`.

### `GET /api/v1/vehicles/{vehicleId}/documents`
Optional `docType` query param. **200** → `[ Document, ... ]`.

### `POST /api/v1/vehicles/{vehicleId}/documents`
Called **after** the client has uploaded the file to Cloudinary.
**Request**
```json
{
  "docType": "insurance",
  "title": "2026 Insurance Policy",
  "storageUrl": "https://res.cloudinary.com/drivevault/image/upload/v1/.../doc123.pdf",
  "storagePublicId": "vehicles/{vehicleId}/documents/doc123",
  "mimeType": "application/pdf",
  "fileSizeBytes": 482000,
  "issueDate": "2026-01-01",
  "expiryDate": "2026-12-31"
}
```
Required: `docType`, `title`, `storageUrl`. **201** → `Document`.

### `GET /api/v1/documents/{id}` · `PATCH /api/v1/documents/{id}` · `DELETE /api/v1/documents/{id}`
**200** / **200** / **204**. (Delete removes the DB row; the backend also deletes the
Cloudinary asset via its `public_id`.)

**Document object:** create fields + `id`, `vehicleId`, `createdAt`, `updatedAt`.

---

## Dashboard

### `GET /api/v1/dashboard`
Aggregated summary across all the caller's vehicles for the home screen.
**200**
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
> In Phase 1, `nextService` and reminder data are minimal (just document expiries). Full
> service-due logic arrives with Phase 2 (`maintenance_schedules` / `reminders`).

---

## Health Check (public, no auth)
### `GET /health` → `{ "status": "ok" }` — used by Render and uptime pings.
