# Flutter → React Native (`mobile-rn`) Migration Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Scope note:** This is the **master migration plan**. Phases 0–1 below are fully bite-sized and executable. Phases 2–9 are locked architecture + file maps + acceptance criteria; before coding each of those phases, expand it into its own detailed execution plan under `docs/superpowers/plans/` (same format as Phase 0–1). Do not invent API fields — `docs/03-api-contract.md` and `docs/02-database-schema.md` win.

**Goal:** Replace the Flutter app in `mobile/` with feature-parity React Native (Expo) in `mobile-rn/`, following `mobile-rn/docs/best-practices.md`, while keeping the existing FastAPI backend unchanged.

**Architecture:** Feature folders mirror Flutter’s `data/ → domain/ → presentation/` as `api.ts → repository.ts → types.ts → hooks.ts → components/`. Expo Router routes stay dumb. TanStack Query owns server state; Zustand owns auth session + thin UI globals; `expo-sqlite` + Drizzle own local cache (after online parity). One typed `lib/api-client.ts` attaches Firebase Bearer tokens.

**Tech Stack:** Expo 57 · React Native 0.86 · Expo Router · TypeScript strict · pnpm · Firebase JS Auth · TanStack Query · Zustand · expo-image · expo-image-picker · react-native-reanimated · (later) expo-sqlite + drizzle-orm · Jest + RNTL

**Source of truth while migrating:**
- API shapes: `docs/03-api-contract.md`
- Schema: `docs/02-database-schema.md`
- UI conventions: `docs/ui-conventions.md` + `docs/design-references/`
- RN conventions: `mobile-rn/docs/best-practices.md`
- Flutter reference implementation: `mobile/lib/` (behavior to match, not to copy line-by-line)

---

## 0. Migration principles (non-negotiable)

1. **Backend stays frozen.** No new endpoints, fields, or renames for the RN port. If something is missing, ask.
2. **One feature at a time.** Finish a phase’s “Done when” before starting the next.
3. **Parity over redesign.** Match Flutter UX (floating tab bar, form headers, pickers, soft email-verify banner). Do not invent new screens.
4. **Repository-only networking.** Hooks/components never call `fetch` — only `repository.ts` calls `api.ts`, which calls `lib/api-client.ts`.
5. **Online-first, then cache.** Ship each feature talking to the live API first. Add SQLite cache + optimistic sync in Phase 8 (after feature parity).
6. **pnpm only.** Flag any new dependency before adding it (list in §1 is pre-approved for this migration).
7. **iOS Simulator → local Docker backend** (`EXPO_PUBLIC_API_BASE_URL=http://localhost:8000/api/v1`), same as Flutter.
8. **Do not delete `mobile/` until Phase 9** explicitly says so.

---

## 1. Locked dependency decisions

| Concern | Choice | Notes |
|---|---|---|
| Routing | Expo Router (file-based) | Already in project |
| Server state | `@tanstack/react-query` | Replaces Riverpod notifiers for API data |
| Auth / session | `firebase` (JS SDK) + Zustand | Expo-friendly; Bearer token from `user.getIdToken()` |
| Google sign-in | `expo-auth-session` (Google provider, web client ID) → `GoogleAuthProvider.credential(idToken)` into Firebase JS SDK | **Resolved:** Flutter uses the *native* `google_sign_in` package (`GoogleService-Info.plist` / `google-services.json` present), which has no Expo Go equivalent. Use Expo Auth Session's browser-based OAuth flow instead — it stays inside Expo Go and reaches feature parity (Google login works) without a dev client. Only fall back to `@react-native-google-signin/google-signin` + dev client if Auth Session proves unreliable in testing. |
| HTTP | Native `fetch` wrapper in `lib/api-client.ts` | No axios unless needed |
| Images | `expo-image` (already present) | |
| Image pick | `expo-image-picker` | Vehicle photo + docs |
| Document pick | `expo-document-picker` | Document upload |
| Lists | `FlatList` first; `@shopify/flash-list` only if profiling needs it | |
| Local DB | `expo-sqlite` + `drizzle-orm` | Phase 8 only |
| Secure prefs | `expo-secure-store` or `AsyncStorage` | Profile cache blob (Flutter used SharedPreferences) |
| SVG | `react-native-svg` | Fuel pump icon etc. |
| Testing | `jest` + `@testing-library/react-native` | Co-locate `*.test.ts(x)` |

