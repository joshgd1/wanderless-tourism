# Authentication and Identity Specification

## 1. Purpose

Authentication and identity are the trust foundation for WanderLess's three-sided marketplace. Every tourist, guide, and business partner must have a verified identity before transacting. Identity data also feeds safety scoring, guide licensing verification, and dispute resolution.

## 2. User Problem Solved

**Tourist**: Wants to know that the guide they book is a real, licensed person — not an anonymous stranger. Also wants their own data protected.

**Guide**: Needs a credible identity profile that differentiates them from unverified competitors and builds tourist trust. MICT license verification is required for Laos and Singapore operations.

**Business Partner**: Needs assurance that the platform is a legitimate channel for qualified tourist footfall, not a spam aggregator.

**Platform Operator**: Needs role-based access control to separate tourist, guide, partner, and admin capabilities. Must also support compliance with tourism regulations (MICT licensing) and dispute handling.

## 3. User Roles Affected

| Role              | Authentication Method                         | Identity Requirements                              |
| ----------------- | --------------------------------------------- | -------------------------------------------------- |
| Tourist           | Email + password; optional phone verification | Name, email, nationality (optional)                |
| Guide             | Email + password + ID document upload         | Full name, ID document, MICT license if applicable |
| Business Partner  | Email + password + business registration      | Business name, registration number, contact        |
| Platform Operator | Email + password + MFA                        | Internal staff credentials                         |

## 4. Core Workflow

### Tourist Registration and Login

1. Tourist submits email + password.
2. Server creates account with `tourist` role, generates JWT access token.
3. Optional: Tourist completes phone verification (OTP).
4. Tourist optionally completes interest-profile onboarding.
5. Subsequent requests include JWT in `Authorization: Bearer <token>` header.
6. JWT refresh token enables session continuity.

### Guide Registration and Verification

1. Guide submits email + password + personal ID document (image upload).
2. Guide submits MICT license information (Laos or Singapore) or equivalent regional license.
3. Platform stores documents pending review.
4. **Manual review** (planned): Platform ops verify documents within 48 hours.
5. Guide account activates on approval.
6. JWT issued with `guide` role.

**Current Status**: Email/password registration implemented; document upload and manual review are **planned** production features.

### Business Partner Registration

1. Business submits email + password + business registration number + business name.
2. Platform validates registration number format.
3. Account created with `partner` role.
4. **Verification**: Business registration number cross-check is **planned**.

### Role-Based Access Control

| Endpoint                     | Tourist | Guide | Partner | Operator |
| ---------------------------- | ------- | ----- | ------- | -------- |
| `GET /api/recommendations/*` | ✓       | ✓     | —       | ✓        |
| `POST /api/bookings/*`       | ✓       | ✓     | —       | ✓        |
| `POST /api/groups/form`      | ✓       | —     | —       | ✓        |
| `GET /api/partner/analytics` | —       | —     | ✓       | ✓        |
| `GET /api/ops/flags`         | —       | —     | —       | ✓        |
| `POST /api/admin/*`          | —       | —     | —       | ✓        |

JWT claims encode: `{ "sub": "<user_id>", "role": "<role>", "exp": <timestamp> }`.

## 5. Data Inputs

| Field              | Type   | Required      | Stored    | Notes                                       |
| ------------------ | ------ | ------------- | --------- | ------------------------------------------- |
| `email`            | string | Yes           | Hashed    | Unique; used as login identifier            |
| `password_hash`    | string | Yes           | bcrypt    | Never stored plaintext                      |
| `role`             | enum   | Yes           | Plaintext | tourist / guide / partner / operator        |
| `phone`            | string | No            | E.164     | Optional OTP verification                   |
| `full_name`        | string | Guide/Partner | Encrypted | PII; access controlled                      |
| `id_document_url`  | string | Guide         | Encrypted | S3 signed URL; ops-only access              |
| `license_number`   | string | Guide (LA/SG) | Encrypted | MICT license number                         |
| `license_tier`     | enum   | Guide (SG)    | Plaintext | licensed / verified_expert / community_host |
| `business_reg_num` | string | Partner       | Encrypted | Business registration number                |
| `business_name`    | string | Partner       | Plaintext | Display name                                |
| `mfa_enabled`      | bool   | Operator      | Plaintext | TOTP-based second factor                    |

## 6. Decision Logic

### Guide Licensing Verification (Planned)

```
if guide.region == "SG":
    if guide.license_tier == "licensed":
        verify_against_MICT_registry(guide.license_number)  # planned
        if not valid:
            flag_for_manual_review()
```

