# DriveVault — UI & Screens (Phase 1)

> The UI counterpart to the API contract. Defines the **navigation architecture**, the
> **screen inventory**, and **what data/actions each screen has**. Visual layouts (the
> arrangement of elements on each screen) are added from hand-drawn sketches — those sections
> are marked **🎨 Layout: from sketch**.
>
> Data on every screen maps to `03-api-contract.md`. Build per `04-phase1-tasks.md` (C/D tasks).

---

## 1. Principles
- **Only repositories call the API**; providers expose state; widgets render it (per `CLAUDE.md`).
- **Three bottom tabs**, each its own navigation stack. Auth lives above the tabs.
- **One consistent form pattern:** every create/edit is a **full-screen modal dialog** with
  **Cancel / Save** in the top bar.
- Every list/detail screen handles four **states**: loading · empty · error · loaded.

### Design language
See [`design-references/`](./design-references/) — `mockup-screens.html` is the agreed
baseline and `DESIGN-LANGUAGE.md`/`README.md` define the palette and components. In short:
light background, white soft-rounded cards, **green primary accent** (`#16a34a`), amber link
accent, **dark vehicle cards** (photo overlapping the top + stat row), **floating dark pill
tab bar** (active tab = white circle + colored icon), green progress rings + mini sparklines.

---

## 2. Navigation architecture

### Top level (no tab bar)
```
/splash            decides auth state → /login, /verify-email, or /home
/login
/signup
/forgot-password
/verify-email      email/password users only, until Firebase email is verified
```
Verified auth success → enter the shell (tabs appear). Unverified email/password sign-up
→ `/verify-email` (stay signed in). Sign-out → back to `/login`.

### Shell — StatefulShellRoute with 4 branches
```
🚗 GARAGE branch
/garage                            Vehicles list
  /garage/vehicle/:id              Vehicle detail (one scrolling page)

  Modals (full-screen dialogs presented over the Garage stack):
    Add / Edit Vehicle
    Add / Edit Fuel log
    Add / Edit Maintenance
    Add / Upload Document
    Document viewer

🏠 HOME branch  (default landing tab, center)
/home                              Dashboard (cross-vehicle summary)
  → tapping an item (e.g. a renewal) switches to the Garage branch
    and deep-links to that vehicle's relevant section

💰 EXPENSES branch
/expenses                          Expense history across all vehicles

⚙️ SETTINGS branch
/settings                          Profile / Settings
  /settings/edit                   Edit profile (modal)
```

- **Tabs (left→right):** Garage · **Home** · Expenses · Settings. Home is the default after login.
- Updated 2026-06-12: 4-tab shell approved (Expenses tab added; Profile renamed Settings).
- **Forms = full-screen modal dialogs** (`fullscreenDialog: true`), Cancel/Save app bar.
- **Cross-tab deep-link:** Home never duplicates vehicle screens — it switches to the Garage
  branch (`goBranch`) and navigates there.

---

## 3. Screen inventory

| Area | Screen | Route / presentation |
|---|---|---|
| Auth | Splash | `/splash` |
| Auth | Login | `/login` |
| Auth | Sign-up | `/signup` |
| Auth | Forgot password | `/forgot-password` |
| Auth | Verify email | `/verify-email` |
| Garage | Vehicles list | `/garage` |
| Garage | Vehicle detail | `/garage/vehicle/:id` |
| Garage | Add/Edit Vehicle | modal |
| Garage | Add/Edit Fuel log | modal |
| Garage | Add/Edit Maintenance | modal |
| Garage | Add/Upload Document | modal |
| Garage | Document viewer | modal/route |
| Home | Dashboard | `/home` |
| Profile | Profile / Settings | `/profile` |
| Profile | Edit profile | modal |

---

## 4. Per-screen detail (data + actions + states)

> 🎨 **Layout: from sketch** — the visual arrangement for each screen is filled in from the
> hand-drawn designs. The **data** and **actions** below are locked.

### Auth — Login
- **Data:** none (entry screen).
- **Fields/actions:** email, password → Sign in · "Continue with Google" · "Sign in with
  Apple" · Forgot-password link · Create-account link.
- **States:** idle · submitting · error (invalid credentials).

### Auth — Sign-up
- **Fields:** email, password, (display name — optional), social buttons, back-to-login link.
- **States:** idle · submitting · error.
- **On success:** sends Firebase verification email → redirects to `/verify-email` (not `/home`).

### Auth — Verify email
- **Data:** signed-in user's email address.
- **Actions:** "I've verified" (reload user + re-check) · Resend email · Sign out.
- **States:** idle · checking · resending · message (sent / not verified yet / error).
- **Gate:** Google/Apple users bypass; only email/password accounts see this screen.

### Auth — Forgot password
- **Fields:** email → send reset. **States:** idle · sent · error.

