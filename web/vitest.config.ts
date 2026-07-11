import path from 'node:path';
import { defineConfig } from 'vitest/config';

export default defineConfig({
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
      // Next.js swaps `server-only` for a no-op in its server bundle; Vitest
      // runs in plain Node, so it needs the same substitution.
      'server-only': path.resolve(__dirname, './src/server/test/server-only-stub.ts'),
    },
  },
  test: {
    environment: 'node',
    setupFiles: ['./vitest.setup.ts'],
  },
});
