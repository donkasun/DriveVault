# Pivot 01: Sri Lanka Compliance Guardian

---

## One-line positioning

The only app that aggregates every Sri Lankan vehicle's compliance deadlines — revenue licence, insurance, emission test, fitness certificate, driving licence, and permits — and pushes a penalty-amount-in-LKR reminder before each one expires.

---

## Why this avoids competing with CRLO

CRLO is a generic, globally positioned logbook with no concept of country-specific compliance rules. It cannot model Sri Lanka's four-document renewal dependency chain (insurance + emission cert + fitness cert → revenue licence), does not know the DMT's progressive penalty schedule (10 / 20 / 30%), and cannot quote penalty amounts in LKR. Its own brand positioning — "made for the pump, not the desk" — explicitly cedes the compliance/admin use-case. A Sri Lanka Compliance Guardian lives entirely in the gap CRLO declared it will not enter.

---

## Market evidence (verified)

**Vehicle population — the addressable base:**
Sri Lanka's registered vehicle population reached **8,528,002** as of May 2025, comprising ~912,871 cars, ~4,981,211 motorcycles, ~1,186,220 three-wheelers, ~452,819 dual-purpose vehicles, and ~114,362 buses. ([Ada Derana / DMT data](http://www.adaderana.lk/news/115789/223000-motorcycles-55000-cars-and-13000-three-wheelers-registered-in-2025-dmt); [Daily Mirror](https://www.dailymirror.lk/breaking-news/Vehicle-registrations-surge-over-133-000-registered-in-2025-so-far/108-316038))