**Pre-approved new packages for Phase 0** (flag if versions conflict with Expo 57):
`firebase`, `@tanstack/react-query`, `zustand`, `expo-image-picker`, `expo-document-picker`, `expo-secure-store`, `react-native-svg`, `jest`, `@testing-library/react-native`, `@types/jest`

**Deferred (Phase 8):** `expo-sqlite`, `drizzle-orm`, `drizzle-kit`

---

## 2. Flutter → RN mapping

| Flutter | React Native |
|---|---|
| `lib/features/<f>/data/*_repository.dart` | `src/features/<f>/repository.ts` |
| `lib/features/<f>/data/*_api` (implicit in repo) | `src/features/<f>/api.ts` |
| `lib/features/<f>/domain/*.dart` | `src/features/<f>/types.ts` |
| Riverpod `*Notifier` / `*Provider` | TanStack Query hooks in `hooks.ts` (+ Zustand for auth) |
| `lib/features/<f>/presentation/*_screen.dart` | `src/features/<f>/components/*-screen.tsx` |
| `go_router` routes | `src/app/**` Expo Router files (thin) |
| `MainShell` floating tabs | Custom tab layout in `src/app/(tabs)/_layout.tsx` |
| `FormScreenAppBar` | `src/components/form-screen-app-bar.tsx` |
| `BottomSheetPickerField` | `src/components/bottom-sheet-picker-field.tsx` |
| `ApiClient` (Dio) | `src/lib/api-client.ts` |
| Drift cache | `src/db/` + `features/*/local.ts` (Phase 8) |
| `--dart-define=API_BASE_URL` | `EXPO_PUBLIC_API_BASE_URL` |
| `AppColors` | `src/constants/theme.ts` (DriveVault tokens) |

### Route map (must match)

| Flutter path | Expo Router file |
|---|---|
| `/splash` | `src/app/index.tsx` (auth bootstrap) **or** `src/app/splash.tsx` |
| `/login` | `src/app/(auth)/login.tsx` |
| `/signup` | `src/app/(auth)/signup.tsx` |
| `/forgot-password` | `src/app/(auth)/forgot-password.tsx` |
| `/verify-email` | `src/app/(auth)/verify-email.tsx` (reachable, not a hard gate) |
| `/home` | `src/app/(tabs)/home/index.tsx` |
| `/home/activity` | `src/app/(tabs)/home/activity.tsx` |
| `/garage` | `src/app/(tabs)/garage/index.tsx` |
| `/garage/add-vehicle` | `src/app/(tabs)/garage/add-vehicle.tsx` |
| `/garage/edit-vehicle/[id]` | `src/app/(tabs)/garage/edit-vehicle/[id].tsx` |
| `/garage/vehicle/[id]` | `src/app/(tabs)/garage/vehicle/[id]/index.tsx` |
| `/garage/vehicle/[id]/fuel-records` | `src/app/(tabs)/garage/vehicle/[id]/fuel-records.tsx` |
| `/garage/vehicle/[id]/maintenance/add` | `.../maintenance/add.tsx` |
| `/garage/vehicle/[id]/maintenance/edit` | `.../maintenance/edit.tsx` |
| `/garage/vehicle/[id]/documents/upload` | `.../documents/upload.tsx` |
| `/expenses` | `src/app/(tabs)/expenses/index.tsx` |
| `/profile` | `src/app/(tabs)/profile/index.tsx` |
| `/profile/edit` | `src/app/(tabs)/profile/edit.tsx` |
| `/profile/credentials/add` | `src/app/(tabs)/profile/credentials/add.tsx` |
| `/profile/credentials/edit` | `src/app/(tabs)/profile/credentials/edit.tsx` |

Tabs: **Home · Garage · [center +] · Expenses · Settings** — floating pill bar matching Flutter `MainShell`. Center `+` opens Quick Add sheet (Log fuel / Add service / Upload doc / Add vehicle).

---

## 3. Target folder structure (end state)

```
mobile-rn/
  src/
    app/
      _layout.tsx                 # providers, db migrate, auth gate
      index.tsx                   # redirect splash → home|login
      (auth)/
        _layout.tsx
        login.tsx
        signup.tsx
        forgot-password.tsx
        verify-email.tsx
      (tabs)/
        _layout.tsx               # floating tab shell + quick-add
        home/
        garage/
        expenses/
        profile/
    features/
      auth/
      dashboard/
      vehicles/
      fuel-logs/
      maintenance/
      documents/
      driving-credentials/
      activity/
      expenses/
      profile/
    components/                   # shared dumb UI
    constants/                    # theme tokens (DriveVault)
    db/                           # Phase 8
    lib/                          # api-client, formatting, dates, currency
  docs/best-practices.md
  .env.example                    # EXPO_PUBLIC_API_BASE_URL=...
```

