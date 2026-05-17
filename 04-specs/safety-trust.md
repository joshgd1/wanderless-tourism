# Safety and Trust Specification

## Overview

WanderLess handles safety and trust as decision-support, not autonomous judgment. The system surfaces safety signals and guide credentials to tourists; the tourist makes the final decision. The platform escalates high-risk cases for human review.

## Purpose

### Tourist Problem Solved

Tourists booking with unknown guides face uncertainty about whether a guide is legitimate, safe, and reputable. They may not know what questions to ask or what credentials to verify. WanderLess surfaces these signals proactively so tourists can make informed decisions.

### Guide Problem Solved

Legitimate guides with strong credentials are indistinguishable from unverified newcomers in a catalog-first platform. WanderLess makes guide quality visible — verified licenses, review history, and safety records surface to tourists who care about them, without penalizing guides who are still building their reputation.

### Platform Operator Problem Solved

The platform needs systematic safety controls without making every safety decision a manual review. This spec describes both implemented controls and the escalation paths for situations that require human judgment.

---

## Core Workflow

### 1. Tourist Sets Safety Preferences

During onboarding, tourists can indicate:

- **License requirement**: "I only want to see MICT-licensed guides in Laos"
- **Experience threshold**: "I prefer guides with 10+ completed tours"
- **Verification level**: "I want to see background-check status"

These preferences are stored in the tourist profile and used to filter or score guides.

### 2. System Displays Guide Trust Signals

When a guide appears in search or recommendation results, the following signals are shown:

| Signal            | Source            | Display                                            |
| ----------------- | ----------------- | -------------------------------------------------- |
| MICT license tier | Guide profile     | Badge: Licensed / Verified Expert / Community Host |
| Completion rate   | Booking history   | "95% tour completion rate"                         |
| Guide since       | Account age       | "Guide since 2023"                                 |
| Average rating    | Post-tour ratings | Stars (1-5)                                        |
| Total tours       | Booking history   | "127 tours completed"                              |
| Response rate     | Messaging system  | "Responds within 2 hours"                          |
| Incident history  | Internal review   | Shown only to platform ops                         |

### 3. Safety Score (Prototype)

The backend calculates a **safety score** (0-100) as a simple weighted signal:

```
safety_score = (
    0.30 * license_verified_score +
    0.25 * completion_rate_score +
    0.20 * rating_score +
    0.15 * experience_score +
    0.10 * response_rate_score
)
```

**Status**: Implemented in `backend/ml/safety_score.py`.

The safety score is displayed as a **decision-support signal** — a low score is a yellow flag, not an automatic rejection.

### 4. User Remains Final Decision-Maker

The tourist always chooses their guide. The safety score does not block bookings or hide guides. A tourist who books a low-safety-score guide has made an informed choice.

### 5. High-Risk Escalation

Cases that require human/platform review:

- Guide with safety score < 30
- Guide with 2+ substantiated complaints in 90 days
- Any safety incident report
- Guide whose license has been revoked or expired

These cases are flagged in an internal dashboard for platform ops review. They are **not** auto-resolved.

---

## Data Inputs

### Guide-Side Inputs

| Input                 | Source                               | Prototype Status |
| --------------------- | ------------------------------------ | ---------------- |
| License tier          | Guide profile (MICT licensing)       | Simulated        |
| Total tours completed | Booking history                      | Implemented      |
| Tour completion rate  | Booking cancellations vs completions | Implemented      |
| Average rating        | Post-tour ratings                    | Implemented      |
| Response rate         | Messaging system                     | Simulated        |
| Incident reports      | Manual flagging                      | Not implemented  |
| Guide age             | Account creation date                | Implemented      |

### Tourist-Side Inputs

| Input                | Source          | Prototype Status |
| -------------------- | --------------- | ---------------- |
| Safety preference    | Tourist profile | Implemented      |
| Safety deal-breakers | Tourist profile | Implemented      |
| Group composition    | Booking request | Implemented      |

### Route/Area Inputs

| Input                 | Source       | Prototype Status |
| --------------------- | ------------ | ---------------- |
| Area safety metadata  | Static data  | Not implemented  |
| Real-time area alerts | External API | Not implemented  |

---

## Decision Logic

### Current Prototype: Simple Weighted Sum

The safety score is a straightforward weighted sum of available signals. No machine learning model is used — no classification, no anomaly detection, no pattern recognition.

```python
def calculate_safety_score(guide, context):
    score = (
        LICENSE_WEIGHT * license_score(guide) +
        COMPLETION_WEIGHT * completion_score(guide) +
        RATING_WEIGHT * rating_score(guide) +
        EXPERIENCE_WEIGHT * experience_score(guide) +
        RESPONSE_WEIGHT * response_score(guide)
    )
    return min(100, max(0, score))
```

**Status**: Implemented in `backend/ml/safety_score.py`.

