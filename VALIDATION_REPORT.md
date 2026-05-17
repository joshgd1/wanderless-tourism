# Validation Report

## Test Summary

**Command:** `pytest tests/`
**Result:** 14/14 passed
**Date:** 2026-05-17
**Environment:** macOS Darwin 24.6.0, Python 3.11+

---

## Smoke Test Scenarios

### Scenario 1 — Cultural Solo Traveler (Emma)

**Input:** English, slow pace, culture+food+heritage interests, high safety preference, moderate budget

**Expected behavior:** Top guide emphasizes culture, English language, moderate pace, high safety score

**Actual behavior:** Compatible guide recommended with culture/food interest alignment and high trust score

**Pass/Fail:** PASS

---

### Scenario 2 — Budget Backpacker

**Input:** English, fast pace, adventure+food interests, low budget, solo

**Expected behavior:** Lower-cost guides rank higher; safety threshold remains active

**Actual behavior:** Budget-appropriate guides surfaced; safety scoring still applied

**Pass/Fail:** PASS

---

### Scenario 3 — Food-Focused Traveler

**Input:** English, medium pace, food+heritage interests, medium budget

**Expected behavior:** Food/culture guides rank higher than adventure-only guides

**Actual behavior:** Food-specialized guides ranked above adventure-only guides

**Pass/Fail:** PASS

---

### Scenario 4 — Risk-Sensitive Traveler

**Input:** High safety preference, English, culture+heritage interests

**Expected behavior:** High safety/trust guides rank higher even if price is slightly higher

**Actual behavior:** Safety score weighted prominently in ranking

**Pass/Fail:** PASS

---

### Scenario 5 — Group Compatibility

**Input:** Multiple tourist profiles with similar interests and pace

**Expected behavior:** K-Means clustering groups compatible travelers; DBSCAN flags outliers

**Actual behavior:** Groups formed by similarity; solo candidates identified separately

**Pass/Fail:** PASS

---

## Known Limitations

- **Synthetic data:** All validation uses synthetic tourist/guide profiles and ratings
- **No real booking transaction:** Booking flow is simulated state machine
- **No payment integration:** No Stripe or payment processor involved
- **No production user authentication:** Demo auth uses simple JWT
- **No real-time geolocation:** Location features not in current scope
- **No trained model on real labels:** Weights are fixed, not learned from outcomes

## Next Validation

- 90-day pilot with real users in Luang Prabang
- Collect conversion outcomes (match → booking → completion)
- Collect post-tour satisfaction labels
- Compare matching vs manual guide assignment
- Tune weights based on real outcomes
