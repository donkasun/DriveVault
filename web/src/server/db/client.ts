import 'server-only';

import { neon } from '@neondatabase/serverless';
import { drizzle as drizzleNeon } from 'drizzle-orm/neon-http';
import { drizzle as drizzleNodePg } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';

import * as schema from './schema';

const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) {
  throw new Error('DATABASE_URL is not set.');
}

function createDb() {
  if (process.env.ENVIRONMENT === 'production') {
    const sql = neon(databaseUrl as string);
    return drizzleNeon(sql, { schema });
  }

  const pool = new Pool({ connectionString: databaseUrl });
  return drizzleNodePg(pool, { schema });
}

declare global {
  var __drivevaultDb: ReturnType<typeof createDb> | undefined;
}

export const db = globalThis.__drivevaultDb ?? createDb();

if (process.env.NODE_ENV !== 'production') {
  globalThis.__drivevaultDb = db;
}
