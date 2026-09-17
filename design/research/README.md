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

- **Living Syntheses (`synthesis/`):** **Update in place.** Never spawn `-v2.md` files or delete living databases, as rules, card registries, and modules link to them directly. When a newer AI model audits or expands a file, update `audited_by` or `origin`, and update `confidence`. Git permanently preserves prior revisions.
- **Raw Reports (`reports/`):** Treat as immutable point-in-time harvesting runs. If a new deep research query produces superior data, add a new report folder and mark the older report as superseded in `research/index.yaml` or archive tags.

---

## Contribution & Research Guidelines

- **Style:** Objective, analytical, and concise. Prioritize structured tables, timelines, and clear metrics over conversational exposition.
- **Quantification Standard:** When researching physical exertion, prioritize quantifiable metrics of energy expenditure. **Metabolic Equivalent of Task (METs)** is our system-agnostic standard for comparing action costs.
- **External Archival Mandate:** Whenever an agent or researcher fetches an external paper, report, or essay, archive a clean local copy into `design/research/sources/` (`verisimilitude/`, `ludology/`, or `ephemera/`), commit it to the nested repository, and link it in the appropriate catalog via `local_archive`.
- **Constraint:** **Do not propose specific game mechanics here.** This directory establishes facts and theoretical frameworks. Mechanic design and rule brainstorming belong in `design/iteration/` and `design/rules/`.
