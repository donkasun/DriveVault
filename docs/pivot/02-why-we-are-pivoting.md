# DriveVault — Why We Are Pivoting

> Decision recorded 2026-06-25.

## The competitive reality

A competitor (**CRLO**, crlo.cc) already ships a polished, free-with-IAP vehicle logbook on both stores:
- Fuel logs, service history, reminders, document vault, shared garages
- Offline-first (works without internet)
- Free base tier with in-app purchases for premium features
- Actively maintained and positioned for general car owners

CRLO has a head start on table-stakes logbook features. Building the same thing and shipping later is not a viable path.

## CRLO's deliberate blind spots

CRLO's own positioning reveals what it refuses to be:
- **"Made for the pump, not the desk"** — explicitly rejects power users and enthusiasts
- **"Deliberately unglamorous"** — no aspiration, no identity, just record-keeping
- **Global product** — cannot model Sri Lanka–specific compliance rules, penalties, or renewal processes
- No shareable car profiles, no build/mod log, no enthusiast community hooks

These are not gaps CRLO missed by accident — they are strategic choices. That means they are durable openings.

## The Sri Lanka timing window

2025–2026 is a once-in-a-decade inflection for the SL vehicle market:
- **Vehicle import ban lifted February 2025** after 5 years — imports projected >$1B/yr
- **New vehicle wave:** Euro 6 / ABS / ESC mandates for 2026, EV tax-relief incentives
- **Compliance pressure increasing:** late revenue-licence penalties of 10% / 20% / 30% for 3mo / 3–12mo / 12mo+ overdue; no app aggregates or reminds for this
- First-time car buyers entering the market need guidance on compliance — opportunity to be the default app they install

## Why not just compete on the logbook?

| Factor | DriveVault (today) | CRLO |
|--------|-------------------|------|
| Launch timing | Behind | Shipped |
| Offline support | Not built | Yes |
| Feature breadth | Phase 1 complete | More complete |
| SL-specific rules | Partially built | None |
| Enthusiast angle | Not built | Refused |
| Monetization | None | IAPs live |

Competing feature-for-feature on a logbook is a slow, resource-intensive race against a product that already ships. The alternative is to compete where CRLO cannot or will not go.

## The pivot thesis

**Don't out-logbook CRLO. Win the segment they refuse and the market they can't serve.**

1. **Enthusiast garage** — build the product for car enthusiasts, not just car owners. CRLO says "unglamorous"; DriveVault says "your car deserves a proper profile." This wins a passionate, vocal minority who drive word-of-mouth.

2. **Sri Lanka compliance guardian** — build the app that knows SL renewal dates, penalties, and aggregates every document + credential expiry in one place. CRLO is global and structurally cannot do this. This wins the mass market with obvious, daily-relevant value.

The two pivots are complementary: enthusiast garage drives acquisition and viral loops; compliance guardian drives retention and monetization.

## What was considered and dropped

**EV ownership companion** was researched and rejected (2026-06-25):
- The car itself (and OEM apps) already tracks charging stats automatically
- Manual charge logging is redundant and high-friction
- The only defensible sliver (LKR running-cost calculations via CEB tariffs) is a thin optional feature, not a pillar
- See `docs/ev-sri-lanka-landscape.md` for the full research archive
