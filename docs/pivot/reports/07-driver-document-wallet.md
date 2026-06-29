# Pivot 7: Driver & Document Wallet

## One-line positioning

A personal mobility document wallet for Sri Lanka — store, track, and instantly present your driving credentials and vehicle documents at any moment, including roadside police checks.

---

## Why this avoids competing with CRLO

CRLO is a **vehicle-centric logbook**: it records fuel fills, service history, and expenses per vehicle. It has no concept of a person's own documents (driving licence, learner permit, international driving permit), no document expiry notifications, no family-member credential management, and no roadside-presentability UX. The wallet use-case is person-centric, not vehicle-centric. CRLO's architecture cannot easily absorb it without a fundamental redesign. DriveVault already has the driving-credentials feature and doc-vault foundation built; this pivot deepens those rather than extending the logbook core that CRLO owns.

---

## Market evidence (verified)

### Digital licence adoption in SL is happening now
Sri Lanka formally introduced a **digital driving licence in 2026**, displayed via the official Department of Motor Traffic app. The licence contains a unique QR code; police officers scan it with their device to instantly see the holder's name, licence validity period, and current demerit-point status. The digital licence is also accepted for vehicle rental and insurance identity verification.
Source: [MotorGuide LK — Digital Driving Licenses and Online Fine Payments Introduced in 2026](https://motorguide.lk/en/news-advice/digital-driving-licenses-and-online-fine-payments-introduced-in-2026)

A separate DMT mobile appointment and renewal system has been operational since at least mid-2025:
Source: [DMT Appointments Portal](https://dmtappointments.dmt.gov.lk/)

### Renewal process moving online
The DMT launched the **first phase of an online driving licence renewal platform on 30 September 2025**, allowing eligible applicants to begin renewal without a physical visit to DMT Werahera headquarters.
Source: [Lanka News Web — Online Platform Launched to Simplify Driving Licence Renewals](https://lankanewsweb.net/archives/130230/online-platform-launched-to-simplify-driving-licence-renewals-in-sri-lanka/)

### eRL 2.0 — vehicle revenue licence is already digital
The **eRevenue Licence 2.0 (eRL 2.0)** system, operated by ICTA and the DMT, allows vehicle owners to renew their revenue licence online from any province. On payment confirmation, a temporary digital licence valid for 14 days is emailed immediately; a printed licence follows by registered post. This means the revenue licence already has a digital-first workflow; what is missing is a personal wallet that aggregates it alongside all other documents.
Source: [ICTA — Electronic Revenue Licence System](https://www.icta.lk/projects/electronic-revenue-licence-system-erl/)
Source: [eRL 2.0 Portal](https://web.erl2.gov.lk/)

### Vehicle population creates large addressable base
- Total registered vehicles in SL: **~8.5 million** (DMT, 2024), including ~912,871 cars, ~1.19 million three-wheelers, ~4.98 million motorcycles.
- New registrations in 2025 (full year): **~55,000 cars, 223,000 motorcycles, 13,000 three-wheelers**.
- The February 2025 lifting of Sri Lanka's five-year vehicle import ban triggered a registration surge.
Source: [Daily Mirror — 73,489 new vehicles registered, total rises to 8.5 Mn](https://www.dailymirror.lk/print/front-page/73-489-new-vehicles-registered-this-year-total-count-rises-to-8-5-Mn-DMT/238-312075)
Source: [Ada Derana — 223,000 motorcycles, 55,000 cars registered in 2025](http://www.adaderana.lk/news/115789/223000-motorcycles-55000-cars-and-13000-three-wheelers-registered-in-2025-dmt)

### Internet and smartphone penetration
- **12.4 million** internet users in SL as of January 2025 (53.6% penetration), up 808,000 year-on-year.
Source: [DataReportal — Digital 2025: Sri Lanka](https://datareportal.com/reports/digital-2025-sri-lanka)

### Used car market growth
Sri Lanka's used-car market was valued at **USD 283 million in 2025**, projected to reach USD 436 million by 2031 at a 7.49% CAGR — every used car transaction generates fresh document-expiry cycles (insurance, revenue licence, emission, fitness).
Source: [Mordor Intelligence — Sri Lanka Used Car Market](https://www.mordorintelligence.com/industry-reports/sri-lanka-used-car-market)

### QR code on physical driving licence (2023 onwards)
Sri Lanka replaced semiconductor chips on driving licences with QR codes due to import difficulties during the economic crisis. The QR code holds licence details readable by police and institutions.
Source: [Newswire LK — New driving licence with QR code (2023)](https://www.newswire.lk/2023/11/01/new-driving-licence-with-qr-code/)

---

## Target user & Sri Lanka relevance

**Primary user:** Sri Lankan adult driver (age 20–55) who owns or operates a car, van, or motorcycle and must manage at minimum: driving licence (5-year validity), vehicle revenue licence (annual), insurance (annual), emission certificate (annual), fitness certificate (annual for older vehicles). Missing a renewal means fines, impoundment, or inability to transfer a vehicle at sale.

**Pain points specific to SL:**
1. **Police checks are frequent and often surprise stops** — officers now scan the physical licence QR code, but the driver still must produce insurance, revenue licence, and (if stopped near an inspection point) fitness and emission certificates. Fumbling through the glovebox for paper documents during a police stop is stressful and common.
2. **Renewal deadlines are scattered and paper-based** — most SL vehicle owners receive zero proactive expiry reminders. The eRL portal sends a digital licence on renewal but not a 30/60-day advance alert.
3. **Multi-vehicle households** — it is common for an SL household to own a car + a motorcycle; spouses or adult children each have their own licences. A family view of expiries is highly practical.
4. **Three-wheeler and motorcycle riders** — 6+ million combined; even a simple licence + revenue licence wallet has utility at this scale.
5. **International driving permit (IDP)** — for Sri Lankans going abroad or foreigners driving in SL; IDP tracking is niche but underserved.

**Secondary user:** a small business owner managing a small fleet (2–5 vehicles), e.g. a private tutor, delivery operator, or taxi owner — needs one view of all vehicle document expirations.

---

## User acquisition

**In order of priority for a solo SL developer:**

1. **WhatsApp and Facebook car groups** — post a "how many of you missed a revenue licence renewal?" poll in active groups (AutoLanka Facebook, Honda Civic Turbo Club SL, space rider groups). Genuine engagement, not spam. These groups have 10,000–26,000 members each.
   Source: [Space Riders Club SL FB — 26,452 likes](https://www.facebook.com/SpaceRidersSL/); [Honda Civic Turbo Club SL FB](https://www.facebook.com/hondacivicturboclub/)

2. **Google Play / App Store organic search** — "Sri Lanka driving licence reminder", "vehicle document expiry", "eRL reminder Sri Lanka". Low competition; target the renewal-anxiety keyword cluster. A well-described Play listing in Sinhala + English captures this.

3. **YouTube tutorials** — "How to renew your driving licence in Sri Lanka 2026" walkthrough that mentions the app as a tracker. High-intent audience. One good video can drive sustained installs for months.

4. **AutoLanka forum post** — a genuine thread in the `General` board explaining the renewal chaos problem and how DriveVault solves it. AutoLanka is Sri Lanka's oldest and largest enthusiast forum (founded 2001).
   Source: [AutoLanka Forums](https://forums.autolanka.com)

5. **Content SEO** — "driving licence renewal Sri Lanka 2026", "revenue licence Sri Lanka how to renew" — search demand is validated by the DMT's own renewal guide pages ranking highly. A short lankawebsites.com-style guide page (or a blog on the DriveVault site) can capture this traffic.
   Source: [Lanka Websites — Driving Licence Renewal 2026](https://lankawebsites.com/blog/automobiles/vehicle-registration-renewal-process-in-sri-lanka-2026)

6. **Near renewal-time social posts** — post "Revenue licence renewal season begins" content in November–December (the typical Q4 SL renewal peak).

---

## Virality

**The built-in loop: the share-at-police-check moment.**

When a driver opens DriveVault at a police stop and presents the QR code or document image from the app, the officer may ask "what app is that?" — instant word-of-mouth to the one person who has maximum authority and attention in that moment. Bystanders in traffic also notice.

**Secondary sharing loop: family document sharing.** Once a user adds their spouse's licence and a second vehicle, they naturally say "download this, I've put your licence expiry in it." A single household install becomes two installs.

**Tertiary: WhatsApp share card.** When an expiry reminder fires, the app can offer "Share reminder with co-owner" — a pre-formatted WhatsApp message with the document name and expiry date. The recipient has a reason to install to manage their own documents.

**What gets shared and why:** the expiry reminder notification itself. "Your insurance expires in 14 days — tap to renew" is actionable and passes the "I should forward this to my dad" test.

---

## Revenue model & potential

### Model

**Freemium with a single premium tier.**

| Tier | Price | What you get |
|------|-------|--------------|
| Free | LKR 0 | 1 vehicle, driving licence, up to 3 documents, basic expiry alerts |
| DriveVault Pro | LKR 490/month or LKR 3,900/year | Unlimited vehicles, unlimited documents, family member profiles (up to 4), custom reminder lead times, offline document access, PDF/image export, revenue-licence renewal deeplink |

LKR 490/month ≈ USD 1.60 (at ~300 LKR/USD). This is below the psychological barrier of LKR 500 and aligns with what SL consumers pay for productivity apps on Google Play (international subscription prices in SL typically land LKR 300–800 for utility apps).

**Supplementary revenue (Phase 2):**
- **Insurance renewal affiliate / lead-gen** — partner with Ceylinco Insurance, Sri Lanka Insurance, or Janashakthi. For each insurance renewal initiated through DriveVault, earn a referral fee (LKR 300–1,000 per policy). This is realistic because every vehicle document wallet user has an insurance expiry on file.
- **Emission / fitness test center directory** (free to list, paid to be featured) — "Find nearest VTM" with promoted slots at LKR 5,000–15,000/month per test center.

### TAM math

- Registered cars in SL: ~912,871 (2024 DMT).
- Add dual-purpose and vans: total four-wheelers ≈ 1.37 million.
- Addressable (smartphone users with cars): assume 50% smartphone penetration in this demographic ≈ 685,000.
- Realistic install target in 12–18 months post-launch: **10,000–30,000 installs** (comparable to other niche SL utility apps).
- Paid conversion at 5% (typical for freemium utilities in developing markets): **500–1,500 paying subscribers**.

**Conservative scenario:** 800 Pro subscribers × LKR 490/month = **LKR 392,000/month (≈ LKR 4.7M/year)**.
**Mid scenario:** 3,000 subscribers × LKR 490/month = **LKR 1.47M/month (≈ LKR 17.6M/year)**.
**With insurance affiliate (200 referrals/month × LKR 500 avg):** +LKR 100,000/month in the conservative scenario.

These are real solo-developer-sustainable revenues, not VC-scale. At LKR 4.7–17.6M/year, this is a fundable side-income for a solo SL dev.

---

## Feature roadmap by phase

### Phase 1 / MVP (already exists in DriveVault, extend minimally)
- Driving credentials: driver licence, learner permit, IDP — **already built**
- Document vault: revenue licence, insurance, emission, fitness with expiry tracking — **already built**
- Dashboard with upcoming-renewal reminders — **already built**
- Credential expiry banners — **already built**
- **Net-new for this pivot:** fullscreen document display / "present at police check" mode (large-text doc number + expiry date + photo), QR code display for DMT-issued documents, offline cache so documents are accessible without mobile data

### Phase 2 (3–6 months)
- Family profiles: add spouse / child / parent licences under one account
- Multi-vehicle household view: all documents across all family vehicles in one dashboard
- Insurance renewal deeplink (partner with Ceylinco/SLI eService portals)
- eRL 2.0 renewal shortcut (deeplink to `web.erl2.gov.lk` pre-filled with user's vehicle number)
- Sinhala language support (critical for mass-market motorcycle segment)
- Push notifications: 60-day, 30-day, 7-day, 1-day expiry alerts per document
- Small-fleet mode (2–5 vehicles, for small business owners)

### Phase 3 (6–12 months)
- Emission / fitness test center finder with GPS
- Insurance affiliate integration (lead-gen revenue)
- Featured test center directory (LKR 5,000–15,000/month paid slots)
- Document OCR scan: point camera at licence or certificate, auto-fill fields (Gemini Vision — already planned for Phase 3 of DriveVault per `docs/01-tech-spec.md`)
- Shared fleet link: owner grants mechanic / family member read-only view of a vehicle's documents

---

## Risks & moat

**Risks:**
1. **DMT launches its own official app** — the 2026 digital licence is already DMT-app-driven. If DMT builds a full personal wallet, it could displace the need. Mitigation: DriveVault adds family profiles, multi-vehicle aggregation, and insurance/renewal integrations that a government department will never build fast.
2. **Low willingness-to-pay** — SL consumers are price-sensitive. Mitigation: the free tier must be genuinely useful (1 vehicle + licence), so free users stay engaged and the viral loop operates; paid converts on multi-vehicle need.
3. **Android dominance** — SL is predominantly Android. Flutter serves Android and iOS equally, so this is not a blocker, but App Store revenue (iOS) will be smaller.
4. **Data privacy concern** — users storing licence photos and document numbers in an app requires trust. Mitigation: communicate Cloudinary-backed secure storage, no third-party data sales, privacy-first messaging.

**Moat:**
- **Data lock-in:** once a family's 5+ documents with custom reminder times are entered, switching cost is real.
- **SL-specific compliance knowledge:** knowing which documents are required for SL police checks, which are annual, the exact fee schedules — this is local knowledge embedded in the product.
- **First-mover:** no dedicated SL document wallet app is visible in Play Store searches as of mid-2026. CRLO does not cover personal credentials at all.
- **Insurance affiliate relationships:** once Ceylinco or SLI embeds DriveVault as a renewal-reminder partner, they have commercial incentive to recommend the app.

---

## Viability verdict

| Dimension | Score /10 | Rationale |
|-----------|-----------|-----------|
| Acquisition | 7 | Organic WhatsApp/FB groups + Play Store search + renewal-season content; no paid ads needed |
| Virality | 6 | Police-check sharing and family installs are real but not explosive; word-of-mouth more than viral loops |
| Monetization | 7 | LKR 490/month is viable; insurance affiliate is realistic upside; conservative scenario is sustainable solo |
| Defensibility | 7 | SL-specific data lock-in + first-mover + potential government API integrations; DMT competition is the key risk |
| Build effort | 8 | Most infrastructure already exists; Phase 1 MVP is an extension of current features, not a rebuild |

**Bottom line:** Pivot 7 is the lowest-risk, fastest-to-revenue option for DriveVault because the core — driving credentials + document vault + expiry tracking — is already built. The 2026 introduction of Sri Lanka's digital driving licence validates the timing precisely; the government is normalising digital credentials, but its app does not serve the personal wallet + family + multi-vehicle use-case. A solo developer can launch an MVP in weeks, not months.
