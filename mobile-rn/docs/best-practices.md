# React Native (Expo) Best Practices — DriveVault

Working conventions for this app. Read before adding features. When Flutter conventions
from the main `mobile/` app map cleanly (feature folders, repository-only API access,
ownership rules), keep parity — the goal of `mobile-rn/` is eventually to replace `mobile/`.

---

## 1. Project & folder structure

Organize by **feature**, not by type. Mirrors the Flutter app's
`data/ → domain/ → presentation/` split:

```
src/
  app/                     # Expo Router routes only — thin, no business logic
    (tabs)/
    vehicles/[id].tsx
  features/
    vehicles/
      api.ts               # fetch calls for this feature only
      repository.ts        # the only thing that calls api.ts
      types.ts             # domain types/interfaces
      hooks.ts             # useVehicle(), useVehicles() — expose state, call repository
      components/          # feature-local components
    fuel-logs/
    auth/
  components/              # shared, dumb, reusable UI only (Button, Card, FormField)
  db/                      # local SQLite: schema, migrations, client
  lib/                     # cross-cutting utilities (formatting, date, currency)
  constants/               # design tokens, colors, spacing
```

Rules:
- **Routes (`app/`) are dumb.** They import a screen component from `features/*` and
  render it. No fetches, no SQL, no business logic in route files.
- **Only `repository.ts` calls `api.ts`.** Hooks/components never call `fetch`/`axios`
  directly — same rule as the Flutter app's "only repositories call the API."
- A file over ~250–300 lines is doing too much — split it.
- Co-locate tests next to the file: `repository.test.ts` beside `repository.ts`.

---

## 2. TypeScript

- `strict: true` always (Expo's default template already sets this — don't loosen it).
- No `any`. Use `unknown` + narrowing, or generate types from the API contract
  (Doc 3 in the Flutter app) — don't hand-roll response shapes that can drift.
- Prefer `type` for data shapes, `interface` only when you need declaration merging.
- Discriminated unions for state: `{ status: 'idle' | 'loading' | 'error' | 'success', ... }`
  instead of multiple optional booleans.

---

## 3. Components

- Function components only. No class components.
- Keep components small and single-purpose; extract a subcomponent once a component
  mixes more than one concern (e.g. "renders a list item" + "handles swipe-to-delete").
- Presentational vs. container split: components in `components/` and `features/*/components/`
  take data + callbacks as props: they don't fetch, don't read global state, don't own
  business logic. Screens (in `app/`) wire hooks to presentational components.
- Avoid inline anonymous functions/objects as props on components wrapped in `React.memo`
  or rendered in a `FlatList` — they defeat memoization. Define with `useCallback`/`useMemo`
  or hoist outside the render function when they don't depend on props/state.
- Don't overuse `useEffect`. If you're deriving state from props/state, compute it during
  render (or `useMemo`) instead of syncing via an effect.

---

## 4. State management

- **Server state** (anything from the DriveVault API): use a query/cache library
  (e.g. TanStack Query) rather than hand-rolled `useEffect` + `useState` fetching.
  Gives you caching, retries, and invalidation for free and matches the Flutter app's
  "state invalidation pattern" for free.
- **Local/UI state**: `useState`/`useReducer` in the owning component; lift only as high
  as the nearest common consumer.
- **Global app state** (auth session, active vehicle, theme): a single lightweight store
  (Zustand or Context+useReducer for something this small) — avoid prop-drilling but also
  avoid dumping everything into one global store out of convenience.
- Never store server data that already lives in the query cache in global state too —
  one source of truth per piece of data.

---

## 5. Performance

- **Lists**: always use `FlatList`/`FlashList`, never `.map()` inside a `ScrollView` for
  anything unbounded (vehicle lists, fuel logs, activity feed). Provide `keyExtractor`,
  and `getItemLayout` when row height is fixed.
- **Images**: use `expo-image` (already a dependency) instead of the core `Image` —
  it caches and decodes off the JS thread.
- **Memoization**: wrap list-row components in `React.memo`; use `useCallback` for
  handlers passed to them and `useMemo` for derived/expensive computations — but don't
  memoize everything reflexively, only where profiling or an obvious render cost justifies it.
- **Avoid unnecessary re-renders**: don't put fast-changing values (e.g. scroll position,
  animated values) in React state — use `useRef` or Reanimated shared values instead.
- **Animations**: use `react-native-reanimated` (already a dependency) for anything
  gesture-driven or continuous, so it runs on the UI thread instead of the JS thread.
- **Startup time**: keep `app/_layout.tsx` minimal; defer non-critical initialization
  (analytics, background sync) until after first paint.
- Profile with Flipper / React DevTools Profiler before optimizing — don't guess.

---

## 6. Local database (SQLite)

DriveVault's local DB is for **caching/offline reads of server data**, not a sync
engine — the source of truth is always the backend (see the Flutter app's Phase 1 scope:
no offline sync yet). Keep the same scope here unless a task says otherwise.

- Use **`expo-sqlite`** (Expo-managed, no native config needed) as the driver.
- Put a query builder/ORM on top rather than hand-written SQL strings scattered through
  the app — **Drizzle ORM** (`drizzle-orm` + `expo-sqlite` driver) is the standard choice
  here: typed schema, typed queries, and a migrations story.
- Structure:
  ```
  src/db/
    schema.ts        # Drizzle table definitions — mirror backend Doc 2 column names/types
    client.ts         # opens the db connection, runs migrations on startup
    migrations/       # generated by drizzle-kit
  features/vehicles/
    local.ts          # local read/write helpers for this feature's tables, using db/client
  ```
- **Naming parity with backend**: local table/column names should match the Postgres
  schema (`snake_case`) so a row can be reasoned about without a translation layer in
  your head. Convert to `camelCase` only at the TS type boundary.
- **Never treat local SQLite writes as the write path.** Writes go: UI → repository →
  API call → on success, upsert into local cache. Don't write-then-sync.
- All local DB access goes through `db/client.ts` + feature-level `local.ts` helpers —
  no raw `db.execute(...)` calls scattered in components or hooks.
- Run migrations once at app startup (in the root layout, before rendering routes),
  not lazily per-screen.
- Wrap multi-statement writes in a transaction; SQLite on device is a single writer —
  don't fire concurrent uncoordinated writes to the same table.

---

## 7. Networking & auth

- One typed API client (thin wrapper over `fetch`) in `lib/api-client.ts`, feature `api.ts`
  files call it — don't instantiate `fetch` ad hoc per feature.
- Base URL from `process.env.EXPO_PUBLIC_API_BASE_URL` (Expo's public env var convention) —
  never hard-code, mirrors the Flutter app's `--dart-define=API_BASE_URL`.
- Attach the Firebase ID token as `Authorization: Bearer <token>` in the API client's
  request interceptor, not per-call.
- Handle 404-as-not-yours (DriveVault's ownership convention) and token-expired-refresh
  centrally in the API client, not per repository.

---

## 8. Testing

- Unit test repositories and `lib/` utilities with Jest.
- Component tests with React Native Testing Library — test behavior (what the user sees/taps),
  not implementation details (internal state, function calls).
- Don't test Expo/RN internals or third-party libraries — trust their own test suites.

---

## 9. Tooling

- **Package manager: pnpm only** — see repo-wide preference. Never commit `package-lock.json`
  or `yarn.lock`.
- Lint/format: `expo lint` (ESLint) must be clean before considering a task done.
- No new dependencies without flagging first — same rule as the Flutter app.
