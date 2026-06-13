# DriveVault Phase 1 Audit — 2026-06-12

Audit of `mobile/` against `docs/` (tasks 04, contract 03, screens 06, fuel-prefs 07, PRD).
Method: orchestrated review — five parallel feature auditors + analyzer/test run.
Baseline health: **`flutter analyze` clean** (4 info-level lints in tests), **all 119 tests pass**.

---

## 1. Phase 1 task scorecard

| Task | Scope | Status | Notes |
|---|---|---|---|
| C2a | Email/password auth | ✅ Done | Firebase init via `firebase_options.dart`; sign-up/in/out wired |
| C2b | Google sign-in | ✅ Done | Apple correctly deferred |
| C2c | Auth gate + persistence | ✅ Done | `resolveAuthRedirect` pure fn + router listenable |
| C2d | Email-verification gate | ✅ Done | 12 unit tests; Google bypass works |
| C3 | API client + token injection | ✅ Done | `--dart-define` base URL, typed errors, 401 → `ApiAuthException` |
| D1a | Garage list (4 states) | ✅ Done | ⚠️ "dashed" Add Vehicle card renders **solid green**, not dashed |
| D1b | Add/Edit vehicle form | ✅ Done | ⚠️ PATCH null-clobber bug (see §2.1) |
| D1c | Vehicle photo (Cloudinary) | ✅ Done | Gallery-only, no camera option |
| D2 | Vehicle detail shell | ✅ Done | Fuel/Maintenance/Documents sections all present |
| D3 | Fuel tracking UI | ✅ Done | List, form, delete-with-confirm, stats card all present |
| D4 | Maintenance UI | ⚠️ Partial | **No delete path** from detail screen or form (only via Expenses swipe) |
| D5a | Docs grouped list + expiry badges | ✅ Done | Red/amber/green badges per spec |
| D5b | Document upload | ⚠️ Partial | **Images only** — `pickImage()`; PDFs (insurance, registration) cannot be uploaded |
| D5c | Doc viewer + delete | ✅ Done | Image viewer; PDF falls back to browser |
| D6 | Dashboard | ⚠️ Partial | Aggregates correct; renewal rows show **raw UUID** and are **not tappable** |
| E1 | Smoke pass | ✅ Done | Per task doc, 2026-06-10 |
| 07-fuel-prefs F1–F10 | Fuel/prefs follow-on | ✅ Done | Consistent with code; `fuelVariant` intentionally dropped on mobile but still in Doc 3 |

**Built beyond the plan:** Expenses tab (combined history across vehicles), Profile/Settings screen, forgot-password screen. Useful, but the shell is now **4 tabs vs the 3-tab spec**, and the Expenses tab introduces an N+1 API pattern (§3.4).

---

## 2. Bugs to fix (correctness)

### 2.1 High
1. **Vehicle edit clobbers `fuelType`/`distanceUnit`** — `vehicle_form_screen.dart:146` sends `fuelType: null` / `distanceUnit: null` unconditionally in the PATCH body. Editing only the year wipes a previously set fuel type on the server. Omit untouched/null fields from the PATCH payload.
2. **Document upload can't pick PDFs** — `document_upload_screen.dart:45` uses `ImagePicker.pickImage()` only. Insurance/registration PDFs — the primary document use case — can't be uploaded. Use `file_picker` (flag: new dependency) or at minimum add camera + document sources.
3. **Maintenance records can't be deleted from the vehicle detail flow** — no delete in `_MaintenanceTile` (`vehicle_detail_screen.dart:724-758`) or `MaintenanceFormScreen`. Only path is swipe in the Expenses tab. Violates the D4 contract and the project convention (delete lives on detail/view screens).
4. **Maintenance form hardcodes `currency: 'USD'`** — `maintenance_form_screen.dart:52,105-107` sends USD (free-text field) instead of omitting currency so the backend fills from user prefs (as the fuel form correctly does). Non-USD users silently log wrong-currency expenses, which also corrupts the Expenses tab total (mixed-currency sum at `expense_history_screen.dart:53-56`).