Each feature folder:

```
features/<name>/
  api.ts
  repository.ts
  types.ts
  hooks.ts
  components/          # screens + feature widgets
  local.ts             # Phase 8 only
  *.test.ts
```

---

## Phase 0 — Strip boilerplate + foundation tokens

**Goal:** Empty DriveVault-ready shell with design tokens and shared primitives; no Expo tutorial screens.

### Task 0.1: Install foundation dependencies

**Files:**
- Modify: `mobile-rn/package.json`
- Create: `mobile-rn/.env.example`

- [ ] **Step 1: Add pre-approved packages**

```bash
cd mobile-rn
pnpm add firebase @tanstack/react-query zustand expo-image-picker expo-document-picker expo-secure-store react-native-svg
pnpm add -D jest @types/jest @testing-library/react-native jest-expo
```

- [ ] **Step 2: Create `.env.example`**

```bash
EXPO_PUBLIC_API_BASE_URL=http://localhost:8000/api/v1
EXPO_PUBLIC_FIREBASE_API_KEY=
EXPO_PUBLIC_FIREBASE_AUTH_DOMAIN=
EXPO_PUBLIC_FIREBASE_PROJECT_ID=
EXPO_PUBLIC_FIREBASE_APP_ID=
EXPO_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=
EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID=
```

- [ ] **Step 3: Add test script to `package.json`**

```json
"scripts": {
  "start": "expo start",
  "android": "expo start --android",
  "ios": "expo start --ios",
  "web": "expo start --web",
  "lint": "expo lint",
  "test": "jest",
  "reset-project": "node ./scripts/reset-project.js"
}
```

- [ ] **Step 4: Commit**

```bash
git add mobile-rn/package.json mobile-rn/pnpm-lock.yaml mobile-rn/.env.example
git commit -m "chore(mobile-rn): add foundation deps for Flutter migration"
```

### Task 0.2: Replace theme tokens with DriveVault palette

**Files:**
- Modify: `mobile-rn/src/constants/theme.ts`
- Reference: `mobile/lib/core/theme/app_theme.dart`

- [ ] **Step 1: Rewrite `theme.ts` with Flutter `AppColors` parity**

```ts
export const Colors = {
  background: '#EBEBF0',
  surface: '#FFFFFF',
  surfaceDark: '#1E1D2B',
  primary: '#FFD600',
  onPrimary: '#1E1D2B',
  textPrimary: '#1A1A2E',
  textMuted: '#9898A6',
  textOnDark: '#FFFFFF',
  textOnDarkMuted: 'rgba(244,243,248,0.62)',
  divider: '#E2E2EA',
  success: '#34D399',
  warning: '#FBBF24',
  danger: '#FF7A7A',
  successBg: 'rgba(34,197,94,0.16)',
  warningBg: 'rgba(245,158,11,0.18)',
  dangerBg: 'rgba(239,68,68,0.18)',
  dashedBorder: '#C2C4CF',
  cardGradientStart: '#23232E',
  cardGradientEnd: '#15151C',
  photoUploadTint: '#FFF9E6',
} as const;

export const Spacing = {
  half: 2,
  one: 4,
  two: 8,
  three: 16,
  four: 24,
  five: 32,
  six: 64,
} as const;

export const Radii = {
  card: 16,
  pill: 999,
} as const;
```

Keep light-only for Phase 0 (Flutter Phase 1 is light). Remove Expo template light/dark split or keep dark stubs unused.

- [ ] **Step 2: Commit**

```bash
git add mobile-rn/src/constants/theme.ts
git commit -m "feat(mobile-rn): adopt DriveVault design tokens"
```

### Task 0.3: Remove Expo tutorial screens; scaffold folders

**Files:**
- Delete: `mobile-rn/src/app/explore.tsx`, tutorial-only components as unused
- Create empty dirs via placeholder `.gitkeep` or first real files in later tasks:
  - `src/features/`, `src/lib/`, `src/components/`
