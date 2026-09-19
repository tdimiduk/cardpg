---
title: Research Directory
doc_type: meta
track: ludology
origin: AI drafted
epistemic_status:
  confidence: medium
  vetted_by_human: false
---

# Research Directory

This directory houses the analytical and empirical foundation of **caRdPG**. Its purpose is to provide evidence-based grounding for game mechanics, separating _what is real_ and _how game systems function_ from _how we iterate on specific rules_ (which belongs in `/iteration`).

---

## The Two Research Tracks

Research in caRdPG operates across two distinct epistemological tracks:

### Track A: Verisimilitude Research (Physical Reality & Factual Bedrock)

The evidence-based foundation for our "Casual Realism" guiding principle. Governed by `.agent/standards/empirical_research_standards.md` and investigated by the `empirical_researcher` subagent.

- **[verisimilitude-sources.yaml](verisimilitude-sources.yaml)**: Master bibliography of vetted historical treatises, archaeological data, and scientific/medical publications.
- **[reports/](reports/)**: Deep-dive, point-in-time empirical research reports (e.g., trauma timelines, metabolic costs of armor). Each report contains its findings (`report.md`), research mandate (`prompt.md`), and tooling metadata (`meta.yaml`).
- **[synthesis/](synthesis/)**: Actionable design frameworks and consequence databases (e.g., `armor.md`, `consequences-combat.md`). Translates raw empirical data into practical gameplay reference tables.

### Track B: Ludology & Game Design Theory (Systems & Secondary Sources)

The structural analysis of how tabletop mechanics generate player dynamics, tension, and agency.

- **[ludology-sources.yaml](ludology-sources.yaml)**: Curated catalog of secondary game design theory, analytical essays, system post-mortems, and ludological frameworks.
- **[theory/readings/](theory/readings/)**: Analytical literature notes on substantive game design essays, post-mortems, and critical analyses (e.g., `exploration-is-logistics.md`, `calibrating-your-expectations.md`). Analyzes how external systems work and how caRdPG adapts their insights to its card economy.
- **[inspiration-sources.yaml](inspiration-sources.yaml)**: Curated library of creative media touchstones (books, games, films) establishing a common aesthetic and thematic vocabulary.

---

## Epistemic Provenance & Frontmatter Standard

All internal syntheses and literature notes must include standardized YAML frontmatter tracking their origin, AI generation tool, and human vetting status:

```yaml
---
title: "Logistics & Equipment Consequence Database"
doc_type: "synthesis" # report | synthesis | literature-note | card-database
track: "verisimilitude" # verisimilitude | ludology
origin: "Gemini 2.5 Pro" # Tool or human that laid the foundation
epistemic_status:
  confidence: "medium-low" # speculative | medium-low | medium | high
  audited_by: "Gemini 3.8" # Optional: Set when a newer model reviews/corrects the document
  vetted_by_human: false # false | "Tom Dimiduk (YYYY-MM)"
  vetting_notes: "Unvetted AI draft. Contains placeholder citations needing empirical validation."
related_files:
  - "design/research/reports/functional-decline-under-physical-hardship/report.md"
---
```

### Document Revision Rules:

- **Human Vetting Invariant (`vetted_by_human`):** AI agents must **never** set `vetted_by_human: true` (or assign a human reviewer identifier). Only human designers may mark a document as vetted by a human. When an agent makes substantial edits, structural rewrites, or conceptual additions to any document, the agent **must flip `vetted_by_human` to `false`** and summarize the changes in `vetting_notes` for human re-review.
- **Living Syntheses (`synthesis/`):** **Update in place.** Never spawn `-v2.md` files or delete living databases, as rules, card registries, and modules link to them directly. When a newer AI model audits or expands a file, update `audited_by` or `origin`, and update `confidence`. Git permanently preserves prior revisions.
- **Raw Reports (`reports/`):** Treat as immutable point-in-time harvesting runs. If a new deep research query produces superior data, add a new report folder and mark the older report as superseded in `research/index.yaml` or archive tags.

---

## Contribution & Research Guidelines

