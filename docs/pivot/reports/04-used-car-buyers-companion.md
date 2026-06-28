# Pivot 4: Used-Car Buyer's Companion / Pre-Purchase Toolkit

## One-line positioning

A structured pre-purchase toolkit for Sri Lankan used-car buyers — inspection checklist, DMT verification guide, market-price benchmarking, and red-flag detection — turning a high-anxiety LKR 5M+ decision into a confident one.

---

## Why this avoids competing with CRLO

CRLO is a logbook for the current owner: log fuel, record services, set renewal reminders. Its user already owns the car. A buyer — who has not yet purchased — has no use for CRLO. The buyer needs: "Is this specific car worth buying, at this price, from this seller?" That is a completely different job-to-be-done. CRLO structurally cannot serve pre-purchase buyers without becoming a different product. DriveVault's existing DMT-adjacent data model (vehicle registration, credentials, document vault) provides a natural foundation for a buyer-facing verification workflow.

---

## Market evidence (verified)

### The used car market is enormous and growing fast

- **16,434+ active used-car ads on Riyasewana** ([riyasewana.com](https://riyasewana.com/search/cars)) and **8,291+ on ikman** as of mid-2025 ([ikman.lk](https://ikman.lk/en/ads/sri-lanka/cars)) — together over **24,000 listed vehicles** at any point in time.
- ikman July 2025 snapshot: 6,100 active car listings, of which 3,839 (63%) were used. ([blog.ikman.lk](https://blog.ikman.lk/en/sri-lanka-car-market-2025-insights/))
- Market size estimated at **USD 202–283 million in 2025** by multiple research firms. ([mordorintelligence.com](https://www.mordorintelligence.com/industry-reports/sri-lanka-used-car-market), [datainsightsmarket.com](https://www.datainsightsmarket.com/reports/sri-lanka-used-car-market-15212))
- **85.06% of the market is unorganised** — informal cash deals, no standardised inspection, limited consumer protection. ([mordorintelligence.com](https://www.mordorintelligence.com/industry-reports/sri-lanka-used-car-market))

### Import ban lifting created a wave of first-time buyers

- Vehicle registrations jumped from **74,410 in 2024 to 312,317 by November 2025** after the private car import ban was lifted February 1, 2025 — a **4.2× year-on-year increase**. ([adaderana.lk](https://adaderana.lk/news.php?nid=121742))
- Total 2025 vehicle import expenditure: **USD 2.04 billion** — third-highest in history, following USD 2.12B (2015) and USD 2.09B (2018). ([sundaytimes.lk](https://www.sundaytimes.lk/260111/news/revenue-soars-after-sri-lanka-lifts-vehicle-import-ban-627703.html))
- Motor Traffic Department revenue: Rs 64,740mn — **up 111%** year-on-year. ([sundaytimes.lk](https://www.sundaytimes.lk/260111/news/revenue-soars-after-sri-lanka-lifts-vehicle-import-ban-627703.html))
- Many of these 312,317 buyers are first-time or returning buyers who have not bought a car in 5+ years of the import ban — exactly the high-anxiety, information-poor buyer this pivot serves.

### Fraud is systemic and well-documented

- **Over 60% of vehicles on Sri Lankan roads have a hidden history** — CarChecks ([carchecksonline.com](https://carchecksonline.com/)), which positions itself as "Sri Lanka's first and only dedicated vehicle scrutiny center with 14+ years in the industry."
- **5,000+ condemned vehicles re-enter the market annually** in Sri Lanka. ([carchecksonline.com](https://carchecksonline.com/))
- Common frauds: odometer rollback, accident-damage concealment with repaint, "open paper" transactions (seller doesn't actually own the vehicle), flooded vehicles, salvaged vehicles reintroduced after the 2022 economic crisis. ([findus.lk](https://findus.lk/blogs/classified-ad-scams-sri-lanka/))

### Existing inspection market is fragmented and expensive

Professional on-site inspection services that currently fill this gap:

| Service | Basic Package | Standard / Comprehensive |
|---|---|---|
| **Greasemonkey Inspectors** ([greasemonkeyinspectors.lk](https://greasemonkeyinspectors.lk/)) | LKR 8,990 (100 checkpoints, ~30 min) | LKR 11,990 (200 checkpoints, ~60 min) |
| **CarChecks** ([carchecksonline.com](https://carchecksonline.com/)) | LKR 7,500–8,500 (230+ point check) | LKR 18,750 (incl. international history) |
| **Open Bonnet, MyMechanic, Auto Miraj, NextDrive** | Varying, estimated LKR 8,000–15,000 | — |

These services are:
- High-cost relative to digital alternatives (LKR 8K+ per check)
- Geographically constrained (Western Province focus)
- Only booked after a buyer is already close to purchasing
- Not integrated into the browsing/research phase on ikman or riyasewana

There is a clear gap for a **digital pre-filter** — a structured checklist and data-lookup tool a buyer uses while still browsing listings, costing LKR 500–2,500 per check instead of LKR 8,000+.

### DMT and Customs data is partially publicly accessible

- **DMT Online Vehicle Information Service** ([eservices.motortraffic.gov.lk](https://eservices.motortraffic.gov.lk/)) allows lookup of registered vehicle details by registration number + chassis number — for a fee.
- **SMS to 1919** (`V REGNUMBER`) retrieves basic ownership info instantly.
- **Sri Lanka Customs Vehicle Verification Portal** ([services.customs.gov.lk/vehicles](https://services.customs.gov.lk/vehicles)) — verifies import history and customs clearance status.
- Riyasewana has already demonstrated an API integration with DMT to let buyers "instantly authenticate title status," which raised certified listings by a measurable margin — proving both the technical feasibility and the buyer demand. ([mordorintelligence.com](https://www.mordorintelligence.com/industry-reports/sri-lanka-used-car-market))
- No app currently wraps all these sources — DMT + Customs + structured inspection checklist + market price comparison — into a single guided buyer workflow.

### Price range context (used cars in SL)

Used car prices range from LKR 3M (Nissan March K11) to LKR 17.5M+ (Honda Vezel 2023 import). Toyota Premio trades at LKR 10–16.5M; Honda Fit GP5 at LKR 7.35M; Vitz at LKR 8.15M. ([autolanka.com](https://www.autolanka.com/cars.html), [ccarprice.com](https://www.ccarprice.com/lk/)) A LKR 5M–15M purchase with LKR 0 consumer protection is the exact problem this pivot solves.

---

## Target user & Sri Lanka relevance

**Primary user: the anxious first-time or returning buyer** — someone who has saved LKR 8–15M to buy a used car, is browsing ikman and riyasewana, has found 2–3 candidates, and is terrified of buying a condemned or accident-repaired vehicle. They cannot tell a re-painted panel from a genuine one. They want a structured process and something to reassure them (or their spouse) before committing.

**Secondary user: the informed second-hand buyer** — already knows the market, but wants to spend 10 minutes running a quick data check (DMT, Customs, price benchmark) before deciding whether to pay for a full physical inspection.

**Tertiary: the seller wanting a "clean cert"** — a private seller who proactively gets a verification run done on their vehicle to share with prospective buyers and justify the asking price. This reverses the typical buyer-pays model.

Sri Lanka relevance is exceptionally high: the combination of a fragmented, 85%-unorganised used car market, systemic fraud (60% hidden history, 5K condemned vehicles/year), and a 4× surge in buyers post-import-ban is as demand-dense as it gets.

---

## User acquisition

### Primary channel: organic search at the point of need

Buyers searching "how to check a used car in Sri Lanka," "ikman used car scam," "odometer tampering Sri Lanka," or "DMT vehicle check online" have immediate intent. A well-structured blog or landing page ("The Complete Sri Lanka Used Car Buyer's Guide") targeting these queries costs nothing to produce and captures highly qualified traffic. This is the most scalable, zero-cost acquisition channel for a solo developer.

Specific content targets:
- "How to check if a car has been in an accident — Sri Lanka guide"
- "SMS 1919 vehicle check explained"
- "Sri Lanka used car inspection checklist (free download)"

### Secondary channels

1. **ikman and riyasewana contextual placement** — even a comment or post in ikman's buyer blog or community sections (they have a blog at blog.ikman.lk) can drive targeted traffic. Long-term: approach ikman for a "Buyer Protection" partner badge or link — they benefit from trust-building on their platform.
2. **AutoLanka forum "Buying / Selling" section** — buyers routinely ask "how do I check if this car is clean?" A forum signature link and an occasional helpful post ("I built a tool for this") is a legitimate, non-spammy channel.
3. **Facebook Groups for used car buyers** — "Cars for Sale Sri Lanka," "Buy Sell Cars SL" etc. Drop a useful post ("Red flags to check before buying on ikman — free checklist").
4. **Referral partnership with inspection services** — Greasemonkey, CarChecks, Open Bonnet. DriveVault sends qualified, pre-screened buyers (those who passed the digital pre-filter and still want a physical inspection). In return, inspection services promote the app or share a referral code. Neither party competes with the other.
5. **YouTube / TikTok content** ("I checked 5 ikman listings with this tool — 3 had red flags") — a single well-produced video can generate thousands of installs for a high-anxiety topic where viewers actively search for guidance.

### Acquisition economics

All the above channels are zero-cost or near-zero. The target is 500–2,000 monthly active users in year 1 from organic traffic alone. Paid acquisition is not needed at this stage.

---

## Virality

**The shareable buyer's report** is the viral artifact.

1. Buyer runs a vehicle check through DriveVault and gets a structured report: DMT status, customs clearance, mileage cross-reference, market price vs. asking price, checklist score, red flags highlighted.
2. Buyer shares the report via WhatsApp to a spouse/parent/friend before making the decision. The report is branded with DriveVault; the recipient sees "Generated by DriveVault — Sri Lanka's Used Car Buyer's Companion."
3. The recipient — who is likely also in the market for a car or knows someone who is — downloads the app.

**Reverse virality (seller-to-buyer)**: A seller proactively runs a "clean cert" report on their own car and shares it in their ikman/riyasewana listing or WhatsApp to potential buyers. Every buyer who sees a DriveVault report in a seller listing is a potential download. This is powerful because it reaches buyers at the exact moment of maximum purchase intent.

**WhatsApp group loop**: Sri Lankan car buying involves family consultation. A single buyer check shared in a family WhatsApp group can reach 10–20 people. Given the average purchase is LKR 8–15M, all of them pay close attention.

---

## Revenue model & potential

### Model: Freemium per-check + optional subscription

| Tier | What you get | Price |
|---|---|---|
| Free | 3 vehicle checks/month: DMT lookup guide, 50-point checklist, basic market price range | LKR 0 |
| Per-check credit | Full report: DMT status, Customs clearance status, 150-point checklist with scoring, market price benchmark vs. 3 comparable ikman/riyasewana listings, red-flag summary, shareable PDF | LKR 1,500 per check |
| Buyer Pass (30-day) | Unlimited checks for active buyer period | LKR 2,500/month |
| Seller Clean Cert | Structured seller-facing report + shareable badge for listings | LKR 2,000 per vehicle |
| Inspection Partner Referral | DriveVault earns LKR 500–1,000 per referral to Greasemonkey/CarChecks/Open Bonnet | (affiliate revenue) |

### Why LKR 1,500 per check is the right price

Physical inspections cost LKR 8,990–18,750. A buyer typically evaluates 3–6 cars before deciding. Spending LKR 8,990 × 6 = LKR 53,940 to pre-screen all candidates is prohibitive. A LKR 1,500 digital pre-filter to narrow to 1–2 finalists — then spending LKR 9,000 on a physical inspection for the winner — is the rational decision. The app is not competing with inspection services; it is the step before them.

### Rough TAM math

- Monthly used car listing count on ikman + riyasewana: approximately **10,000–16,000 unique vehicles** (conservative, many listings are the same car re-listed).
- Assume buyer-to-listing ratio of 3:1 (multiple buyers browse each listing): approximately **30,000–50,000 active car buyers/month** across SL.
- App reaches 5% of buyers in year 1 (via SEO, forum, FB): **1,500–2,500 monthly active users**.
- Conversion to paid check: 20% of MAU run ≥1 paid check/month (high-intent users): **300–500 paying transactions/month**.
- Average revenue per paying user: LKR 1,500–2,500 per check.
- **Monthly revenue: LKR 450,000–1,250,000 (~USD 1,500–4,100)**.
- **Annual revenue: LKR 5.4M–15M (~USD 17,600–49,000)** in year 1.

This is meaningfully larger than Pivot 3 because the transaction value is higher and purchase frequency is tied to a real high-stakes event (buying a car), not a recurring subscription that people cancel when they forget.

**Seller Clean Cert upside**: If 2% of the 16,000 monthly listings are accompanied by a DriveVault cert (320 certs × LKR 2,000 = LKR 640,000/month), this alone adds LKR 7.7M/year.

**Affiliate referrals**: If 10% of paid-check users go on to book a physical inspection via referral (LKR 750 referral fee average), 300–500 × 10% × 750 = LKR 22,500–37,500/month additional.

**Realistic year-1 total (conservative): LKR 6M–18M**

---

## Feature roadmap by phase

### Phase 1 / MVP (net-new: this pivot has no existing DriveVault features to lean on, but backend patterns apply)

| Feature | Status |
|---|---|
| 150-point pre-purchase inspection checklist (in-app, interactive) | 🆕 Net-new |
| DMT vehicle lookup guide (step-by-step: SMS 1919, eservices portal) | 🆕 Net-new (data entry is manual/guided; no API integration required at MVP) |
| Customs clearance verification guide (services.customs.gov.lk) | 🆕 Net-new |
| Market price benchmarker (user enters car details; app shows scraped/cached median price from comparable ikman/riyasewana ads) | 🆕 Net-new |
| Red-flag scoring summary | 🆕 Net-new |
| Shareable PDF / link report | 🆕 Net-new |
| Per-check credit purchase (LKR 1,500 via payment gateway) | 🆕 Net-new |
| Firebase Auth (login) | ✅ Already built in DriveVault |
| FastAPI + PostgreSQL backend | ✅ Already built |

**Implementation note on DMT API**: At MVP, the app does not need a real DMT API integration. The checklist guides the buyer through the manual steps (SMS 1919, eservices.motortraffic.gov.lk) and lets them enter the result. This sidesteps the API access problem entirely. A real API integration is Phase 2.

### Phase 2

- Direct DMT eservices integration (if API access is available) — auto-populate ownership details
- Sri Lanka Customs portal integration — auto-verify import clearance status
- Saved checks history (for buyers evaluating multiple cars in parallel)
- Seller Clean Cert product — seller runs the check and gets a shareable listing badge
- Inspection partner booking flow (direct booking with Greasemonkey/CarChecks etc. via referral link)
- Price trend graphs per model/year (aggregate ikman/riyasewana data over time)

### Phase 3

- Community / wisdom-of-crowds: "3 other buyers checked this registration in the last 30 days — 2 flagged it" (aggregated, anonymised)
- JEVIC / BM report parsing (imported Japanese cars come with auction sheets; allow buyer to upload and parse key fields)
- Used-car dealer ratings (buyer reviews of specific dealers on ikman/riyasewana)
- Handover to DriveVault owner mode: once purchase is complete, convert the buyer's check into the new owner's DriveVault garage entry (seamless onboarding to Phase 1 features)

---

## Risks & moat

| Risk | Severity | Mitigation |
|---|---|---|
| Cannot access DMT data programmatically at MVP | Medium | Guided manual workflow (SMS 1919, eservices portal) is sufficient for MVP and genuinely useful — buyers often don't know these tools exist. Real integration is Phase 2 once product is proven. |
| Physical inspection services (Greasemonkey, CarChecks) see DriveVault as competition | Low | Positioning is explicitly complementary: DriveVault is the pre-filter; they are the final verification. Approach them for referral partnerships, not competition. |
| ikman/riyasewana build this themselves | Medium | Both platforms are classifieds businesses, not inspection/buyer-protection businesses. Riyasewana has already done DMT integration for listings, but not for buyers. DriveVault is buyer-first; classifieds are seller-first. |
| Price scraping from ikman/riyasewana may break | Low | Market price benchmarking can be maintained manually or updated weekly as a cached dataset. Not a blocking issue at MVP. |
| Trust: buyers need to trust the report | High | Cite all data sources in the report (DMT reference number, Customs portal result, checklist authored by reference to Greasemonkey's 200-point standard). Add a clear disclaimer. Over time, referral to physical inspectors builds credibility. |
| Low repeat purchase frequency | Medium | Each buyer buys 1 car every 5–7 years. Retention comes from: (a) selling the "ongoing ownership" mode (DriveVault Phase 1 features) immediately after purchase; (b) referral / word-of-mouth from satisfied buyers to the next person in their network. |

**Moat sources**: Trust built over time (inspection track record, user reviews, community reputation); data accumulation (aggregated check history per vehicle becomes a crowd-sourced red-flag database); referral network with inspection partners; SEO authority on "used car Sri Lanka" informational queries. None of these are strong moats individually, but collectively they create switching cost.

---

## Viability verdict

| Dimension | Score /10 | Notes |
|---|---|---|
| Acquisition | **8** | High-intent buyers actively searching for this; strong SEO opportunity; zero-cost channels (forum, FB groups, organic search); import surge = 4.2× buyer volume in 2025 |
| Virality | **7** | Shareable report + seller clean cert are genuine viral mechanisms; WhatsApp family loop is culturally native to SL buying process; not quite as automatic as a physical QR sticker |
| Monetization | **8** | Per-check transactional model (LKR 1,500) is well-priced relative to alternatives (LKR 9K physical inspection); high-stakes purchase = willingness to pay; seller cert adds a second revenue source |
| Defensibility | **6** | DMT data is publicly accessible (no exclusive data moat); trust and brand reputation are the real moat; incumbent inspection services could digitize but haven't; ikman/riyasewana are classifieds businesses unlikely to pivot |
| Build effort | **6** | Phase 1 MVP (guided checklist + manual DMT steps + market price lookup + shareable report) is achievable in 3–5 weeks; payment integration is the main new complexity; existing FastAPI/Postgres backend applies directly |

**Bottom line:** Pivot 4 has the highest revenue potential of the two pivots — the per-transaction model (LKR 1,500/check) attached to a genuine high-stakes decision (LKR 5M–15M car purchase) converts reliably. The 4× import surge of 2025 has created a one-time wave of inexperienced buyers that this product is perfectly timed to serve; that window will not last forever, but the underlying used car market (85% unorganised, 60% hidden histories) is structural and persistent.

---

*Sources consulted: [riyasewana.com](https://riyasewana.com/search/cars), [ikman.lk](https://ikman.lk/en/ads/sri-lanka/cars), [blog.ikman.lk July 2025](https://blog.ikman.lk/en/sri-lanka-car-market-2025-insights/), [mordorintelligence.com](https://www.mordorintelligence.com/industry-reports/sri-lanka-used-car-market), [datainsightsmarket.com](https://www.datainsightsmarket.com/reports/sri-lanka-used-car-market-15212), [adaderana.lk](https://adaderana.lk/news.php?nid=121742), [sundaytimes.lk](https://www.sundaytimes.lk/260111/news/revenue-soars-after-sri-lanka-lifts-vehicle-import-ban-627703.html), [carchecksonline.com](https://carchecksonline.com/), [greasemonkeyinspectors.lk](https://greasemonkeyinspectors.lk/), [eservices.motortraffic.gov.lk](https://eservices.motortraffic.gov.lk/), [services.customs.gov.lk/vehicles](https://services.customs.gov.lk/vehicles), [findus.lk](https://findus.lk/blogs/classified-ad-scams-sri-lanka/), [autolanka.com](https://www.autolanka.com/cars.html), [datareportal.com](https://datareportal.com/reports/digital-2025-sri-lanka)*
