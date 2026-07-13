/**
 * Local SQLite read-cache connection.
 *
 * Opens the on-device DB via expo-sqlite, wraps it with Drizzle, and exposes
 * `runMigrations()` to be called ONCE at startup (in `app/_layout.tsx`),
 * before routes render — best-practices.md §6.
 *
 * NOTE on migrations: drizzle-kit's expo-sqlite migration workflow needs a
 * Babel plugin (`drizzle-orm/expo-sqlite/migrator` + inlined SQL journal) to
 * bundle `.sql` files into the Metro build. Wiring that in is a Metro/Babel
 * config change outside this task's scope, so per the task brief we use a
 * hand-written idempotent `CREATE TABLE IF NOT EXISTS` bootstrap instead.
 * Schema changes going forward should add a new `CREATE TABLE IF NOT EXISTS`
 * / `ALTER TABLE` statement here, guarded so re-running is always safe.
 */

import { drizzle } from 'drizzle-orm/expo-sqlite';
import * as SQLite from 'expo-sqlite';

import * as schema from './schema';

const DB_NAME = 'drivevault-cache.db';

const sqliteConnection = SQLite.openDatabaseSync(DB_NAME);

export const db = drizzle(sqliteConnection, { schema });

let migrationsPromise: Promise<void> | null = null;

/**
 * Creates the cache tables if they don't exist yet. Safe to call multiple
 * times (e.g. in tests) — only runs the actual work once per process.
 */
export function runMigrations(): Promise<void> {
  if (!migrationsPromise) {
    migrationsPromise = sqliteConnection.execAsync(`
      CREATE TABLE IF NOT EXISTS vehicles (
        id TEXT PRIMARY KEY NOT NULL,
        make TEXT NOT NULL,
        model TEXT NOT NULL,
        year INTEGER,
        registration_number TEXT,
        vin TEXT,
        purchase_date TEXT,
        purchase_price_cents INTEGER,
        currency TEXT NOT NULL DEFAULT 'LKR',
        current_mileage INTEGER,
        vehicle_type TEXT,
        fuel_type TEXT,
        distance_unit TEXT,
        photo_url TEXT,
        photo_public_id TEXT,
        docs_status_json TEXT NOT NULL DEFAULT '{"state":"none","needsActionCount":0}',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        cached_at INTEGER NOT NULL
      );

      CREATE TABLE IF NOT EXISTS fuel_logs (
        id TEXT PRIMARY KEY NOT NULL,
        vehicle_id TEXT NOT NULL,
        date TEXT NOT NULL,
        liters REAL NOT NULL,
        price_cents INTEGER NOT NULL,
        currency TEXT NOT NULL DEFAULT 'LKR',
        odometer INTEGER NOT NULL,
        is_full_tank INTEGER NOT NULL DEFAULT 1,
        notes TEXT,
        created_at TEXT NOT NULL DEFAULT '',
        updated_at TEXT NOT NULL DEFAULT '',
        cached_at INTEGER NOT NULL
      );
      CREATE INDEX IF NOT EXISTS idx_fuel_logs_vehicle_id ON fuel_logs (vehicle_id);

      CREATE TABLE IF NOT EXISTS maintenance_records (
        id TEXT PRIMARY KEY NOT NULL,
        vehicle_id TEXT NOT NULL,
        date TEXT NOT NULL,
        service_type TEXT NOT NULL,
        category TEXT,
        cost_cents INTEGER,
        currency TEXT,
        odometer INTEGER,
        workshop TEXT,
        notes TEXT,
        source TEXT NOT NULL DEFAULT 'manual',
        ai_extraction_id TEXT,
        updated_at TEXT,
        created_at TEXT NOT NULL,
        cached_at INTEGER NOT NULL
      );
      CREATE INDEX IF NOT EXISTS idx_maintenance_records_vehicle_id ON maintenance_records (vehicle_id);

      CREATE TABLE IF NOT EXISTS dashboard_snapshots (
        id INTEGER PRIMARY KEY NOT NULL,
        payload TEXT NOT NULL,
        cached_at INTEGER NOT NULL
      );
    `);
  }
  return migrationsPromise;
}

/**
 * Wipes every cached row. MUST be called on sign-out (CLAUDE.md — privacy
 * requirement): otherwise the next user to sign in on this device would see
 * the previous user's vehicles/fuel logs/etc. read straight off disk before
 * the network ever responds.
 */
export async function clearAllCaches(): Promise<void> {
  await sqliteConnection.execAsync(`
    DELETE FROM vehicles;
    DELETE FROM fuel_logs;
    DELETE FROM maintenance_records;
    DELETE FROM dashboard_snapshots;
  `);
}
