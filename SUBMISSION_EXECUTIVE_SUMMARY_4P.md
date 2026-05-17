# WanderLess — Executive Summary (4P Framework)

**MGMT655: Machine Learning for Decision Making | Luang Prabang, Laos | May 2026**

---

## 1. Product (What We Built)

**WanderLess** is a compatibility-intelligence marketplace for local guided travel — an ML decision-support system that matches tourists with guides based on who they are, not just where they're going.

The product wedge: travel is the last major consumer domain where ML-powered compatibility matching has not been applied. Every major OTA (Klook, Viator, GetYourGuide) sorts by popularity. WanderLess asks: _who are you, how do you travel, what do you care about_ — and surfaces the guide most likely to deliver an exceptional experience.

### Four ML Capabilities

| #   | Capability                          | Algorithm                                                | Status                       |
| --- | ----------------------------------- | -------------------------------------------------------- | ---------------------------- |
| 1   | **Interest-Compatibility Matching** | Cosine similarity + TruncatedSVD collaborative filtering | Implemented                  |
| 2   | **Group Formation Engine**          | K-Means clustering + DBSCAN outlier detection            | Implemented                  |
| 3   | **Itinerary Optimization**          | Greedy construction + 2-opt local search                 | Implemented                  |
| 4   | **Satisfaction Prediction**         | XGBoost regression                                       | Prototype — not wired to API |

**What the ML actually does:**

- Scores tourist-guide compatibility (0–100%) using a hybrid recommender (45% content-based + 45% collaborative + 10% destination boost)
- Clusters compatible tourists into groups of 3–8 using K-Means + DBSCAN
- Constructs day itineraries using greedy + 2-opt local search, respecting time windows, budgets, and meal breaks

**Prototype limitations disclosed:** Satisfaction prediction (XGBoost) is a prototype model not yet wired to the recommendation API. Collaborative filtering is trained on 600 synthetic ratings (88% genuine signal + 12% calibrated noise). No real user pilot has been conducted.

---

## 2. Price (Business Model)

**Commission-first B2B2C marketplace.** Three revenue streams:

| Revenue Stream            | Rate         | Trigger                             |
| ------------------------- | ------------ | ----------------------------------- |
| Booking commission        | 15–18%       | Tourist completes booking           |
| Guide premium tools       | $14.99/month | Guide exceeds 20 lifetime bookings  |
| Business partner referral | 5–10%        | Tourist visits listed partner venue |

**Unit economics:**

| Side    | CAC          | LTV             | Payback   |
| ------- | ------------ | --------------- | --------- |
| Tourist | $5–15        | $45–90          | 1 trip    |
| Guide   | $0 (organic) | $600–1,200/year | 1–2 tours |

**Commission rate rationale:** WanderLess takes 15–18%, below Viator (~25%) and GetYourGuide (~20%). Rate justified by superior match quality, not just transaction facilitation. Disintermediation tolerance: 20–30% of tourists estimated to attempt direct guide contact post-intro — accepted as marketplace tax.

---

## 3. Place (Market Strategy)

**Beachhead: Luang Prabang, Laos**

- 10M+ tourists/year, manageable density
- 50 licensed Laos guides (MICT framework modeled in data schema)
- Mobile-first markets; solo travel up 20%+ YoY
- No competitor uses compatibility matching in SE Asia

**Geographic expansion path:** Luang Prabang (months 1–9) → Vientiane + Hoi An (months 10–18) → 5–8 SE Asian cities (months 18–36)

**TAM: $300B** (global tours, activities, experiences); **SAM: $15–20B** (SE Asian personalized experience); **SOM: $75–200M** (0.5–1% capture in 3–5 years)

---

## 4. Promotion (Go-to-Market)

**Phase 1 (Months 1–9): Luang Prabang Beachhead**

- Target: 200 bookings/month by month 6
- 50 guides activated
- NPS target: 40+
- Zero safety incidents
- ML matching accuracy >75% (synthetic validation)

**Key go-to-market insight:** Guide density before tourist scale. Marketing to tourists before sufficient guide density creates a bad experience that destroys trust. The flywheel requires guide supply first.

**Demonstration strategy:** Live backend API (14/14 tests passing), Flutter app with API fallback via cURL commands, 10-minute demo script with marker-facing narration.

---

## Team & Decision Log

Every major architectural and business decision — alternatives considered, trade-offs accepted, and rationale — is documented in `docs/COC_DECISION_LOG_A_PLUS.md`.

---

_WanderLess is a MGMT655 Machine Learning for Decision Making team project. Prototype — not a commercial product. Not for deployment without further development and validation._
