import { defineConfig } from 'drizzle-kit';

if (!process.env.DATABASE_URL) {
  try {
    process.loadEnvFile('.env.local');
  } catch {}
}
if (!process.env.DATABASE_URL) {
  throw new Error('DATABASE_URL is not set. Copy web/.env.example to web/.env.local first.');
}

export default defineConfig({
  schema: './src/server/db/schema.ts',
  out: './src/server/db/migrations',
  dialect: 'postgresql',
  dbCredentials: { url: process.env.DATABASE_URL },
});
