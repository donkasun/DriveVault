import type { Persistence } from 'firebase/auth';

/**
 * `getReactNativePersistence` ships only in Firebase's `react-native` build
 * (`dist/index.rn.d.ts`). Metro resolves that export condition at runtime, but
 * TypeScript and Jest resolve the default build, where the symbol is absent.
 *
 * Declaring it here lets us import it normally. At runtime outside RN (Jest) the
 * binding is simply `undefined`, which `getFirebaseAuth()` guards against.
 */
declare module 'firebase/auth' {
  export function getReactNativePersistence(storage: unknown): Persistence;
}
