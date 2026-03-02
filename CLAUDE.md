# OCEAN Foundation Knowledge Base

This repository contains the knowledge base for the OCEAN Foundation - an open standards and open source foundation for **enterprise AI capability**.

## The Foundational Insight

The AI era fundamentally changes the economics of enterprise software creation. The combination of AI-assisted development, pre-constructed enterprise-quality building blocks, and open standards means that **small teams with deep domain expertise can now build what previously required enterprise budgets**. OCEAN provides the systematic infrastructure that makes this transformation accessible.

## Project Overview

**Mission**: Develop and steward open standards, open source software, and shared knowledge infrastructure that enable organizations of all sizes to build trustworthy, interoperable AI systems.

**Vision**: A future where any organization, regardless of size, can build and operate trustworthy AI systems at enterprise scale through open standards, pre-constructed building blocks, and community-shared knowledge.

**Core Principle**: Composition over creation—enterprise concerns are pre-constructed into building blocks; what remains is composition.

## Complete Platform Stack

### Standards Layer (Open Standards)
- **EATP Framework** - Enterprise Agent Trust Protocol for trust lineage
- **CDI Framework** - Competency Depth Index for measuring AI adoption depth
- **Interoperability** - Integration with MCP, A2A, SPIFFE/SPIRE

### Software Layer (Open Source - Apache 2.0)
- **Kailash Core SDK** - 115+ production nodes, workflow orchestration, runtime engines
- **DataFlow** - Zero-config database operations, MongoDB-style queries
- **Nexus** - Multi-channel deployment (API + CLI + MCP)
- **Kaizen** - AI agent framework, signature-based, 87% less code

### Knowledge Layer (Community)
- Reference architectures and best practices
- Training programs (via NTUC partnership)
- Vibe coding methodology and setup

### Ecosystem Layer (Partnerships)
- ASME (SME advocacy), NTUC (training), SBF (policy bridge)
- Certification and conformance programs
- Community governance

## Repository Structure

```
docs/
├── 00-anchor/           # Foundation truths (AUTHORITATIVE - must not contradict)
│   ├── 00-first-principles.md    # Core beliefs, entrenched constraints
│   ├── 01-core-entities.md       # Foundation independence
│   ├── 02-the-gap.md             # What OCEAN fills
│   ├── 03-ip-ownership.md        # IP and licensing
│   ├── 04-value-model.md         # Economics of openness
│   ├── 05-governance.md          # Decision-making authority
│   ├── 06-stakeholders.md        # Commitments to each audience
│   ├── 07-failure-modes.md       # What happens when things go wrong
│   └── 08-gap-closure.md         # Implementation requirements
├── 01-strategy/         # Strategic direction
├── 02-standards/        # EATP, CDI specifications
├── 03-technology/       # Kailash SDK, architecture
├── 04-community/        # Community governance
├── 05-partnerships/     # Partner documentation (ASME, NTUC, SBF, Government)
├── 06-operations/       # Operational processes
├── 07-compliance/       # Legal and compliance
├── 08-research/         # Supporting research
├── presentations/       # Generated output
└── instructions/        # Agent instructions
```

**Rule of Precedence**: When documents conflict, 00-anchor/ is authoritative. Nothing can contradict anchor documents.

## Working with This Knowledge Base

### Available Agents

**Domain Experts** (for technical questions):
- `care-expert` - CARE framework, Dual Plane Model, Mirror Thesis, Human-on-the-Loop
- `eatp-expert` - EATP Framework, trust lineage, verification gradient, trust postures
- `coc-expert` - COC framework, five-layer architecture, vibe coding critique
- `agentic-enterprise-expert` - Agent hierarchy, governance mesh
- `kailash-expert` - Kailash SDK, implementation details
- `depth-metrics-expert` - CDI levels, adoption measurement
- `context-engineering-expert` - Context engineering, knowledge persistence, portability
- `singapore-ecosystem-expert` - ASME, NTUC, SBF, government
- `foundation-governance-expert` - Legal structure, funding, IP

**Use-Case Agents** (for tasks):
- `research-analyst` - Create/update papers and documentation
- `debate-expert` - Answer and debate questions
- `presentation-creator` - Create decks and talking points
- `stakeholder-communicator` - Craft communications for specific audiences
- `alignment-critic` - Check alignment with OCEAN philosophy