- **Style:** Objective, analytical, and concise. Prioritize structured tables, timelines, and clear metrics over conversational exposition.
- **Quantification Standard:** When researching physical exertion, prioritize quantifiable metrics of energy expenditure. **Metabolic Equivalent of Task (METs)** is our system-agnostic standard for comparing action costs.
- **External Archival Mandate:** Whenever an agent or researcher fetches an external paper, report, or essay, archive a clean local copy into `design/research/sources/` (`verisimilitude/`, `ludology/`, or `ephemera/`), commit it to the nested repository, and link it in the appropriate catalog via `local_archive`.
- **Literature Sourcing & Human Escalation Protocol:** Follow the verified 5-tier open-access hierarchy (Internet Archive, Extension Bulletins, CDC Stacks/Federal guides, StatPearls, PMC) detailed in [.agent/standards/empirical_research_standards.md](../../.agent/standards/empirical_research_standards.md#4-literature-sourcing-ingestion-hierarchy--human-escalation) and [sources/README.md](sources/README.md). If a critical source is trapped behind an interactive gate/CAPTCHA, agents are explicitly empowered to request human web UI retrieval. If behind a paywall with no open-access equivalent, request human institutional library retrieval as a last resort.
- **Constraint:** **Do not propose specific game mechanics here.** This directory establishes facts and theoretical frameworks. Mechanic design and rule brainstorming belong in `design/iteration/` and `design/rules/`.<!-- BEGIN AUTO-TOC -->

## Research Catalog

### Bibliographies & Bedrock

| Document                                              | Type                | Summary                                                                                |
| :---------------------------------------------------- | :------------------ | :------------------------------------------------------------------------------------- |
| [Verisimilitude Sources](verisimilitude-sources.yaml) | Factual Bedrock     | A list of historical and scientific sources used to ground the game in casual realism. |
| [Inspiration Sources](inspiration-sources.yaml)       | Inspiration Library | A curated library of media (books, games, films) and their key design lessons.         |
| [Ludology Sources](ludology-sources.yaml)             | Inspiration Library | Catalog of secondary game design theory, essays, and ludological frameworks.           |

### Living Research Syntheses (`synthesis/`)

| Document                                                                          | Type               | Summary                                                                                                                                      |
| :-------------------------------------------------------------------------------- | :----------------- | :------------------------------------------------------------------------------------------------------------------------------------------- |
| [The Armor Tradeoff](synthesis/armor.md)                                          | Research Synthesis | A synthesis of research on historical armor, analyzing the fundamental tradeoff between protection and the physiological costs of exertio... |
| [Tactical Movement & Positioning](synthesis/tactical-movement.md)                 | Research Synthesis | A synthesis of research on historical combat locomotion, providing a factual basis for designing mechanics related to tactical movement, ... |
| [Physical Harm and Trauma](synthesis/physical-harm-and-trauma.md)                 | Research Synthesis | A synthesis of research reports on battlefield injuries and physical hardship, providing a factual basis for designing consequences relat... |
| [Consequence Database Hub](synthesis/consequence-database.md)                     | Research Synthesis | A central hub and calibration guide for the structured, rules-independent databases of physical, cognitive, environmental, and social str... |
| [Combat Consequence Database](synthesis/consequences-combat.md)                   | Research Synthesis | A structured, rules-independent database of physical injuries, tactical disruptions, and combat-related trauma.                              |
| [Exploration Consequence Database](synthesis/consequences-exploration.md)         | Research Synthesis | A structured, rules-independent database of environmental hazards, travel-related hardship, and wilderness trauma.                           |
| [Social Consequence Database](synthesis/consequences-social.md)                   | Research Synthesis | A structured, rules-independent database of social fallout, reputational damage, and psychological stress.                                   |
| [Crafting and Labor Consequence Database](synthesis/consequences-crafting.md)     | Research Synthesis | A structured, rules-independent database of workplace accidents, industrial hazards, downtime exhaustion, and material strain.               |
| [Arcane & Alchemical Consequence Database](synthesis/consequences-arcane.md)      | Research Synthesis | A structured, rules-independent database of magical backdrafts, alchemical toxicity, elemental exposure, and runic failures.                 |
| [Logistics & Equipment Consequence Database](synthesis/consequences-logistics.md) | Research Synthesis | A structured, rules-independent database of equipment wear, transport breakdowns, supply contamination, and pack animal injuries.            |
| [Hardship and Exertion](synthesis/hardship-and-exertion.md)                       | Research Synthesis | A synthesis of research on the functional impact of physical hardship, providing a factual basis for designing consequences related to at... |
| [Catastrophic Trauma & Lethality](synthesis/catastrophic-trauma-and-lethality.md) | Research Synthesis | Translates quantitative research on physiological timelines of death following catastrophic trauma into an evidence-based framework for h... |
| [Dynamics of the Duel](synthesis/dynamics-of-duel.md)                             | Research Synthesis | Synthesizes the key findings from 'The Dynamics of the Duel' report into a concise summary of actionable design principles for combat pac... |
| [Combat Spacing and Reach](synthesis/combat-spacing-and-reach.md)                 | Research Synthesis | A synthesis of research on historical weapon lengths, armor, and fighting styles, providing a factual basis and reference table for model... |
| [Combat Timelines and Tempos](synthesis/combat-timelines-and-tempos.md)           | Research Synthesis | A consolidated synthesis of research on the timescales of combat, providing reference tables for physiological phases, performance degrad... |

### Empirical Reports (`reports/`)

| Report                                                                                          | Type            | Summary                                                                                                                                      |
| :---------------------------------------------------------------------------------------------- | :-------------- | :------------------------------------------------------------------------------------------------------------------------------------------- |
| [Battlefield Injury Research](reports/pre-modern_battlefield_injury/report.md)                  | Research Report | A detailed analysis of pre-modern battlefield trauma, its functional impacts, and progression.                                               |
| [Decline Under Physical Hardship](reports/functional-decline-under-physical-hardship/report.md) | Research Report | A scientific analysis of how real-world injuries and hardship affect the human body, providing a factual basis for the game's consequence... |
| [Catastrophic Trauma Timelines](reports/catastrophic-trauma-timelines/report.md)                | Research Report | A quantitative analysis of the physiological timelines of death following catastrophic trauma.                                               |
| [The Dynamics of the duel](reports/dynamics-of-the-duel/report.md)                              | Research Report | A detailed biomechanical and tactical analysis of pre-modern combat, focusing on physiological energy systems, fatigue, and the rhythm of... |
| [Combat Dynamics Analysis](reports/combat-dynamics-analysis/report.md)                          | Research Report | A detailed tactical and mechanical analysis of pre-modern combat.                                                                            |
| [Combat Locomotion Analysis](reports/combat-locomotion/report.md)                               | Research Report | A detailed biomechanical analysis of pre-modern combat locomotion.                                                                           |
| [Combat Action Time Lexicon](reports/combat-action-time/report.md)                              | Research Report | A quantitative lexicon of the time costs, in seconds, for discrete pre-modern combat actions, including ranged attacks, movement, and wea... |
| [Metabolic Cost of Armor](reports/metabolic-cost-of-armor/report.md)                            | Research Report | A deep-dive research report on the metabolic and biomechanical costs of wearing replica medieval armor, providing quantitative multiplier... |
| [Exertion and Recovery Dynamics](reports/exertion-recovery-dynamics/report.md)                  | Research Report | A quantitative analysis of the physiological dynamics of exertion, stress, and multi-stage recovery.                                         |
| [Positional Advantage](reports/positional-advantage/report.md)                                  | Research Report | A biomechanical, perceptual, and cognitive analysis of positional advantage in pre-modern melee.                                             |
| [Armor Effectiveness Research](reports/armor_effectiveness/report.md)                           | Research Report | Research on armor effectiveness against different damage types.                                                                              |

### Game Design Theory (`theory/readings/`)

| Document                                                                                                         | Type            | Summary                                                                                                                     |
| :--------------------------------------------------------------------------------------------------------------- | :-------------- | :-------------------------------------------------------------------------------------------------------------------------- |
| [Literature Note: How OSR Teaches Us That Exploration Is Logistics](theory/readings/exploration-is-logistics.md) | Literature Note | Analysis of OSR resource management and its application to CardPG's card economy and exploration pacing.                    |
| [Literature Note: Calibrating Your Expectations](theory/readings/calibrating-your-expectations.md)               | Literature Note | Analysis of Justin Alexander's Casual Realism, mortal power thresholds, and their application to CardPG's grounded heroism. |

_Last synced from `research/index.yaml` via `tools/audit_index.py`._

<!-- END AUTO-TOC -->
