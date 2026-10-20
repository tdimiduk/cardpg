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

This directory houses the project's empirical testing suite: benchmark scenarios and narrative stress-test traces for validating resolution mechanics, stamina systems, and consequence economies.

Because _caRdPG_ models characters with stateful physical, mental, and logistical limits, game outcomes are deeply path-dependent. Actions taken during morning reconnaissance shape character fatigue by midday, which in turn influences physical resilience during an ambush hours later. In this architecture, canonical benchmark scenarios serve as the tabletop equivalent of **integration tests and behavioral regression suites**.

---

## Operating Conventions & Architecture

1. **Benchmark Scenarios vs. Mechanical Traces:**
   - **Rules-Agnostic Benchmark Scenarios:** Canonical scenario definitions (e.g., the five benchmark scenarios below) establish rich narrative testing arcs across all four pillars (**Combat**, **Exploration**, **Social**, **Downtime**) and all three colors of approach (**[[Red]]**, **[[Yellow]]**, **[[Blue]]**) without baking in specific numerical mechanics or proposal-specific rules. They serve as comparative testbeds for candidate resolution engines.
   - **Proposal-Specific Traces:** Mechanical play traces authored to test exploratory proposals (e.g., Consequence Pool & Tag Escalation) reside within their respective proposal directories until evaluated.
2. **Core Evaluative Focus: Crisis ↔ General Action Coupling & Cross-Domain Bleed:**
   - **Universal Effort & Fatigue:** Exerting effort mentally, socially, or physically draws upon a shared well of human stamina. Working hard all morning leaves an adventurer weary by afternoon.
   - **Asymmetric, Domain-Sensitive Consequence Bleed:** Conditions and consequences suffered in one domain must bleed into others in an honest, biologically and socially plausible manner:
     - _Physical bodily trauma_ (e.g., a sprained ankle or cracked rib from an environmental hazard) heavily degrades physical defense, athletic dodging, and combat mobility.
     - _Social humiliation or political rebuke_ must **never** make a character physically easier to kill outright with a blade, even though the mental strain of a high-pressure debate tires them out.
     - _Neurological and cognitive trauma_ (e.g., an arcane migraine or sensory overload) selectively impairs fine-motor finesse, intellectual deciphering, and rhetorical debate while leaving raw brute-force muscle output relatively functional.
     - _Equipment degradation_ (e.g., a dented breastplate or shredded coat) can be shed or repaired without penalizing social standing or unarmed agility.
     - _Cover or social failure_ propagates forward into the environment as heightened enemy alertness and fortified defenses, rather than personal bodily damage.
3. **Promotion to Canonical Golden Benchmarks:**
   - As game systems solidify, verified traces that resolve cleanly against active core rules will graduate into permanent reference benchmarks for future rules tuning.

---

## Benchmark Scenario Catalog

| Document                                                                                     | Scope             | Focus & Purpose                                                                                                                                                                                                                                                                                                        |
| :------------------------------------------------------------------------------------------- | :---------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **[The Harbor Charter & The Cobblestone Ambush](scenario-urban-debate-and-ambush.md)**       | Urban Arc         | Rules-agnostic urban scenario testing Crisis ↔ General Action coupling across Social debate, Combat ambush, Exploration infiltration, and Downtime recovery. Explores why social humiliation must not reduce physical lethality resistance while physical wounds bleed heavily into subsequent social/covert actions. |
| **[The Sunken Aqueduct & The Vault of Echoes](scenario-mountain-pass-and-ruin-delve.md)**    | Alpine Delve      | Rules-agnostic alpine delve scenario testing environmental harm bleed into combat, pre-crisis casing trade-offs, and post-crisis wounded extraction where bodily trauma turns routine travel into a survival ordeal.                                                                                                   |
| **[The Last Watch at Timber-Ford](scenario-border-keep-siege-and-rally.md)**                 | Border Defense    | Rules-agnostic border defense scenario testing physical labor prep, communal/environmental condition bleed (shaky militia morale attaching to the scene rather than the hero), parley standoffs, protracted multi-wave combat, and spiritual convalescence.                                                            |
| **[The Blighted Apothecary & The Quarantine Riot](scenario-arcane-plague-and-sanctuary.md)** | Arcane Plague     | Rules-agnostic arcane plague scenario testing cognitive and neurological condition bleed into precision tasks, voluntary sanity sacrifice for time, non-lethal crowd crisis, and mental convalescence.                                                                                                                 |
| **[Three Days on the Ash-Hound Trail](scenario-borderland-pursuit-multi-day.md)**            | Multi-Day Pursuit | Rules-agnostic multi-day pursuit scenario testing overland macro attrition, what camp rest clears versus persistent injury/mount conditions, social blown cover propagating into tactical enemy readiness, and stealth-to-combat transitions.                                                                          |
