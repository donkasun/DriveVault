/** @type {import('jest').Config} */
module.exports = {
  preset: 'jest-expo',
  // The local watchman install hangs jest-haste-map at startup (jest produces no
  // output and never exits). Jest's own node crawler is fine for a repo this size.
  watchman: false,
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1',
    '^@/assets/(.*)$': '<rootDir>/assets/$1',
  },
  // NOTE: do not override transformIgnorePatterns — jest-expo's default already
  // handles pnpm's nested `.pnpm/` layout, which a hand-rolled pattern breaks.
  collectCoverageFrom: ['src/**/*.{ts,tsx}', '!src/**/*.test.{ts,tsx}'],
};