### Garage — Vehicles list  (`GET /vehicles`)
- **Data per vehicle:** photo, make + model + year, current mileage, (optional quick stat).
- **Actions:** tap → vehicle detail · "+ Add vehicle" (modal).
- **States:** loading · **empty** ("Add your first vehicle") · error · loaded list.
- 🎨 **Layout (locked):** header "Your **Garage**" + avatar. A vertical list of **dark
  vehicle cards** — each with the vehicle **photo overlapping the top-right**, name + year ·
  registration, amber **"DETAILS →"**, and a bottom **stat row: Mileage · Economy · Spent ·
  Docs**. A **dashed "＋ Add Vehicle" card** closes the list. Floating tab bar (Garage active).

### Garage — Vehicle detail  (one scrolling page, `GET /vehicles/:id`)
Sections top-to-bottom:
- **Header:** photo, make/model/year, mileage, registration · edit · delete (confirm).
- **Overview:** total spent, avg fuel economy, last service, # documents.
- **Fuel** (`/fuel-logs` + `/fuel-stats`): stats card (L/100km, cost/km, monthly spend) +
  recent logs · "+ Add fuel".
- **Maintenance** (`/maintenance`): recent service records (date, type, cost, workshop) ·
  "+ Add service".
- **Documents** (`/documents`): documents grouped by type with expiry badges · "+ Upload".
- **States:** loading · loaded; each section has its own empty state.
- 🎨 **Layout (locked):** back-to-Garage + vehicle name. A **dark photo hero** (vehicle photo
  + the Mileage/Economy/Spent/Docs stat row). Then scrolling sections — **Fuel** (economy value
  + sparkline card), **Service** (recent rows), **Documents** (rows with expiry pills) — each
  with a green **"＋ Add / Upload"** on its section header. Floating tab bar stays visible.

### Garage — Add/Edit Vehicle (modal)
- **Fields:** make*, model*, year, registrationNumber, vin, purchaseDate, purchasePriceCents,
  currency, currentMileage, vehicleType, photo (upload → Cloudinary).  (* required)
- **Actions:** Cancel · Save (`POST`/`PATCH /vehicles`).

### Garage — Add/Edit Fuel log (modal)  — `POST/PATCH fuel-logs`
- **Fields:** date*, liters*, priceCents*, odometer*, isFullTank, notes.

### Garage — Add/Edit Maintenance (modal)  — `POST/PATCH maintenance`
- **Fields:** date*, serviceType*, odometer, category, costCents, currency, workshop, notes.

### Garage — Add/Upload Document (modal)  — Cloudinary + `POST documents`
- **Fields:** file/photo picker, docType*, title*, issueDate, expiryDate.
- **Flow:** pick → upload to Cloudinary (signed) → save metadata.

### Garage — Document viewer
- **Data:** opens the image/PDF from `storage_url`.

### Home — Dashboard  (`GET /dashboard`)
- **Data:** total ownership cost · this month's fuel spend · cost breakdown (fuel /
  maintenance / purchase) · upcoming renewals (document expiries).
- **Actions:** tap a renewal/item → switch to Garage branch, deep-link to that vehicle.
- **States:** loading · empty (no vehicles yet → prompt to add) · error · loaded.
- 🎨 **Layout (locked):** greeting + avatar. A **Total Ownership Cost** card with a **green
  progress ring** (becomes Health Score in Phase 5) and a **fuel-trend sparkline**. A row of
  two stat cards (**Fuel · this month**, **Maintenance**). Then **Upcoming renewals** rows with
  colored expiry pills. Floating tab bar (Home active, default landing tab).

### Profile / Settings  (`GET /me`)
- **Data:** display name, email, avatar.
- **Actions:** edit profile (modal, `PATCH /me`) · (default currency?) · **Sign out** → `/login`.

---

## 5. Shared components (build once, reuse)
- **VehicleCard** — used in the Vehicles list (and possibly dashboard).
- **StatCard** — labelled metric tile (dashboard + vehicle overview + fuel stats).
- **EntryListTile** — a fuel/service/document row.
- **EmptyState** — icon + message + optional action, for all empty lists.
- **AppForm field set** — consistent text/number/date/picker fields for all modal forms.
- **MoneyText / MileageText** — format cents→currency and km consistently.

---

## 6. UI state convention (every async screen)
1. **Loading** — spinner / skeleton.
2. **Empty** — friendly prompt + primary action.
3. **Error** — message + retry.
4. **Loaded** — the content.

---

## Open / deferred
- Default **currency** handling (app-wide vs per-record) — schema stores per record; UI default TBD.
- Apple sign-in — enabled later (needs Apple Developer setup).
- 🎨 **Layouts locked** for the three core screens (Home, Garage, Vehicle detail). Auth,
  modal forms, and Profile follow the same design language (`design-references/`) — detailed
  layouts can be refined when those screens are built.
