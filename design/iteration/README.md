---
title: Iteration Directory
doc_type: meta
track: ludology
origin: AI drafted
epistemic_status:
  confidence: high
  vetted_by_human: false
---

# Iteration & Active Design Workshop

This directory serves as the active workshop and incubation space for **caRdPG** system design. Documents here represent unsettled ideas, active proposals, mechanical constraints, and ideation sketches.

---

## Operating Conventions

1. **Working State:** Unlike `rules/` (canonical) and `research/` (evidence bedrock), files in `iteration/` are exploratory and iterative.
2. **Encapsulated Suites:** Multi-file proposals (such as `consequence-pool-tag-escalation/`) should be packaged in self-contained subdirectories with their own local `index.yaml`.
3. **Graduation:** Once a proposal is finalized and approved, its rules graduate to `rules/` (e.g. `core-rules.md` or `gamemaster-guide.md`) and the iteration draft is archived or tagged as superseded.

<!-- BEGIN AUTO-TOC -->

## Active Iteration Catalog

### Mechanical Constraints & Frameworks

| Document                                                                                | Summary                                                                                                                                                      |
| :-------------------------------------------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Resolution System Design Constraints & Evaluation Criteria](resolution/constraints.md) | Authoritative reference for architectural constraints, tabletop ergonomics, and evaluation criteria that any proposed Core Resolution Mechanic must satisfy. |
| [Resolution System Pitfalls & Anti-Patterns](resolution/pitfalls.md)                    | Authoritative catalog of recurring mechanical failure modes, degenerate incentives, and tabletop friction points discovered across resolution iterations.    |

### Active Proposals & Mechanics

| Document                                                                                                                                            | Summary                                                                                                                                                          |
| :-------------------------------------------------------------------------------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Candidate Resolution Mechanics Catalog](resolution/candidates/README.md)                                                                           | Catalog and comparison overview of active candidate resolution mechanics.                                                                                        |
| [Consequence Pool & Tag Escalation Engine](resolution/candidates/consequence-pool-tag-escalation/README.md)                                         | Comprehensive proposal suite replacing legacy Defense/Resilience with a Consequence Pool and Tag Escalation drafting engine.                                     |
| [Candidate Architecture: Consolidated 3-Tier Cards, Pip Tracks & Post-Combat Triage](resolution/candidates/consolidated-tiered-cards-and-triage.md) | Candidate architecture featuring single-deck 3-tier cards, in-place pip escalation, and post-combat triage.                                                      |
| [Candidate Resolution Mechanic: Declared Defense Effort](resolution/candidates/declared-defense-effort.md)                                          | Candidate exploration: upfront declaration of defense flips with accepted costs and overage penalties.                                                           |
| [Candidate Resolution Mechanic: Push Your Luck & The Consequence Buy-Off](resolution/candidates/push-your-luck-buyoff.md)                           | Candidate exploration: sequential flips with consequence buy-offs.                                                                                               |
| [Core Resolution Mechanics: History & Open Design Space](resolution/history-and-design-space.md)                                                    | Historical post-mortems of prior mechanics and taxonomy of open mechanical design axes.                                                                          |
| [Fatigue Change Proposal](fatigue-change-proposal.md)                                                                                               | A proposal to change fatigue from 'add cards to deck' to 'overlay cards in deck' using physical card sleeves, keeping deck size constant.                        |
| [Design Proposal: Carrying Capacity, Load, and Pack Architecture](carrying-capacity-proposal.md)                                                    | High-level design proposal for the Carrying Capacity module: Load = Weight + Awkwardness, container transformations, Frame + Conditioning Load Increment, and... |
| [Carrying Capacity & Logistics: Empirical Benchmarks & Formula Stress-Testing](carrying-capacity-benchmarks.md)                                     | Empirically calibrated benchmark dataset for weapons, armor, containers, delving gear, trade goods, and pack creatures, with stress-test evaluations of Candi... |

### Ideation Sketches

| Document                                                                                                                 | Summary                                                                                                                                                          |
| :----------------------------------------------------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Design Sketchbook](design-sketchbook.md)                                                                                | A collection of specific mechanic ideas and explorations; look here to see if an idea exists prior to formalization.                                             |
| [Brief: Inline Card Art Rendering & Embedding Pipeline](card-art-rendering-pipeline-brief.md)                            | Pipeline to embed live card layouts into rules documentation from data/cards/ YAML definitions using native Reflex components.                                   |
| [Universal Guide to Writing Consequence & Condition Cards](resolution/universal-consequence-authoring.md)                | Universal style and authoring guide for consequence and condition cards across all caRdPG resolution engines.                                                    |
| [Design Brief: Consequence Scaling, Progression, and Recovery Economics](resolution/consequence-scaling-and-recovery.md) | Design brief exploring how consequence passive penalties, in-combat action recoveries, and out-of-combat task checks interact with character progression and ... |

### Macro Structure & Gameplay Traces

| Document                                                                                                                                  | Summary                                                                                                                                                          |
| :---------------------------------------------------------------------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Design Brief: Macro Structure, Session Cadence, and Campaign Roadmap](macro-structure-and-gameplay-loop-brief.md)                        | Articulates and formalizes the macro-level gameplay loop, session cadence, and campaign lifecycle connecting crisis resolution and exploration.                  |
| [Design Brief: Exploration Procedures, Dungeon Clocks, and Location Decks](exploration-decks-and-dungeon-clocks-brief.md)                 | Table procedures for Adventuring Time, formalizing the 6-Tick Turn Wheel, Location Decks, and Effort Cycle pacing.                                               |
| [Design Brief: Crisis Round Duration and Phrase Cadence](crisis-round-duration-and-phrase-cadence-brief.md)                               | Finalizes the 2.0-3.0 second round duration, aligns deck cycle math with ATP-PCr energetics, and evaluates adopting the 'Phrase of Arms' concept.                |
| [Design Brief: Movement, Area Control, and Reach Priority in Simultaneous Crisis Time](movement-area-control-and-reach-priority-brief.md) | Deep dive on movement, spatial interception, area control, and reach priority in 2-3s simultaneous rounds without Attacks of Opportunity.                        |
| [Design Brief: Action Stack Accumulation for Extended Actions](action-stack-accumulation-for-extended-actions-brief.md)                   | Authoring framework and rules standard for multi-round Crisis Time actions via progressive Action Stack accumulation across Plan Steps.                          |
| [Gameplay Traces & Empirical Benchmarks](traces/README.md)                                                                                | Multi-resolution gameplay traces, character ledgers, and empirical benchmark scenarios testing combat, fatigue, and expedition pacing.                           |
| [Campaign Workshop: The Outlaw of Weeping Fen](campaign-weeping-fen/README.md)                                                            | Development benchmark scenario: a short, complete campaign arc testing travel, non-combat general actions, tactical combat, persistent harm, and the living w... |
| [Campaign Workshop: The Delve of Crag-Gallows](campaign-crag-gallows/README.md)                                                           | Zero-GM benchmark scenario: a procedural dungeon and wilderness crawl testing fatigue accumulation, consequence escalation, push-your-luck retreat loops, and... |

_Last synced from `iteration/index.yaml` via `audit-index`._

<!-- END AUTO-TOC -->
