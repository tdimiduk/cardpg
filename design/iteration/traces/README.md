---
title: "Gameplay Traces & Empirical Benchmarks"
doc_type: meta
track: ludology
origin: AI drafted
epistemic_status:
  confidence: high
  vetted_by_human: false
---

# Gameplay Traces & Empirical Benchmarks

This directory houses the project's empirical testing suite: multi-resolution gameplay traces, standardized character state ledgers, and canonical benchmark scenarios.

Because _caRdPG_ represents character stamina, capabilities, physical trauma, and equipment through stateful 24-card decks, discard piles, and on-table conditions, game outcomes are deeply path-dependent. Choices made in Round 1 shape deck composition in Round 4, which dictates survival during an Effort Cycle an hour later. In this architecture, gameplay traces serve as the tabletop equivalent of **integration tests and behavioral regression suites**.

---

## Operating Conventions & Architecture

1. **Compliance with the 3-Tier Specification:** All traces must conform to the resolutions, notation, and ledger standards defined in [Specification: Multi-Resolution Gameplay Trace Standards](gameplay-trace-standards.md):
   - **Tier 1 (Micro / Atomic Mechanics):** Card-by-card mechanical fidelity, flip-by-flip math, cumulative color sums, and table ergonomics.
   - **Tier 2 (Meso / Encounter & Scene):** Full 3–8 round combat crises or multi-stage skill challenges, focusing on hand depletion, Fatigue Cycles, and tag escalation cascades.
   - **Tier 3 (Macro / Expedition & Session):** Safe Haven to Safe Haven gauntlets, testing deck attrition, Burden drag, Breather cadences, and dungeon clock pacing.
2. **Feature Traces vs. System Integration Traces:**
   - **Feature/Proposal Traces:** Traces authored to test unmerged, exploratory mechanics (e.g. Consequence Pool & Tag Escalation) remain within their proposal package (e.g. `../consequence-pool-tag-escalation/`) until that proposal is resolved.
   - **System Integration Traces:** Multi-round and multi-scene traces testing the broader system and cross-domain loops reside here.
3. **Promotion to Canonical Traces (`design/traces/`):**
   - As game systems solidify, verified traces that resolve cleanly against canonical rules ([`../../rules/`](../../rules/)) will graduate out of `iteration/` into a top-level directory (`design/traces/`).
   - Promoted traces serve as permanent "Golden Benchmarks" for future rules tuning.

---

## Trace Catalog & Benchmarks

| Document                                                                                    | Tier / Scope    | Focus & Purpose                                                                                                                                  |
| :------------------------------------------------------------------------------------------ | :-------------- | :----------------------------------------------------------------------------------------------------------------------------------------------- |
| **[Specification: Multi-Resolution Gameplay Trace Standards](gameplay-trace-standards.md)** | Meta / Standard | Establishes the 3-tier resolution framework (Micro, Meso, Macro), fractal spotlight patterns, and character ledger formatting.                   |
| **[Play Trace: The Sunken Vaults of Mor-Thal](macro-gauntlet-expedition-trace.md)**         | Tier 3 (Macro)  | Full-day expedition gauntlet testing 24-card endurance budgets, 6-Tick Turn Wheels, Breather tradeoffs, and Burden 2 armor drag across 5 scenes. |
| **[Play Trace: The Sunken Matron](trace-climactic-boss-8-rounds.md)**                       | Tier 2 (Meso)   | Extended 8-round boss crisis testing the mid-combat Turn Horizon, fatigue dilution, Pass-to-Charge economy, and finisher escalation.             |
| **[Non-Combat Benchmark Scenarios](non-combat-scenarios.md)**                               | Benchmarks      | Canonical, rules-agnostic test scenarios across environmental, social, and analytical domains to prevent combat-centric rules bias.              |
