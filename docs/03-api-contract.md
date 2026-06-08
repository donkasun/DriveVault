# DriveVault — API Contract (Phase 1)

> REST/JSON contract for the **Phase 1 MVP** backend (FastAPI). This is the agreement between
> the Flutter app and the backend — either side can be built independently against it.
> Later-phase endpoints are added in their own contract docs.

## Conventions
- Base URL (prod): `https://drivevault-api.onrender.com`  ·  (local): `http://localhost:8000`
- All endpoints are under `/api/v1`.
- **Auth:** every endpoint except none-listed-as-public requires header
  `Authorization: Bearer <Firebase ID token>`. The backend resolves the current user from it.
- All request/response bodies are JSON. Timestamps are ISO-8601 UTC. Money is integer cents.
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
  "createdAt": "2026-06-08T10:00:00Z"
}
```

### `PATCH /api/v1/me`
Update profile fields. Body (all optional): `{ "displayName": "...", "photoUrl": "..." }`
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
  "currency": "USD",
  "currentMileage": 48000,
  "vehicleType": "pickup",
  "photoUrl": null
}
```
Only `make` and `model` are required. **201** → `Vehicle`.

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
  "purchaseDate": "2020-03-15", "purchasePriceCents": 3500000, "currency": "USD",
  "currentMileage": 48000, "vehicleType": "pickup", "photoUrl": null,
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
  "currency": "USD",
  "odometer": 48200,
  "isFullTank": true,
  "notes": null
}
```
Required: `date`, `liters`, `priceCents`, `odometer`. **201** → `FuelLog`.

### `PATCH /api/v1/fuel-logs/{id}` · `DELETE /api/v1/fuel-logs/{id}`
Update / delete a single log. **200** / **204**.

### `GET /api/v1/vehicles/{vehicleId}/fuel-stats`
Computed economy metrics (derived from full-tank entries).
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
  "currency": "USD",
  "workshop": "City Auto",
  "notes": "5W-30 synthetic"
}
```
Required: `date`, `serviceType`. **201** → `MaintenanceRecord`.

### `GET /api/v1/maintenance/{id}` · `PATCH /api/v1/maintenance/{id}` · `DELETE /api/v1/maintenance/{id}`
**200** / **200** / **204**.

**MaintenanceRecord object:** create fields + `id`, `vehicleId`, `source` ("manual"),
`aiExtractionId` (null in Phase 1), `createdAt`, `updatedAt`.

---

## Documents
File bytes are uploaded by the client **directly to Firebase Storage**; the API only stores
metadata + the resulting URL.

### `GET /api/v1/vehicles/{vehicleId}/documents`
Optional `docType` query param. **200** → `[ Document, ... ]`.

### `POST /api/v1/vehicles/{vehicleId}/documents`
Called **after** the client has uploaded the file to Firebase Storage.
**Request**
```json
{
  "docType": "insurance",
  "title": "2026 Insurance Policy",
  "storageUrl": "gs://drivevault.appspot.com/users/uid/doc123.pdf",
  "mimeType": "application/pdf",
  "fileSizeBytes": 482000,
  "issueDate": "2026-01-01",
  "expiryDate": "2026-12-31"
}
```
Required: `docType`, `title`, `storageUrl`. **201** → `Document`.

### `GET /api/v1/documents/{id}` · `PATCH /api/v1/documents/{id}` · `DELETE /api/v1/documents/{id}`
**200** / **200** / **204**. (Delete removes the DB row; the client/cleanup job removes the
Storage object.)

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
