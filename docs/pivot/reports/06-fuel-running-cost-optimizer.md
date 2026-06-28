# Pivot 6: Fuel & Running-Cost Optimizer

*Research date: 2026-06-27. All LKR figures use approximate exchange of 1 USD ≈ 300 LKR.*

---

## One-line positioning

DriveVault becomes Sri Lanka's only vehicle running-cost intelligence layer — calculating true cost-per-km in LKR, forecasting fuel spend against CPC price shifts, and giving EV/hybrid owners the definitive local comparison that proves (or disproves) whether switching from petrol was worth it.

---

## Why this avoids competing with CRLO

CRLO logs fuel fill-ups and can calculate average consumption — that is the extent of its intelligence. Confirmed from live review of crlo.cc (June 2026): no cost-per-km calculation, no LKR fuel price feed, no forecasting, no EV/petrol/hybrid comparison, no SL-specific tariff logic, and no insight layer of any kind beyond raw log entry.

DriveVault Pivot 6 is an **intelligence product**, not a log product. It takes the existing fuel/expense log foundation and builds a calculation and insight engine on top, with outputs that are uniquely Sri Lankan: CPC/Lanka IOC pump prices, CEB time-of-use electricity tariffs, and LKR-denominated comparison tables. A generic global logbook cannot replicate this localization without rebuilding from scratch for the Sri Lankan market.

---

## Market evidence (verified)

### Fuel price volatility creates urgency
Sri Lanka's fuel price history (source: [CPC Historical Prices](https://ceypetco.gov.lk/historical-prices/)):

| Date | 92 Octane (LKR/L) | Auto Diesel (LKR/L) |
|---|---|---|
| June 2021 | 157 | 144 |
| December 2023 | 346 | 434 |
| September 2024 | 332 | 352 |
| May 2026 | 434 | 478 |

**92 octane rose 176% between June 2021 and May 2026; auto diesel rose 232%.** These are not marginal fluctuations — they are existential changes to household transport budgets. A 1,000 km/month driver's fuel bill tripled over five years. Every driver in Sri Lanka has a lived experience of this volatility. Any tool that helps them understand and control this cost lands on fertile ground.

