// Phase 1 tables from docs/02-database-schema.md (repo root).
//
// `user_documents` is NOT listed in Doc 2 (it lives under the "driving credentials"
// feature added after Doc 2 was written) — it is ported here verbatim from the real
// SQLAlchemy model (`backend/app/models/user_documents.py`) and its Alembic revision
// `g1001` so Drizzle matches the actual local/prod database exactly.
import { sql } from 'drizzle-orm';
import {
  bigint,
  boolean,
  char,
  check,
  date,
  index,
  integer,
  numeric,
  pgTable,
  text,
  timestamp,
  uuid,
} from 'drizzle-orm/pg-core';

export const users = pgTable(
  'users',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    firebaseUid: text('firebase_uid').notNull().unique(),
    email: text('email').notNull(),
    displayName: text('display_name'),
    photoUrl: text('photo_url'),
    currency: char('currency', { length: 3 }).notNull().default('LKR'),
    distanceUnit: text('distance_unit').notNull().default('km'),
    renewalRemindersEnabled: boolean('renewal_reminders_enabled').notNull().default(true),
    fcmToken: text('fcm_token'),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [index('ix_users_email').on(table.email)],
);

export const vehicles = pgTable(
  'vehicles',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    make: text('make').notNull(),
    model: text('model').notNull(),
    year: integer('year'),
    registrationNumber: text('registration_number'),
    vin: text('vin'),
    purchaseDate: date('purchase_date'),
    purchasePriceCents: bigint('purchase_price_cents', { mode: 'number' }),
    currency: char('currency', { length: 3 }).notNull().default('LKR'),
    currentMileage: integer('current_mileage'),
    photoUrl: text('photo_url'),
    photoPublicId: text('photo_public_id'),
    vehicleType: text('vehicle_type'),
    fuelType: text('fuel_type'),
    distanceUnit: text('distance_unit'),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [
    index('ix_vehicles_user_id').on(table.userId),
    check('ck_vehicles_year_range', sql`${table.year} >= 1900 AND ${table.year} <= 2100`),
  ],
);

export const fuelLogs = pgTable(
  'fuel_logs',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    vehicleId: uuid('vehicle_id')
      .notNull()
      .references(() => vehicles.id, { onDelete: 'cascade' }),
    date: date('date').notNull(),
    liters: numeric('liters', { precision: 8, scale: 3 }).notNull(),
    priceCents: bigint('price_cents', { mode: 'number' }).notNull(),
    currency: char('currency', { length: 3 }).notNull().default('LKR'),
    odometer: integer('odometer').notNull(),
    isFullTank: boolean('is_full_tank').notNull().default(true),
    notes: text('notes'),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [
    index('ix_fuel_logs_vehicle_id').on(table.vehicleId),
    index('ix_fuel_logs_vehicle_date').on(table.vehicleId, table.date),
    check('ck_fuel_logs_liters_positive', sql`${table.liters} > 0`),
  ],
);

export const maintenanceRecords = pgTable(
  'maintenance_records',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    vehicleId: uuid('vehicle_id')
      .notNull()
      .references(() => vehicles.id, { onDelete: 'cascade' }),
    date: date('date').notNull(),
    odometer: integer('odometer'),
    serviceType: text('service_type').notNull(),
    category: text('category'),
    costCents: bigint('cost_cents', { mode: 'number' }).notNull().default(0),
    currency: char('currency', { length: 3 }).notNull().default('LKR'),
    workshop: text('workshop'),
    notes: text('notes'),
    source: text('source').notNull().default('manual'),
    // Nullable UUID WITHOUT a FK — the ai_extractions table doesn't exist until Phase 3.
    aiExtractionId: uuid('ai_extraction_id'),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [
    index('ix_maintenance_vehicle_id').on(table.vehicleId),
    index('ix_maintenance_vehicle_date').on(table.vehicleId, table.date),
    index('ix_maintenance_category').on(table.category),
  ],
);

export const documents = pgTable(
  'documents',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    vehicleId: uuid('vehicle_id')
      .notNull()
      .references(() => vehicles.id, { onDelete: 'cascade' }),
    docType: text('doc_type').notNull(),
    title: text('title').notNull(),
    storageUrl: text('storage_url').notNull(),
    storagePublicId: text('storage_public_id'),
    mimeType: text('mime_type'),
    fileSizeBytes: bigint('file_size_bytes', { mode: 'number' }),
    issueDate: date('issue_date'),
    expiryDate: date('expiry_date'),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [
    index('ix_documents_vehicle_id').on(table.vehicleId),
    index('ix_documents_doc_type').on(table.docType),
    index('ix_documents_expiry_date').on(table.expiryDate),
  ],
);

// Ported from backend/app/models/user_documents.py (Alembic g1001) — driving
// credentials (license / permit / international license) per user.
export const userDocuments = pgTable(
  'user_documents',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    docType: text('doc_type').notNull(),
    docNumber: text('doc_number'),
    issueDate: date('issue_date'),
    expiryDate: date('expiry_date'),
    notes: text('notes'),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [
    index('ix_user_documents_user_id').on(table.userId),
    index('ix_user_documents_expiry_date').on(table.expiryDate),
    check(
      'ck_user_documents_doc_type',
      sql`${table.docType} IN ('license','permit','international_license')`,
    ),
  ],
);
