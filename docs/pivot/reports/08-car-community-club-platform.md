# Pivot 8: Car Community / Club Platform

## One-line positioning

The dedicated digital home for Sri Lanka's car clubs — member directories, shared garages, event calendars, and club-branded showcases in one place instead of scattered WhatsApp threads and Facebook groups.

---

## Why this avoids competing with CRLO

CRLO is strictly **single-user and vehicle-centric**: one person, their vehicles, their logs. It has no concept of clubs, member directories, shared/group garages, event calendars, or community showcases. Network effects are entirely absent from CRLO's model. A club secretary using CRLO today still manages their event calendar in Google Sheets, membership list in WhatsApp, and photo gallery on Facebook — CRLO offers no help. DriveVault's community pivot attacks the coordination layer that CRLO cannot serve without re-architecting from scratch.

---

## Market evidence (verified)

### Active club ecosystem documented in the wild
The AutoLanka forums' "Car Clubs in Sri Lanka" thread documents **at least 15–17 distinct clubs** with different profiles: marque-specific (Honda Club SL, Honda CRV Club, Honda Civic Turbo Club, Mercedes Benz Club, Land Rover Owners Club, Subaru WRX Club SL, VW Beetle Owners Club), activity-specific (Ceylon Motor Sports Club, Racers Edge, Rapid Rev, Street X), and type-specific (Classic Car Club of Ceylon, 4WD Club).
Source: [AutoLanka Forums — Car Clubs in Sri Lanka](https://forums.autolanka.com/topic/2108-car-clubs-in-sri-lanka/)

### CMSC: oldest motorsport club in South East Asia, FIA-affiliated
The **Ceylon Motor Sports Club (CMSC)**, founded 4 September 1934, is affiliated with the FIA (world governing body of motorsport). CMSC organises multiple events annually: the Mahagastotte Hill Climb (running since 1934), rallies (Lotus Rally 50+ years running), circuit racing, karting, gymkhana, autocross, drag racing, and e-sports. In 2025, CMSC organised the **Asia Pacific Motorsport Championship 2025**, a regional event hosted in Sri Lanka.
Source: [CMSC Official Website](https://www.cmsc.lk/)
Source: [The Papare — Sri Lanka hosts Asia Pacific Motorsport Championship 2025](https://www.thepapare.com/sri-lanka-hosts-the-asia-pacific-motorsport-championship-2025/)

### Facebook-based community has significant followings
- **Space Riders Club Sri Lanka** (Colombo): **26,452 Facebook likes** — an active ride and meet-up club.
  Source: [Space Riders Club SL Facebook](https://www.facebook.com/SpaceRidersSL/)
- **Cars and Coffee Sri Lanka**: **9,880 Facebook likes** — international car meet format adapted for SL.
  Source: [Cars and Coffee SL Facebook](https://www.facebook.com/carsncoffeesl/)
- **Honda Civic Turbo Club SL**: active Facebook page described as the largest Honda Civic official page in SL.
  Source: [Honda Civic Turbo Club SL Facebook](https://www.facebook.com/hondacivicturboclub/)

### AutoLanka: the largest SL car community, founded 2001
AutoLanka (autolanka.com) is Sri Lanka's oldest and largest online car community. Founded in 2001, it operates a large forum, a buy/sell classified platform, and an active Facebook group. It is the de facto gathering point for enthusiasts who are not in a specific marque club.
Source: [AutoLanka Forums](https://forums.autolanka.com)
Source: [AutoLanka on Tracxn](https://tracxn.com/d/companies/autolanka/__jGSvpaYvxB3_M0tYsf0EAc-ldAOQ9-eMMwv1qBCRgYc)

### Regular, recurring car meets and major events
- **Colombo Motor Show 2025**: two editions — June 27–29 and November 21–23, 2025 — at the BMICH (Bandaranaike Memorial International Conference Hall, Colombo). Positioned as the largest automotive exhibition in the region.
  Source: [Colombo Motor Show Official](https://colombomotorshow.lk/)
  Source: [10times — Colombo Motor Show](https://10times.com/colombo-motor-show)
- **Srilankan Carmeetup** on Instagram: a dedicated account for SL car meet events with a following and regular upcoming-event posts.
  Source: [Srilankan Carmeetup Instagram](https://www.instagram.com/srilanka_carmeetup_/)
- **Sri Lankan Car Zone**: active Instagram community for car enthusiasts.
  Source: [Sri Lankan Car Zone Instagram](https://www.instagram.com/srilankanscarzone/)

### Current organising tools are ad hoc
Club secretaries currently manage: member lists in WhatsApp group member rosters or Excel, event announcements as Facebook posts or WhatsApp broadcasts, car showcases as Facebook photo albums, RSVP counting via post reactions or poll bots. None of these tools are purpose-built for car clubs. There is no SL-specific dedicated club management platform.

### Vehicle population gives enthusiast base scale
Total registered cars and dual-purpose vehicles in SL: approximately **1.37 million** (4-wheelers only, 2024 DMT data). Even a 2–5% enthusiast share = 27,000–68,000 potential community users.
Source: [Daily Mirror — 73,489 new vehicles, total 8.5 Mn](https://www.dailymirror.lk/print/front-page/73-489-new-vehicles-registered-this-year-total-count-rises-to-8-5-Mn-DMT/238-312075)

---

## Target user & Sri Lanka relevance

**Primary user A — Club secretary / organiser:** manages a marque club or meetup group of 20–200 members. Currently spends hours per event on logistics: WhatsApp broadcast, Facebook event, photo album, chasing RSVPs, updating member lists. Willingness-to-pay is tied to time savings.

**Primary user B — Club member / enthusiast:** attends 2–4 meets per year, wants to discover events, show off their build, see other members' cars, and belong to a branded community space. Currently uses Facebook and Instagram; there is no car-specific profile page for their vehicle.

**Secondary user — Event attendee (non-member):** casual car enthusiast who follows Cars and Coffee SL or the AutoLanka forum but is not in a formal club. Will browse the event discovery feed and vehicle showcases without full club membership.

**SL relevance:**
- **WhatsApp culture is dominant** in SL social organisation; but WhatsApp groups hit friction at scale (300-member limit for broadcast lists, no searchable event history, no photo archive organisation). Facebook groups fill some gaps but are algorithmically suppressed and hard to manage.
- **Colombo + suburban car culture is growing rapidly** — the import ban lift in February 2025 is bringing fresh vehicles into the market and energising the enthusiast community.
- **Regional pride** — SL enthusiasts want a local platform, not a generic global tool. A "Sri Lanka car clubs" brand identity is a differentiator.

---

## User acquisition

**In order of priority for a solo SL developer with no LinkedIn:**

1. **Direct outreach to club secretaries** — personally approach 5–10 club admins (CMSC, Honda Club SL, Space Riders Club, Cars and Coffee SL) via Facebook Messenger or forum DM. Offer to set up their club's digital home for free and provide white-glove onboarding. Each club that goes live brings their entire membership in.

2. **AutoLanka Forums post** — announce the platform in the "General Discussion" or "Car Shows & Events" section. Authentic, non-spam post with screenshots. AutoLanka's forum users are exactly the engaged segment this pivot targets.
   Source: [AutoLanka Car Shows & Events Gallery](https://forums.autolanka.com/gallery/category/5-car-shows-events/)

3. **Instagram car meet accounts** — reach out to `@srilanka_carmeetup_` and `@srilankanscarzone` for a shoutout or collab post featuring the event discovery feature. These accounts have modest but highly targeted followings.

4. **CMSC partnership** — CMSC is FIA-affiliated and runs professional-grade events. Offer free club page + event listings as an official CMSC digital partner. This is a prestigious anchor tenant and gives the platform credibility.

5. **Facebook group posts in Cars and Coffee SL, Space Riders Club, Honda Civic Turbo Club SL** — announce event-listing and club-page features directly in the groups where members already gather.

6. **Colombo Motor Show presence** — the November 2025 show is bi-annual. A stall or digital banner presence at the show (even just a QR code standee) captures the highest-density enthusiast audience in SL in one location.

---

## Virality

**The built-in loop: "my club is on DriveVault — join to see our next meet."**

When a club secretary creates the club page and posts the first event, they naturally share the event link (or a screenshot of the event card) to the existing WhatsApp group and Facebook page. Every member who clicks the link lands on the app. The event RSVP feature gives them a reason to install: "RSVP here so we know how many are coming."

**Secondary loop: the vehicle showcase card.**
Each member car gets a shareable profile card (vehicle photo, specs, club badge). Members share their car card on Instagram Stories — organic brand impressions from enthusiasts who *want* to be seen. The card carries the DriveVault watermark/club badge.

**Tertiary loop: event discovery.**
Non-club-members find an upcoming meet through the discovery feed, attend, meet the club, and are invited to join via the app. In-person → digital onboarding is reliable for enthusiast communities.

**What gets shared and why:** the event card ("Sri Lanka Honda Club Meet — Sunday 10am, Race Course, Colombo — RSVP") and the vehicle showcase card. Both are shareable social objects with high visual quality and real utility.

---

## Revenue model & potential

### Model

**Freemium for individuals + Club SaaS tier for organisers.**

| Tier | Price | Who |
|------|-------|-----|
| Free member | LKR 0 | Individual club member: join clubs, RSVP to events, basic vehicle profile |
| Member Pro | LKR 390/month | Enthusiast: unlimited vehicle showcase cards, private build log, event history, cross-club discovery |
| Club Basic | LKR 1,500/month | Club of up to 50 members: member directory, event calendar, club gallery, RSVP tracking |
| Club Pro | LKR 4,500/month | Club of up to 300 members: all Basic + branded club page, event tickets (with payment collection), sponsor listing, analytics |
| Annual discount | –20% | Any paid tier |

LKR 1,500/month ≈ USD 5/month for Club Basic; LKR 4,500/month ≈ USD 15/month for Club Pro. These price points sit below what any international club management SaaS charges (Wild Apricot, ClubExpress charge USD 40–200/month) while being meaningful for a SL club with a dozen paying members.

**Supplementary revenue:**
- **Event ticket processing fee** — 2–3% of ticket value for paid event tickets processed through the platform. A 100-car event at LKR 500 entry = LKR 50,000 gross; platform fee = LKR 1,000–1,500 per event.
- **Sponsor listing / featured placement** — car-related brands (lubricants, tyre shops, detailing studios) pay LKR 5,000–20,000/month to be featured in the club feed or event pages.
- **Photography / printing partner affiliate** — event photo packages, car-wrap shops, merchandise.

### TAM math

**Bottom-up:**
- Documented active clubs: 15–20. Estimated total SL clubs (including WhatsApp-only groups): 50–100.
- Target signed clubs in Year 1: 20 clubs.
  - 10 on Free (referencing the platform), 5 on Club Basic, 5 on Club Pro.
  - Revenue: (5 × LKR 1,500) + (5 × LKR 4,500) = LKR 7,500 + LKR 22,500 = **LKR 30,000/month**.

- Individual Member Pro in Year 1: 500 paying members (across clubs totalling 2,000–3,000 installs).
  - 500 × LKR 390 = **LKR 195,000/month**.

- Combined Year 1 conservative: **LKR 225,000/month ≈ LKR 2.7M/year**.

**Mid scenario (Year 2, 40 clubs signed, 2,000 pro members):**
- Club revenue: (15 × LKR 1,500) + (25 × LKR 4,500) = LKR 22,500 + LKR 112,500 = LKR 135,000/month.
- Member Pro: 2,000 × LKR 390 = LKR 780,000/month.
- Event ticket fees: 10 events/month × avg LKR 1,200 fee = LKR 12,000/month.
- Sponsor listings: 5 sponsors × LKR 10,000 = LKR 50,000/month.
- **Total: ≈ LKR 977,000/month ≈ LKR 11.7M/year**.

The monetization ceiling is lower than Pivot 7 in the early stages, but grows with each club acquired (B2B SaaS churn is lower than consumer churn).

---

## Feature roadmap by phase

### Phase 1 / MVP (net-new build required)
- Club creation and club page (name, logo, marque, description, club admin roles)
- Member directory (join via invite code or club admin approval)
- Vehicle showcase: each member links their DriveVault garage vehicles to their club profile — **existing garage feature is reused**
- Event creation: date, location (Google Maps link), description, RSVP button
- Event discovery feed: public list of upcoming SL car events across all clubs
- Club photo gallery (post-event upload)
- **Already exists in DriveVault:** vehicle garage with photos, Firebase auth, user profiles

### Phase 2 (3–6 months)
- Club admin dashboard: member approval, RSVP counts, attendance reports
- Event ticket sales with payment (PayHere or iPay integration — SL payment gateways)
- Branded shareable event card (Instagram/WhatsApp story format)
- Shareable vehicle showcase card with club badge
- Cross-club discovery: "find meets near me", "meets this weekend"
- Push notifications: "new event in your club", "your RSVP is confirmed", "meet is tomorrow"
- Sinhala language support for the club/event layer

### Phase 3 (6–12 months)
- Sponsor portal: brands create sponsor profiles, target clubs by type/marque/region
- Club leaderboards: active members, events hosted, vehicles added
- Inter-club challenges / friendly competitions (e.g. "best build of the month" voted by members)
- Live meet check-in (QR scan at the gate for RSVP verification)
- Media partner integrations: share event galleries to AutoLanka's forum directly

---

## Risks & moat

**Risks:**

1. **Facebook / WhatsApp inertia is strong** — most clubs have functional-enough organising on Facebook right now. Switching requires club secretary motivation. Mitigation: focus initial outreach on the secretary's pain (not the member's), offer free setup, make migration of existing member list painless.

2. **Network effect bootstrapping** — the platform is worthless to a member if their club is not on it. Classic cold-start problem. Mitigation: the "club secretary first" sales motion (1 secretary brings 50–200 members at once) is the only viable solution. Don't try to recruit members directly.

3. **Monetization timing** — clubs will resist paying until they see value. Free tier must be genuinely functional; paid tier unlocks convenience and analytics. Timeline to meaningful revenue is 12–18 months.

4. **Solo developer bandwidth** — the community feature set (member directories, event tickets, group garages) is a significantly larger build than Pivot 7. This is the biggest risk for a solo developer.

5. **Community moderation** — car communities can be territorial and combative. The platform needs basic reporting and admin controls from day one.

**Moat:**

- **Network effect:** once a club's members are on the platform, the club's social graph creates switching cost — you leave the platform, you lose your club history, your RSVP records, and your connection to your fellow members.
- **Club relationship lock-in:** the club secretary relationship is B2B; churn requires a deliberate decision by an admin, not passive user drift.
- **Local brand identity:** "DriveVault — home of Sri Lanka's car clubs" is a positioning that can be owned if DriveVault moves fast. No international competitor is investing in the SL club niche.
- **Exclusive CMSC / major club partnerships:** if CMSC officially lists DriveVault as its digital partner, the FIA-affiliated credibility transfers.
- **Event history data:** past event galleries, member attendance records, and vehicle build timelines become irreplaceable club assets over time.

---

## Viability verdict

| Dimension | Score /10 | Rationale |
|-----------|-----------|-----------|
| Acquisition | 6 | B2B club outreach is high-effort; but one secretary = 50–200 installs, making each conversion high-value |
| Virality | 8 | Shareable event cards + vehicle showcase cards are strong social objects; event discovery drives organic discovery |
| Monetization | 5 | Club SaaS revenue is smaller and slower than consumer subscriptions; grows with club roster; ticket fees add upside |
| Defensibility | 8 | Multi-layer network effects (club graph + event history + vehicle showcase) create genuine switching costs |
| Build effort | 4 | Community features (member directory, event tickets, group garages) are a substantial net-new build for a solo developer; most of what makes this pivot distinct does not yet exist |

**Bottom line:** Pivot 8 has the strongest long-term defensibility of the two pivots — network effects are hard to replicate once a club community is embedded — but it carries the highest build cost and the longest path to revenue for a solo developer. The cold-start problem requires a focused "sign three flagship clubs first" strategy before any broad launch. Best treated as a second-phase extension after Pivot 7 establishes a paying user base, or executed in parallel only if a technical co-founder joins.
