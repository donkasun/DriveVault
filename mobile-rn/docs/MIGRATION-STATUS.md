# Flutter → React Native migration — status

**As of 2026-07-13** · branch `feat/rn-migration-plan` · last commit `5214f23`

Plan: [`2026-07-10-flutter-to-rn-migration.md`](./2026-07-10-flutter-to-rn-migration.md)
Conventions: [`best-practices.md`](./best-practices.md)

---

## The one-line summary

**Phases 0–8 are code-complete and green. Nothing has ever been run against a real
Firebase project or a live backend.** Every screen exists, 210 tests pass, the iOS
bundle builds — and not one screen has been rendered against a real server.

---

## Verification status

| Check | Result |
|---|---|
| `tsc --noEmit` | clean |
| `eslint src` | clean — 186 files, 0 errors, 0 warnings |
| `jest --ci` | 210 tests, 19 suites, all passing |
| `expo export --platform ios` | bundles (5.4 MB) |
| **Run against a real backend** | **NEVER DONE** |
| **Run against a real Firebase project** | **NEVER DONE** |
| Android smoke | never done |

> These four checks are weaker than they look. All of them passed for **four
> commits** while the app had **no login route at all** — see "Bugs found" below.

---

## Done

### Phase 0 — foundation
- Design tokens ported from `app_theme.dart` (verified value-by-value).
- `formatCents` / distance / economy helpers, with parity tests covering the
  `.00`-stripping rule and the "space only after multi-letter symbols" rule
  (`Rs 26,793`, but `A$4,120.50`).
- Expo tutorial scaffold stripped.

### Phase 1 — auth + API client + `/me`
- `api-client.ts` mirrors Dio: `{detail}` → message, 401 → `ApiAuthError`,
  transport failure → `statusCode: 0`, 10s timeout.
- Firebase auth with AsyncStorage persistence; Zustand session store.
- Login / signup / forgot-password screens.
- `resolveAuthRedirect` ported as a pure, tested function.

### Phase 2 — app shell
- Floating tab bar (82px dark pill, yellow active chip, raised 72px `+`), hides
  with the keyboard. Quick Add sheet.

### Phase 3 — garage
- Vehicle list + gradient card, add/edit form, Cloudinary signed upload,
  detail screen.

### Phase 4 — fuel + maintenance
- `FuelEntryCalc` (liters/total/per-litre derivation + AUTO field) and
  `estimateNextOdometer`, hand-ported with 16 parity tests.
- Quick fuel sheet + numeric keypad, fuel record cards, maintenance sheet + form.

### Phase 5 — documents
- Upload (image + PDF) via the signed Cloudinary path; viewer with delete.

### Phase 6 — dashboard, activity, verify banner
- Dashboard (stat cards, breakdown bar, needs-attention, upcoming renewals,
  recent activity, credential-expiry banner).
- Activity screen calling `GET /activity` directly.
- `VerifyEmailBanner` — soft nudge, contains no navigation (grep-verified).

### Phase 7 — profile, credentials, expenses
- Profile + preferences; currency is **locked** (matching the Dart).
- Driving credentials full CRUD.
- Expenses composed client-side by fanning out over all vehicles.
- Sign out clears the TanStack Query cache.

### Phase 8 — local SQLite read cache
- Drizzle over `expo-sqlite`; cache-first reads, API-first writes.
- Sign out also clears the on-disk cache.

---

## Remaining

### Phase 9 — parity audit + cutover (NOT STARTED)
- [ ] **Smoke test against a real backend and Firebase project.** This is the
      single highest-value remaining task. Nothing below matters until this is done.
- [ ] Android smoke test.
- [ ] Walk every route against the seeded Hilux user and compare screen-by-screen
      with the Flutter app.
- [ ] Point `EXPO_PUBLIC_API_BASE_URL` at the production host. **If the
      FastAPI → Next.js cutover has landed, that is the Next.js host, not the
      Cloud Run URL.** Coordinate with `web/docs/migration-plan.md` Phase 8.
- [ ] Update root `CLAUDE.md` / `AGENTS.md` stack line to React Native.
- [ ] Archive or deprecate `mobile/` (only on explicit approval).

### Known gaps in what's built
- [ ] **No offline writes.** Deliberate (see Phase 8 decision). Flutter can log a
      fill-up with no signal; this cannot. Offline *reads* work.
- [ ] **Reminders have no receiver.** `users.fcm_token` is never written by any
      client — Flutter never registered a device token either, so no renewal
      reminder has ever been delivered by *either* app. The pipeline creates rows
      and sends nothing. Needs: client FCM registration + an endpoint to accept
      the token (none exists in the contract).
- [ ] Vehicle detail hero doesn't collapse on scroll (Flutter uses a
      `SliverAppBar` with per-frame photo-luminance sampling).