Current implementation: License tier is self-reported and stored directly. No MICT registry cross-check exists.

### Password Strength

Minimum 8 characters; no common password dictionary check in prototype. Production would integrate a common-passwords blocklist.

### JWT Expiry

Access tokens expire after 1 hour. Refresh tokens expire after 30 days. **Refresh token rotation** (revoke old on reissue) is a planned upgrade.

## 7. Prototype Status

| Capability                | Status          | Notes                                                 |
| ------------------------- | --------------- | ----------------------------------------------------- |
| Tourist registration      | **Implemented** | Email/password; JWT issued                            |
| Tourist login             | **Implemented** | JWT returned on valid credentials                     |
| Guide registration        | **Implemented** | Email/password; role assigned                         |
| Guide document upload     | **Planned**     | S3 upload + encrypted storage; manual review workflow |
| MICT license verification | **Planned**     | Registry cross-check; manual ops review               |
| Partner registration      | **Implemented** | Email/password; role assigned                         |
| Business reg verification | **Planned**     | Format validation only; no registry check             |
| Operator MFA              | **Planned**     | TOTP-based; internal ops only                         |
| Role-based JWT claims     | **Implemented** | Role field in JWT payload                             |
| Password reset flow       | **Planned**     | Email-based reset; token expiry                       |
| Session revocation        | **Planned**     | Redis token blocklist or refresh rotation             |

## 8. Production Upgrade Path

- **Document storage**: Migrate from local encrypted storage to S3 with signed URLs and lifecycle policies.
- **KYC integration**: Integrate with Singapore MyInfo, Laos digital ID, or equivalent regional KYC provider.
- **MICT registry**: Connect to MICT license registry API for automatic license verification.
- **Fraud detection**: Flag accounts created from high-risk IPs or with suspicious document patterns.
- **MFA**: Deploy TOTP (Google Authenticator / Authy) for all operator accounts.
- **Audit logging**: Log all identity data access for compliance and incident response.

## 9. Edge Cases

- **Tourist books guide with expired license**: Guide's license_expiry is checked at booking time; expired license triggers booking block + notification. **Planned**.
- **Guide disputes license revocation**: Appeal process routed to ops via internal ticket. **Planned**.
- **Identity document contains PII beyond scope**: S3 metadata tags document category; ops access logged. Documents auto-purge after 7 years per data retention policy. **Planned**.
- **JWT stolen**: Refresh token rotation revokes stolen token on reissue. Attacker must have both access and refresh token. **Planned**.
- **Account takeover**: Phone/email verification required for password change. **Planned**.

## 10. Risks and Mitigations

| Risk                                                | Mitigation                                                                   |
| --------------------------------------------------- | ---------------------------------------------------------------------------- |
| **Privacy**: PII in documents                       | Encrypted at rest; S3 signed URLs; access logged; ops-only                   |
| **Fraud**: Fake guide accounts                      | Document upload + manual review before activation; MICT registry check       |
| **Trust**: Tourist books with unverified guide      | Safety score reflects license tier; tourist safety preference filters        |
| **Safety**: Guide identity not confirmed            | License verification before guide appears in search; incident flagging       |
| **Bias**: License tiers favor certain nationalities | Regional license equivalents accepted; platform ops review edge cases        |
| **Compliance**: PDPA / PDPA equivalents             | Data minimization; encryption; retention limits; audit logs                  |
| **Operational**: Ops credential compromise          | MFA required for all operator accounts; access logged; least-privilege roles |

## 11. Rubric Contribution

### Market & Problem

Identity verification directly addresses the "guide invisibility" problem tourists face. A tourist booking a guide they found online needs to know that person is real, licensed, and has a track record. Auth + identity makes first-booking viable.

### Product & Demo

Working tourist/guide registration with JWT auth is demonstrated in the Flutter app. The demo shows real account creation — not just "browsing." This raises the product from "prototype UI" to "functional marketplace."

### Business Model

Identity enables the commission settlement engine (who completed what tour), dispute resolution (who was who), and guide premium tiering (verified vs. community host). Without verified identity, the business model lacks accountability.

### Team & Execution

Documenting the difference between prototype registration and planned KYC compliance shows the team understands the gap between a demo and a deployable product. This is credible — it shows the team has thought about what production requires.

### AI/ML Depth

Identity data (completed tours, license tier, rating history) feeds the safety score and collaborative filtering. Guide verification level is a feature in the matching model. The auth layer is the foundation for all downstream ML signals.
