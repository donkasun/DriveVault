# DriveVault — What We Have Now

> Status as of 2026-06-25. Phase 1 (Batch 1) is complete.

## Product

A Flutter (iOS/Android) + FastAPI vehicle management app, built for the Sri Lanka market.

### Completed features
| Feature | What it does |
|---------|-------------|
| **Firebase Auth** | Email/password + Google Sign-In; soft email-verification nudge (banner, not gate) |
| **Vehicles (Garage)** | Add/edit/delete cars; photo upload via Cloudinary; odometer in km |
| **Fuel logs** | Full/partial tank logs; price per litre, total cost in LKR; quick-entry sheet |
| **Expenses** | Categorised expense history; LKR-locked currency |
| **Driving credentials** | Driver's licence, permit, international permit with expiry dates |
| **Document vault** | Vehicle documents (revenue licence, insurance, emission, fitness) with expiry |
| **Expiry reminders** | Dashboard upcoming-renewals widget: shows docs + credentials expiring soon |
| **Dashboard** | Upcoming renewals, fuel stats, recent activity |
| **Profile screen** | Edit profile, driving credentials section, sign-out |

### Stack
- **Mobile:** Flutter 3.44 + Riverpod 3.x + go_router
- **Backend:** FastAPI 0.115 + Python 3.12 + SQLAlchemy 2 + Alembic
- **DB:** PostgreSQL 16 (Neon in prod, Docker locally)
- **Auth:** Firebase Auth + FCM
- **Storage:** Cloudinary (client-side upload, backend stores URL)
- **Hosting:** Google Cloud Run (`--min-instances=0`, always-free tier)

### What is NOT built yet
- Shareable public car profile (enthusiast garage flagship feature)
- Compliance guardian: proactive push notifications before expiry with penalty context
- Build/mod log per vehicle
- Monetization layer (no subscription, no IAP)
- Onboarding flow / new-user empty states

## Monetization
**None.** App is free with no paywall. No subscription, no IAP.

## Marketing reach
**None.** No public launch, no social presence, no user base yet.

## The problem this creates
- CRLO (crlo.cc) already ships a clean, free, offline-first logbook with IAPs on iOS + Android
- DriveVault needs a clear reason to exist alongside CRLO — not just "also a logbook"
- LinkedIn (the founder's primary professional network) is not an available promotion channel
- Without a differentiator, competing on features against a shipped product is a losing race