- Modify: `mobile-rn/src/app/_layout.tsx`, `mobile-rn/src/app/index.tsx`
- Modify: `mobile-rn/src/components/app-tabs.tsx` → temporary single “Home” stub

- [ ] **Step 1: Replace `index.tsx` with a placeholder Home**

```tsx
import { Text, View } from 'react-native';
import { Colors, Spacing } from '@/constants/theme';

export default function HomePlaceholder() {
  return (
    <View style={{ flex: 1, backgroundColor: Colors.background, padding: Spacing.three }}>
      <Text style={{ color: Colors.textPrimary, fontSize: 24, fontWeight: '700' }}>
        DriveVault
      </Text>
      <Text style={{ color: Colors.textMuted, marginTop: Spacing.two }}>
        React Native migration scaffold
      </Text>
    </View>
  );
}
```

- [ ] **Step 2: Simplify root layout** — keep splash overlay if useful; drop Explore tab.

- [ ] **Step 3: Lint**

```bash
cd mobile-rn && pnpm lint
```

Expected: clean (or only pre-existing template warnings you just removed).

- [ ] **Step 4: Commit**

```bash
git add -A mobile-rn/src
git commit -m "chore(mobile-rn): strip Expo tutorial; scaffold DriveVault shell"
```

### Task 0.4: Shared formatting utils + first unit test

**Files:**
- Create: `mobile-rn/src/lib/formatting.ts`
- Create: `mobile-rn/src/lib/formatting.test.ts`
- Create: `mobile-rn/src/lib/currencies.ts`
- Create: `mobile-rn/src/lib/distance-unit.ts`
- Reference: `mobile/lib/shared/utils/formatting.dart`, `currencies.dart`, `distance_unit.dart`

- [ ] **Step 1: Write failing test**

```ts
import { formatCents } from './formatting';

describe('formatCents', () => {
  it('formats LKR cents as major units', () => {
    expect(formatCents(23400, 'LKR')).toMatch(/234/);
  });
});
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
cd mobile-rn && pnpm test -- src/lib/formatting.test.ts
```

- [ ] **Step 3: Implement `formatCents` / economy helpers** (money always integer cents; never floats for storage).

- [ ] **Step 4: Run test — expect PASS; commit**

```bash
git add mobile-rn/src/lib
git commit -m "feat(mobile-rn): add currency and distance formatting utils"
```

**Phase 0 done when:** app launches to a DriveVault-branded placeholder; theme tokens match Flutter; foundation deps installed; formatting tests pass.

---

## Phase 1 — Auth + API client + `/me`

**Goal:** Email/password + Google sign-in, auth gate, typed API client with Bearer token, `GET/PATCH /me`. Soft verify-email banner later (Phase 6); gate is soft (land on home).

### Task 1.1: Firebase init + auth store

**Files:**
- Create: `mobile-rn/src/lib/firebase.ts`
- Create: `mobile-rn/src/features/auth/types.ts`
- Create: `mobile-rn/src/features/auth/repository.ts`
- Create: `mobile-rn/src/features/auth/store.ts`
- Create: `mobile-rn/src/features/auth/hooks.ts`
- Reference: `mobile/lib/features/auth/data/auth_repository.dart`

- [ ] **Step 1: Firebase bootstrap**

```ts
// src/lib/firebase.ts
import { initializeApp, getApps } from 'firebase/app';
import { getAuth, initializeAuth, getReactNativePersistence } from 'firebase/auth';
import ReactNativeAsyncStorage from '@react-native-async-storage/async-storage';

const firebaseConfig = {
  apiKey: process.env.EXPO_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.EXPO_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.EXPO_PUBLIC_FIREBASE_PROJECT_ID,
  appId: process.env.EXPO_PUBLIC_FIREBASE_APP_ID,
  messagingSenderId: process.env.EXPO_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
};

export function getFirebaseApp() {
  return getApps()[0] ?? initializeApp(firebaseConfig);
}

export function getFirebaseAuth() {
  const app = getFirebaseApp();
  try {
    return initializeAuth(app, {
      persistence: getReactNativePersistence(ReactNativeAsyncStorage),
    });
  } catch {
    return getAuth(app);
  }
}
```

> If `getReactNativePersistence` import path differs for the pinned `firebase` version, adjust per Firebase RN docs — do not invent a second auth stack.

Also add `@react-native-async-storage/async-storage` (Expo-compatible; flag as dependency).