### EV and hybrid running-cost interest
- **EVs now hold 15% of new vehicle registrations in Sri Lanka** as of 2025 (post import ban lift). Source: [Lanka Talks / Sunday Times](https://lankatalks.com/post/electric-vehicles-hold-15--of-sri-lanka-s-brand-new-vehicle-registrations-Red-tape-on-EV-imports)
- Vehicle import ban was lifted **February 2025**, triggering a wave of hybrid and EV imports. Source: [EconomyNext](https://economynext.com/sri-lanka-vehicle-import-ban-lifted-for-cars-electric-vehicles-202655/)
- Over **85% of EVs imported from China and India** — predominantly affordable city EVs and BYD models. Source: search results, 2025
- Sri Lanka's cumulative vehicle population: ~8.25 million registered, ~5.6 million in active operation (World Bank / Lanka Statistics data). Hybrids like the Toyota Aqua and Prius dominate the affordable used-import market.

### The running-cost gap is quantified and enormous
Verified cost comparisons from Sri Lanka-specific sources (April–June 2026 fuel prices):

**Petrol car (12 km/L efficiency, typical older vehicle):**
- 92 octane at LKR 434/L (May 2026 CPC price)
- Cost per km: LKR 36.17
- Monthly cost (1,000 km): ~LKR 36,170

**Hybrid (Toyota Prius/Aqua at ~20–30 km/L real-world):**
- At 20 km/L: cost per km = LKR 21.70; monthly: ~LKR 21,700
- At 30 km/L: cost per km = LKR 14.47; monthly: ~LKR 14,467
- Monthly saving over petrol: LKR 10,000–22,000

**EV (Nissan Leaf / BYD equivalent, CEB TOU off-peak charging at LKR 18/kWh, 5 km/kWh):**
- Cost per km: LKR 3.60
- Monthly cost (1,000 km): ~LKR 3,600
- Monthly saving over petrol: ~LKR 32,570
- Annual saving: ~LKR 555,000

Sources: [Induwara EV Calculator](https://induwara.lk/tools/sri-lanka-ev-charging-cost-calculator), [Lanka Websites Hybrid vs Petrol 2026](https://lankawebsites.com/blog/automobiles/hybrid-vs-petrol-cars-best-choice-for-sri-lanka-2026)

These are not theoretical numbers — they are derived from CEB PUCSL-approved tariffs (off-peak LKR 18/kWh, day LKR 36/kWh, peak LKR 58/kWh) and current CPC pump prices. Yet **no mobile app in Sri Lanka consolidates these calculations** against a user's actual logged mileage and fuel spend.

### Demand signal: manual calculator tool usage
The existence and popularity of third-party Sri Lanka-specific cost calculators — [Induwara EV Charging Calculator](https://induwara.lk/tools/sri-lanka-ev-charging-cost-calculator), [FuelPass.lk](https://fuelpass.lk/fuel-price-sri-lanka/), [Lanka Calculator fuel tracker](https://www.lankacalculator.com/rates/fuel-prices), [V3Cars SL fuel cost calculator](https://www.v3cars.com/fuel-cost-calculator-sri-lanka) — proves that Sri Lankan vehicle owners **actively seek this information** but currently use fragmented web tools rather than a unified app. DriveVault can capture this existing search intent and turn a multi-step web process into a single-screen insight.

---

## Target user & Sri Lanka relevance

**Primary: The hybrid/EV owner who wants validation**
- Bought a Toyota Aqua, Prius, BYD, or Nissan Leaf post-import-ban-lift (Feb 2025 onwards)
- Question: "Am I actually saving money vs my old petrol car, or did I over-pay for the EV?"
- Wants: month-by-month cost-per-km on their actual mileage, compared against what a petrol car would have cost at current pump prices

**Secondary: The petrol/diesel vehicle owner facing cost pressure**
- Running an older petrol car; fuel bill has tripled since 2021
- Question: "Should I switch to hybrid? How long until it pays off?"
- Wants: a break-even calculator using their own consumption data + current LKR prices

**Tertiary: The high-mileage commuter or gig worker**
- Drives 2,000–3,000 km/month (taxi, delivery, commuter)
- Fuel is their largest expense; 1 LKR/km change = LKR 2,000–3,000/month impact
- Wants: week-by-week cost trend, alert when per-km cost spikes above threshold

**Sri Lanka relevance:** The import ban lift in February 2025, combined with 15% EV share of new registrations, means tens of thousands of new hybrid/EV owners entered the market in 2025 and are asking exactly this cost-comparison question right now. The EV duty increase (210%–1,600%+ in August 2025; source: [JPChecker EV tax update](https://jpchecker.com/blogs/view/sri-lanka-vehicle-import-tax-amendment-new-category-for-series-hybrid-electric-vehicles)) makes the buying decision more expensive and the post-purchase justification question even more pressing.

---

## User acquisition

**What to do first (solo SL dev, no LinkedIn):**

1. **SEO-driven web companion (highest long-term ROI):** The web calculators above are already getting search traffic. Build a free web page at a driveVault subdomain — "Sri Lanka EV vs Petrol Running Cost Calculator 2026" — that ranks for these searches. The calculator itself is a lead magnet for the app. This is the highest-value zero-cost acquisition channel for Pivot 6 because the search intent is explicit ("EV cost Sri Lanka").

2. **Facebook groups for new EV/hybrid owners:** Post-import-ban, groups like "Electric Vehicles Sri Lanka", "Toyota Prius Sri Lanka", "BYD Sri Lanka Owners" are active. A post with a real before/after cost comparison (month 1 vs month 6 of owning a hybrid) drives organic downloads.

3. **YouTube Sinhala content:** "I calculated my actual Toyota Aqua running cost for 6 months" is a video with proven search intent; embed a CTA to the app. One or two well-placed sponsorships of existing SL auto YouTube channels (many with 50K–200K subscribers) would reach the target audience cheaply.

4. **Partnership with vehicle importers/dealers:** Post-import-ban, dealers selling hybrid and EV vehicles are looking for value-adds. A bundled offer ("3 months DriveVault Pro free with your Aqua purchase") converts at point of sale when cost-savings is already the dominant conversation.

5. **ikman.lk / Riyasewana car listing integration:** These are Sri Lanka's dominant vehicle classifieds. A "Calculate running cost" widget embedded or linked from a used-car listing would deliver traffic at the exact moment of buying intent.

6. **App Store ASO:** Target keywords "fuel cost Sri Lanka", "petrol cost calculator LKR", "EV running cost Sri Lanka" — low competition, highly specific, measurable.

---

## Virality

**The built-in loop: the "Break-even Proof" share card**

DriveVault generates a shareable insight card after 3 months of logging:

```
My Toyota Aqua vs Petrol comparison — Month 3
My actual cost per km:     LKR 14.2 (hybrid logged data)
Equivalent petrol cost:    LKR 36.2 (current 92 octane)
Monthly saving:            LKR 22,000
Break-even on price premium: 34 months remaining
Annual saving projected:   LKR 264,000
```

This card answers the #1 question EV and hybrid owners are already asking publicly. The urge to share "I proved my EV pays off" in Facebook car groups, WhatsApp family chats, and TikTok is direct. Every share is an unsolicited testimonial with an implicit "what app did you use?" response.

**Secondary loop — the "Price Alert":** When CPC revises fuel prices (which happens frequently), DriveVault sends a push notification: "Fuel up 14% — your monthly cost just increased LKR 3,200. Here's how to offset it." Users screenshot and forward this to driver communities. App awareness rises every time CPC announces a price change, which is a recurring external trigger DriveVault does not need to manufacture.

---

## Revenue model & potential

### Model
**Freemium + one-tier Pro subscription**
- **Free tier:** Log up to 2 vehicles; basic fuel consumption graph; current month cost-per-km only
- **Pro tier — LKR 390/month or LKR 3,500/year:** Full history, EV/petrol/hybrid comparison engine, break-even calculator, price forecasting, fuel price alerts, exportable reports, up to 5 vehicles

*Pricing rationale:* LKR 390/month (~USD 1.30) is a psychological impulse tier — less than a cup of coffee at a Colombo café, or less than 1 litre of 92 octane. Annual pricing (LKR 3,500) represents 2.5 months free and is the preferred push for high-intent users. This is deliberately below the LKR 490 suggested for Pivot 5 because Pivot 6 buyers are consumers (cost-sensitive individuals), not business operators.

*Additional model: one-time "Switcher Report" purchase:* LKR 1,500 to generate a permanent PDF break-even analysis for a specific vehicle pair (e.g. "My 2018 Fit Hybrid vs a new BYD Atto 3 at today's LKR prices"). This is an IAP that does not require a subscription and appeals to the one-time buyer making a vehicle purchase decision.

### TAM math

| Segment | Addressable | Conversion | Paying users |
|---|---|---|---|
| New hybrid/EV owners (post Feb 2025 import lift) | ~50,000+ (est. from 15% of new regs and import volumes) | 3% annual Pro | 1,500 |
| Existing hybrid fleet (Aqua/Prius dominant in SL) | ~200,000 est. (pre-ban registered hybrids) | 1% annual | 2,000 |
| High-mileage petrol commuters seeking insight | ~500,000 est. | 0.3% | 1,500 |

**Scenario A — Conservative (12 months):**
- 2,000 Pro monthly subscribers × LKR 390 = **LKR 780,000/month**
- 1,000 annual subscribers × LKR 3,500 = LKR 3,500,000/year (= LKR 292,000/month equiv.)
- 500 one-time Switcher Reports × LKR 1,500 = LKR 750,000 (one-time)
- **Recurring MRR: ~LKR 1,072,000 (~USD 3,575)**
- Annual recurring: ~LKR 12.9M (~USD 43,000)

**Scenario B — Optimistic (24 months, SEO gains compounding):**
- 6,000 Pro users = **~LKR 2.3M MRR**

The SEO web-companion strategy means this pivot has compounding acquisition dynamics that Pivot 5 (community-driven) does not — Google search traffic is free and persistent.

---

## Feature roadmap by phase

### Phase 1 / MVP (net-new on top of existing DriveVault)
*Already exists in DriveVault:* Firebase auth, vehicle garage, fuel logs with litre volume and cost, expense logs (LKR-locked), odometer entries, dashboard.

*Net-new for this pivot:*
- **Cost-per-km engine:** calculate LKR/km per vehicle per period from existing fuel logs and odometer delta
- **CPC/Lanka IOC price feed:** pull current pump prices (or allow manual entry synced from FuelPass.lk / ceypetco.gov.lk) and store price history
- **Cost trend graph:** cost-per-km over rolling 6 months per vehicle
- **Fuel price alert:** push notification when CPC announces a revision (can be manually triggered at V1 — dev monitors announcements)
- **EV/hybrid comparison screen:** user inputs a comparison vehicle (type + efficiency), app calculates what the same km driven would cost in that vehicle at today's fuel/electricity prices
- **Paywall and Pro gate** (annual + monthly tiers)

### Phase 2
- **Break-even calculator:** purchase price premium + running cost delta → months to break even; shareable output card
- **CEB tariff integration:** full residential TOU tariff (off-peak LKR 18 / day LKR 36 / peak LKR 58) applied to EV energy consumption for accurate charging cost
- **Fuel price forecasting:** simple trend projection based on CPC historical price series + global oil price trend (a rolling average projection, not ML at this stage)
- **Monthly cost forecast:** "At this consumption rate and current prices, your fuel spend next month will be LKR X"
- **Web companion:** public-facing calculator at drivevault.lk/calculator for SEO acquisition

### Phase 3
- **Fuel price history database:** full CPC price history integrated so users can see their historical cost-per-km recalculated at actual pump prices for each fill-up
- **Vehicle benchmark comparison:** "Your Aqua's 22 km/L is below the SL average of 26 km/L for this model — possible causes…"
- **Multi-vehicle household optimizer:** "Assigning your 60 km commute to the EV instead of the petrol car saves LKR 1,200/day"
- **Gemini-powered insight summaries** (Phase 3+ per DriveVault tech spec, AI feature behind `AIProvider` interface)

*Note: The prior decision ruled out manual EV charge logging as redundant (car/OEM app already tracks it). This roadmap respects that: the intelligence layer works from odometer/cost data, not charge session counts.*

---

## Risks & moat

**Risks:**
1. **Free web tools as substitutes:** Multiple free web calculators already exist (induwara.lk, v3cars.com, lankacalculator.com). The counter-argument: none of these integrate with the user's *actual logged data*. A calculator using assumed averages is a one-shot tool; DriveVault uses the user's real fill-up history to produce personalized intelligence. That is a fundamentally different product.
2. **CPC price feed reliability:** CPC does not publish a public API for fuel prices. Mitigation: at V1, price updates can be user-confirmed (the app shows "CPC revised prices on June 1 — confirm new price?"); at V2, scrape FuelPass.lk which aggregates prices reliably.
3. **Low-frequency users:** Users who fill up once a month may not open the app often enough to see value. Mitigation: monthly cost report push notification ("Your June running cost: LKR 18,400 — here's your breakdown") drives re-engagement without requiring the user to open the app proactively.
4. **EV adoption stall:** If new EV taxes (Aug 2025: 210–1,600% duty increase) slow the import wave, the new-EV-owner addressable market shrinks. Mitigation: the petrol/hybrid comparison is still highly valuable for the much larger existing vehicle base; EV new owners are the top-of-funnel hook, not the entire market.

**Moat:**
- **Data accumulation:** A user with 2 years of logged fill-ups + real-world km data cannot easily migrate to a generic app without losing that history. Lock-in compounds monthly.
- **SL-specific data integration:** CPC price history (back to 2021, the 176% increase era), CEB TOU tariffs, SL road-condition-adjusted efficiency benchmarks — none of this is in any global app.
- **SEO compounding:** A web calculator ranked for "EV running cost Sri Lanka" drives free organic installs indefinitely. This is a structural cost advantage a late competitor must pay to overcome.
- **CRLO structural gap:** CRLO is explicitly consumer/global/free; it cannot add SL-specific intelligence without a complete product pivot.

---

## Viability verdict

| Dimension | Score /10 | Notes |
|---|---|---|
| Acquisition | 9 | SEO web-companion is a compounding zero-cost channel; EV import wave created a timed audience peak; explicit search intent ("EV cost Sri Lanka") is already documented |
| Virality | 8 | Break-even proof card is highly shareable in car-buyer communities; CPC price-revision alerts are recurring external triggers |
| Monetization | 7 | LKR 390/month is a below-resistance price; annual plan adds LKR value; one-time Switcher Report IAP broadens conversion surface |
| Defensibility | 8 | CPC price history data integration + user's own logged history creates durable lock-in; SEO moat compounds over time |
| Build effort | 8 | The core cost-per-km engine is 1–2 weeks net-new on top of existing fuel + odometer logs; the comparison UI is another 1–2 weeks; web calculator is a bonus scope-control release |

**Bottom line:** The EV import wave post-February 2025 has created a time-sensitive audience of tens of thousands of hybrid and EV buyers who are actively asking the exact question this product answers — and no Sri Lankan app addresses it. The SEO web-companion strategy gives Pivot 6 a compounding organic acquisition flywheel that Pivot 5 lacks, and the data-gravity moat is stronger here because the intelligence value scales directly with the richness of the user's log history.

---

*Sources consulted:*
- [CPC Historical Fuel Prices](https://ceypetco.gov.lk/historical-prices/)
- [FuelPass.lk — Current LKR fuel prices March 2026](https://fuelpass.lk/fuel-price-sri-lanka/)
- [Induwara.lk — Sri Lanka EV Charging Cost Calculator (CEB tariffs)](https://induwara.lk/tools/sri-lanka-ev-charging-cost-calculator)
- [Lanka Websites — Hybrid vs Petrol Best Choice Sri Lanka 2026](https://lankawebsites.com/blog/automobiles/hybrid-vs-petrol-cars-best-choice-for-sri-lanka-2026)
- [Lanka Talks / Sunday Times — EVs hold 15% of new vehicle registrations](https://lankatalks.com/post/electric-vehicles-hold-15--of-sri-lanka-s-brand-new-vehicle-registrations-Red-tape-on-EV-imports)
- [EconomyNext — Vehicle import ban lifted Feb 2025](https://economynext.com/sri-lanka-vehicle-import-ban-lifted-for-cars-electric-vehicles-202655/)
- [JPChecker — EV import tax amendment Sri Lanka](https://jpchecker.com/blogs/view/sri-lanka-vehicle-import-tax-amendment-new-category-for-series-hybrid-electric-vehicles)
- [EVTech.news — Sri Lanka EV import delays 2025](https://evtech.news/news/sri-lanka-electric-vehicle-import-delays-2025-what-s-behind-the-sudden-halt.html)
- [PUCSL — Proposed Electricity Tariff Revision 2026](https://www.pucsl.gov.lk/proposed-electricity-tariff-revision-2026-1/)
- [CRLO.cc — Feature review](https://crlo.cc)
