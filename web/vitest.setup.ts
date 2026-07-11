if (!process.env.DATABASE_URL) {
  try {
    process.loadEnvFile('.env.local');
  } catch {}
}