### Available Skills

- `/ocean-philosophy` - Core principles and mission
- `/care-reference` - CARE framework reference (Dual Plane, Mirror Thesis, Human-on-the-Loop)
- `/eatp-reference` - EATP technical reference (trust lineage, verification gradient, trust postures)
- `/coc-reference` - COC framework reference (five-layer architecture, institutional knowledge)
- `/cdi-assessment` - CDI assessment framework
- `/ocean-alignment` - Alignment checklist

### Available Commands

- `/kb-search [topic]` - Search the knowledge base
- `/create-whitepaper [topic]` - Create a white paper
- `/create-presentation [topic]` - Create a presentation
- `/debate [topic]` - Engage in debate on a position
- `/check-alignment [content]` - Check alignment with philosophy
- `/assess-cdi [context]` - Assess CDI level

## Key Principles (from 00-anchor/00-first-principles.md)

1. **Sustainability Enables Mission** - Commercial viability required, not shameful
2. **Contributors Deserve Recognition and Reward** - No martyrdom; fair exchange
3. **Protection Without Restriction** - Patents as shields, not swords
4. **Transparency Over Cleverness** - All relationships documented publicly
5. **Community Before Platform** - People, not code, are irreplaceable
6. **Applications Over Research** - Commercializing AI, not creating models

## Entrenched Constraints (require 90% board + 80% member approval + 12-month notice)

1. Foundation does not profit (CLG structure)
2. License stability (no retroactive changes)
3. Contributor protection is irrevocable
4. Transparent relationships (all disclosed)
5. Community voice (RFC process)
6. Singapore first, then ASEAN

## What OCEAN IS NOT

- NOT a methodology provider
- NOT a rapid delivery accelerator
- NOT a proprietary product company
- NOT a consulting firm
- NOT a vendor (we enable vendors)

## When Creating Content

**CRITICAL**: All content must align with `docs/00-anchor/` documents.

1. Read relevant anchor documents FIRST
2. Check alignment using `/check-alignment` or invoke `alignment-critic` agent
3. Content that contradicts anchors is NOT aligned, regardless of other considerations

**Key Terminology:**

*Governance Framework (CARE):*
- CARE: Collaborative Autonomous Reflective Enterprise
- Dual Plane Model: Trust Plane (human) + Execution Plane (shared with AI)
- Mirror Thesis: AI execution reveals uniquely human value
- Human-on-the-Loop: Third path between human-in-the-loop and human-out-of-the-loop
- Six Human Competencies: Ethical Judgment, Relationship Capital, Contextual Wisdom, Creative Synthesis, Emotional Intelligence, Cultural Navigation

*Trust Protocol (EATP):*
- EATP elements: Genesis Record, Capability Attestation, Delegation Record, Constraint Envelope, Audit Anchor
- Trust Lineage Chain: The complete chain formed by linking the five EATP elements
- EATP Operations: ESTABLISH, DELEGATE, VERIFY, AUDIT
- Verification Gradient: Auto-approved, Flagged, Held, Blocked
- Trust Postures: Pseudo-Agent, Supervised, Shared Planning, Continuous Insight, Delegated
- Traceability vs Accountability: EATP provides traceability; accountability requires organizational practices

*Development Methodology (COC):*
- COC: Cognitive Orchestration for Codegen
- Five Layers: Intent (agents), Context (library), Guardrails (supervisor), Instructions (procedures), Learning (evolution)
- Three Fault Lines of Vibe Coding: Amnesia, Convention Drift, Security Blindness
- Anti-amnesia hook: Deterministic rule re-injection surviving context compression
- Framework-First: Check frameworks before coding from scratch
- Context Engineering: Organizational knowledge persisting across sessions (distinct from prompt engineering)
- CDI levels: 1 (Aware), 2 (Experimenting), 3 (Implementing), 4 (Optimizing), 5 (Transforming)

*Platform Components:*
- Kailash Core SDK: Foundation layer with 115+ nodes
- DataFlow: Zero-config database operations
- Nexus: Multi-channel deployment platform
- Kaizen: AI agent framework

*Institutional Roles:*
- Foundation (standards + software), ASME (SME advocacy), NTUC (training), SBF (policy bridge)