New registrations are surging post-import-ban-lift (Feb 2025): 223,423 motorcycles and 55,338 cars registered in the first ~11 months of 2025 alone, with the DMT collecting Rs. 17.8 billion in revenue against a Rs. 16 billion target — 11% above plan. ([Ada Derana](http://www.adaderana.lk/news/115789/223000-motorcycles-55000-cars-and-13000-three-wheelers-registered-in-2025-dmt))

**Penalty exposure — the pain quantified:**
Under Motor Traffic (Fees) Regulations No. 04 of 2022, the late revenue-licence penalty schedule is:
- Up to 3 months overdue: **+10%** of the annual tax fee
- 3–12 months overdue: **+20%** of the annual tax fee
- Over 12 months overdue: **+30%** of the annual tax fee

([Lanka Websites renewal guide, 2026](https://lankawebsites.com/blog/automobiles/vehicle-registration-renewal-process-in-sri-lanka-2026); [News First, 2022](https://www.newsfirst.lk/2022/11/17/vehicle-registration-fee-revenue-license-fee-hiked/))

Annual revenue licence fees start at Rs. 2,500 (petrol car <762 kg) and Rs. 3,900 (diesel car), so a 30% penalty on a typical mid-range vehicle adds Rs. 750–Rs. 2,500+ to the tax bill — before counting the emission test (Rs. 1,690 for cars effective Oct 2025, ([Drivegreen price list](https://www.drivegreen.lk/emission-test-price-list/))) and insurance that must also be renewed.

**No existing reminder infrastructure:**
The official eRevenue Licence portal ([web.erl2.gov.lk](https://web.erl2.gov.lk/)) handles online renewal only; it sends no calendar reminders and does not aggregate multiple documents or vehicles. The government's own advice is to "mark your renewal date on your calendar." ([Lanka Websites](https://lankawebsites.com/blog/automobiles/vehicle-registration-renewal-process-in-sri-lanka-2026)) The gap between "government system exists" and "proactive, penalty-quantifying push notification" is wide and unoccupied by any app visible in Sri Lankan app stores.

**Digital reach — the channel is there:**
Sri Lanka has 12.4 million internet users (53.6% of population), 8.20 million Facebook users, and 29.3 million mobile connections (127% of population). ([DataReportal Digital 2025 Sri Lanka](https://datareportal.com/reports/digital-2025-sri-lanka)) Android dominates with ~75–80% smartphone market share; iOS users skew higher-income (the premium tier target).

**Motor insurance market:**
The Sri Lanka motor insurance market is projected at US$425 million in 2026. ([Mordor Intelligence / Statista](https://www.statista.com/outlook/fmo/insurances/non-life-insurances/motor-vehicle-insurance/sri-lanka)) Every insured vehicle (required by law for road use) has an annual renewal date — a captive, recurring reminder event.

---

## Target user & Sri Lanka relevance

**Primary:** Urban private vehicle owners aged 25–45 with one or two cars, who currently rely on memory or WhatsApp self-notes to track renewal dates and routinely pay avoidable penalties. This is the 912,871-strong car population — Colombo, Kandy, Galle, Negombo.

**Secondary:** Three-wheeler and motorcycle owners (the 6.1M+ combined), who face the same compliance chain but are lower willingness-to-pay; better served as a free tier.

**Sri Lanka specificity:** No other market has this exact four-document dependency chain (insurance → emission cert → fitness cert → revenue licence), this penalty structure, and this eRevenue portal that does renewal-but-not-reminders. A global app cannot model this because the rules are jurisdiction-specific and change by gazette notification.

---

## User acquisition

**Facebook Groups (highest-ROI first action):**
There are 8.20 million Facebook users in Sri Lanka and dozens of active vehicle buy/sell groups (e.g., "All Vehicles for Sale in Sri Lanka," "Vehicle Sale Sri Lanka," "Car Sale – Sri Lanka"). A single genuinely helpful post — "missed your revenue licence date? here's what the penalty costs you" with a link — can seed thousands of installs with zero ad spend. Budget: Rs. 0.

**AutoLanka Forum (enthusiast beachhead):**
AutoLanka (forums.autolanka.com) is Sri Lanka's largest automotive online community, active since at least 2011 and still posting in 2025. Post a thread about the penalty calculator feature; forum members are vocal sharers and influencers in the broader community. Budget: Rs. 0.

**WhatsApp / word-of-mouth within vehicle owner circles:**
The compliance nudge has a natural sharing moment: "I just saved Rs. 2,000 in fines — you should get this." This is pull-based and costs nothing to engineer if the app is useful.

**YouTube Sinhala:**
Sri Lanka has 8.13 million YouTube users. ([DataReportal](https://datareportal.com/reports/digital-2025-sri-lanka)) Sinhala-language explainer videos ("how to renew your revenue licence and avoid the fine") with an app CTA have demonstrated strong install conversion for local utility apps. Budget: Rs. 0 organic; Rs. 10,000–25,000/month for modest paid promotion.

**TikTok:**
5.79 million adult TikTok users. Short "did you know your revenue licence fine is X%" explainer clips match the platform's format. Budget: Rs. 0 organic.

**What to do first:** Post to 3–5 Facebook car groups and the AutoLanka forum the day the app hits the store. Attach a screenshot of the penalty calculator with a real example (e.g., "1.5L petrol car, 4 months late = Rs. 500 fine"). Measure install velocity in week 1 before spending a rupee on ads.

---

## Virality

**The "forwarded to my group" loop:** Every reminder push notification saying "Your revenue licence expires in 30 days — if you miss it, the fine is Rs. 500" is a concrete, shareable fact. Users who were previously unaware of the penalty structure naturally forward this insight to family members who share a car or to WhatsApp groups of vehicle owners.

**The shared-vehicle scenario:** Sri Lankan households frequently have multiple vehicles across family members. The app's multi-vehicle support means one user adds both cars, then shares the app with a spouse or parent to add their own. This is the same household-fleet virality that drove early CarDroid and similar utility apps globally.

**The artifact shared:** Not a report (too formal) — a screenshot of the countdown widget or the penalty-amount banner ("Fine if you miss it: Rs. 750"). Highly shareable because it's a useful fact most Sri Lankan drivers do not know precisely.

**K-factor estimate:** Modest but positive — each user who avoids a fine has a high probability (estimated 40–60%) of telling at least one other vehicle owner. Even at K=0.3, organic growth is meaningful in a market this size.

---

## Revenue model & potential

**Model:** Freemium subscription with a free tier (1 vehicle, basic expiry reminders) and a paid tier (unlimited vehicles, penalty-amount context, 90-day advance warnings, document photo vault, driving licence/permit reminders).

**Pricing:**
- Free: 1 vehicle, 30-day advance reminder only (no penalty context)
- Pro: Rs. 290/month or Rs. 2,490/year (~US$0.96/month or US$8.30/year)

This undercuts a single late-renewal penalty (Rs. 500–2,500) by 5–10×, making the ROI argument trivially easy.

**TAM (Total Addressable Market):**
- 912,871 registered cars in SL as of mid-2025
- Conservatively assume 60% have a smartphone-equipped owner = 547,000 reachable car owners
- Add 30% of 1.186M three-wheelers whose owners are smartphone users = ~355,000 more
- Reachable TAM: ~900,000 vehicle owners

**Conservative scenario (Year 2):**
- 1% of car TAM converts to paid = 5,500 subscribers
- Rs. 2,490/year × 5,500 = **Rs. 13.7 million/year (~US$45,700)**

**Moderate scenario (Year 3):**
- 3% paid conversion across cars + three-wheelers = 27,000 subscribers
- Rs. 2,490/year × 27,000 = **Rs. 67.2 million/year (~US$224,000)**

**B2B upside (Year 2+):** Fleet operators (SMEs with 5–50 vehicles) have acute compliance pain — one missed fitness certificate pulls their entire fleet off the road. A fleet-tier plan at Rs. 500/vehicle/month for 5-vehicle fleets = Rs. 2,500/month per customer. Acquiring 100 fleet customers = Rs. 3 million/month additional. This is the Carfax dealer-subscription analogue.

**Revenue from day 1 alternative:** A one-time "penalty calculator" in-app purchase at Rs. 149 can monetize free users who want the exact penalty amount for their specific vehicle class without subscribing. Low friction, high conversion.

---

## Feature roadmap by phase

### Phase 1 / MVP (builds directly on existing DriveVault work)

*Already in DriveVault (use as-is or minor adaptation):*
- Multi-vehicle garage with photos
- Document vault (revenue licence, insurance, emission, fitness) with expiry dates
- Driving credentials (licence, permit, international permit) with expiry dates
- Firebase Auth + push notifications (FCM)
- CredentialExpiryBanner and document-expiry banner in dashboard

*Net-new for MVP:*
- Per-vehicle compliance dashboard: single screen showing all 5 documents with days-remaining pills
- Penalty calculator: given vehicle category and days overdue, compute fine in LKR using the gazette schedule
- Penalty-amount in push notification body: "Revenue licence expires in 14 days. If you miss it by 3 months, the fine will be Rs. 500."
- 90-day, 30-day, 7-day, and 1-day push notification schedule per document (configurable)
- Sinhala-language UI strings (optional for MVP, high priority for growth)

### Phase 2 (3–6 months post-launch)

- Multi-vehicle household: share garage across Firebase UIDs (family accounts)
- Fleet mode: owner manages 5–50 vehicles, per-vehicle compliance status board
- Insurance company and emission station directory (partner links)
- In-app eRevenue Licence portal deep-link at point of renewal nudge
- Widget (home-screen) showing next upcoming expiry countdown

### Phase 3 (6–12 months)

- OCR scan of physical documents to auto-fill expiry dates (ML Kit, already planned in DriveVault tech spec for Phase 3)
- Compliance calendar export (Google Calendar / .ics)
- WhatsApp reminder (SL users heavily WhatsApp-dependent)
- Fleet B2B tier with CSV bulk upload
- Gazette notification tracker: alert users when DMT changes fee schedules

---

## Risks & moat

**Top risks:**

1. **Government builds a reminder system into eRL** — The current eRL 2.0 portal is purely transactional; adding multi-document, multi-vehicle proactive push is a non-trivial product investment for a government department with a history of slow iteration. Risk: low-medium in a 2-year horizon.

2. **Low willingness to pay at Rs. 290/month** — Sri Lankan app paid conversion rates are historically low (most top paid apps are <LKR 1,000 one-time). Mitigate: hard ROI framing ("saves you Rs. 500–2,500 per year in fines"), one-time purchase option, free tier with enough value to build trust first.

3. **Low smartphone penetration among motorcycle/three-wheeler owners** — The 6.1M motorcycle + three-wheeler market has lower income/smartphone rates. Mitigate: focus monetization on car owners (912K addressable) and treat motorcycles as free-tier growth volume.

4. **Notification fatigue** — Users disable push if reminders feel spammy. Mitigate: sensible defaults (only 3 push events per document per year), user-configurable timing, actionable deep-links in every notification.

**Moat:**

- **Sri Lanka compliance schema is the moat.** Encoding the exact gazette penalty schedule, vehicle-category rules, and the insurance → emission → fitness → revenue licence dependency chain requires ongoing local domain knowledge that a global competitor cannot trivially replicate or keep current.
- **First-mover advantage in push notification relationship.** Once users allow notifications for their renewal dates, they are highly sticky — switching cost is re-entering all dates in a new app.
- **Accumulated document vault.** After 2 years of use, a user's complete compliance history lives in DriveVault. That data has value for resale (Pivot 2) and is hard to export.

---

## Viability verdict

| Dimension | Score /10 | Rationale |
|---|---|---|
| Acquisition ease | **8** | Facebook/WhatsApp/TikTok organic is proven for SL utility apps; no paid spend required to launch |
| Virality | **7** | Penalty-amount share moment is genuine; household multi-vehicle dynamic drives organic spread |
| Monetization | **6** | Rs. 290/month subscription is a viable ROI argument but SL paid-app conversion is historically low; fleet B2B lifts ceiling |
| Defensibility | **8** | Compliance rules schema + notification relationship + data vault = 3-layer moat; global apps structurally excluded |
| Build effort | **8** | 70% of infrastructure already exists in DriveVault Phase 1; MVP is penalty calculator + notification scheduler + compliance dashboard |

**Bottom line:** This is the most natural first pivot — it deepens what DriveVault already built, serves a pain point that costs every SL vehicle owner real LKR each year, and is structurally defended against CRLO. The monetization ceiling is modest (Rs. 13–67M/year at scale) but achievable solo, and the fleet B2B tier provides a meaningful revenue expansion path beyond the consumer subscription.