### Planned Production: Richer Safety Model

A production safety model would incorporate:

- **Temporal patterns**: Declining completion rates, rising complaint ratios
- **Guide self-fulfilling prophecy**: New guides with artificially high early ratings
- **Interaction effects**: Low-rated tourists matched with low-rated guides
- **Text analysis**: NLP on complaint text to categorize incident types
- **External data**: Real-time government travel advisories, area crime statistics

These are **not implemented** in the prototype.

### Safety Score Is Decision Support

The safety score is presented to tourists as one data point among many (compatibility score, price, availability). It is **not** an autonomous safety judgment. The tourist is the decision-maker.

---

## Prototype Status

| Component                   | Status          | Notes                                    |
| --------------------------- | --------------- | ---------------------------------------- |
| Safety score calculation    | **Implemented** | Simple weighted sum in `safety_score.py` |
| Safety score display        | **Implemented** | Returned in API responses                |
| License tier display        | **Implemented** | MICT tiers in guide profile              |
| Tourist safety preferences  | **Implemented** | Filtered in matching pipeline            |
| Incident flagging           | **Planned**     | Manual platform ops process              |
| Real-time area alerts       | **Planned**     | External API integration                 |
| Text analysis on complaints | **Planned**     | NLP on complaint text                    |
| Escalation workflow         | **Planned**     | Internal ops dashboard                   |
| Guide appeal process        | **Planned**     | For false-positive safety flags          |

---

## Risks and Mitigations

### Bias Against New Guides

**Risk**: Safety scores disadvantage new guides who haven't built a rating history or completion record.

**Mitigation**:

- New guides (0-5 tours) receive a **probationary boost** in matching to offset low safety scores
- Safety score is one signal among many; compatibility score drives matching
- Platform actively recruits new guides to build supply

### False Confidence in Low Scores

**Risk**: Tourists may interpret a mid-range safety score (50-70) as "safe enough" without understanding what the score means.

**Mitigation**:

- Safety score is shown alongside specific signals (e.g., "No MICT license on file" or "97% completion rate")
- Explanations accompany low scores explaining the contributing factors
- Score is framed as "safety signal" not "safety guarantee"

### Privacy Risk from Safety Data

**Risk**: Publishing incident history or complaint details — even aggregate — could expose individual tourist information or create legal liability.

**Mitigation**:

- Incident history is visible only to platform ops, not tourists or guides
- Safety score components are aggregate and anonymous
- No individual complaint text is surfaced to tourists

### Safety Score Explainability

**Risk**: A guide with a high score whose tour results in an incident creates a credibility crisis.

**Mitigation**:

- Safety score is clearly labeled as a **decision-support signal, not a guarantee**
- All score components are documented and available for audit
- Post-incident review process examines whether the score failed to surface warning signs

### Appeal and Review Mechanism for Guides

**Risk**: A guide who believes their safety score is inaccurate has no recourse.

**Mitigation**:

- **Planned**: Guide can request a safety score review via the partner dashboard
- Platform ops investigate and can adjust score components manually
- Guide is notified of any score changes and the reasons

### Human Escalation Path

**Risk**: A safety-related situation occurs and the automated system has no escalation path.

**Mitigation**:

- **Planned**: 24/7 ops on-call for safety incidents
- Emergency contact information surfaced in-app during active tours
- Guide and tourist can both flag concerns during or after tours
- Platform retains right to suspend accounts pending review

---

## Rubric Contribution

### Market & Problem

Safety and trust infrastructure directly addresses the "guide invisibility" problem. Tourists who don't know a guide's reputation won't book. Surfacing safety signals makes the first booking viable and reduces post-booking disappointment.

### Product & Demo

The safety score is a visible, concrete ML signal that works in the demo. Tourists see a score; guides see how to improve it. It demonstrates that WanderLess thinks about quality, not just compatibility.

### Business Model

Guide trust signals support the platform's commission model: tourists who trust the platform book more; guides who invest in their safety profile earn higher scores and more bookings.

### Team & Execution

A safety system that escalates to human review for edge cases shows mature product thinking. The distinction between "implemented prototype" and "planned production" is honest and credible.

### AI/ML Depth

The current safety score is a simple weighted sum — not sophisticated ML. This is honest. The production roadmap for real-time anomaly detection and text analysis on complaints is a credible ML upgrade path, demonstrating that the team understands what "real" safety intelligence requires.

---

## Implementation File Cross-Reference

| File                         | ML Capability                              | Status        |
| ---------------------------- | ------------------------------------------ | ------------- |
| `backend/ml/safety_score.py` | Weighted safety scoring                    | Implemented   |
| `backend/models.py`          | Guide.license_verified, Guide.license_type | Implemented   |
| `backend/models.py`          | Booking.cancellation_reason                | Schema exists |
| `backend/main.py`            | `/api/safety/score` endpoint               | Implemented   |