- [ ] **Step 2: Auth repository methods** (parity with Flutter):
  - `signInWithEmailAndPassword`
  - `createUserWithEmailAndPassword` (+ `sendEmailVerification`)
  - `signInWithGoogle`
  - `signOut`
  - `sendPasswordResetEmail`
  - `reloadUser`
  - `getIdToken()`

- [ ] **Step 3: Zustand auth store**

```ts
type AuthStatus = 'loading' | 'signedOut' | 'signedIn';

type AuthState = {
  status: AuthStatus;
  user: AuthUser | null; // { uid, email, emailVerified, isPasswordProvider }
  setFromFirebaseUser: (user: AuthUser | null) => void;
};
```

Subscribe to `onAuthStateChanged` once in root layout.

- [ ] **Step 4: Unit-test repository error mapping** with mocked Firebase (no real network).

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(mobile-rn): Firebase auth repository and session store"
```

### Task 1.2: Typed API client

**Files:**
- Create: `mobile-rn/src/lib/api-client.ts`
- Create: `mobile-rn/src/lib/api-errors.ts`
- Create: `mobile-rn/src/lib/api-client.test.ts`
- Reference: `mobile/lib/core/network/api_client.dart`

- [ ] **Step 1: Failing test — 401 maps to `ApiAuthError`; body `{ detail }` becomes message**

- [ ] **Step 2: Implement**

```ts
// Behaviour contract:
// - baseUrl = process.env.EXPO_PUBLIC_API_BASE_URL (required)
// - every request: Authorization: Bearer <firebase idToken> when signed in
// - parse JSON; on non-OK throw ApiError(status, detail)
// - 401 → ApiAuthError
// - ownership 404 stays 404 (do not remap to 403)
```

```ts
export class ApiError extends Error {
  constructor(
    public status: number,
    message: string,
    public body?: unknown,
  ) {
    super(message);
  }
}

export class ApiAuthError extends ApiError {
  constructor(message: string, body?: unknown) {
    super(401, message, body);
  }
}

type RequestOptions = {
  method?: 'GET' | 'POST' | 'PATCH' | 'DELETE';
  body?: unknown;
  token?: string | null;
};

