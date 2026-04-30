---
name: language-bonus-inverts-local-guide-incentive
description: Flat +0.30 language match bonus rewards multilingual tourist guides over authentically local mono-lingual guides — inverts authenticity incentive
type: GAP
---

## GAP: Language Match Bonus Inverts Local Guide Incentive

**File**: `backend/matching.py:73,82`

```python
lang_match = 1.0 if tourist.language in [lp.split("→")[0] ...] else 0.0
bonus = lang_match * 0.30 + (compat - 0.8) * 0.15
```

The flat +0.30 bonus for language match creates a perverse incentive:

**Guide A** — Monolingual authentic local:

- `language_pairs = "en→th"` (learned English serving tourists over 20 years)
- Deep local knowledge, third-generation local
- **Gets +0.30 language bonus**

**Guide B** — Multilingual tourist-oriented:

- `language_pairs = "en→th|ru→th|de→th|es→th|zh→th"`
- Certified international guide, learned Thai from textbooks
- **Gets +0.30 language bonus** (same as Guide A)

The bonus doesn't reward:

- Depth of local residency
- How the guide acquired the language
- Whether Thai is native vs. learned

But it does reward:

- Adding more language pairs (to capture the bonus across more tourist nationalities)

**Inverted signal**: A guide who adds "zh→th" (learned Chinese from a course) to their profile gets a higher language match bonus than a guide who has spent 30 years in the same neighborhood.

**Second-order effect**: Guides are incentivized to list more language pairs (to maximize bonus eligibility) rather than deepening their local expertise.

**Fix options**:

1. Replace flat bonus with tiered: native speaker = 0.30, fluent = 0.20, conversational = 0.10
2. Add source-language quality weight: how the guide acquired Thai (native vs. learned)
3. Combine language bonus with authenticity signal: local + bilingual > tourist-oriented + multilingual
4. Use `language_pairs` as a filter (guide must speak tourist's language) not a scorer

**Status**: GAP identified, not fixed in this session. Language matching is a filter in MVP, not a differentiator.
