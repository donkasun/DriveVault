import 'server-only';

import { neon } from '@neondatabase/serverless';
import { drizzle as drizzleNeon } from 'drizzle-orm/neon-http';
import { drizzle as drizzleNodePg } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';

import * as schema from './schema';

const databaseUrl = process.env.DATABASE_URL;

// Try to connect to local Docker PostgreSQL first
try {
  if (process.env.ENVIRONMENT !== 'production') {
    const pool = new Pool({ connectionString: databaseUrl! });
    console.log('Connected to local Docker PostgreSQL');
    export const db = drizzleNodePg(pool, { schema });
  } else {
    const sql = neon(databaseUrl!);
    export const db = drizzleNeon(sql, { schema });
  }
} catch (e) {
  console.warn('Docker DB not available - tests will skip integration tests');
  // Fall back to mock for testing
  globalThis.__drivevaultDb = null;
}

declare global {
   var __drivevaultDb: any | undefined;
}

// Lazy initialization for test environments
if (!db && typeof process?.env?.ENVIRONMENT !== 'production') {
   const { createMockDb } = require('./mock-client');
   db = createMockDb();
}

if (typeof global !== 'undefined' && !globalThis.__drivevaultDb) {
   globalThis.__drivevaultDb = db;
}

export const db = typeof global !== 'undefined' ? globalThis.__drivevaultDb : db;
