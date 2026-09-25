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

This directory houses the project's empirical testing suite: benchmark scenarios and play traces for validating resolution mechanics and card economies.

Because _caRdPG_ represents character stamina, capabilities, physical trauma, and equipment through stateful 24-card decks, discard piles, and on-table conditions, game outcomes are deeply path-dependent. Choices made in Round 1 shape deck composition in Round 4, which dictates survival during an Effort Cycle an hour later. In this architecture, gameplay traces serve as the tabletop equivalent of **integration tests and behavioral regression suites**.

---

## Operating Conventions & Architecture

1. **Benchmark Scenarios vs. Mechanical Traces:**
   - **Benchmark Scenarios:** Scenario definitions (e.g. [non-combat-scenarios.md](non-combat-scenarios.md)) establish standard test situations across pillars (environmental, social, analytical) without baking in specific resolution mechanics. They serve as comparative testbeds for candidate engines.
   - **Proposal Traces:** Traces authored to test unmerged, exploratory mechanics (e.g. Consequence Pool & Tag Escalation) reside within their proposal package (e.g. `../consequence-pool-tag-escalation/`) until evaluated.
2. **Promotion to Canonical Traces (`design/traces/`):**
   - As game systems solidify, verified traces that resolve cleanly against active rules will graduate into a top-level directory (`design/traces/`).
   - Promoted traces serve as permanent "Golden Benchmarks" for future rules tuning.

---

## Trace Catalog & Benchmarks

| Document                                                      | Scope      | Focus & Purpose                                                                                                                     |
| :------------------------------------------------------------ | :--------- | :---------------------------------------------------------------------------------------------------------------------------------- |
| **[Non-Combat Benchmark Scenarios](non-combat-scenarios.md)** | Benchmarks | Canonical, rules-agnostic test scenarios across environmental, social, and analytical domains to prevent combat-centric rules bias. |
