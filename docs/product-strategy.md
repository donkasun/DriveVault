# DriveVault — Product Strategy & Pivot Directions

> Context (2026-06-25): A competitor, **CRLO** (crlo.cc, iOS/Android), already ships a clean,
> general-purpose vehicle logbook (fuel, service history, reminders, document vault, shared
> garages). It is free with IAPs, offline-first, and **deliberately positions away from
> enthusiasts** ("made for the pump, not the desk", "deliberately unglamorous").
>
> DriveVault's response is **not** to out-feature a generic logbook. It is to win the segment
> and market CRLO ignores: **car enthusiasts + Sri Lanka–specific value**, launched into a
> once-in-a-decade market inflection (vehicle import ban lifted Feb 2025; imports projected
> >$1B/yr; EV tax-relief wave in 2026).

> **Update 2026-06-25:** The EV companion direction was **dropped**. The car (and its OEM app)
> already tracks charge stats automatically, so a manual EV charge logbook is redundant and
> high-friction. The only defensible sliver (EV *running cost* in LKR via CEB tariffs) is a thin
> optional feature at most, not a pillar. Two pivots remain. See `docs/ev-sri-lanka-landscape.md`
> for the archived EV research and rationale.

## The two chosen directions

### 1. Enthusiast garage (the soul / brand engine)
Build & mod log, project/build timeline per car, and a **shareable public car profile**
("digital spec card"). Turns the same vehicle data CRLO logs as cost into something owners are
proud to show. This is the most viral, most "CRLO would never" feature and drives community
marketing (a car profile *is* the flyer).
- **Differentiation:** Strong. CRLO explicitly refuses the enthusiast segment.
- **Role:** The face of the product; marketing & word-of-mouth engine.
- **Foundation:** Builds on existing vehicles/fuel/expense data.

### 2. Renewal / compliance guardian (the mass hook & monetization)
One place that tracks and reminds **before expiry** for: revenue license, insurance, emission
test, fitness certificate, and driving license/credentials. The government eRevenue portal only
*renews* — nobody aggregates the 3–4 separate dates or warns ahead of the late penalty
(10% / 20% / 30% of annual tax for 3mo / 3–12mo / 12mo+ overdue).
- **Differentiation:** Strong. CRLO is global and can't model SL-specific rules.
- **Role:** The reason every owner (not just enthusiasts) opens the app; the feature with
  obvious dollar value → best candidate for paid tier (penalty avoidance pays for itself).
- **Foundation:** Builds directly on the existing driving-credentials + document-expiry work.

> _(Dropped: EV ownership companion — see update note above.)_

## Stack & positioning
**Lead with (1), monetize/retain with (2).** Enthusiast garage is the brand & word-of-mouth
engine; compliance guardian is the essential daily-use hook and the thing worth paying for.
CRLO cannot assemble this combination — it's global (can't model SL compliance rules) and
deliberately unglamorous (won't build for enthusiasts).

## Local marketing (replaces LinkedIn entirely)
The SL car community is concentrated and organized — target the right rooms, don't broadcast:
- **AutoLanka** forums + Facebook group — the enthusiast hub; members already host project/build
  threads (native fit for the garage profile).
- **Marque clubs** (e.g. Honda Club SL) — club-branded garages / showcases.
- **Car meets & events** — QR "add your car"; the shareable profile is the flyer.
- **Owner buy/sell FB groups + ikman/riyasewana audiences** — for the compliance & resale-history
  angle (mass owners, not just enthusiasts).
- **Instagram / YouTube / TikTok** — garage profiles & build timelines are inherently visual
  content CRLO can't produce.
- **Compliance as viral hook** — "never pay a late revenue-license penalty again" is shareable in
  every owner group with zero enthusiast interest required.

## Biggest risk
Not CRLO — **willingness to pay** (CRLO trains the market to expect free). Mitigation: the
compliance/penalty-avoidance angle (direction 2) is the one feature with obvious cash value;
validate that WTP first.

## Open next step
Lock the single flagship "this is not CRLO" feature (leading candidate: shareable enthusiast
garage profile) and spec its MVP against the existing data model.