### 2.2 Medium
5. **Edit-vehicle navigation uses `context.go`** (`vehicle_detail_screen.dart:93`) — replaces the stack; Back returns to the garage list, not the detail screen. Use `context.push`.
6. **Vehicle delete bypasses `VehiclesNotifier`** (`vehicle_detail_screen.dart:78-79`) — calls the repository directly, so the garage list state isn't updated; relies on a refetch flash.
7. **Dashboard renewal rows** (`dashboard_screen.dart:489,529`) — show `vehicleId.substring(0,8)` and have no `onTap`. Spec: show vehicle name, deep-link to that vehicle.
8. **Liters validator accepts 0/negative** (`fuel_log_form_screen.dart:465`) — backend rejects with 422 but client should validate `> 0` before the round-trip.
9. **Google logo loaded from Wikimedia URL** (`login_screen.dart:283`) — fails offline/blocked networks; bundle as an asset.

### 2.3 Low
10. Distance unit hardcoded: `userUnit: 'km'` on detail hero stats (`vehicle_detail_screen.dart:229`) and "Odometer (km)" label in the maintenance form (`maintenance_form_screen.dart:214`) — both ignore the user's preference.
11. Dashboard progress ring `_maxCents` hardcoded (`dashboard_screen.dart:260`) — ring is pegged full for normal spend levels.
12. No release-build guard that `API_BASE_URL` was provided (`app_config.dart:8`) — silently hits localhost.
13. Raw `FirebaseAuthException` strings shown to users (`login_screen.dart:44`); no show-password toggle; no resend cooldown on verify-email.
14. `fuelVariant` exists in Doc 3 but was dropped from the mobile model/form (commit `641d8db`) — update Doc 3 or restore the field so docs stay the source of truth.

---

## 3. Spec/contract deviations (not bugs, but drift)

1. **Shell: 4 tabs vs spec's 3** (Garage · Home · Profile). Expenses and Settings tabs are additions; decide and update Doc 6, or fold Expenses into the dashboard.
2. **`/profile/edit` modal missing** — `displayName`/`photoUrl` cannot be updated even though `PATCH /me` supports them.
3. **Vehicle form omits spec fields** — VIN, purchase date, purchase price, currency (Doc 6 lists them). Consequence: `totalOwnershipCostCents` on the dashboard is always understated because purchase price can never be entered. (Counterpoint: fewer fields = less friction — recommend an optional collapsed "Purchase details" section.)
4. **Forms pushed via `MaterialPageRoute`** (fuel/maintenance/document) instead of go_router routes — inconsistent back behaviour, no deep-linking.
5. **Performance:** `VehicleCard` mounts 4 provider fetches per card (40 calls for 10 vehicles); `allExpensesProvider` is N+1 (2 calls per vehicle per Expenses-tab visit). Needs batching/caching before the garage grows.
6. Cloudinary folder hardcoded to `'vehicles'` vs Doc 3's `vehicles/{id}/...` example — cosmetic.

---

## 4. UX: "driver shouldn't fill in a load of information"

### Form friction ranking (worst first)
| Form | Required entries per use | Frequency | Verdict |
|---|---|---|---|
| Fuel log | ~4 (vehicle, liters, **odometer typed every time**, price usually prefilled) | Every fill-up | **Highest friction** |
| Maintenance | 2 (service type freetext, + silent currency fix) | Monthly | Medium |
| Document upload | 3 (file, type, title) — no camera, no PDFs | Rare | Medium-low |
| Vehicle | 2 (make, model) | Once | Low — already good |

Logging fuel from a cold app open is currently **5+ interactions**; target ≤3.

### Prioritized UX improvements
1. **Pre-fill odometer in the fuel form** — not just a hint; populate with last reading (optionally + typical fill-to-fill delta). Single biggest win. `fuel_log_form_screen.dart` (`_applyAddDefaults`).
2. **Auto-select the vehicle when the user has exactly one** (dashboard quick action → fuel form). `dashboard_screen.dart`, `fuel_log_form_screen.dart`.
3. **Maintenance currency from user prefs / omit from payload** (bug §2.1.4).
4. **Tappable renewal rows with vehicle names** → deep-link to the vehicle. `dashboard_screen.dart`.
5. **Fix edit-vehicle back navigation** (`context.push`). `vehicle_detail_screen.dart`.
6. **Service-type suggestions** (chips: Oil Change, Tyres, Brakes, Air Filter…) instead of pure freetext. `maintenance_form_screen.dart`.
7. **Camera + file (PDF) sources for documents**; auto-suggest title from docType. `document_upload_screen.dart`.
8. **Migrate form pushes to go_router** for consistent back/deep-link behaviour.
9. **Friendly auth error messages** + show-password toggle. `login_screen.dart`.
10. **Decide the tab structure** (3 vs 4) and update Doc 6 to match reality.

---

## 5. Test gaps (by priority)