- [ ] Date fields use a bottom-sheet picker, not a native calendar.
- [ ] `mobile/assets/icons/home.svg` is a 334 KB auto-traced path; carrying it
      over costs ~400 KB of bundle. Worth re-exporting at 24px.

### Housekeeping
- [ ] **Delete the stray files at the repo root** — untracked leftovers from a
      shell cwd drift, and a live trap for any tool that resolves `package.json`
      upward:
      ```
      rm -rf /Users/DonDimal/Documents/Kasun/DriveVault/{src,node_modules,package.json,pnpm-lock.yaml,.expo}
      ```
- [ ] `pnpm-lock.yaml` contains entries pnpm's `minimumReleaseAge` policy rejects
      (a scoped exception was used to install Expo 57). Plain `pnpm install` /
      `pnpm test` will fail the pre-run check until those packages age past 7 days.
      Workaround in use: call binaries directly (`node_modules/.bin/...`).

---

## Deliberate deviations from Flutter

These are **intentional**. Do not "fix" them without deciding first.

| # | Deviation | Why |
|---|---|---|
| 1 | Full-tank toggle sits on the **Liters row** | `ui-conventions.md:28` mandates it; the Dart puts it on its own row. **The Flutter app violates its own conventions doc.** |
| 2 | Maintenance **delete lives on the detail screen**, not the edit form | `ui-conventions.md:16`. Same conflict as above. |
| 3 | **No offline writes** | User decision; `best-practices.md` §6 forbids write-then-sync. Avoids inheriting Flutter's silent-orphan bug. |
| 4 | Google sign-in via `expo-auth-session` (browser OAuth) | Flutter uses native `google_sign_in`, which has no Expo Go equivalent. Same end state. |
| 5 | `expiryColor()` **not ported** | Dead code in Flutter — zero call sites, and returns raw Material colours contradicting the design tokens. |
| 6 | Activity/expenses delete is long-press, not swipe | RN convention; no swipe-to-dismiss dependency added. |
| 7 | Fuel pump icon is flat, not a gradient shader-mask | No RN equivalent without a custom shader. |

**Items 1 and 2 are the ones to revisit if you want literal Flutter parity** — they
are places where Flutter contradicts your own conventions doc, and `CLAUDE.md` says
the docs win.

---

## Bugs found and fixed during the migration

Worth recording, because each one passed typecheck, lint, and the full test suite.

1. **The login screen did not exist.** A shell cwd drift wrote `(auth)/login.tsx`,
   `signup.tsx` and `forgot-password.tsx` to the **repo root** instead of
   `mobile-rn/src/app/`. Expo Router never saw them; `index.tsx` redirected every
   signed-out user to a route that wasn't there. tsc, eslint, 157 tests and
   `expo export` **all passed** for four commits. Only enumerating the router tree
   caught it. (Fixed: `1af7e55`.)

2. **Invented fuel-log field names.** `filledAt` / `totalCostCents` / `odometerKm` /
   `stationName` / `monthlySpend.totalCents` — none exist. The real contract is
   `date` / `priceCents` / `odometer` / `spentCents`. Every fuel request would have
   failed. It typechecked perfectly because both sides of the lie were written
   together. Caught by cross-checking `backend/app/schemas/fuel_logs.py`.

3. **`parseInt` silently truncating.** The vehicle form used `Number.parseInt` where
   Dart uses `int.tryParse`. `"2015abc"` parsed as year `2015`; `"120km"` as
   mileage `120`. Since odometer feeds `displayToKm`, junk would have been written
   to the DB as real kilometres. Replaced with strict parsers + regression tests.

4. **`package.json` clobbered.** A `pnpm add` run from the wrong cwd rewrote it down
   to two dependencies, dropping `"main": "expo-router/entry"`. Tests still passed;
   only the bundle caught it.

5. **Jest was fundamentally broken.** The local `watchman` install hung
   `jest-haste-map` (zero output, never exits), and `jest-expo@57` requires the
   Jest **29** ecosystem. Fixed via `watchman: false`, Jest pinned to 29, and the
   missing `@react-native/jest-preset` peer.

**The lesson:** green checks proved very little here. Four of these five bugs passed
every automated gate. The migration needs a human to actually run the app.

---

## Contract facts (`docs/03-api-contract.md` is wrong; the API is right)

| Gap | Reality |
|---|---|
| `GET /activity` | Real and deployed, undocumented. Richer than `dashboard.recentActivity`, and **excludes** driving credentials. |
| `/me/driving-credentials` | Full CRUD is real; Doc 3 hasn't caught up. |
| `dashboard.upcomingRenewals` | Merges vehicle documents **and** driving credentials (credential rows have a null `vehicleId`). Doc 3 says documents-only. |
| `DELETE /documents/{id}` | Deletes only the DB row — **not** the Cloudinary asset, despite what Doc 3 says. |