export async function apiRequest<T>(path: string, options: RequestOptions = {}): Promise<T> {
  const baseUrl = process.env.EXPO_PUBLIC_API_BASE_URL;
  if (!baseUrl) throw new Error('EXPO_PUBLIC_API_BASE_URL is not set');

  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  };
  if (options.token) headers.Authorization = `Bearer ${options.token}`;

  const res = await fetch(`${baseUrl}${path}`, {
    method: options.method ?? 'GET',
    headers,
    body: options.body === undefined ? undefined : JSON.stringify(options.body),
  });

  const text = await res.text();
  const data = text ? JSON.parse(text) : null;

  if (!res.ok) {
    const detail =
      data && typeof data === 'object' && 'detail' in data
        ? String((data as { detail: unknown }).detail)
        : res.statusText;
    if (res.status === 401) throw new ApiAuthError(detail, data);
    throw new ApiError(res.status, detail, data);
  }

  return data as T;
}
```

Wire token via a small `getAccessToken: () => Promise<string | null>` injected from auth (avoid circular imports).

- [ ] **Step 3: Tests pass; commit**

```bash
git commit -m "feat(mobile-rn): typed API client with Bearer token injection"
```

### Task 1.3: Profile `/me` feature slice

**Files:**
- Create: `mobile-rn/src/features/profile/types.ts`
- Create: `mobile-rn/src/features/profile/api.ts`
- Create: `mobile-rn/src/features/profile/repository.ts`
- Create: `mobile-rn/src/features/profile/hooks.ts`
- Create: `mobile-rn/src/features/profile/repository.test.ts`
- Contract: Doc 3 `GET/PATCH /me`

```ts
// types.ts — camelCase JSON per Doc 3
export type AppUser = {
  id: string;
  firebaseUid: string;
  email: string;
  displayName: string | null;
  photoUrl: string | null;
  currency: string;
  distanceUnit: 'km' | 'mi';
  renewalRemindersEnabled: boolean;
  createdAt: string;
  updatedAt: string;
};
```

- [ ] **Step 1: Repository tests with mocked `apiRequest`**
- [ ] **Step 2: `useMe()` via TanStack Query `queryKey: ['me']`**
- [ ] **Step 3: Commit**

```bash
git commit -m "feat(mobile-rn): /me profile repository and query hook"
```

### Task 1.4: Auth screens + route gate

**Files:**
- Create: `src/features/auth/components/login-screen.tsx`, `signup-screen.tsx`, `forgot-password-screen.tsx`
- Create: `src/app/(auth)/_layout.tsx`, `login.tsx`, `signup.tsx`, `forgot-password.tsx`
- Modify: `src/app/_layout.tsx` — `QueryClientProvider`, auth listener, redirect

**Auth redirect (parity with Flutter soft gate):**
- `status === 'loading'` → splash/null
- `signedOut` → `/(auth)/login`
- `signedIn` → `/(tabs)/home` (even if email unverified)

- [ ] **Step 1: Build login/signup UI** matching Flutter fields (email, password, Google button, links).
- [ ] **Step 2: Manual smoke** against Firebase + local backend: sign up → `GET /me` succeeds.
- [ ] **Step 3: Commit**

```bash
git commit -m "feat(mobile-rn): auth screens and Expo Router auth gate"
```

**Phase 1 done when:**
- [ ] Sign up / sign in / sign out work
- [ ] Auth persists across reload
- [ ] `GET /me` returns user with Bearer token
- [ ] Unverified email users still reach home
- [ ] Repository + api-client unit tests pass
- [ ] `pnpm lint` clean

---

## Phase 2 — App shell (tabs + quick add)

**Goal:** Floating 4-tab shell + center Quick Add matching Flutter `MainShell` / `QuickAddSheet`.

**Files to create:**
- `src/components/floating-tab-bar.tsx`
- `src/components/quick-add-sheet.tsx`
- `src/components/form-screen-app-bar.tsx`
- `src/components/bottom-sheet-picker-field.tsx`
- `src/components/app-button.tsx`
- `src/components/shimmer-box.tsx`
- `src/components/status-pill.tsx`
- `src/app/(tabs)/_layout.tsx` — Home / Garage / Expenses / Profile + center action
- Stub tab screens for garage/expenses/profile

**UI rules (`docs/ui-conventions.md`):**
- Form headers: Cancel left, Save pill right, title 16 centered
- Bottom sheets that cover the tab bar use the root navigator / full-screen modal presentation
- Destructive actions stay on detail screens, not edit forms

**Done when:** tabs switch; `+` opens Quick Add with four actions (can navigate to stub routes); visual parity with Flutter shell screenshots in `docs/design-references/`.

> Expand into a detailed execution plan before coding if the tab bar animation needs Reanimated work.

---

## Phase 3 — Vehicles (Garage)

**Goal:** Vehicle list, detail, add/edit form, Cloudinary photo upload — parity with Flutter garage tasks D1–D5.

**Feature folder:** `src/features/vehicles/`

| File | Responsibility |
|---|---|
| `types.ts` | `Vehicle`, `DocsStatus` per Doc 3 |
| `api.ts` | `/vehicles` CRUD paths only |
| `repository.ts` | only caller of `api.ts` |
| `hooks.ts` | `useVehicles`, `useVehicle(id)`, mutations with query invalidation |
| `components/garage-screen.tsx` | list (`FlatList`) |
| `components/vehicle-card.tsx` | memoized row |
| `components/vehicle-detail-screen.tsx` | detail + delete |
| `components/vehicle-form-screen.tsx` | add/edit |
| `components/vehicle-photo-field.tsx` | light yellow upload tint |

**Upload:** shared `src/features/uploads/` (or under documents) — `POST /uploads/cloudinary-signature` then direct Cloudinary upload; store only `secure_url` on the vehicle. File bytes never hit FastAPI.

**Form conventions:** odometer above registration; distance unit mile/km defaulting to user preference; vehicle type default Car; photo field yellow tint.

**Routes:** wire all garage routes from §2.

**Tests:** repository CRUD + ownership 404 handling; form validation unit tests where pure.

**Done when:** create/list/get/patch/delete vehicle against local Docker backend; photo upload works; detail shows docs status; lint + scoped tests pass.

---

## Phase 4 — Fuel logs + Maintenance

**Goal:** Fuel records list, quick fuel entry sheet, maintenance form/sheet — online-only first (no optimistic SQLite yet).

**Feature folders:** `src/features/fuel-logs/`, `src/features/maintenance/`

**Fuel:**
- Endpoints: Doc 3 fuel-logs + fuel-stats
- `QuickFuelEntrySheet` + `FuelNumericKeypad` parity
- Full tank toggle **on the same row as Liters**
- Money in cents; liters as number per contract
- Vehicle fuel records screen under garage

**Maintenance:**
- CRUD per Doc 3; `source: 'manual'`
- `QuickMaintenanceSheet` + fullscreen form for add/edit
- Delete on detail/list swipe or detail only — match Flutter

**Hooks:** TanStack mutations invalidate `['vehicles', id, 'fuel-logs']`, `['fuel-stats', id]`, `['maintenance', id]`, `['dashboard']`.

**Done when:** add fuel + maintenance from Quick Add and from vehicle detail; stats display; tests for repository + any pure calc helpers (`FuelEntryCalc` / odometer estimate if ported).

---

## Phase 5 — Documents

**Goal:** Upload + list + viewer for vehicle documents.

**Feature folder:** `src/features/documents/`

- Signature → Cloudinary → `POST /vehicles/{id}/documents` with `secureUrl`
- `DocumentUploadScreen` with `FormScreenAppBar`
- Viewer via `expo-linking` / in-app WebView only if Flutter does — match behavior
- Grouped documents provider parity (`groupedDocuments`)

**Done when:** upload insurance/registration-style doc; list on vehicle detail; delete works; 404 for other user’s doc.

---

## Phase 6 — Dashboard + Activity + Verify banner

**Goal:** Home dashboard from `GET /dashboard`; activity “See all”; soft `VerifyEmailBanner`.

**Feature folders:** `src/features/dashboard/`, `src/features/activity/`

**Dashboard widgets to port:**
- Stat cards (monthly fuel, ownership cost, vehicle count)
- `BreakdownBar` cost breakdown
- Upcoming renewals list (`StatusPill`)
- Recent activity rows → navigate to activity screen
- `CredentialExpiryBanner` if Flutter shows credentials on home
- `VerifyEmailBanner` — per-session dismissible; Resend / I’ve verified (`reloadUser`); **not** a hard gate

**Activity:** Resolved — `backend/app/routers/activity.py` defines a real, deployed `GET /activity` endpoint (`response_model=list[ActivityItemRead]`), separate from dashboard's embedded `recentActivity`. Doc 3 doesn't document it yet (contract lag), but the endpoint is live — the Activity screen should call `GET /activity` directly, not just reuse dashboard's list.

**Done when:** home matches Flutter layout for a seeded user (Hilux fixture); banner soft-nudge behavior matches; lint + tests for any pure status helpers (`expiryColor`).

---

## Phase 7 — Profile, preferences, driving credentials, expenses

**Goal:** Settings tab parity.

**Profile:**
- View + edit display name, currency (`BottomSheetPickerField`: symbol + name rows, store ISO, closed field shows name), distance unit, renewal reminders
- Sign out with red styling + confirmation sheet

**Driving credentials:**
- Section on profile; add/edit forms
- Resolved — `backend/app/routers/driving_credentials.py` is real and deployed:
  `GET /me/driving-credentials`, `POST /me/driving-credentials`,
  `PATCH /me/driving-credentials/{credential_id}`, `DELETE /me/driving-credentials/{credential_id}`.
  Doc 3 hasn't caught up, but the routes exist — build against them directly (check
  `backend/app/schemas/driving_credentials.py` for exact field names before typing `types.ts`).

**Expenses:**
- Fan-out view: all vehicles’ fuel + maintenance merged (Flutter `expenses_provider`) — client-side compose via existing queries is OK if no dedicated API

**Done when:** edit profile persists via `PATCH /me`; credentials CRUD works if API exists; expenses list filters; sign out clears query cache + auth.

---

## Phase 8 — Local SQLite cache + optimistic sync

**Goal:** Parity with Flutter Drift cache-first + pending fuel/maintenance sync — **after** online feature parity.

Per `best-practices.md` §6:
- `expo-sqlite` + Drizzle
- `src/db/schema.ts` mirrors Doc 2 `snake_case` columns
- `src/db/client.ts` + migrations at startup in root layout
- Feature `local.ts` helpers only — no raw SQL in components
- **Writes:** UI → repository → API → on success upsert cache. Optimistic path: write `sync_status='pending'` → background push (like Flutter `SyncService`)

**Tables (match Flutter):** vehicles, dashboard_snapshots, fuel_logs, maintenance_records (+ sync_status).

**Done when:** airplane-mode read of cached garage/dashboard works; pending fuel/maintenance flush on foreground; unit tests for sync state machine.

---

## Phase 9 — Parity audit + cutover

**Goal:** RN is the mobile client of record.

Checklist:
- [ ] Every route in §2 implemented
- [ ] Doc 3 endpoints used by Flutter are covered
- [ ] UI conventions doc followed
- [ ] No secrets committed
- [ ] `pnpm lint` + feature tests green
- [ ] iOS Simulator smoke against local Docker (seeded Hilux user)
- [ ] Android smoke
- [ ] Update root `CLAUDE.md` / `AGENTS.md` stack line to React Native when cutover is accepted
- [ ] Archive or mark `mobile/` deprecated (only when user explicitly approves)

---

## 4. Suggested worktree / branch strategy

Mirror Flutter Phase 1 batches:

| Branch | Phase |
|---|---|
| `rn/phase-0-foundation` | Phase 0 |
| `rn/phase-1-auth` | Phase 1 |
| `rn/phase-2-shell` | Phase 2 |
| `rn/phase-3-vehicles` | Phase 3 |
| `rn/phase-4-fuel-maint` | Phase 4 |
| `rn/phase-5-documents` | Phase 5 |
| `rn/phase-6-dashboard` | Phase 6 |
| `rn/phase-7-profile-expenses` | Phase 7 |
| `rn/phase-8-sqlite-cache` | Phase 8 |
| `rn/phase-9-cutover` | Phase 9 |

Use `.worktrees/` for parallel phases only when they don’t touch the same files (e.g. vehicles vs profile after shell merges).

---

## 5. Testing strategy

| Layer | Tool | What |
|---|---|---|
| `lib/*`, repositories | Jest | Pure functions, mocked fetch |
| Screens | RNTL | User-visible behavior (tap Sign in → calls repo) |
| Manual | Simulator | Auth, CRUD, uploads against Docker backend |

Run **scoped** tests per phase (`pnpm test -- src/features/vehicles`), not the full suite every time.

---

## 6. Explicit non-goals (during migration)

- No AI / OCR / Gemini
- No Apple Sign-In (deferred like Flutter)
- No FCM push handlers unless Flutter already ships them (it doesn’t meaningfully)
- No Firestore
- No redesign / new product features
- No replacing NativeTabs with a different IA than Flutter’s four tabs

---

## 7. Self-review (plan quality)

| Spec / inventory item | Covered by |
|---|---|
| Auth email/Google + soft verify | Phase 1 + 6 |
| API client + `/me` | Phase 1 |
| Floating shell + quick add | Phase 2 |
| Vehicles + Cloudinary photo | Phase 3 |
| Fuel + maintenance | Phase 4 |
| Documents | Phase 5 |
| Dashboard + activity | Phase 6 |
| Profile + credentials + expenses | Phase 7 |
| Drift/SQLite cache + sync | Phase 8 |
| best-practices folder rules | §3 + all phases |
| Doc 3 contract fidelity | §0 principles + each feature phase |
| ui-conventions | Phase 2–7 notes |

**Open questions — resolved 2026-07-10:**
1. Phase 6: `GET /activity` is a real, deployed backend route (`backend/app/routers/activity.py`), distinct from dashboard's `recentActivity`. Build against it directly.
2. Phase 7: Driving-credential endpoints are real and deployed (`backend/app/routers/driving_credentials.py`) — full CRUD under `/me/driving-credentials`. Doc 3 just hasn't been updated; the API is authoritative here since it's live.
3. Phase 1: Flutter uses native Google Sign-In (has `GoogleService-Info.plist`/`google-services.json`), which Expo Go can't replicate. Use `expo-auth-session`'s browser-based Google OAuth → Firebase credential exchange to stay in Expo Go; only add a dev client + native Google Sign-In package if that flow doesn't hold up in testing.

---

## 8. Execution handoff

**Plan complete and saved to `mobile-rn/docs/2026-07-10-flutter-to-rn-migration.md`. All three open questions above are resolved.**

**Recommended next step:** implement **Phase 0** (then Phase 1) with subagent-driven development. Before starting Phase 2+, write a bite-sized execution plan for that phase alone (file-level steps + tests), using this master plan as the spec.

**Two execution options:**

1. **Subagent-Driven (recommended)** — fresh subagent per task, review between tasks  
2. **Inline Execution** — execute tasks in this session with checkpoints  

Which approach, and should we start at Phase 0?
