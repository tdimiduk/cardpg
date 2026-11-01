---
title: "Candidate Resolution Mechanics Catalog"
doc_type: meta
track: ludology
origin: AI drafted
epistemic_status:
  confidence: high
  vetted_by_human: false
---

# Candidate Resolution Mechanics Catalog

This directory houses proposed candidate resolution mechanics, alternative architectures, and mechanical exploration suites for **caRdPG**.

Before advancing any candidate to proposal status or testing it in play traces, evaluate it against the authoritative [constraints.md](../constraints.md) and audit it against [pitfalls.md](../pitfalls.md).

---

## Active Candidate Catalog

| Candidate                                                                                     |         Status          | Core Mechanism                                                                                                                                       | Key Strengths                                                                                                   | Open Questions / Known Risks                                                                              |
| :-------------------------------------------------------------------------------------------- | :---------------------: | :--------------------------------------------------------------------------------------------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------------- |
| **[Consequence Pool & Tag Escalation Engine](consequence-pool-tag-escalation/README.md)**     | **Full Proposal Suite** | Layered Pool Fill ($1\text{ Impact} = 1\text{ Card}$) + _"I Cut, You Choose"_ consequence drafting market + $I < N$ soak threshold.                  | High defender agency, clean non-HP harm model, domain decoupling via tags, symmetrical minion design ($N=1$).   | Multi-deck table footprint (4 decks) and heavy card draws on penetrating hits.                            |
| **[Tag Escalation Replacing Resilience](tag-escalation-resilience.md)**                       |  **Targeted Proposal**  | Canon $\lfloor I / D \rfloor$ division + matching leaf tags escalate active conditions (eliminating global Resilience row).                          | Solves Unified Doom with minimal rules footprint (1 paragraph patch), zero pool drafting, and blistering speed. | Lacks post-flip defender agency; discards leftover Impact remainders.                                     |
| **[Consolidated 3-Tier Cards, Pip Tracks & Triage](consolidated-tiered-cards-and-triage.md)** |  **Architecture Seed**  | Single 15-card trauma deck with 3 printed tiers per card + in-place pip markers + decoupled post-combat triage.                                      | Reduces table footprint to 1 deck, completely eliminates mid-combat deck tutoring, cuts in-combat reading load. | Needs drafting rules integration and prototype card set authoring.                                        |
| **[Declared Defense Effort](declared-defense-effort.md)**                                     |  **Early Exploration**  | Defender declares $K$ cards to flip upfront. Meeting Strength succeeds with accepted costs; under-declaring inflicts overage consequences.           | High upfront agency and dramatic tension on declaration.                                                        | High risk of table AP and deck card-counting; uncapped declarations risk stagnation trap.                 |
| **[Push Your Luck & Buy-Off](push-your-luck-buyoff.md)**                                      |  **Early Exploration**  | Sequential flips where defender can stop flipping at any point and buy off remaining Strength with a consequence (+1 severity bump for free choice). | Dramatic risk-mitigation agency.                                                                                | Halting after every single card flip slows Crisis Time; +1 severity bump strains lean 3-to-4 tier ladder. |
