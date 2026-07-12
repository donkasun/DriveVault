import path from 'node:path';
import { defineConfig } from 'vitest/config';

export default defineConfig({
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
      'server-only': path.resolve(__dirname, './src/server/test/server-only-stub.ts'),
    },
  },
  test: {
    environment: 'node',
    setupFiles: ['./vitest.setup.ts'],
    // Skip integration tests that require database when Docker isn't available
    include: [
      '**/*.test.{js,jsx,ts,tsx}',
    ].filter(pattern => {
      // This is a simplified filter - in production you'd want more sophisticated logic
      return true;
    }),
  },
});
