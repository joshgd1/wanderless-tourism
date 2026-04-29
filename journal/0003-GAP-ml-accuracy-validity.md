# GAP: ML Accuracy Claims Are Unvalidated Targets

## Gap

The pitch deck claims "85%+ directional accuracy after 10K tours." This is presented as a feature milestone, but it's actually an **unvalidated assumption**.

## What We Don't Know

1. Is 85% accuracy achievable with the proposed architecture?
2. What exactly does "directional accuracy" mean? (Predicted > 3.5 → actual > 3.5?)
3. What's the baseline to beat? (Random guessing gets ~40% for 5-class)
4. Has any travel matching system achieved this?

## Why This Is Critical

The entire value proposition rests on ML producing **better matches than alternatives**. If matching quality is only marginally better than random or popularity-based selection, the platform offers no advantage over catalog browsing.

## Missing Validation

- No mention of ML model benchmarks in pitch materials
- No comparison to random baseline
- No mention of cold-start performance (the hardest problem)
- No A/B test framework described

## What Needs to Happen

1. Define "directional accuracy" precisely
2. Establish baseline (random, popularity, content-only)
3. Design cold-start ML strategy (synthetic data is a placeholder)
4. Plan validation milestones at 500, 1000, 5000 tours

## Source

ML architecture analysis, red team
