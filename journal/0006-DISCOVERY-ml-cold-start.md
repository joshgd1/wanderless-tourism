# DISCOVERY: Cold Start Is Actually Three Distinct Problems

## Finding

The pitch deck treats "cold start" as a single problem. Analysis reveals it's actually **three distinct problems** with different severity and solutions:

### 1. Tourist Cold Start (Moderate Problem)

Tourist with no history → use stated preferences (5 sliders) only

- **Solution**: Content-based matching dominates until collaborative signals accumulate
- **Severity**: LOW - stated preferences are reasonably predictive

### 2. Guide Cold Start (Serious Problem)

New guide with no ratings → no collaborative filtering signal

- **Solution**: Content-based expertise vectors + synthetic training data
- **Severity**: HIGH - this blocks guide value proposition

### 3. Marketplace Cold Start (Existential Problem)

No one on platform → no data for any matching

- **Solution**: Synthetic data + staged rollout
- **Severity**: CRITICAL - this is the primary failure mode

## Why This Matters

Most ML cold-start literature focuses on #1. For WanderLess, **#2 and #3 are the real challenges**.

## Implication for Building

- Guide onboarding must include "probationary matching" period
- Early guides need extra attention (higher payouts? guaranteed visibility?)
- Synthetic data strategy needs to be more sophisticated than "just use general interest distributions"

## Source

ML architecture deep dive