- No widget tests for any form screen: `VehicleFormScreen`, `FuelLogFormScreen`, `MaintenanceFormScreen`, `DocumentUploadScreen` — these are where the §2 bugs live (null-clobber PATCH, currency hardcode, liters validation), and none has a regression test.
- No repository tests for documents/upload (`DocumentRepository`, both `UploadRepository`s) or `UserRepository.updatePreferences`.
- `ApiClient`: no test that the `Authorization: Bearer` header is actually attached; no network-error path test.
- `AuthRepository` real paths (email sign-in, Google, sign-out) untested.
- Garage error state, vehicle-detail delete confirmation, verify-email flow untested.

---

## 6. UI redesign track *(added 2026-06-12)*

Decisions from the product owner:
- **The tab system stays as-is** (4 tabs, floating dark pill bar). Everything else may be redesigned.
- **The HTML mockup is direction, not a pixel spec.** The design *language* is binding — yellow `#FFD600` accent, dark `#1E1D2B` cards, light `#EBEBF0` background, soft shadows, pill buttons, caps-muted section labels — but we may design better than the mockup where UX wins (e.g. keep the dashboard quick-action the mockup lacks).

Visual audit (current screenshots vs `docs/design-references/`) found the coded `AppColors` already match the spec exactly; the gaps are in application, not tokens.

### 6.1 Theme-level fixes (one file, lifts every screen)
`mobile/lib/core/theme/app_theme.dart`:
- **Card shadows render as nothing** — `elevation: 0` + shadowColor is a no-op in Material 3. Apply the soft shadow (`0 4px 14px rgba(20,20,40,0.06)`) via theme or a shared card decoration.
- **Save buttons → true pills** (`StadiumBorder`), affecting every form AppBar.
- Add missing tokens: dashed-border grey `#C2C4CF`, dark-card gradient `#23232E → #15151C`, warm photo-upload tint (light yellow).

### 6.2 Component redesigns (by visual impact)
1. **Garage vehicle card** — photo should overflow above the card's top edge (Stack, negative offset) instead of sitting inset; apply the dark gradient. Most distinctive element of the design language; most-visited screen.
2. **"Add Vehicle" card** — currently a solid yellow pill; redesign as the dashed-border light card (`#FAFAFB` fill, dashed `#C2C4CF`, yellow `+ Add Vehicle` text). Also closes the D1a spec gap from §1.
3. **Dashboard hero** — progress ring is a hollow circle; make it a real filled progress arc with the percentage inside (CustomPaint), and fix the hardcoded `_maxCents` (§2.3) so the ring means something — e.g. ring = month-vs-budget or month-vs-average, our call since the mockup isn't binding.
4. **Dashboard renewals section** — bottom of Home is empty; add the upcoming-renewals card (with vehicle names + tap-to-vehicle, merging §2.2.7). This is the redesign item with the most functional value.
5. **Vehicle detail polish** — demote the heavy white "Fuel type" card to a subtle info row; "Full" chip → filled `successBg`/`success` pill; verify hero stat typography (8px caps muted labels / 11px w700 values).
6. **Bottom sheets** — divider-separated rows, rounded top corners on the vehicle picker; tighten currency symbol column.
7. **Add Vehicle form** — photo-upload zone grey → light yellow tint (already a learned preference; one-line fix).

### 6.3 Already correct — do not touch
Floating tab bar, color tokens, form AppBar pattern (Cancel/centered title/pill Save), dark vehicle-card base + `DETAILS →` link + 4-stat row, Full-tank-on-liters-row, segmented unit control, red sign-out + confirmation sheet, currency picker highlight.

---

## 7. Updated fix batches

1. **Batch A — correctness (do first):** §2.1 items 1–4 + liters validation. Small, isolated; Sonnet subagents per item, form widget tests as regression cover.
2. **Batch B — theme + high-impact redesign:** §6.1 theme fixes, then garage card photo-overflow, dashed Add Vehicle card, dashboard progress ring + renewals section (absorbs §2.2.7 tappable renewals and §2.3 `_maxCents`).
3. **Batch C — quick-entry UX:** odometer prefill, single-vehicle auto-select, service-type chips, doc title suggestion, camera + PDF picker.
4. **Batch D — navigation + polish:** `context.push` fixes, go_router form routes, `/profile/edit`, §6.2 items 5–7 (detail polish, bottom sheets, upload tint).
5. **Batch E — hardening:** provider fan-out/N+1 batching, API_BASE_URL guard, friendly auth errors, doc updates (`fuelVariant`, Doc 6 to reflect kept 4-tab structure).
