# Demo Script — Wanderless Laos

## Demo Thesis

"Wanderless Laos turns local guided tourism from search-and-scroll into compatibility-based decision support."

## Persona

**Emma** — Solo traveler, 4-day Laos trip, interested in culture and food, moderate budget, prefers slow pace, wants English-speaking guide, cautious about safety.

## Demo Path

### 1. Show Landing Page / Product Purpose

Explain: "Wanderless matches you with compatible local guides, not just available ones."

### 2. Show Tourist Onboarding

Emma enters preferences:

- Language: English
- Budget: moderate ($50–150)
- Pace: slow
- Interests: culture, food, heritage
- Safety: high comfort
- Group: solo

### 3. Show Recommended Guides

Top 3 guide recommendations appear with compatibility scores.

### 4. Explain Why the Top Match

"Why this guide" panel shows:

- Interest alignment (culture + food)
- Language match (English)
- Price fit (within budget)
- Safety score (high trust indicator)

### 5. Show Alternative Matches

Compare top guide vs alternatives — show trade-offs.

### 6. Show Group Compatibility

Emma is shown compatible group option — similar interests, compatible pace.

### 7. Show Safety / Trust Indicators

Safety score displayed with explanation of what factors contribute.

### 8. Show Itinerary Recommendation

Suggested day plan with stops, timing, meal breaks.

### 9. Show Booking Simulation

"Confirm booking" flow — clearly labeled as simulation.

### 10. End with Business Value

- Tourist gets confidence and fit assurance
- Guide gets better-fit leads
- Operator gets higher conversion data

## Fallback Demo Plan

If Flutter fails:

1. Run `pytest tests/` — 14/14 pass
2. Show API response using curl commands in `DEMO_API_COMMANDS.md`
3. Show screenshots in `docs/demo_screenshots/`
4. Walk through matching output and explain ML logic

## What NOT to Say

- "This is fully production-ready"
- "We use real user data"
- "This is live booking"
- "This replaces human guides"

## What TO Say

- "This is a pilot-ready prototype"
- "The data is synthetic but structured to mirror realistic matching attributes"
- "The ML layer demonstrates the decision logic needed for a commercial pilot"
