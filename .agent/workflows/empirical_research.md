---
description: Empirical research workflow covering gap analysis, literature harvesting, quantitative synthesis, and verisimilitude auditing
---

# Empirical Research Workflow

This workflow guides all empirical research tasks across CardPG, connecting design requirements to the project's factual bedrock.

---

## 1. Context & Standards

Before executing, load the core standards:

- `view_file <workspace_root>/.agent/standards/standards.md`
- `view_file <workspace_root>/.agent/standards/empirical_research_standards.md`
- Check `design/research/sources/README.md` if operating on vault bundles.

---

## 2. Determine Mode from Request

| Mode               | Trigger Keywords                                                                | Subagent & Strategy                                                    | Behavior                                                                                                                                                             |
| :----------------- | :------------------------------------------------------------------------------ | :--------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`gap_analysis`** | "gap analysis", "assess gaps", "what are we missing", "research agenda"         | **Main Agent Direct Execution**                                        | Audit design requirements against `design/research/index.yaml` and catalogs. Isolate ungrounded assumptions and formulate quantitative research questions.           |
| **`harvest`**      | "find sources", "harvest", "archive paper", "ingest source", "look up research" | **Delegate to `source_harvester`** (`enable_write_tools: true`)        | Searches open-access repositories (Tier 1/2), executes `archive_source.py ingest --commit`, verifies extraction, and registers catalog YAML.                         |
| **`synthesize`**   | "synthesize", "extract metrics", "summarize research", "build synthesis"        | **Delegate to `empirical_synthesizer`** (`enable_write_tools: false`)  | Reads local `sources/<track>/<slug>/extracted.*` text files. Extracts hard numbers (METs, Joules, timescales, failure modes) and drafts structured reference tables. |
| **`audit`**        | "fact check", "audit verisimilitude", "is this realistic", "check rules"        | **Delegate to `verisimilitude_auditor`** (`enable_write_tools: false`) | Cross-examines proposed mechanics against `design/research/synthesis/`. Flags Gross Violations vs. Casual Realism stylization.                                       |

---

## 3. Execution Procedures

### Mode: `gap_analysis` (Main Agent)

1. **Scope the Subsystem:** Identify the physical interactions, materials, or environmental hardships involved in the active mechanic or module.
2. **Catalog Audit:** Check `design/research/verisimilitude-sources.yaml`, `design/research/ludology-sources.yaml`, and `design/research/synthesis/` for existing coverage.
3. **Formulate Questions:** Output a structured research agenda defining:
   - Primary physical phenomenon (e.g. cold-water immersion, rock spalling, draft horse pull limits)
   - Specific quantitative metrics needed (Joules, failure curves, recovery duration, metabolic cost in METs)
   - Target source types (Tier 1 primary manual, experimental archaeology, or Tier 2 clinical/extension bulletin).

### Mode: `harvest` (Subagent: `source_harvester`)

1. Define and invoke `source_harvester` via `invoke_subagent` (`enable_write_tools: true`) following [.agent/skills/empirical_research_subagents/SKILL.md](file:///home/tdimiduk/cardpg/cardpg/.agent/skills/empirical_research_subagents/SKILL.md).
2. The subagent searches open-access tiers per the [Automated Ingestion Hierarchy](file:///home/tdimiduk/cardpg/cardpg/.agent/standards/empirical_research_standards.md#b-automated-ingestion-hierarchy-open-access-tiers).
3. The subagent ingests the source via `archive_source.py ingest` (see [design/research/sources/README.md](file:///home/tdimiduk/cardpg/cardpg/design/research/sources/README.md) for CLI options and automated catalog registration), verifies clean text extraction via `view_file`, and reports back.
4. If blocked by an interactive gate or paywall, escalate per the Human Escalation Boundary below.

### Mode: `synthesize` (Subagent: `empirical_synthesizer`)

1. Define and invoke `empirical_synthesizer` via `invoke_subagent` (`enable_write_tools: false`) following [.agent/skills/empirical_research_subagents/SKILL.md](file:///home/tdimiduk/cardpg/cardpg/.agent/skills/empirical_research_subagents/SKILL.md).
2. Pass the path to the vaulted bundle text (e.g. `design/research/sources/verisimilitude/<slug>/extracted.txt`).
3. Subagent reads the source text, extracts quantitative parameters, and returns a draft synthesis.
4. **Parent Ingestion:** The parent agent reviews the output and integrates it into a living document in `design/research/synthesis/<topic>.md` (or a point-in-time report under `design/research/reports/<slug>/`).
5. Ensure epistemic frontmatter is complete (`origin`, `doc_type`, `epistemic_status`, `vetted_by_human: false`).

### Mode: `audit` (Subagent: `verisimilitude_auditor`)

1. Define and invoke `verisimilitude_auditor` via `invoke_subagent` (`enable_write_tools: false`) following [.agent/skills/tabletop_rules_subagents/SKILL.md](file:///home/tdimiduk/cardpg/cardpg/.agent/skills/tabletop_rules_subagents/SKILL.md).
2. Provide the draft rules or card text, along with pointers to relevant syntheses in `design/research/synthesis/`.
3. Subagent evaluates the rules against the [Verisimilitude Audit Rubric](file:///home/tdimiduk/cardpg/cardpg/.agent/standards/empirical_research_standards.md#6-verisimilitude-audit-rubric-gross-violations-vs-casual-realism) in `empirical_research_standards.md`, distinguishing Gross Violations from Casual Realism stylization.
4. Subagent returns an objective audit report recommending adjustments to harmonize mechanics with reality without sacrificing playability.

---

## 4. Human Escalation Boundary

When a needed source cannot be obtained automatically, follow the [Human-in-the-Loop Sourcing Escalation Protocol](file:///home/tdimiduk/cardpg/cardpg/.agent/standards/empirical_research_standards.md#e-human-in-the-loop-sourcing-escalation-protocol) in `empirical_research_standards.md`:

- **Web UI Gate / CAPTCHA:** Request the user retrieve the file via browser for CLI ingestion (`archive_source.py ingest --file ...`).
- **Paywall:** Exhaust open-access preprints and government reviews first. If foundational and unreachable, record in `design/research/sources/DEFERRED_ACQUISITIONS.md` or request institutional library retrieval as a last resort.
