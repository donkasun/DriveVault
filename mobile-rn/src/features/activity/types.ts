/**
 * Activity domain types — `GET /activity?limit=`.
 *
 * CRITICAL (task brief / CLAUDE.md): `docs/03-api-contract.md` does not
 * document this endpoint at all. It is a real, deployed endpoint distinct
 * from the dashboard's embedded `recentActivity` — richer (has `id`,
 * `currency`, and type-specific fields) and it EXCLUDES driving credentials
 * entirely (only fuel logs, maintenance records, and documents). This feature
 * must call `GET /activity` directly — never reuse `dashboard.recentActivity`.
 *
 * Field names verified against `backend/app/schemas/activity.py`
 * (`ActivityItemRead`) — the authoritative wire contract. Do not invent
 * fields; a previous slice invented `filledAt`/`totalCostCents` and broke.
 *
 * Money is integer cents; `odometer` is integer kilometres.
 */

export type ActivityKind = 'fuel' | 'maintenance' | 'document';

export type ActivityEntry = {
  type: ActivityKind;
  id: string;
  vehicleId: string;
  vehicleLabel: string;
  /** "YYYY-MM-DD" */
  date: string;
  /** Null for document entries. */
  amountCents: number | null;
  label: string;
  currency: string;
  createdAt: string;

  // Fuel-only
  liters: number | null;
  isFullTank: boolean | null;

  // Fuel + maintenance
  odometer: number | null;
  notes: string | null;

  // Maintenance-only
  source: string | null;
  category: string | null;
  workshop: string | null;

  // Document-only (null for fuel/maintenance)
  title: string | null;
  docType: string | null;
  storageUrl: string | null;
  storagePublicId: string | null;
  mimeType: string | null;
  fileSizeBytes: number | null;
  issueDate: string | null;
  expiryDate: string | null;
};
