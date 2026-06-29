# Pivot 9: Service & Workshop Marketplace

## One-line positioning

DriveVault becomes the layer Sri Lankan vehicle owners use to find, book, and review trusted local workshops — turning maintenance reminders already in the app into real bookings, and giving workshops their first professional online presence.

## Why this avoids competing with CRLO

CRLO is structurally single-sided: it is an owner-facing record-keeping tool with no service-provider interface, no marketplace, no booking flow, and no transaction. Adding those features would require CRLO to become a fundamentally different product. A two-sided marketplace with local garage relationships, SL-specific compliance hooks (revenue licence, emission test reminders → book now), and trust infrastructure (verified reviews + service history on file) is architecturally incompatible with what CRLO is. DriveVault's existing data — vehicles, documents, maintenance logs, upcoming renewals — becomes the demand signal that feeds bookings; no single-user logbook app can replicate that without becoming a marketplace itself.

## Market evidence (verified)

**Fleet size & service demand**
- Sri Lanka's registered vehicle fleet totals approximately **8.5 million** vehicles: ~4.85 million motorcycles, ~1.18 million three-wheelers, ~0.90 million motor cars, plus other classes (as at Q3 2023, Department of Motor Traffic). Source: search result citing DMT data via [SriLankaMirror / Lanka Statistics](https://srilankamirror.com/news/1826-new-vehicles-added-to-roads-daily-1213-motorcycles-and-386-cars/) and [EconomyNext](https://economynext.com/sri-lanka-vehicle-registration-rise-to-35000-in-july-mobikes-almost-at-pre-crisis-levels-234977/).
- Post-import-ban-lift (February 2025) new registrations surged to **312,317 vehicles in 2025** (through November), up from 74,410 in all of 2024. The fleet is actively growing again. Source: [Sunday Times](https://www.sundaytimes.lk/260111/news/revenue-soars-after-sri-lanka-lifts-vehicle-import-ban-627703.html), [numbers.lk](https://numbers.lk/analysis/sri-lanka-s-vehicle-import-ban-lift-market-shake-up-and-revenue-concerns).
- Older vehicle fleet = high maintenance frequency. Sri Lanka's roads are dominated by reconditioned imports; workshops report "more frequent repairs" as owners maintain aging vehicles rather than replace them. Source: [DHL Sri Lanka / Lanka News Web](https://lankanewsweb.net/archives/71184/sri-lankas-automotive-industry-current-landscape-and-future-prospects/).
- The local garage segment has a projected **CAGR of 8.33%** through the forecast period, the fastest-growing sub-segment in SL's automotive service market. Source: [6W Research — Sri Lanka Automotive Service Market 2025–2031](https://www.6wresearch.com/industry-report/sri-lanka-automotive-service-market).

**Garage landscape**
- Only **~1,445 formally listed garages** are trackable in SL directories (97.5% single-owner), concentrated in Western Province (1,059). Source: [RentechDigital SmartScraper listing data](https://rentechdigital.com/smartscraper/business-report-details/list-of-garages-in-sri-lanka).
- ikman.lk lists **5,788+ auto service providers** in its maintenance & repair category, confirming that the true workshop count (including informal roadside workshops) massively exceeds the formal registry. Source: [ikman.lk — Maintenance & Repair Sri Lanka](https://ikman.lk/en/ads/sri-lanka/maintenance-and-repair).
- **Trust and pricing transparency are the documented pain points**: ikman's own blog advises owners to check reviews on social media, verify mechanic training, ask about parts sourcing, and visit in person — because "narrowing down local repair businesses to find one that is genuinely trustworthy might be difficult." Overcharging and poor-quality parts are explicitly cited risks. Source: [ikman Blog — How to find a reliable vehicle service station](https://blog.ikman.lk/en/how-to-find-a-reliable-vehicle-service-station-in-sri-lanka/).

**Existing platform gaps**
- **GarageNear.lk**: a basic directory — garage listings with phone numbers and a map. No booking, no structured reviews, no service history linkage, no transaction. Source: [GarageNear.lk](https://garagenear.lk/).
- **GarageBox** (garagebox.io): B2B SaaS for workshop-side management (job cards, invoicing, technician tracking). It has *no consumer-facing marketplace* and no public discovery layer. Source: [GarageBox Sri Lanka](https://www.garagebox.io/en/auto-repair-garage-management-software-in-srilanka).
- **MyMech.lk**: a direct repair service provider (breakdown, repair, spa), not a marketplace. Source: [MyMech](https://mymech.lk/).
- **Conclusion**: No two-sided marketplace connecting SL vehicle owners to local workshops with reviews, booking, and service-history integration exists. The gap is clear.

**Digital readiness**
- **12.34 million internet users** in Sri Lanka (56.3% penetration) as of early 2024; **87% Android** share. Source: [DataReportal — Digital 2024: Sri Lanka](https://datareportal.com/reports/digital-2024-sri-lanka), [Statista — SL mobile OS share](https://www.statista.com/statistics/931178/sri-lanka-mobile-os-share/).
- Mobile:desktop ratio 4:1. WhatsApp and Facebook are the dominant commerce channels. Source: [Sandeshaya — Web & Mobile App Usage Trends SL](https://www.sandeshaya.org/web-mobile-app-usage-trends-in-sri-lanka/).

## Target user & Sri Lanka relevance

**Vehicle owner (demand side)**
- Any of Sri Lanka's ~8.5M registered vehicle owners who needs to service their vehicle, renew a revenue licence (which requires a valid emission test certificate), or book repairs after a breakdown.
- Primary early target: **smartphone-owning motorcycle and car owners in Western Province** (highest vehicle density, highest smartphone penetration). Estimated addressable: ~2–3 million in the Western Province alone.
- Pain state: they have a DriveVault maintenance reminder firing, an upcoming revenue-licence deadline, or a breakdown — and no reliable way to find and vet a local workshop without asking on Facebook or trusting a roadside sign.

**Workshop owner (supply side)**
- The ~5,000+ independent workshops (extrapolating from ikman listings), most of which have no digital presence beyond a WhatsApp number and a hand-painted sign.
- They already get customers from word-of-mouth and ikman ads. The pitch: a free listing gives them a professional profile; a paid subscription gives them booking management, CRM reminders, and job-history PDF for customers.

**SL relevance:** The entire value prop is local trust-building in a market where informal mechanics dominate, pricing is opaque, and no Yelp-equivalent for garages exists.

## User acquisition

**Phase 1 — Owner-side (no budget required)**
1. **In-app conversion**: Users who already have DriveVault's maintenance reminders and document-expiry alerts see a "Book a service" CTA attached to the alert. Zero incremental CAC; demand already exists inside the app.
2. **Facebook groups**: Sri Lanka Motorcycle Riders Association, EV Club Sri Lanka, ikman vehicle groups, and general SL car enthusiast pages. Post real-value content (e.g., "checklist before taking your bike to a garage") and link to app. Active, low-cost distribution channel aligned with how SL consumers discover services.
3. **WhatsApp seeding**: Share short video demo (30 s, Sinhala narration) in vehicle-owner WhatsApp groups. Sinhala-language content is heavily shared.

**Phase 2 — Workshop-side (supply, first 50)**
1. **On-foot enrolment**: Visit the top 10–15 garages in Colombo and Gampaha districts personally. Offer free listing + 3-month free subscription. Solo dev + no marketing spend = hustle is the budget.
2. **Rainbowpages / ikman outreach**: Contact garages already advertising on these platforms via their listed numbers. They are already paying for visibility — offer better.
3. **SLIC approved garage list**: Sri Lanka Insurance Corporation publishes an approved garages PDF (~2019 vintage, but contacts still valid). Cold-call/WhatsApp outreach to these verified workshops.

**First action**: Launch a Sinhala-language Facebook post in the Sri Lanka Motorcycle Riders Association page explaining the "service history on your phone" concept, driving downloads. Measure organic installs before spending anything.

## Virality

**The natural sharing loop:**
1. Vehicle owner receives a digital **service completion report** (PDF/link) from the workshop after a DriveVault-booked job — the mechanic logs what was done, parts used, cost, next service due.
2. The owner shares this report link when selling the vehicle on ikman or vahana.lk: *"Full verified service history — click to view."* This is a meaningful differentiator that increases resale value.
3. The buyer (future vehicle owner) downloads DriveVault to verify the history and continues using it. The vehicle record outlives the owner relationship.

**Secondary virality**: Workshop owners tell customers *"Book through DriveVault and get a digital job card."* Workshop reputation travels with the vehicle record; positive reviews drive organic workshop discovery.

**Why it gets shared**: Resale value is a strong motivator. SL vehicle buyers on ikman routinely ask for service history; currently sellers produce paper records or nothing. A shareable verified digital record is immediately valuable.

## Revenue model & potential

### Model options (layered)

| Stream | Description | Price (LKR) |
|---|---|---|
| Workshop subscription — Starter | Listed profile, basic booking management, job-card PDF | Rs. 2,500 / month |
| Workshop subscription — Pro | + CRM reminders, analytics, priority listing, WhatsApp job updates | Rs. 5,000 / month |
| Booking lead fee | Per confirmed booking sent to a free-tier workshop | Rs. 300 / booking |
| Booking commission | 5% of service value on transactions processed in-app | ~Rs. 400–800 / booking avg |
| Insurance affiliate | Revenue licence renewal → partner insurer referral | Rs. 200–500 / policy |

### TAM math

- Total SL auto service spend estimate: 8.5M vehicles × 2 service events/year × avg Rs. 5,000/service = **Rs. 85 billion / year total market**.
- Addressable in 3 years (smartphone users who'd book online): ~2M vehicle owners.
- DriveVault realistic capture at 3% of addressable = **60,000 bookings/year**.
- At Rs. 400 avg commission: **Rs. 24M/year** from commissions.
- Plus 200 workshop subscriptions × Rs. 3,500/month avg = **Rs. 8.4M/year**.
- Combined 3-year target: **~Rs. 32M/year (~USD 110K)**.

### Conservative Year 1 scenario

- 30 workshops onboarded × Rs. 2,500/month × 12 = Rs. 900,000
- 150 bookings/month × Rs. 300 lead fee × 12 = Rs. 540,000
- **Year 1 ARR: ~Rs. 1.44M (~USD 5,000)** — modest but bootstrappable with zero marketing spend; covers Cloud Run + Neon costs many times over.

### Optimistic Year 2 scenario

- 150 workshops × Rs. 4,000/month avg = Rs. 7.2M
- 800 bookings/month × Rs. 350 commission = Rs. 3.36M
- **Year 2 ARR: ~Rs. 10.5M (~USD 36K)**

## Feature roadmap by phase

### Phase 1 / MVP (what already exists + minimal net-new)
- **Already built**: Vehicles garage, maintenance logging, document vault with expiry reminders, driving credentials, dashboard upcoming-renewals panel.
- **Net-new for MVP**:
  - Workshop directory screen (public, unauthenticated): search by location, vehicle type, specialisation. Basic listing sourced from manual data entry + ikman scrape.
  - "Book a service" CTA on maintenance reminder tiles — opens a WhatsApp deep-link to the garage (zero booking backend needed at MVP).
  - Workshop claim flow: garage owner submits their details in-app; manually verified by dev.
  - Simple star-rating after each service (stored against the maintenance log).
- Deliverable: A directory with WhatsApp booking, already differentiated from GarageNear by being tied to in-app reminders.

### Phase 2
- In-app booking with date/time slots (workshop sets availability; owner books without leaving app).
- Digital job card: mechanic logs work done, parts, cost — pushes to owner's maintenance history automatically.
- Workshop dashboard (web or Flutter): booking management, customer history, push notifications via FCM.
- Payment gateway integration (PayHere or iPay) for deposit or full payment in-app.
- Workshop subscription billing (monthly LKR billing via PayHere).

### Phase 3
- Verified reviews with photo uploads; abuse moderation.
- Shareable service-history link (public URL for resale use on ikman/vahana.lk).
- Insurance partner integration: revenue-licence reminder → in-app insurance renewal → affiliate commission.
- Workshop analytics dashboard: monthly revenue, repeat customers, top services.
- Expand to three-wheeler-specialist workshops (tie-in with Pivot 10 user base).

## Risks & moat

**Risks**

| Risk | Severity | Mitigation |
|---|---|---|
| Workshop adoption is slow (cold-start supply) | High | Start with 10 personally enrolled Colombo workshops; don't launch directory publicly until supply exists |
| Garages don't see value until booking volume arrives | High | Lead with free listing, no commitment; add subscription only once they see inbound leads |
| Informal cash economy — workshops prefer off-platform payment | Medium | Don't require payment in-app at MVP; commission only on in-app paid bookings (Phase 2+) |
| GarageBox or a well-funded competitor adds a consumer layer | Medium | First-mover relationship advantage; workshop relationships + vehicle-owner data are sticky |
| Trust/liability if a booked workshop does shoddy work | Medium | Clear T&C that DriveVault is a marketplace; invest in review quality moderation |

**Moat**
- **Data flywheel**: vehicle service history inside DriveVault increases switching cost for both owners (their records live here) and workshops (their CRM is here).
- **Compliance wedge**: revenue licence expiry + emission test = mandatory annual touchpoint; no competitor routes this compliance trigger into a booking funnel.
- **Local relationships**: physical workshop partnerships in SL are not replicable by CRLO or any global app without a local team.

## Viability verdict

| Dimension | Score /10 | Notes |
|---|---|---|
| Acquisition | 7 | In-app trigger is essentially free CAC; workshop cold-start is hard work |
| Virality | 6 | Resale history loop is real but slow to emerge; service-report sharing is the best hook |
| Monetization | 7 | Workshop subscriptions are recurring and clear; commission requires in-app payments (Phase 2) |
| Defensibility | 7 | Vehicle data + workshop relationships are sticky; no well-capitalised SL competitor yet |
| Build effort | 5 | Marketplace = two-sided; workshop onboarding, booking backend, job-card flow are non-trivial additions to Phase 1 codebase |

**Bottom line**: The pain is real and documented (ikman itself admits the trust gap), the market is large (8.5M vehicles, Rs. 85B annual service spend), and no two-sided marketplace fills this gap in Sri Lanka today. The cold-start workshop supply problem is the principal risk — the first 6 months must be spent personally enrolling 30–50 garages in Western Province before any public launch.
