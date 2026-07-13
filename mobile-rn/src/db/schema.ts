/**
 * Local SQLite read-cache schema (Drizzle ORM, sqlite-core).
 *
 * This is a CACHE, not a sync store: no `sync_status`, no pending rows, no
 * client-generated ids (best-practices.md §6 / CLAUDE.md task brief). Writes
 * always go through the API first; only the server-confirmed row is ever
 * upserted here.
 *
 * Table/column names mirror the backend Postgres schema (Doc 2) in
 * snake_case, per best-practices.md §6 — "a row can be reasoned about
 * without a translation layer in your head." Every row also carries a
 * `cached_at` (epoch ms) so a screen can show "cached Xm ago" if needed.
 *
 * Shape mirrors Flutter's Drift tables:
 *   mobile/lib/core/database/tables/{vehicles,fuel_logs,maintenance_records,dashboard_snapshots}_table.dart
 * minus the `sync_status` column, which has no equivalent here.
 */

import { integer, real, sqliteTable, text } from 'drizzle-orm/sqlite-core';

export const vehicles = sqliteTable('vehicles', {
  id: text('id').primaryKey(),
  make: text('make').notNull(),
  model: text('model').notNull(),
  year: integer('year'),
  registration_number: text('registration_number'),
  vin: text('vin'),
  purchase_date: text('purchase_date'),
  purchase_price_cents: integer('purchase_price_cents'),
  currency: text('currency').notNull().default('LKR'),
  current_mileage: integer('current_mileage'),
  vehicle_type: text('vehicle_type'),
  fuel_type: text('fuel_type'),
  distance_unit: text('distance_unit'),
  photo_url: text('photo_url'),
  photo_public_id: text('photo_public_id'),
  // JSON-encoded DocsStatus — server-derived, not a real backend column, but
  // mirrors Flutter's `docsStatusJson` cache column.
  docs_status_json: text('docs_status_json')
    .notNull()
    .default('{"state":"none","needsActionCount":0}'),
  created_at: text('created_at').notNull(),
  updated_at: text('updated_at').notNull(),
  cached_at: integer('cached_at').notNull(),
});

export const fuel_logs = sqliteTable('fuel_logs', {
  id: text('id').primaryKey(),
  vehicle_id: text('vehicle_id').notNull(),
  date: text('date').notNull(),
  liters: real('liters').notNull(),
  price_cents: integer('price_cents').notNull(),
  currency: text('currency').notNull().default('LKR'),
  odometer: integer('odometer').notNull(),
  is_full_tank: integer('is_full_tank', { mode: 'boolean' }).notNull().default(true),
  notes: text('notes'),
  created_at: text('created_at').notNull(),
  updated_at: text('updated_at').notNull(),
  cached_at: integer('cached_at').notNull(),
});

export const maintenance_records = sqliteTable('maintenance_records', {
  id: text('id').primaryKey(),
  vehicle_id: text('vehicle_id').notNull(),
  date: text('date').notNull(),
  service_type: text('service_type').notNull(),
  category: text('category'),
  cost_cents: integer('cost_cents'),
  currency: text('currency'),
  odometer: integer('odometer'),
  workshop: text('workshop'),
  notes: text('notes'),
  source: text('source').notNull().default('manual'),
  ai_extraction_id: text('ai_extraction_id'),
  updated_at: text('updated_at'),
  created_at: text('created_at').notNull(),
  cached_at: integer('cached_at').notNull(),
});

/** Single-row cache (id always 1) holding the whole dashboard payload as JSON. */
export const dashboard_snapshots = sqliteTable('dashboard_snapshots', {
  id: integer('id').primaryKey().default(1),
  payload: text('payload').notNull(),
  cached_at: integer('cached_at').notNull(),
});

/** The dashboard cache is always a single row at this id. */
export const DASHBOARD_SNAPSHOT_ID = 1;
