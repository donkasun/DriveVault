// Vitest runs in plain Node, not Next.js's bundler, so the real `server-only`
// package (which unconditionally throws) is aliased to this no-op stub —
// see vitest.config.ts. Next's build still uses the real package.
export {};
