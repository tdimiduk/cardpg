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

| Document                                                                 | Type               | Summary                                                                                                                                      |
| :----------------------------------------------------------------------- | :----------------- | :------------------------------------------------------------------------------------------------------------------------------------------- |
| [Resolution System Design Constraints](resolution-design-constraints.md) | Design Constraints | Authoritative reference for architectural constraints, tabletop ergonomics, and evaluation criteria that any proposed Core Resolution Mec... |
| [Resolution System Pitfalls & Anti-Patterns](resolution-pitfalls.md)     | Design Constraints | Authoritative catalog of recurring mechanical failure modes, degenerate incentives, and tabletop friction points discovered across resolu... |

### Active Proposals & Mechanics

| Document                                                                              | Type               | Summary                                                                                                                                   |
| :------------------------------------------------------------------------------------ | :----------------- | :---------------------------------------------------------------------------------------------------------------------------------------- |
| [Consequence Pool & Tag Escalation Engine](consequence-pool-tag-escalation/README.md) | Index              | Comprehensive proposal suite replacing legacy Defense/Resilience with a Consequence Pool and Tag Escalation drafting engine.              |
| [Resolution Mechanic Exploration](resolution-exploration.md)                          | Design Exploration | An honest critique of legacy resolution mechanics (Defense/Resilience) and exploration of alternatives, particularly 'Declared Defenses.' |
| [Defense Action Iteration](defense-action.md)                                         | Ideation           | Exploration of active defense action mechanics and timing.                                                                                |
| [Fatigue Change Proposal](fatigue-change-proposal.md)                                 | Design Exploration | A proposal to change fatigue from 'add cards to deck' to 'overlay cards in deck' using physical card sleeves, keeping deck size constant. |

### Ideation Sketches

| Document                                  | Type     | Summary                                                                                                              |
| :---------------------------------------- | :------- | :------------------------------------------------------------------------------------------------------------------- |
| [Design Sketchbook](design-sketchbook.md) | Ideation | A collection of specific mechanic ideas and explorations; look here to see if an idea exists prior to formalization. |

_Last synced from `iteration/index.yaml` via `tools/audit_index.py`._

<!-- END AUTO-TOC -->
